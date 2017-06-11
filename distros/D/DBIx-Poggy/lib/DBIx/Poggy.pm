use strict;
use warnings;
use v5.14;

package DBIx::Poggy;
our $VERSION = '0.08';

use Scalar::Util qw(weaken refaddr);

=head1 NAME

DBIx::Poggy - async Pg with AnyEvent and Promises

=head1 SYNOPSIS

    use strict;
    use warnings;

    use DBIx::Poggy;
    my $pool = DBIx::Poggy->new( pool_size => 5 );
    $pool->connect('dbi:Pg:db=test', 'root', 'password');

    use AnyEvent;
    my $cv = AnyEvent->condvar;

    my $res;
    $pool->take->selectrow_arrayref(
        'SELECT * FROM users WHERE name = ?', {}, 'ruz'
    )
    ->then(sub {
        my $user = $res->{user} = shift;

        return $pool->take->selectall_arrayref(
            'SELECT * FROM friends WHERE user_id = ?', undef, $user->{id}
        );
    })
    ->then(sub {
        my $friends = $res->{friends} = shift;
        ...
    })
    ->catch(sub {
        my $error = shift;
        die $error;
    })
    ->finally(sub {
        $cv->send( $res );
    });

    $cv->recv;

=head1 DESCRIPTION

"Async" postgres as much as L<DBD::Pg> allows with L<Promises> instead of callbacks.

You get DBI interface you used to that returns promises, connections pool, queries
queuing and support of transactions.

=head2 Why pool?

DBD::Pg is not async, it's non blocking. Every connection can execute only one query
at a moment, so to execute several queries in parallel you need several connections.
What you get is you can do something in Perl side while postgres crunches data for
you.

=head2 Queue

Usually if you attempt to run two queries on the same connection then DBI throws an
error about active query. Poggy takes care of that by queuing up queries you run on
one connection. Handy for transactions and pool doesn't grow too much.

=head2 What is async here then?

Only a queries on multiple connections, so if you need to execute many parallel
queries then you need many connections. pg_bouncer and haproxy are your friends.

=head2 Pool management

In auto mode (default) you just "loose" reference to database handle and it gets
released back into the pool after all queries are done:

    {
        my $cv = AnyEvent->condvar;
        $pool->take->do(...)->finally($cv);
        $cv->recv;
    }
    # released

Or:
    {
        my $cv = AnyEvent->condvar;
        my $dbh = $pool->take;
        $dbh->do(...)
        ->then(sub { $dbh->do(...) })
        ->then(sub { ... })
        ->finally($cv);
        $cv->recv;
    }
    # $dbh goes out of scope and all queries are done (cuz of condvar)
    # released

=cut

use DBIx::Poggy::DBI;
use DBIx::Poggy::Error;

=head1 METHODS

=head2 new

Named arguments:

=over 4

=item pool_size

number of connections to create, creates one more in case all are busy

=back

Returns a new pool object.

=cut

sub new {
    my $proto = shift;
    my $self = bless { @_ }, ref($proto) || $proto;
    return $self->init;
}

sub init {
    my $self = shift;
    $self->{pool_size} ||= 10;
    $self->{ping_on_take} ||= 30;
    return $self;
}

=head2 connect

Takes the same arguments as L<DBI/connect>, opens "pool_size" connections.
Saves connection settings for reuse when pool is exhausted.

=cut

sub connect {
    my $self = shift;
    my ($dsn, $user, $password, $opts) = @_;

    $opts ||= {};
    $opts->{RaiseError} //= 1;

    $self->{free} ||= [];

    $self->{connection_settings} = [ $dsn, $user, $password, $opts ];

    $self->_connect for 1 .. $self->{pool_size};
    return $self;
}

sub _connect {
    my $self = shift;

    my $dbh = DBIx::Poggy::DBI->connect(
        @{ $self->{connection_settings} }
    ) or die DBIx::Poggy::Error->new( 'DBIx::Poggy::DBI' );
    push @{$self->{free}}, $dbh;
    $self->{last_used}{ refaddr $dbh } = time;

    return;
}

=head2 take

Gives one connection from the pool. Takes arguments:

=over 4

=item auto

Connection will be released to the pool once C<dbh> goes out of
scope (gets "DESTROYED"). True by default.

=back

Returns L<DBIx::Poggy::DBI> handle. When "auto" is turned off
then in list context returns also guard object that will L</release>
handle to the pool on destruction.

=cut

sub take {
    my $self = shift;
    my (%args) = (auto => 1, @_);
    unless ( $self->{free} ) {
        die DBIx::Poggy::Error->new(
            err => 666,
            errstr => 'Attempt to take a connection from not initialized pool',
        );
    }
    my $dbh;
    while (1) {
        unless ( @{ $self->{free} } ) {
            warn "DB pool exhausted, creating a new connection";
            $self->_connect;
            $dbh = shift @{ $self->{free} };
            delete $self->{last_used}{ refaddr $dbh };
            last;
        }

        $dbh = shift @{ $self->{free} };
        my $used = delete $self->{last_used}{ refaddr $dbh };
        if ( (time - $used) > $self->{ping_on_take} ) {
            unless ( $dbh->ping ) {
                warn "connection is not alive, dropping";
                next;
            }
        }
        last;
    }

    if ( $args{auto} ) {
        $dbh->{private_poggy_state}{release_to} = $self;
        weaken $dbh->{private_poggy_state}{release_to};
        return $dbh;
    }
    return $dbh unless wantarray;
    return ( $dbh, guard { $self->release($dbh) } );
}

=head2 release

Takes a handle as argument and puts it back into the pool. At the moment,
no protection against double putting or active queries on the handle.

=cut

sub release {
    my $self = shift;
    my $dbh = shift;
    delete $dbh->{private_poggy_state}{release_to};

    if ( $dbh->err && !$dbh->ping ) {
        warn "handle is in error state and not ping'able, not releasing to the pool";
        return $self;
    }

    push @{ $self->{free} }, $dbh;
    $self->{last_used}{ refaddr $dbh } = time;
    return $self;
}

=head2 AUTHOR

Ruslan U. Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=head2 LICENSE

Under the same terms as perl itself.

=cut

1;

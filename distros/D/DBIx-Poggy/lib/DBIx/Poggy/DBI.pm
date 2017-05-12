use strict;
use warnings;

package DBIx::Poggy::DBI;
use base 'DBI';

=head1 NAME

DBIx::Poggy::DBI - DBI subclass

=head2 DESCRIPTION

Overrides several methods in L<DBI>. All queries are marked as async. See list of
supported methods below:

=cut

package DBIx::Poggy::DBI::db;
use base 'DBI::db';

use AnyEvent;
use DBD::Pg qw(:async);
use Promises qw(collect deferred);
use Scalar::Util qw(weaken blessed);
use Guard qw(guard);
use Devel::GlobalDestruction;

sub connected {
    my $self= shift;
    $self->{private_poggy_state} = {active => 0, queue => []};
    return;
}

=head2 METHODS

=head3 supported

These are supported: L<DBI/selectrow_array>, L<DBI/selectrow_arrayref>, L<DBI/selectrow_hashref>,
L<DBI/selectall_arrayref>, L<DBI/selectall_hashref> and L<DBI/do>.

For example:

    $pool->take->selectrow_array(
        "SELECT * FROM test LIMIT 1",
    )->then(sub {
        my @row = @_;
        ...
    });

See L</Transactions> to learn about L</begin_work>, L</commit> and L</rollback>.

=head3 not supported

These are not supported, but will be when I need them or somebody will write a patch:
L<DBI/selectcol_arrayref>

You don't use C<prepare>, C<bind*>, C<execute> or C<fetch*>. I have some ideas of making
these work, but don't think there is urgent need to pursue.

=cut

my %map = (
    selectrow_array => ['fetchrow_array'],
    selectrow_arrayref => ['fetchrow_arrayref'],
    selectrow_hashref => ['fetchrow_hashref'],
    selectall_arrayref => ['fetchall_arrayref', sub {
        my $in = shift;
        my ($query, $attrs) = splice @$in, 0, 2;
        my @fetch_args;
        @fetch_args = delete @{$attrs}{'Slice', 'MaxRows'} if $attrs;
        return (\@fetch_args, $query, $attrs, $in);
    } ],
    selectall_hashref => ['fetchall_hashref', sub {
        my $in = shift;
        my ($query, $key_field, $attrs) = splice @$in, 0, 3;
        my @fetch_args = $key_field;
        return (\@fetch_args, $query, $attrs, $in);
    } ],
    do => [''],
);
while ( my ($method, $fetch_method) = each %map ) {
    no strict 'refs';
    *{$method} = sub {
        my $self = shift;

        my $d = deferred;

        my @args = $fetch_method->[1]?
            ($d, $fetch_method->[0], $fetch_method->[1]->(\@_))
            : ($d, $fetch_method->[0], [], shift, shift, \@_)
        ;

        my $state = $self->{private_poggy_state};
        if ( $state->{active} ) {
            push @{$state->{queue}}, \@args;
            return $d->promise;
        }
        $self->_do_async( @args );
        return $d->promise;
    }
}

sub _do_async {
    my $self = shift;
    my ($d, $fetch_method, $fetch_args, $query, $args, $binds) = @_;

    my $sth;

    my $done = sub {
        my $method = shift;
        my @res = @_;
        if ( $method eq 'reject' ) {
            my $err = $self->errobj;
            $err->{errstr} ||= $res[0] if @res;
            unshift @res, $err;
        }
        if ( $sth ) {
            $sth->finish unless $method eq 'reject';
            $sth = undef;
        }

        $d->$method( @res );

        return;
    };

    $sth = eval { $self->prepare($query, $args) }
        or return $done->( 'reject', $@ );
    eval { $sth->execute( @$binds ) }
        or return $done->( 'reject', Carp::longmess($@) );

    my $guard;
    my $watcher = sub {
        my $ready;
        local $@;
        eval { $ready = $self->pg_ready; 1 } or do {
            return $done->('reject', $@);
        };
        return unless $ready;

        $guard = undef;
        my $res = eval { $self->pg_result } or return $done->( 'reject', $@ );
        return $done->(resolve => $res) unless $fetch_method;
        my @res;
        eval { @res = $sth->$fetch_method( @$fetch_args ); 1 } or return $done->('reject', $@);
        return $done->( resolve => @res );
    };
    $guard = AnyEvent->io( fh => $self->{pg_socket}, poll => 'r', cb => $watcher );
    return;
}

sub prepare {
    my $self = shift;
    my $args = ($_[1]||={});
    $args->{pg_async} ||= 0;
    $args->{pg_async} |= PG_ASYNC;

    my $sth = $self->SUPER::prepare( @_ );
    return $sth unless $sth;

    my $state = $self->{private_poggy_state};

    $state->{active}++;

    my $wself = $self;
    weaken $wself;
    $sth->{private_poggy_guard} = guard {
        --$state->{active};
        return unless @{ $state->{queue} };

        unless ($wself) {
            warn "still have pending sql queries, but dbh has gone away";
            return;
        }
        $wself->_do_async( @{ shift @{$state->{queue}} } );
    };
    return $sth;
}

=head3 Transactions

This module wraps L</begin_work>, L</commit> and L</rollback> methods to
help handle transactions.

B<NOTE> that behaviour is not yet defined when commiting or rolling back
a transaction with active query. I just havn't decided what to do in this
case. Now it's your job to make sure commit/rollback happens after all
queries on the handle.

=head4 begin_work

Returns a Promise that will be resolved once transaction is committed or
rejected on rollback or failed attempt to start the transaction.

=cut

sub begin_work {
    my $self = shift;
    my $d = deferred;
    $self->SUPER::begin_work(@_)
        or return $d->reject( $self->errobj )->promise;
    $self->{private_poggy_state}{txn} = $d;
    my $wself = $self;
    if ( my $pool = $self->{private_poggy_state}{release_to} ) {
        $d->finally(sub { $pool->release( $wself ) });
    }
    weaken $wself;
    return $d->promise;
}

=head4 commit

Takes resolution value of the transaction, commits and resolves the promise returned
by L</begin_work>.

=cut

sub commit {
    my $self = shift;
    my $d = delete $self->{private_poggy_state}{txn} or die "No transaction in progress";
    my $rv = $self->SUPER::commit();
    unless ( $rv ) {
        $d->reject($self->errobj);
        return $rv;
    }
    $d->resolve(@_);
    return $rv;
}

=head4 rollback

Takes rollback value of the transaction, commits and rejects the promise returned
by L</begin_work>.

=cut

sub rollback {
    my $self = shift;
    my $d = delete $self->{private_poggy_state}{txn} or die "No transaction in progress";
    my $rv = $self->SUPER::rollback();
    unless ( $rv ) {
        $d->reject($self->errobj);
        return $rv;
    }
    $d->reject(@_);
    return $rv;
}

sub errobj {
    my $self = shift;
    return DBIx::Poggy::Error->new( $self );
}

my $orig;
BEGIN { $orig = __PACKAGE__->can('DESTROY') }
sub DESTROY {
    my $self = shift;
    unless (in_global_destruction) {
        # ressurect DBH, bu pushing it back into the pool
        # I know it's hackish, but I couldn't find good way to implement
        # auto release that works transparently
        my $state = $self->{private_poggy_state} || {};
        if ( $state->{release_to} ) {
            $self->SUPER::rollback() if delete $state->{txn};
            return $state->{release_to}->release($self);
        }
    }
    return $orig->($self, @_) if $orig;
    return;
}

package DBIx::Poggy::DBI::st;
use base 'DBI::st';

sub errobj {
    my $self = shift;
    return DBIx::Poggy::Error->new( $self );
}

1;

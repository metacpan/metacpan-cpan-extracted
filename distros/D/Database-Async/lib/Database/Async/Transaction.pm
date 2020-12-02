package Database::Async::Transaction;

use strict;
use warnings;

our $VERSION = '0.013'; # VERSION

use parent qw(Database::Async::DB);

=head1 NAME

Database::Async::Transaction - represents a single database transaction in L<Database::Async>

=head1 DESCRIPTION

=cut

use Future;
use Class::Method::Modifiers qw(:all);

use Log::Any qw($log);

=head1 METHODS

=cut

=head2 new

Instantiates the transaction. This is not intended to be called directly;
that's normally handled by L<Database::Async> itself.

=cut

sub new {
    my ($class, %args) = @_;
    Scalar::Util::weaken($args{database} || die 'expected database parameter');
    $args{open} //= 0;
    bless \%args, $class
}

sub database { shift->{database} }

sub begin {
    my ($self) = @_;
    my $query = Database::Async::Query->new(
        db   => $self->database,
        sql  => 'begin',
        bind => [],
    );
    $query->single
        ->completed
}

sub pool { shift->{pool} }

sub completed { Future->done }

#sub do {
#    my ($self, $sql, %args) = @_;
#    $self->query($sql => %args);
#}

fresh commit => sub {
    my ($self) = @_;
    die 'transaction no longer active' unless $self->{open};
    Future->done->on_ready(sub { $self->{open} = 0 });
};

fresh rollback => sub {
    my ($self) = @_;
    return Future->done unless delete $self->{has_activity};
    die 'transaction no longer active' unless $self->{open};
    Future->done->on_ready(sub { $self->{open} = 0 });
};

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    return unless $self->{open};
    $self->rollback->retain;
}

before [@Database::Async::Query::METHODS] => sub {
    my ($self) = @_;
    $self->{has_activity} //= 1;
    $self->{open} //= 1;
};

sub diagnostics {
    my ($self) = @_;
    die 'need a valid pool instance' unless my $pool = $self->pool;
    die 'pool does not appear to be correct type' unless $pool->DOES('Database::Async::Pool');
    die 'inconsistent activity/open status' if $self->{open} and !$self->{has_activity};
    Future->done;
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.


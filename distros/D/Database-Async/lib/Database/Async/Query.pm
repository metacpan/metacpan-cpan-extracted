package Database::Async::Query;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

=head1 NAME

Database::Async::Query

=head1 SYNOPSIS

 my $query = Database::Async::Query->new(
  db => Database::Async->new(...),
 );

=head1 DESCRIPTION

=cut

use Database::Async::Row;

use Future;
use Ryu::Async;
use Scalar::Util;

use Log::Any qw($log);

use overload
    '""' => sub { ref(shift) },
    bool => sub { 1 },
    fallback => 1;

sub new {
    my ($class, %args) = @_;
    Scalar::Util::weaken($args{db});
    bless \%args, $class;
}

=head2 db

Accessor for the L<Database::Async> instance.

=cut

sub db { shift->{db} }

sub sql { shift->{sql} }
sub bind { @{shift->{bind}} }

sub row_description {
    my ($self, $desc) = @_;
    $log->tracef('Have row description %s', $desc);
}

sub row {
    my ($self, $row) = @_;
    $log->tracef('Have row %s', $row);
    $self->{row_data}->emit($row);
}

sub row_hashrefs {
    my ($self) = @_;
    $self->{row_hashrefs} //= $self->row_data
        ->map(sub {
            +{ map {; $_->{description}->name => $_->{data} } @$_ }
        });
}

sub row_arrayrefs {
    my ($self) = @_;
    $self->{row_arrayrefs} //= $self->row_data
        ->map(sub {
            [ map {; $_->{data} } @$_ ]
        });
}

=head2 start

Schedules this query for execution.

=cut

sub start {
    my ($self) = @_;
    $self->{queued} //= $self->db->queue_query($self)->retain;
}

sub run_on {
    my ($self, $engine) = @_;
    $log->tracef('Running query %s on %s', $self, $engine);
    $engine->simple_query(
        $self->sql,
        $self->bind
    );
}

=head2 rows

Returns a L<Ryu::Source> representing the rows of this transaction.

Each row is a L<Database::Async::Row> instance.

Will call L</start> if required.

=cut

sub row_data {
    my ($self) = @_;
    $self->start;
    $self->{row_data} //= $self->db->new_source;
}

sub done {
    my ($self) = @_;
    $self->{row_data}->completed->done
}

sub rows {
    my ($self) = @_;
    $self->{rows} //= $self->row_data
        ->map(sub {
            my ($row) = @_;
            Database::Async::Row->new(
                index_by_name => +{ map { $row->[$_]->{description}->name => $_ } 0..$#$row },
                data          => $row
            )
        })
}

=head2 single

Defaults to all columns, provide a list of indices to select a subset.

=cut

sub single {
    my ($self, @id) = @_;
    $self->{single} //= $self->row_data
        ->first
        ->map(sub {
            my ($item) = shift;
            map {; $item->[$_]{data} } (@id ? @id : 0..$#$item)
        })->as_list;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2018. Licensed under the same terms as Perl itself.


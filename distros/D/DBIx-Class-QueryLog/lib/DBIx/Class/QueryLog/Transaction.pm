package DBIx::Class::QueryLog::Transaction;
$DBIx::Class::QueryLog::Transaction::VERSION = '1.005001';
# ABSTRACT: A Transaction

use Moo;
use Types::Standard qw( Bool ArrayRef );

extends 'DBIx::Class::QueryLog::Query';

has committed => (
    is => 'rw',
    isa => Bool
);

has queries => (
    traits => [qw(Array)],
    is => 'rw',
    isa => ArrayRef,
    default => sub { [] },
);

sub add_to_queries { push @{shift->queries}, @_ }
sub count { scalar @{shift->queries} }

has rolledback => (
    is => 'rw',
    isa => Bool
);

sub time_elapsed {
    my $self = shift;

    my $total = 0;
    foreach my $q (@{ $self->queries }) {
        $total += $q->time_elapsed;
    }

    return $total;
}

sub get_sorted_queries {
    my ($self, $sql) = @_;

    my @qs;
    if($sql) {
        @qs = grep({ $_->sql eq $sql } @{ $self->queries });
    } else {
        @qs = @{ $self->queries };
    }

    return [ reverse sort { $a->time_elapsed <=> $b->time_elapsed } @qs ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::QueryLog::Transaction - A Transaction

=head1 VERSION

version 1.005001

=head1 SYNOPSIS

Represents a transaction.  All queries executed with the context of this
transaction are stored herein, as well as a start time, end time and flag
for committed or rolledback.

=head1 METHODS

=head2 new

Create a new DBIx::Class::QueryLog::Transcation

=head2 bucket

The bucket this tranaction is in.

=head2 queries

Arrayref containing all queries executed, in order of execution.

=head2 committed

Flag indicating if this transaction was committed.

=head2 rolledback

Flag indicating if this transaction was rolled back.

=head2 start_time

Time this transaction started.

=head2 end_time

Time this transaction ended.

=head2 time_elapsed

Time this transaction took to execute.  start - end.

=head2 add_to_queries

Add the provided query to this transactions list.

=head2 count

Returns the number of queries in this Transaction

=head2 get_sorted_queries([ $sql ])

Returns all the queries in this Transaction, sorted by elapsed time.
(descending).

If given an argument of an SQL statement, only queries matching that statement
will be considered.

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Cory G Watson <gphat at cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Cory G Watson <gphat at cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

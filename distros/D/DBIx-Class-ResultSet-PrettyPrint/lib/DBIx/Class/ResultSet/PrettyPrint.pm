package DBIx::Class::ResultSet::PrettyPrint;

use 5.010;
use strict;
use warnings;

use Moo;
use Text::Table::Tiny qw( generate_table );


=head1 NAME

DBIx::Class::ResultSet::PrettyPrint - Pretty print DBIx::Class result sets.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use DBIx::Class::ResultSet::PrettyPrint;
    use Schema;  # load your DBIx::Class schema

    # load your database and fetch a result set
    my $schema = Schema->connect( 'dbi:SQLite:books.db' );
    my $books = $schema->resultset( 'Book' );

    # pretty print the result set
    my $pp = DBIx::Class::ResultSet::PrettyPrint->new();
    $pp->print_table( $books );

    +----+---------------------+---------------+------------+-----------+---------------+
    | id | title               | author        | pub_date   | num_pages | isbn          |
    +----+---------------------+---------------+------------+-----------+---------------+
    | 2  | Perl by Example     | Ellie Quigley | 1994-01-01 | 200       | 9780131228399 |
    | 4  | Perl Best Practices | Damian Conway | 2005-07-01 | 517       | 9780596001735 |
    +----+---------------------+---------------+------------+-----------+---------------+

=head1 DESCRIPTION

Ever wanted to quickly visualise what a C<DBIx::Class> result set looks like
(for instance, in tests) without having to resort to reproducing the query
in SQL in a DBMS REPL?  This is what this module does: it pretty prints
result sets wherever you are, be it in tests or within a debugging session.

While searching for such a solution, I stumbled across L<an answer on
StackOverflow|https://stackoverflow.com/a/4072923/10874800> and thought:
that would be nice as a module.  And so here it is.

=head1 SUBROUTINES/METHODS

=head2 C<new()>

Constructor; creates a new pretty printer object.

=head2 C<print_table( $result_set )>

Print the "table" from the given result set.

=cut

sub print_table {
    my ($self, $result_set) = @_;

    my @columns = $result_set->result_source->columns;

    my @rows = ( \@columns );
    while ( my $row = $result_set->next ) {
        my @data = map { $row->get_column($_) } @columns;
        push @rows, \@data;
    }

    print generate_table( rows => \@rows, header_row => 1 ), "\n";

    return;  # Explicitly returning nothing meaningful
}

=head1 ACKNOWLEDGEMENTS

I borrowed heavily upon the test structure used in
L<https://github.com/davidolrik/DBIx-Class-FormTools> for the test database
setup and creation.

=head1 AUTHOR

Paul Cochrane, C<< <paul at peateasea.de> >>

=head1 BUGS

Please report any bugs or feature requests via the project's GitHub
repository at
L<https://github.com/paultcochrane/DBIx-Class-ResultSet-PrettyPrint>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::ResultSet::PrettyPrint

Bug reports and pull requests are welcome.  Please submit these to the
L<project's GitHub
repository|https://github.com/paultcochrane/DBIx-Class-ResultSet-PrettyPrint>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Paul Cochrane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; # End of DBIx::Class::ResultSet::PrettyPrint

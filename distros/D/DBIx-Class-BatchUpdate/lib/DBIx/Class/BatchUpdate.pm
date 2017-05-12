package DBIx::Class::BatchUpdate;
$DBIx::Class::BatchUpdate::VERSION = '1.004';
use base qw(DBIx::Class);
use strict;
use warnings;
use true;

use DBIx::Class::BatchUpdate::Update;



sub batch_update {
    my $self = shift;
    my ($rows) = @_;
    return DBIx::Class::BatchUpdate::Update->new({
        resultset => $self,
        rows      => $rows,
    })->update();
}



=head1 NAME

DBIx::Class::BatchUpdate - Update batches of DBIC rows with as few queries as possible

=head1 SYNOPSIS

    # In your result class, e.g. MySchema::ResultSet::Book
    __PACKAGE__->load_components("BatchUpdate");


    # In your code, update loads of row objects and keep track of them
    $book_row1->is_out_of_print(1);
    $book_row2->is_out_of_print(1);
    $book_row3->is_out_of_print(1);
    $book_row3->price(42);
    my $book_rows = [ $book_row1, $book_row2, $book_row3 ];

    # Batch update all rows in as few UPDATE statements as possible
    $schema->resultset("Book")->batch_update($book_rows);

    # SQL queries
    # 1 UPDATE for all the rows with is_out_of_print: 1
    # 1 UPDATE for all the rows with is_out_of_print: 1, price: 42


    # Alternatively, create your own BatchUpdate::Update object:
    use DBIx::Class::BatchUpdate::Update;

    DBIx::Class::BatchUpdate::Update->new({
        rows => $rows,
    })->update();


=head1 DESCRIPTION

This module is for when you have loads of DBIC rows to update as part
of some large scale processing, and you want to avoid making
individual calls to $row->update for each of them. If the number of
dirty rows is large, the many round-trips to the database will be
quite time consuming.

So instead of calling $row->update you collect all the dirty row
objects (of the same Result class) for later and then let
DBIx::Class::BatchUpdate update the database with as few queries as
possible.

This means that if the same columns have been set to the same value in
all the rows, this will be done in a single query. The more different
combinations of columns and values there are in rows, the more queries
are required.


=head1 USAGE

=head2 As a DBIC component

    # In your result class, e.g. MySchema::ResultSet::Book
    __PACKAGE__->load_components("BatchUpdate");

Adding the DBIC component to a ResultSet class enables you to call
->batch_update on the resultset.

It is even more useful to put this in your base class for all the
ResultSet classes, so it's available for all resultsets.


=head3 $resultset->batch_update($rows)

Make UPDATE queries on the $resultset to update all the dirty columns
in the arrayref $rows.

Make the fewest number of queries given the different values to
update.

The $rows must all be of the same ResultSet class as $resultset. $rows
may well be an empty arrayref.

All the $rows must already exist in the database and have an ->id. The
PK column itself must not be dirty.



=head2 As a regular module

=head3 $batch_update->update($rows)

Example:

    use DBIx::Class::BatchUpdate::Update;
    DBIx::Class::BatchUpdate::Update->new({ rows => $rows })->update();

This is functionally the same as the above.

Note that all $rows must be of the same Result class.



=head1 CAVEATS

=head2 Multi-column primary keys

BatchUpdate only works with resultsets that have a single column PK.



=head1 DEVELOPMENT

=head2 Author

Johan Lindstrom, C<< <johanl [AT] cpan.org> >>


=head2 Contributors



=head2 Source code

L<https://github.com/jplindstrom/p5-DBIx-Class-BatchUpdate>


=head2 Bug reports

Please report any bugs or feature requests on GitHub:

L<https://github.com/jplindstrom/p5-DBIx-Class-BatchUpdate/issues>.


=head2 Caveats


=head1 COPYRIGHT & LICENSE

Copyright 2016- Broadbean Technologies, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 ACKNOWLEDGEMENTS

Thanks to Broadbean for providing time to open source this during one
of the regular Hack-days.

=cut

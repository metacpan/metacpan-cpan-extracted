package DBIx::Insert::Multi;
use 5.010000;

our $VERSION = "0.003";

use Moo;

=head1 NAME

DBIx::Insert::Multi -- Insert multiple table rows in a single statement

=head1 SYNOPSIS

    use DBIx::Insert::Multi;

    my $dbh = DBI->connect(...);

    my $multi = DBIx::Insert::Multi->new({ dbh => $dbh, });
    $multi->insert(
        book => [
            {
                title            => "Winnie the Pooh",
                author           => "Milne",
                publication_date => DateTime->new(year => 1926)->ymd,
            },
            {
                title            => "Paddington",
                author           => "Bond",
                publication_date => DateTime->new(year => 1958)->ymd,
            },
        ],
    );   # die on error

    # Database specific INSERT statement
    # MySQL: don't stop on errors
    my $multi = DBIx::Insert::Multi->new({
        ...
        insert_sql_fragment => "INSERT IGNORE INTO",
    });

=head1 DESCRIPTION

Bulk insert many db rows using a single INSERT INTO statement, e.g.

    INSERT INTO book (author, publication_date, title) VALUES
        ( ?, ?, ? ),
        ( ?, ?, ? );

=head2 Restrictions

All the hashrefs with row data should be shaped the same, i.e. have
the same keys.

You should only use values that can be inserted into a database.

That means no data structures (refs), and no objects. However, objects
will be stringified, so if they have overloaded stringification that
will work.

Note that L<DateTime> objects are stringified to a format that is
unlikely to work correctly with your database date format (and without
a timezone), so make sure you construct strings manually before
inserting them.

Undefs become NULL as usual.



=head1 ISSUES

=head2 last_insert_id

It may be that you need to get hold of the PK ids of the inserted
rows. This is very non-standard and fiddly, so at this point this
module doesn't officially do any of that.

You can do this yourself though, but I wouldn't bet it's very
reliable.

    $dbh->last_insert_id(undef, undef, $table, undef);

Calling "$dbh->last_insert_id" returns a newly inserted row PK
value. It seems to vary between databases whether this is the id of
the first row or the last one. For instance:

=over

=item *

MySQL: first

=item *

Postgres: last

=back

If the PK is an auto-increment / sequence, it is probably not
B<guaranteed> that these ids are in an unbroken series, but at least
MySQL B<seems> to do that.

Read more about all the caveats here: L<DBI/"last_insert_id">.


=head3 Returning ids

Some databases (Postgres) support INSERT INTO ... RETURNING, which can
be used to retrieve data from the inserted rows. This seems to be the
only reliable way to do this.

This module can't do this at the moment, but patches are
welcome. Please submit a bug to open a discission about what the API
should look like.

=cut

use DBIx::Insert::Multi::Batch;



has dbh => ( is => "ro", required => 1 );

has insert_sql_fragment => ( is => "lazy" );
sub _build_insert_sql_fragment { "INSERT INTO" }

has is_last_insert_id_required => ( is => "lazy" );
sub _build_is_last_insert_id_required { 0 }



=head1 METHODS

=head2 insert($table_name, $records_arrayref)

Perform the insert into $table_name of all the rows in
$records_arrayref (arrayref with hashrefs, where the hashref keys are
the column names, and the values are the column values).

The return value not specified. If the query fails, die.

=cut

sub insert {
    my $self = shift;
    my ($table, $records) = @_;
    return DBIx::Insert::Multi::Batch->new({
        dbh                        => $self->dbh,
        insert_sql_fragment        => $self->insert_sql_fragment,
        is_last_insert_id_required => $self->is_last_insert_id_required,
        table                      => $table,
        records                    => $records,
    })->insert();
}



1;


=head1 SEE ALSO

=head2 DBIx::Class

If you already have a L<DBIx::Class> schema, you can bulk insert rows
efficiently using the L<DBIx::Class::ResultSet/populate> method (note:
in void context!). You won't get back the new ids.



=head1 DEVELOPMENT

=head2 Author

Johan Lindstrom, C<< <johanl [AT] cpan.org> >>


=head2 Source code

L<https://github.com/jplindstrom/p5-DBIx-Insert-Multi>


=head2 Bug reports

Please report any bugs or feature requests on GitHub:

L<https://github.com/jplindstrom/p5-DBIx-Insert-Multi/issues>.



=head1 COPYRIGHT & LICENSE

Copyright 2019- Broadbean Technologies, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 ACKNOWLEDGEMENTS

Thanks to Broadbean for providing time to open source this module.

=cut

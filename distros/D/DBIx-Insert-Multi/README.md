# NAME

DBIx::Insert::Multi -- Insert multiple table rows in a single statement

# SYNOPSIS

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

# DESCRIPTION

Bulk insert many db rows using a single INSERT INTO statement, e.g.

    INSERT INTO book (author, publication_date, title) VALUES
        ( ?, ?, ? ),
        ( ?, ?, ? );

## Restrictions

All the hashrefs with row data should be shaped the same, i.e. have
the same keys.

You should only use values that can be inserted into a database.

That means no data structures (refs), and no objects. However, objects
will be stringified, so if they have overloaded stringification that
will work.

Note that [DateTime](https://metacpan.org/pod/DateTime) objects are stringified to a format that is
unlikely to work correctly with your database date format (and without
a timezone), so make sure you construct strings manually before
inserting them.

Undefs become NULL as usual.

# ISSUES

## last\_insert\_id

It may be that you need to get hold of the PK ids of the inserted
rows. This is very non-standard and fiddly, so at this point this
module doesn't officially do any of that.

You can do this yourself though, but I wouldn't bet it's very
reliable.

    $dbh->last_insert_id(undef, undef, $table, undef);

Calling "$dbh->last\_insert\_id" returns a newly inserted row PK
value. It seems to vary between databases whether this is the id of
the first row or the last one. For instance:

- MySQL: first
- Postgres: last

If the PK is an auto-increment / sequence, it is probably not
**guaranteed** that these ids are in an unbroken series, but at least
MySQL **seems** to do that.

Read more about all the caveats here: ["last\_insert\_id" in DBI](https://metacpan.org/pod/DBI#last_insert_id).

### Returning ids

Some databases (Postgres) support INSERT INTO ... RETURNING, which can
be used to retrieve data from the inserted rows. This seems to be the
only reliable way to do this.

This module can't do this at the moment, but patches are
welcome. Please submit a bug to open a discission about what the API
should look like.

# METHODS

## insert($table\_name, $records\_arrayref)

Perform the insert into $table\_name of all the rows in
$records\_arrayref (arrayref with hashrefs, where the hashref keys are
the column names, and the values are the column values).

The return value not specified. If the query fails, die.

# SEE ALSO

## DBIx::Class

If you already have a [DBIx::Class](https://metacpan.org/pod/DBIx::Class) schema, you can bulk insert rows
efficiently using the ["populate" in DBIx::Class::ResultSet](https://metacpan.org/pod/DBIx::Class::ResultSet#populate) method (note:
in void context!). You won't get back the new ids.

# DEVELOPMENT

## Author

Johan Lindstrom, `<johanl [AT] cpan.org>`

## Source code

[https://github.com/jplindstrom/p5-DBIx-Insert-Multi](https://github.com/jplindstrom/p5-DBIx-Insert-Multi)

## Bug reports

Please report any bugs or feature requests on GitHub:

[https://github.com/jplindstrom/p5-DBIx-Insert-Multi/issues](https://github.com/jplindstrom/p5-DBIx-Insert-Multi/issues).

# COPYRIGHT & LICENSE

Copyright 2019- Broadbean Technologies, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# ACKNOWLEDGEMENTS

Thanks to Broadbean for providing time to open source this module.

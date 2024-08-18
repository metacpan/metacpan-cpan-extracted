# NAME

DBIx::Squirrel - A `DBI` extension

# VERSION

version 1.2.9

# SYNOPSIS

    # ------------------
    # Import the package
    # ------------------

    use DBIx::Squirrel;

    # We still have the freedom to accomplish tasks the familiar DBI-way.
    #
    $dbh = DBIx::Squirrel->connect($dsn, $user, $pass, \%attr);
    $sth = $dbh->prepare('SELECT * FROM product WHERE Name=?');

    if ( $sth->execute('Acme Rocket') ) {
        $row = $sth->fetchrow_hashref
        print $row->{Name}, "\n";
        $sth->finish
    }

    # ------------------------------
    # Import the package (variation)
    # ------------------------------

    use DBIx::Squirrel database_entities => [qw/db product/];

    # Associate "db" with a database connection, then use "db" to reference
    # it in future.
    #
    db(DBIx::Squirrel->connect($dsn, $user, $pass, \%attr));

    # First, we need to associate "product" with a result set, then use
    # "product" to reference itt in future. The next time arguments are
    # passed, they are treated as bind-values when the statement is
    # executed.
    #
    product(db->results('SELECT * FROM product WHERE Name=?'));

    # Print the named product if there is one. The "single" method will
    # finish the statement automatically.
    #
    print $_->Name, "\n" if product('Acme Rocket')->single;

    # ----------------------------
    # Cloning database connections
    # ----------------------------

    # Cloning connections created by the DBI, DBIx::Squirrel and
    # subclasses is permitted.
    #
    $dbh = DBI->connect($dsn, $user, $pass, \%attr);
    $clone = DBIx::Squirrel->connect($dbh);

    # -----------------------------------------
    # Parameter placeholders and binding values
    # -----------------------------------------

    # Several commonly used placeholder styles are supported and just work!
    #
    # Use the style you prefer. DBIx::Squirrel doesn't care about the DBD
    # engine you are using. By the time the statement is prepared, it will
    # have been normalised to use the legacy style ("?") supported by all
    # engines.
    #
    # Oracle
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=:id');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=:1');

    # Postgres
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=$1');

    # SQLite
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=?1');

    # MySQL, MariaDB and legacy
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=?');

    # Able to bind values to individual parameters for both positional
    # and named placeholder schemes.

    # Use either of these calling styles when binding a value to a
    # named placeholder; both are ok.
    #
    $sth->bind_param(id => '1001099');
    $sth->bind_param(':id', '1001099');

    # Use this calling styles when binding a values to a positional
    # placeholder.
    #
    $sth->bind_param(1, '1001099');

    # Or, bind all values in one call.
    #
    $sth->bind( id => '1001099', ... );
    $sth->bind( ':id' => '1001099', ... );
    $sth->bind( '1001099', ... );

    # References are ok, too.
    #
    $sth->bind( { id => '1001099', ... } );
    $sth->bind( { ':id' => '1001099', ... } );
    $sth->bind( [ '1001099', ... ] );

    # You can also pass the bind values in the same manner to
    # the "execute" and "iterate" methods.
    #
    $res = $sth->execute(...);
    $res = $itr->execute(...);
    $itr = $itr->iterate(...);

    # --------------------------------------------
    # The database connection object's "do" method
    # --------------------------------------------

    # WHEN CALLED IN SCALAR-CONTEXT, the "do" method is used exactly as
    # it would when working with the DBI. The only difference is that
    # the DBIx::Squirrel interface allows for more options in how
    # bind-values are passed.
    #
    $res = $dbh->do('SELECT * FROM product WHERE id=?', '1001099');
    $res = $dbh->do('SELECT * FROM product WHERE id=?', ['1001099']);
    $res = $dbh->do('SELECT * FROM product WHERE id=:id', id => '1001099');
    $res = $dbh->do('SELECT * FROM product WHERE id=:id', ':id' => '1001099');

    # You must supply hash reference (or "undef") as the statement attributes,
    # when bind-values are presented as a hash reference.
    #
    $res = $dbh->do(
        'SELECT * FROM product WHERE id=:id',
        undef | \%attr,
        { ':id' => '1001099'}
    );
    $res = $dbh->do(
        'SELECT * FROM product WHERE id=:id',
        undef | \%attr,
        { id => '1001099' },
    );

    # WHEN CALLED IN LIST-CONTEXT, however, the "do" method works as
    # described previously, but returns both the statement's execution
    # result and its handle (in that order).
    #
    ($res, $sth) = $dbh->do(...);

    # ---------
    # Iterators
    # ---------

    # Both database and statement objects can be used to generate two
    # kinds of iterator.
    #
    # A basic iterator.
    #
    $itr = $dbh->iterate($query, \%attr, ...);
    $itr = $sth->iterate(...);

    # A fancy iterator (or result set).
    #
    $itr = $dbh->results($query, \%attr, ...);
    $itr = $sth->results(...);

    # When we only expect one row, and we require the statement to be
    # finished after that row is fetched, we can call the "single"
    # method (or its alias "one").
    #
    # This method will emit a warning if there are more rows to fetch
    # as a reminder to use "LIMIT 1" in your query.
    #
    $row = $itr->single(OPTIONAL-NEW-BIND-VALUES)
      or die "No matching row!";

    $row = $itr->one(OPTIONAL-NEW-BIND-VALUES)
      or die "No matching row!";

    # As above, but won't whinge if there were unexpectedly more rows
    # available to be fetched.
    #
    $row = $itr->find(OPTIONAL-NEW-BIND-VALUES)
      or die "No matching row!";

    # Populate an array using "next".
    #
    @ary = ();
    push @ary, $_ while $itr->next;

    @ary = $itr->first;
    push @ary, $_ while $itr->next;

    # Get everything at once.
    #
    @ary = $itr->first;
    push @ary, $itr->remaining;

    @ary = $itr->all;

    # Having "all" return a reference is faster!
    #
    $ary_ref = $itr->all;

    # Get the number of records. More memory efficient than "count_all",
    # since "next" is called after each record is read and discarded.
    #
    $num = $itr->count();

    # Get the number of records. Not as memory efficient as "count", since
    # all rows are fetched at once and the size of the resulting array
    # is returned.
    #
    $num = $itr->count_all();

    # Reset an iterator so that it will be executed again.
    #
    $itr = $itr->reset();

    # Reset the iterator. Also set the slice-style.
    #
    $itr = $itr->reset({});
    $itr = $itr->reset([]);

    # Reset the iterator. Also specify how many rows to slurp at a time.
    #
    $itr = $itr->reset(10);

    # Reset the iterator. Set the slice style and how slurpy our row fetches
    # are.
    #
    $itr = $itr->reset($slice, $row_count);
    $itr = $itr->reset($row_count, $slice);

    # --------------------
    # Working with results
    # --------------------

    # Accessing column values using basic iterators.
    #
    $itr = $dbh->iterate('SELECT Id, Name FROM product WHERE Name=?')->reset([]);
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: $row->[0]\n"
    }

    $itr = $dbh->iterate('SELECT Id, Name FROM product WHERE Name=?')->reset({});
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: $row->{Id}\n"
    }

    # Accessing column values using using fancy iterators can be accomplished
    # as shown above. Fancy iterators, however, don't care how your rows are
    # sliced, because they also provide access to column values via on-demand
    # accessors. You can use any case for accessors as they all resolve to
    # the same column.
    #
    $itr = $dbh->results('SELECT Id, Name FROM product WHERE Name=?');
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: ", $row->Id, "\n"
    }

    $itr = $dbh->results('SELECT Id, Name FROM product WHERE Name=?');
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: ", $row->ID, "\n"
    }

    $itr = $dbh->results('SELECT Id, Name FROM product WHERE Name=?');
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: ", $row->id, "\n"
    }

    # ---------------
    # Transformations
    # ---------------

    # A transformation is a sequence of one or more trailing code references
    # passed to the method that generates the iterator. The initial result
    # enters the first stage of the transformation as $_ (and in $_[0]). The
    # result of that transformation is passed on to the next stage (or to the
    # caller), with an explicit "return" statement or as the result of the
    # sfinal expression.
    #
    # Transformations are a great way to declare, in one place, any common
    # processing logic that should be applied automatically to results as
    # they are fetched.
    #
    $itr = $dbh->iterate(
        'SELECT Id, Name FROM product WHERE Name=?' => sub {$_->[0]},
    )->reset([]);
    if ($id = $itr->iterate('Acme Rocket')->single) {
        print "Id: $id\n"
    }

    $itr = $dbh->iterate(
        'SELECT Id, Name FROM product WHERE Name=?' => sub {$_->{Id}},
    )->reset({});
    if ($id = $itr->iterate('Acme Rocket')->single) {
        print "Id: $id\n"
    }

    $itr = $dbh->results(
        'SELECT Id, Name FROM product WHERE Name=?' => sub {$_->Id},
    );
    if ($id = $itr->iterate('Acme Rocket')->single) {
        print "Id: $id\n"
    }

    # Transformation squences.
    #
    $itr = $dbh->results(
        'SELECT Id, Name FROM product WHERE Name=?' => sub {
            $_->Id;
        } => sub {
            my $result = $_;
            print "Id: $result\n";
            return $result;
        },
    );
    $id = $itr->iterate('Acme Rocket')->single;

# DESCRIPTION

The `DBIx::Squirrel` package extends the `DBI` by providing a few extra
conveniences that are subtle and additive in nature, and, hopefully, quite
useful.

## Importing the package

In the simplest case, just import the package as you would any other:

    use DBIx::Squirrel;

Any symbols and tags that you would typically import from the `DBI` can
also be requested via `DBIx::Squirrel`:

    use DBIx::Squirrel DBI-IMPORT-LIST;

If required (and in addition to any `DBI` imports), `DBIx::Squirrel` can
create and import Database Entity Helper functions for you:

    use DBIx::Squirrel database_entity=>NAME;
    use DBIx::Squirrel database_entities=>[NAMES];

### Database Entity Helper Functions

A database entity helper is nothing more than a standard function providing
some syntactic sugar in the form of a polymorphic interface for interacting
with database entities such as database connections, statements and
iterators.

While it is not absolutely necessary to use them—you could just as
easily use scalar references—helper functions do possess the advantage
of being shared more easily among package namespaces than, say, lexical
variables.

Helper semantics deal with three common types of interaction:

- **Establishing an association**

    Before it can be used, a helper must first be associated with a database
    entity. This is accomplished by passing the function single argument: a
    reference to the associated object.

    Once established, associations are _sticky_ and cannot easily be undone.
    You should take care to create them once only, in a sensible place.

    Use Perl's standard importing mechanisms (as shown above) to share
    associations among different package namespaces.

- **Resolving an association**

    Fetching the reference to the associated database entity is accomplished
    by calling the helper function without any arguments.

    When no association exists in this scenario, a helper returns `undef`.

- **Addressing an association**

    Addressing an association amounts to doing something meaningful with it,
    and we accomplish this by calling the helper function with one or more
    arguments.

    Once associated with a database entity, a helper function will consume
    any arguments that are passed to it and send a version of these to the
    database entity method that imparts meaning to the interaction.

    Meaning in this context is determined by the type of association:

    - for a database connection, a statement is prepared using the `prepare` method;
    - for statements and iterators, these are executed with the `execute` and `iterate`
    methods respectively.

    **Clearly there is a paradox here**, and itcentres around those statements
    and iterators that take no parameters and expect no bind-values. In order
    to smooth-out this wrinkle, you can opt to enclose arguments inside an
    anonymous array or hash. When no bind-values are expected, you can coerce
    the helper into performing the execution by passing an empty ARRAYREF or
    HASHREF. Alternatively, you could just resolve the association and call
    the relevant method manually.

#### Examples

- Let us do a full worked example. We will connect to a database, create and
work with two result sets, one of which expects a single bind-value. Some
concepts will be expanded upon and improved later, but it might be helpful
to dip a toe in the water ahead of time:

        use DBIx::Squirrel database_entities => [ qw/db artists artist/ ];

        # Associate helper ("db") with our database connection:

        @connect_args = ( 'dbi:SQLite:dbname=chinook.db', '', '', { sqlite_unicode => 1 } );
        db( DBIx::Squirrel->connect(@connection_args) );

        # Resolve the database connection helper ("db"), using it to
        # associate helpers ("artist" and "artists") with different
        # result sets:

        artist( db->results('SELECT * FROM artists WHERE Name=? LIMIT 1') );
        artists( db->results('SELECT * FROM artists') );

        # Address the helper ("artist"), passing it a bind-value, to get
        # the ArtistId of the artist whose name is "Aerosmith".
        #
        # We could have called "next" to get the only matching record, but by
        # calling "single" (or "first") we can ensure that there are no warnings
        # about dangling active statements emitted when we disconnect from the
        # database.

        print artist('Aerosmith')->single->ArtistId, "\n";

        # Iterate over the "artists" result set, printing the Name-column for
        # each artist. We don't need to trigger execution manually because
        # the "next" method will do that for us, if it is necessary.

        while ( artists->next ) {
            print $_->Name, "\n";
        };

## Connecting to databases

Connecting to a database using `DBIx::Squirrel` may be done exactly as it
would when using the `DBI`'s `connect_cached` and `connect` methods.

### Cloning database connections

The `connect` method implemented by the `DBIx::Squirrel` package offers
an alternative form:

    $new_dbh = DBIx::Squirrel->connect($original_dbh, \%attr);

This form clones another connection object and returns a brand new object
that is blessed using the same class that invoked the `connect` method.
The method will allow you to clone database connections created by the
`DBI` and any subclasses (`DBIx::Squirrel` being one).

## Preparing statements

Preparing a statement using `DBIx::Squirrel` may be done exactly as
it would be done using the `DBI`'s `prepare_cached` and `prepare`
methods.

### Placeholders

A nice quality-of-life improvement offered by `DBIx::Squirrel`'s own
implementation of the `prepare_cached` and `prepare` methods is their
built-in ability to cope with a number of different placeholder styles:

- named (`:name`);
- positional (`:number`, `$number`, `?number`);
- legacy (`?`)

It does not matter what style your `DBD`-driver supports, `DBIx::Squirrel`
will happily deal with all of the above styles. Just pick the one that
you prefer to work with, or use the one that is most suitable for the
task at hand.

By the time your statement is passed to the `DBD`-driver for execution,
both it and its bind-values will have been normalised to use the legacy
style (`?`) supported by all drivers.

#### Examples

- Legacy placeholders (`?`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=? LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute('Aerosmith');
        $res = $sth->execute(['Aerosmith']);

- SQLite positional placeholders (`?number`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=?1 LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute('Aerosmith');
        $res = $sth->execute(['Aerosmith']);

- PostgreSQL positional placeholders (`$number`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=$1 LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute('Aerosmith');
        $res = $sth->execute(['Aerosmith']);

- Oracle positional placeholders (`:number`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=:1 LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute('Aerosmith');
        $res = $sth->execute(['Aerosmith']);

- Oracle named placeholders (`:name`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=:Name LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute(Name => 'Aerosmith');
        $res = $sth->execute( ':Name' => 'Aerosmith');
        $res = $sth->execute({Name => 'Aerosmith'});
        $res = $sth->execute({':Name' => 'Aerosmith'});

## Iterators

In addition to statement objects, `DBIx::Squirrel` provides two kinds
of iterator:

- Basic
- Fancy, _or Result Sets_

### Basic Iterators

Basic iterators present row data as ARRAYREFs or HASHREFs depending
on the slice-style currently in use. Column values are accessed either
by column-index when using the ARRAYREF-slicing, or by column-name
when using the HASHREF-slicing.

The default, row data is sliced as an ARRAYREF. The iterator "reset"
method may be used to alter this behaviour.

#### How to create a basic iterator

    $itr = $dbh->iterate(
        $query,
        [undef|\%attr,]
        [@bindvalues,]
        [@transforms]
    );

    $itr = $sth->iterate(
        [@bindvalues,]
        [@transforms]
    );

The `iterate` methods may be replaced by either of the `it` or `iterator`
aliases, if preferred.

### Fancy Iterators

Fancy iterators behave just like their basic alternatives, but the
row data they present is blessed. Column values may continue to be
accessed as they would be with basic iterators, but accessor methods
may also be used to get column values. Such accessor methods are
created the first time they are used.

#### How to create a fancy iterator

    $itr = $dbh->results(
        $query,
        [undef|\%attr,]
        [@bindvalues,]
        [@transforms]
    );

    $itr = $sth->results(
        [@bindvalues,]
        [@transforms]
    );

The `results` methods may be replaced by either of the `rs` or `resultset`
aliases, if preferred.

## Transforming results

All `DBIx::Squirrel` iterators support an optional processing step called
_transformation_.

Transformation can be summarised as the automatic, just-in-time processing,
re-shaping or filtering of results, as they are fetched from the database
and before they are handed-off to the caller.

A transformation is comprised of one or more processing stages. Each stage
receives its version of the result, changes it or does something else it,
and finally hands it off to the next stage, or to the caller if there are
no more stages.

Recall that there are two kinds of iterator, and two methods to construct
each:

    Basic Iterators              |  Fancy Iterators
    -----------------------------|------------------------------
    $itr = $dbh->iterate(        |  $itr = $dbh->results(
        $query,                  |      $query,
        [undef|\%attr,]          |      [undef|\%attr,]
        [@bindvalues,]           |      [@bindvalues,]
        [@transforms]            |      [@transforms]
    );                           |  );
                                 |
    $itr = $sth->iterate(        |  $itr = $sth->results(
        [@bindvalues,]           |      [@bindvalues,]
        [@transforms]            |      [@transforms]
    );                           |  );

The final element of each constructor's argument-list is the transformation
pipeline (`[@transforms]`). Each stage of this pipeline is an individual
processing step, represented by a CODEREF (or a call that returns a CODEREF).

Each stage of a transformation receives the latest version of the result via
the argument-list (`$_[0]` to be precise). For the sake of convenience (and
for convention), this result is also available as `$_`. If you prefer to
rely on something like `$_`, but would like something much less ephemeral,
just `use DBIx::Squirrel::util 'result'` and use the `result` function
inside your transformation stage.

Handing off to the next stage, or the caller, is with an explicit `return`
statement, or the result of evaluating the unit's final expression. Returning
nothing—either `()`, or a bare `return`—from a processing
step will filter the result out entirely, and no further processing steps
will apply to it.

### Examples

1. See script `examples/transformations/01.pl`:

        use DBIx::Squirrel database_entities => [qw/db get_artist_id_by_name/];

        db do {
            DBIx::Squirrel->connect(
                "dbi:SQLite:dbname=./t/data/chinook.db",
                "",
                "",
                {   PrintError     => !!0,
                    RaiseError     => !!1,
                    sqlite_unicode => !!1,
                },
            );
        };

        get_artist_id_by_name do {
            db->results(
                "SELECT ArtistId, Name FROM artists WHERE Name=? LIMIT 1" => sub {
                    my($artist) = @_;
                    print "----\n";
                    print "Name: ", $artist->Name, "\n";
                    return $artist;
                } => sub {$_->ArtistId}
            );
        };

        foreach my $name ("AC/DC", "Aerosmith", "Darling West", "Rush") {
            if (get_artist_id_by_name($name)->single) {
                print "ArtistId: $_\n";
            }
        }

        db->disconnect();

    The script is comprised of four parts:

    - **Connect to the database**

        Here, I am not just connecting to the database. I am associating the resulting
        database connection handle with the `db` helper function, meaning I can refer
        to it as `db` in future.

    - **Create the `get_artist_id_by_name` helper function**

        Here, I am constructing a fancy iterator and also associating it with the
        `get_artist_id_by_name` helper function. This means I can just call the
        `get_artist_id_by_name` function to execute the iterator in future.

        Also here, I describe the the kind of processing I want applied to every
        single result produced by this iterator, expressed as a transformation
        pipeline that is comprised of two separate stages:

        - I want the names of matched artists printed nicely on the console;
        - I am only intersted in getting back the artist's id.

    - **Query the database and process the results**

        Here, I'm executing the query once for each one of four artists to get and
        print their artist ids.

    - **Disconnect from the database**

        Just as we would with the `DBI`.

    Find the script and run it:

        $ perl -Ilib examples/transformations/1.pl
        ----
        Name: AC/DC
        ArtistId: 1
        ----
        Name: Aerosmith
        ArtistId: 3
        ----
        Name: Rush
        ArtistId: 128

    Notice that we got nothing back for one of our artists? That's because
    the artist in question is not in our database, and we cannot apply a
    transformation to nothing.

# COPYRIGHT AND LICENSE

The DBIx::Squirrel module is Copyright (c) 2020-2014 Iain Campbell.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl 5.10.0 README file.

# SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.
<br><br>!["Logo"](resources/images/ekorn-small.png)

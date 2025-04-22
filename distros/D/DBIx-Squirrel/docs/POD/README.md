# NAME

DBIx::Squirrel - The little Perl DBI extension that makes working with databases a lot easier.

# VERSION

Version 1.6.4

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
    # "product" to reference it in future. The next time arguments are
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

    # Statements can be presented as arrays of smaller strings,
    # which will be concatenated before use, using a single SPACE
    # as a separator. This is true of "prepare", "prepare_cached",
    # "iterate", "do", and "results" methods.
    $sth = $dbh->prepare([
        'SELECT *',
        'FROM product',
        'WHERE id=?',
    ]);

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

    $itr = $dbh->iterate([
        'SELECT Id, Name',
        'FROM product',
        'WHERE Name=?',
    ])->reset({});
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

    $itr = $dbh->results([
        'SELECT Id, Name',
        'FROM product',
        'WHERE Name=?',
    ] => sub {
        $_->Id;
    });
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

Using DBIx-Squirrel is just like using the DBI, but with upgrades.
Those with some experience of classic DBI and DBIx-Class programming
can quickly get to a sweet-spot somewhere between both.

Just as with the DBI, all database queries are crafted with SQL,
keeping you close to the data. With its built-in support for named,
positional and legacy parameter placeholders, DBIx-Squirrel makes
the task of crafting that SQL a lot less bothersome, while its
iterators and transformations offer a clean and elegant way to
process results.

Most comforting of all, everything that could be done with the DBI
can still be done using DBIx-Squirrel. Enhancements are subtle and
progressive in nature, and intended to work in harmony features
provided by its venerable ancestor.

While this package is not going to set the world on fire, it will
help those with a need to quickly hack-together data-processing
scripts, and to do so with absolute ease.

## IMPORTING

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

        artist(db->results([
            'SELECT *',
            'FROM artists',
            'WHERE Name=?',
            'LIMIT 1',
        ]));

        # Address the helper ("artist"), passing it a bind-value, to get
        # the ArtistId of the artist whose name is "Aerosmith".
        #
        # We could call "next" to get the next matching record, and that would
        # be just fine. However, by calling "single" (or "first"), we ensure
        # that there are no warnings about dangling active statements when we
        # disconnect from the database. Furthermore, we would be warned if
        # the result set contained additional rows.

        print artist('Aerosmith')->single->ArtistId, "\n";

        artists(db->results('SELECT * FROM artists'));

        # Iterate over the "artists" result set, printing the Name-column for
        # each artist. We don't need to trigger execution manually because
        # the "next" method will do that for us, if it is necessary.

        while ( artists->next ) {
            print $_->Name, "\n";
        };

## CONNECTING TO DATABASES

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

## PREPARING STATEMENTS

Preparing a statement using `DBIx::Squirrel` may be done exactly as it
would be done using the `DBI`'s `prepare_cached` and `prepare` methods.

Where, `DBI` expects a SQL statement string, `DBIx::Sqirrel` also accepts
a reference to an array of smaller strings; these will be concatenated
using a single SPACE separator. Other `DBIx::Squirrel` methods taking a
SQL statement provide the same accommodation.

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

- PostgreSQL positional placeholders (`$number`), demonstrating the use of
the statement-as-array feature:

        $sth = $dbh->prepare([
            'SELECT *',
            'FROM artists',
            'WHERE Name=$1',
            'LIMIT 1',
        ]);

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

## ITERATORS

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
        $query|\@query,
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
        $query|\@query,
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

## TRANSFORMING RESULTS

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
        $query|\@query,          |      $query|\@query,
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
            db->results([
                'SELECT ArtistId, Name',
                'FROM artists',
                'WHERE Name=?',
                'LIMIT 1',
            ] => sub {
                my($artist) = @_;
                print "----\n";
                print "Name: ", $artist->Name, "\n";
                return $artist;
            } => sub {
                $_->ArtistId
            });
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

        $ perl -Ilib examples/transformations/01.pl
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
    the artist in question is not in our database and we cannot apply a
    transformation to nothing, so nothing is returned.

## REFERENCE

This section describes the `DBIx::Squirrel` interface.

Many of the methods (\*) presented below may seem familiar to the experienced
`DBI` user, and they should. They are documented here because `DBIx::Squirrel`
makes subtle changes to their interfaces.

Such changes are additive and unobtrusive in nature, in most cases, resulting
in additional calling forms rather than any change in outcome. Unless a
documented deviation from the standard `DBI` behaviour exists, one may
safely assume that the `DBI` documentation still applies.

Other parts of the `DBI` interface remain unaltered, as well as being
accessible via `DBIx::Squirrel`.

### DBIx::Squirrel Class Methods

#### `connect` \*

    $dbh = DBIx::Squirrel->connect($data_source, $username, $password)
                or die $DBIx::Squirrel::errstr;
    $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr)
                or die $DBIx::Squirrel::errstr;
    $clone_dbh = DBIx::Squirrel->connect($dbh)
                or die $DBIx::Squirrel::errstr;
    $clone_dbh = DBIx::Squirrel->connect($dbh, \%attr)
                or die $DBIx::Squirrel::errstr;

#### `connect_cached` \*

    $dbh = DBIx::Squirrel->connect_cached($data_source, $username, $password)
                or die $DBIx::Squirrel::errstr;
    $dbh = DBIx::Squirrel->connect_cached($data_source, $username, $password, \%attr)
                or die $DBIx::Squirrel::errstr;

### Database Handle Methods

#### `do` \*

    $rows = $dbh->do($statement|\@statement)
                or die $dbh->errstr;
    $rows = $dbh->do($statement|\@statement, \%attr)
                or die ...;
    $rows = $dbh->do($statement|\@statement, \%attr, @bind_values)
                or die ...;
    $rows = $dbh->do($statement|\@statement, \%attr, %bind_mappings)
                or die ...;
    $rows = $dbh->do($statement|\@statement, \%attr, \@bind_values)
                or die ...;
    $rows = $dbh->do($statement|\@statement, \%attr, \%bind_mappings)
                or die ...;
    $rows = $dbh->do($statement|\@statement, @bind_values)
                or die ...;
    $rows = $dbh->do($statement|\@statement, %bind_mappings)
                or die ...;
    $rows = $dbh->do($statement|\@statement, \@bind_values)
                or die ...;
    $rows = $dbh->do($statement|\@statement, undef, \%bind_mappings)
                or die ...;

Calling `do` in scalar-context works just as it does when using the `DBI`,
although there are a few more calling forms.

Calling `do` in list-context, however, is new behaviour and results in the
return of a list comprised of two elements: the number of rows affected by
the statement, as well as the statement handle:

    ($rows, $sth) = $dbh->do($statement|\@statement)
                or die $dbh->errstr;
    ($rows, $sth) = $dbh->do($statement|\@statement, \%attr)
                or die ...;
    ($rows, $sth) = $dbh->do($statement|\@statement, \%attr, @bind_values)
                or die ...;
    ($rows, $sth) = $dbh->do($statement|\@statement, \%attr, %bind_mappings)
                or die ...;
    ($rows, $sth) = $dbh->do($statement|\@statement, \%attr, \@bind_values)
                or die ...;
    ($rows, $sth) = $dbh->do($statement|\@statement, \%attr, \%bind_mappings)
                or die ...;
    ($rows, $sth) = $dbh->do($statement|\@statement, @bind_values)
                or die ...;
    ($rows, $sth) = $dbh->do($statement|\@statement, %bind_mappings)
                or die ...;
    ($rows, $sth) = $dbh->do($statement|\@statement, \@bind_values)
                or die ...;
    ($rows, $sth) = $dbh->do($statement|\@statement, undef, \%bind_mappings)
                or die ...;

#### `iterate`

    $itor = $dbh->iterate($statement|\@statement)
                or die $dbh->errstr;
    $itor = $dbh->iterate($statement|\@statement, @transforms)
                or die $dbh->errstr;
    $itor = $dbh->iterate($statement|\@statement, \%attr)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \%attr, @transforms)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \%attr, @bind_values)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \%attr, @bind_values, @transforms)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \%attr, %bind_mappings)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \%attr, %bind_mappings, @transforms)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \%attr, \@bind_values)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \%attr, [@bind_values, @transforms])
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \%attr, \%bind_mappings)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \%attr, \%bind_mappings, @transforms)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, @bind_values)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, @bind_values, @transforms)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, %bind_mappings)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, %bind_mappings, @transforms)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, \@bind_values)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, [@bind_values, @transforms])
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, undef, \%bind_mappings)
                or die ...;
    $itor = $dbh->iterate($statement|\@statement, undef, \%bind_mappings, @transforms)
                or die ...;

#### `prepare` \*

    $sth = $dbh->prepare($statement|\@statement)          or die $dbh->errstr;
    $sth = $dbh->prepare($statement|\@statement, \%attr)  or die $dbh->errstr;

The `prepare` method works just the same as it does in the `DBI`.

The `$statement` argument must evauate to a string, and may be any of the
following:

- a simple string containing the SQL statement;
- a reference to an array of simple strings that will be concantenated
(separated by a space) to form a simple string containing the SQL
statement;
- a reference to a function returning a simple string or an array of simple
strings that will be concantenated (separated by a space) to form a simple
string containing the SQL statement;

`DBIx::Squirrel` isn't too opinionated about the placeholder style used,
and will accept `:name`, `:number`, `$number`, `?number` or `?`
placeholders within the statement-string. You must use key-value bindings
if you opted for named placeholders. All statements are normalised to use
the legacy `?` style anyway.

#### `prepare_cached` \*

    $sth = $dbh->prepare_cached($statement|\@statement)
    $sth = $dbh->prepare_cached($statement|\@statement, \%attr)
    $sth = $dbh->prepare_cached($statement|\@statement, \%attr, $if_active)

The `prepare` method works just the same as it does in the `DBI`.

The `$statement` argument must evauate to a string, and may be any of the
following:

- a simple string containing the SQL statement;
- a reference to an array of simple strings that will be concantenated
(separated by a space) to form a simple string containing the SQL
statement;
- a reference to a function returning a simple string or an array of simple
strings that will be concantenated (separated by a space) to form a simple
string containing the SQL statement;

`DBIx::Squirrel` isn't too opinionated about the placeholder style used,
and will accept `:name`, `:number`, `$number`, `?number` or `?`
placeholders within the statement-string. You must use key-value bindings
if you opted for named placeholders. All statements are normalised to use
the legacy `?` style anyway, and it is this normalised statement that is
cached by the `DBI`. 

#### `results`

    $itor = $dbh->results($statement|\@statement)
                or die $dbh->errstr;
    $itor = $dbh->results($statement|\@statement, @transforms)
                or die $dbh->errstr;
    $itor = $dbh->results($statement|\@statement, \%attr)
                or die ...;
    $itor = $dbh->results($statement|\@statement, \%attr, @transforms)
                or die ...;
    $itor = $dbh->results($statement|\@statement, \%attr, @bind_values)
                or die ...;
    $itor = $dbh->results($statement|\@statement, \%attr, @bind_values, @transforms)
                or die ...;
    $itor = $dbh->results($statement|\@statement, \%attr, %bind_mappings)
                or die ...;
    $itor = $dbh->results($statement|\@statement, \%attr, %bind_mappings, @transforms)
                or die ...;
    $itor = $dbh->results($statement|\@statement, \%attr, \@bind_values)
                or die ...;
    $itor = $dbh->results($statement|\@statement, \%attr, [@bind_values, @transforms])
                or die ...;
    $itor = $dbh->results($statement|\@statement, \%attr, \%bind_mappings)
                or die ...;
    $itor = $dbh->results($statement|\@statement, \%attr, \%bind_mappings, @transforms)
                or die ...;
    $itor = $dbh->results($statement|\@statement, @bind_values)
                or die ...;
    $itor = $dbh->results($statement|\@statement, @bind_values, @transforms)
                or die ...;
    $itor = $dbh->results($statement|\@statement, %bind_mappings)
                or die ...;
    $itor = $dbh->results($statement|\@statement, %bind_mappings, @transforms)
                or die ...;
    $itor = $dbh->results($statement|\@statement, \@bind_values)
                or die ...;
    $itor = $dbh->results($statement|\@statement, [@bind_values, @transforms])
                or die ...;
    $itor = $dbh->results($statement|\@statement, undef, \%bind_mappings)
                or die ...;
    $itor = $dbh->results($statement|\@statement, undef, \%bind_mappings, @transforms)
                or die ...;

### Statement Handle Methods

#### `bind`

    $sth->bind(@bind_values);
    $sth->bind(\@bind_values);
    $sth->bind(%bind_mappings);
    $sth->bind(\%bind_mappings);

#### `bind_param` \*

    $sth->bind_param($p_num, $bind_value);
    $sth->bind_param($p_num, $bind_value, \%attr);
    $sth->bind_param($p_num, $bind_value, $bind_type);
    $sth->bind_param($p_name, $bind_value);
    $sth->bind_param($p_name, $bind_value, \%attr);
    $sth->bind_param($p_name, $bind_value, $bind_type);

#### `execute` \*

    $rv = $sth->execute();
    $rv = $sth->execute(@bind_values);
    $rv = $sth->execute(\@bind_values);
    $rv = $sth->execute(%bind_mappings);
    $rv = $sth->execute(\%bind_mappings);

#### `iterate`

    $itor = $sth->iterate()
                or die $dbh->errstr;
    $itor = $sth->iterate(@bind_values)
                or die ...;
    $itor = $sth->iterate(@transforms)
                or die $dbh->errstr;
    $itor = $sth->iterate(@bind_values, @transforms)
                or die ...;
    $itor = $sth->iterate(%bind_mappings)
                or die ...;
    $itor = $sth->iterate(%bind_mappings, @transforms)
                or die ...;
    $itor = $sth->iterate(\@bind_values)
                or die ...;
    $itor = $sth->iterate([@bind_values, @transforms])
                or die ...;
    $itor = $sth->iterate(\%bind_mappings)
                or die ...;
    $itor = $sth->iterate(\%bind_mappings, @transforms)
                or die ...;

#### `results`

    $itor = $sth->results()
                or die $dbh->errstr;
    $itor = $sth->results(@bind_values)
                or die ...;
    $itor = $sth->results(@transforms)
                or die $dbh->errstr;
    $itor = $sth->results(@bind_values, @transforms)
                or die ...;
    $itor = $sth->results(%bind_mappings)
                or die ...;
    $itor = $sth->results(%bind_mappings, @transforms)
                or die ...;
    $itor = $sth->results(\@bind_values)
                or die ...;
    $itor = $sth->results([@bind_values, @transforms])
                or die ...;
    $itor = $sth->results(\%bind_mappings)
                or die ...;
    $itor = $sth->results(\%bind_mappings, @transforms)
                or die ...;

### Iterator Methods

#### `active`

Alias (see `is_active`).

#### `all`

    @results = $itor->all();
    $results_or_undef = $itor->all();

Executes the iterator's underlying statement handle object.

When called in list-context, the `all` method returns an array
of all matching row objects.

When called in scalar-context, this method returns a reference to
an array of all matching row objects. Where no rows are matched,
`undef` would be returned.

#### `buffer_size`

Deprecated alias for `cache_size`.

#### `buffer_size_slice`

Deprecated alias for `cache_size_slice`.

#### `cache_size`

    $cache_size = $itor->cache_size();
    $itor = $itor->cache_size($cache_size);

May be used to determine how many results the iterator makes available to
fetch following each trip to the database.

To change this property, simply provide the new value as the argument. When
used to change the buffer-size, a reference to the iterator is returned.

Normally, an iterator's buffer-size is set to a low initial value, greater
than 1. It is usually gradually increased by a factor of two, up to a maximum,
after every database read. This is done to improve performance when fetching
large result sets.

Manually setting the iterator's buffer-size has the side-effect of fixing it
at that value, preventing the kind of automatic adjustment described above.

The following package globals define the relevant default settings:

    $DBIx::Squirrel::it::DEFAULT_CACHE_SIZE = 2;   # initial buffer-size
    $DBIx::Squirrel::it::CACHE_SIZE_LIMIT   = 64;  # maximum buffer-size

#### `cache_size_slice`

    ($cache_size, $slice) = $itor->cache_size_slice();
    $itor = $itor->cache_size_slice($slice);
    $itor = $itor->cache_size_slice($cache_size);
    $itor = $itor->cache_size_slice($slice, $cache_size);
    $itor = $itor->cache_size_slice($cache_size, $slice);

May be used to determine (a) how the iterator slices the results it fetches
from the database, and (b) how many results it makes available to fetch
following each trip to the database.

When called with no arguments, a list comprised of the following two iterator
properties is returned:

- `$cache_size`

    The current size of the results buffer. That is, the current maximum number of
    results that are processed and ready to fetch after each trip to the database.

- `$slice`

    The how the iterator slices results fetched from the database. This may be an
    ARRAYREF or a HASHREF.

To change these properties, simply provide the new values in the argument
list. When used to change these properties, a reference to the iterator is
returned.

Normally, an iterator's buffer-size is set to a low initial value, greater
than 1. It is usually gradually increased by a factor of two, up to a maximum,
after every database read. This is done to improve performance when fetching
large result sets.

Manually setting the iterator's buffer-size has the side-effect of fixing it
at that value, preventing the kind of automatic adjustment described above.

The following package globals define the relevant default settings:

    $DBIx::Squirrel::it::DEFAULT_SLICE       = [];  # slicing strategy
    $DBIx::Squirrel::it::DEFAULT_CACHE_SIZE = 2;   # initial buffer-size
    $DBIx::Squirrel::it::CACHE_SIZE_LIMIT   = 64;  # maximum buffer-size

#### `count`

    $count = $itor->count();

Returns the total number of rows in the result set.

If the iterator's statement has not yet been executed, it will be, and `undef`
will be returned if the statement was not executed successfully.

Any results remaining to be fetched are then fetched, counted and discarded,
and the final count is returned.

_**BEWARE** that you should not use `next` after this method has been used!_

#### `count_fetched`

    $count = $itor->count_fetched();

Returns the number of results fetched so far.

If the iterator's statement has not yet been executed, it will be. Zero will
be returned if the statement executed successfully, otherwise `undef` is
returned.

#### `first`

    $result = $itor->first();

Returns the first result in the result set, or `undef` if there were no
results.

If the iterator's statement has not yet been executed, it will be, and `undef`
will be returned if the statement was not executed successfully.

If the first result hasn't yet been fetched, it will be and the first result
is fetched and cached. The cached value is returned.

The result of the statement's execution will be returned.

#### `inactive`

Alias (see `not_active`).

#### `is_active`

    $bool = $itor->is_active();

Returns true (`!!1`) if there more results to fetch, otherwise false (`!!0`)
is returned.

#### `iterate`

    $itor_or_undef = $itor->iterate()
    $itor_or_undef = $itor->iterate(@bind_values)
    $itor_or_undef = $itor->iterate(@transforms)
    $itor_or_undef = $itor->iterate(@bind_values, @transforms)
    $itor_or_undef = $itor->iterate(%bind_mappings)
    $itor_or_undef = $itor->iterate(%bind_mappings, @transforms)
    $itor_or_undef = $itor->iterate(\@bind_values)
    $itor_or_undef = $itor->iterate([@bind_values, @transforms])
    $itor_or_undef = $itor->iterate(\%bind_mappings)
    $itor_or_undef = $itor->iterate(\%bind_mappings, @transforms)

Executes the iterator's underlying statement, as well as resetting the
iterator's internal state.

When called with no arguments, any bind-values and transformations passed to
the iterator at the time of construction will be honoured.

A reference to the iterator is returned if the statement was successfully
executed, otherwise the method returns `undef`.

#### `last`

    $result = $itor->last();

Returns the last result of the result set, fetching and discarding any
remaining results before it.

If the iterator's statement has not yet been executed, it will be. If the
statement cannot be executed successfuly, the method will return `undef`.

Once `last` has been called, the iterator should be reset before calling
methods such as `all`, `first`, `next`, `remaining` or `single`, nothing
is returned.

#### `last_fetched`

    $result = $itor->last_fetched();

Returns the last result fetched.

If the iterator's statement has not yet been executed, it will be, then
`undef` is returned regardless of the statement execution's outcome.

If the statement was previously executed then the last result fetched is
always cached. The cached value is returned.

#### `next`

    $result = $itor->next();

Returns the next result in the result set.

If the iterator's statement has not yet been executed, it will be, and `undef`
will be returned if the statement was not executed successfully.

There are two potential side-effects that could result from a call to `next`:

- The first time it is called, the result returned will be cached and returned in
any subsequent call to `first`.
- Every time it is called, the most recent result returned will be cached and
returned in any call to `last_fetched`, or `last` if it was the final result
in the result set.

#### `not_active`

    $bool = $itor->not_active();

Returns true if there are no more results to fetch, otherwise false is
returned.

#### `not_done`

Alias (see `is_active`).

#### `one`

Alias (see `single`).

#### `remaining`

    @results = $itor->remaining();
    $results_or_undef = $itor->remaining;

#### `reset`

    $itor = $itor->reset();
    $itor = $itor->reset($slice);
    $itor = $itor->reset($cache_size);
    $itor = $itor->reset($slice, $cache_size);
    $itor = $itor->reset($cache_size, $slice);

Executes the iterator's underlying statement handle object with the current
bind-values, resetting any internal state.

This method may also be used to set the statement cache size and/or slicing
strategy in the same call.

A reference to the iterator is returned, regardless of execution outcome.

#### `rows`

    $rows = $itor->rows();

Returns the number of rows aftected by non-SELECT statements.

#### `single` (or `one`)

    $result = $itor->single();

Returns the first result in the result set, or `undef` if there were no
results.

If the iterator's statement has not yet been executed, it will be, and `undef`
will be returned if the statement was not executed successfully.

If the first result hasn't yet been fetched, it will be and the first result
is fetched and cached. The cached value is returned.

If the result returned is one of many buffered, a warning will be issued:

    Query would yield more than one result...

The warning is a reminder to include a LIMIT 1 constraint in the statement.

#### `slice`

    $slice = $itor->slice();
    $itor = $itor->slice($slice);

May be used to determine how the iterator slices the results it fetches
from the database. This may be an ARRAYREF or a HASHREF.

To change this property, simply provide the new value as the argument. When
used to change the slicing strategy, a reference to the iterator is returned.

The following package global defines the default setting:

    $DBIx::Squirrel::it::DEFAULT_SLICE       = [];  # slicing strategy

#### `slice_buffer_size`

Deprecated alias for `slice_cache_size`.

#### `slice_cache_size`

    ($slice, $cache_size) = $itor->slice_cache_size();
    $itor = $itor->slice_cache_size($slice);
    $itor = $itor->slice_cache_size($cache_size);
    $itor = $itor->slice_cache_size($slice, $cache_size);
    $itor = $itor->slice_cache_size($cache_size, $slice);

May be used to determine (a) how the iterator slices the results it fetches
from the database, and (b) how many results it makes available to fetch
following each trip to the database.

When called with no arguments, a list comprised of the following two iterator
properties is returned:

- `$slice`

    The how the iterator slices results fetched from the database. This may be an
    ARRAYREF or a HASHREF.

- `$cache_size`

    The current size of the results buffer. That is, the current maximum number of
    results that are processed and ready to fetch after each trip to the database.

To change these properties, simply provide the new values in the argument
list. When used to change these properties, a reference to the iterator is
returned.

Normally, an iterator's buffer-size is set to a low initial value, greater
than 1. It is usually gradually increased by a factor of two, up to a maximum,
after every database read. This is done to improve performance when fetching
large result sets.

Manually setting the iterator's buffer-size has the side-effect of fixing it
at that value, preventing the kind of automatic adjustment described above.

The following package globals define the relevant default settings:

    $DBIx::Squirrel::it::DEFAULT_SLICE       = [];  # slicing strategy
    $DBIx::Squirrel::it::DEFAULT_CACHE_SIZE = 2;   # initial buffer-size
    $DBIx::Squirrel::it::CACHE_SIZE_LIMIT   = 64;  # maximum buffer-size

#### `start`

    $rv_or_undef = $itor->start()
    $rv_or_undef = $itor->start(@bind_values)
    $rv_or_undef = $itor->start(@transforms)
    $rv_or_undef = $itor->start(@bind_values, @transforms)
    $rv_or_undef = $itor->start(%bind_mappings)
    $rv_or_undef = $itor->start(%bind_mappings, @transforms)
    $rv_or_undef = $itor->start(\@bind_values)
    $rv_or_undef = $itor->start([@bind_values, @transforms])
    $rv_or_undef = $itor->start(\%bind_mappings)
    $rv_or_undef = $itor->start(\%bind_mappings, @transforms)

Culminates in the iterator's underlying statement being executed, after
resetting the iterator's internal state.

When called with no arguments, any bind-values and transformations passed to
the iterator at the time of construction are used.

#### `sth`

    $sth = $itor->sth();

Returns the iterator's underlying statement handle object.

### Iterator Exports

The `DBIx::Squirrel::it` package exports a number of subroutines that
may be used within the stages of a transformation pipeline. These provide
information about the current transformation context.

#### `database`

    my $dbh = database();

Returns a reference to the current iterator's database handle object.

#### `iterator`

    my $itor = iterator();

Returns a reference to the current iterator.

#### `result`

    my $result = result();

Returns the result as it was when it entered the _current stage_ of the
transformation pipeline.

There are alternative ways to get at this value without having to pollute
your namespace, although `result` is less cryptic:

- It is the first element of the `@_` list. Use `$_[0]`, or `shift` the
value from the start of the list.
- It is also presented in the ephemeral `$_` variable. It should be consumed
quickly, before it changes.

#### `result_current`

An alias (see `result`).

#### `result_first`

    my $result = result_first();

Returns the first result fetched.

#### `result_prev`

    my $result = result_prev();

Returns the previous result, if there was one.

#### `result_previous`

An alias (see `result_prev`).

#### `result_number`

    my $number = result_number();

Returns the result's 1-based sequence number.

#### `result_offset`

    my $offset = result_offset();

Returns the result's zero-based offset, effectively the number of results
fetched, less one.

#### `result_original`

    my $result = result_original();

Returns the result as it was when it entered the _first stage_ of the current
transformation pipeline.

#### `statement`

    my $sth = statement();

Returns a reference to the current iterator's statement handle object.

# COPYRIGHT AND LICENSE

The DBIx::Squirrel module is Copyright (c) 2020-2025 Iain Campbell.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl 5.10.0 README file.

# SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.

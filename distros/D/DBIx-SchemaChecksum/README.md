# NAME

DBIx::SchemaChecksum - Manage your datebase schema via checksums

# VERSION

version 1.103

# SYNOPSIS

    my $sc = DBIx::SchemaChecksum->new( dbh => $dbh );
    print $sc->checksum;

# DESCRIPTION

When you're dealing with several instances of the same database (eg.
developer, testing, stage, production), it is crucial to make sure
that all databases use the same schema. This can be quite an
hair-pulling experience, and this module should help you keep your
hair (if you're already bald, it won't make your hair grow back,
sorry...)

`DBIx::SchemaChecksum` gets schema information (tables, columns,
primary keys, foreign keys and some more depending on your DB) and
generates a SHA1 digest. This digest can then be used to easily verify
schema consistency across different databases, and to build an update
graph of changes. Therefor, `DBIx::SchemaChecksum` does not requires
you to add a meta-table to your database to keep track of which
changes have already been deployed.

**Caveat:** The same schema might produce different checksums on
different database versions.

**Caveat:** `DBIx::SchemaChecksum` only works with database engines
that support changes to the schema inside a transaction. We know this
works with PostgreSQL and SQLite. We know it does not work with MySQL
and Oracle. We don't know how other database engines behave, but would
be happy to hear about your experiences.

## RUNNING DBIx::SchemaChecksum

Please take a look at the [dbchecksum](https://metacpan.org/pod/bin#dbchecksum) script included
in this distribution. It provides a nice and powerful commandline
interface to make working with your schema a breeze.

## EXAMPLE WORKFLOW

So you have this genious idea for a new startup that will make you
incredibly rich and famous...

### Collect underpants

Usually such ideas involve a database. So you grab your [favourite database engine](http://postgresql.org/) and start a new database:

    ~/Gnomes$ createdb gnomes    # createdb is a postgres tool

Of course this new DB is rather empty:

    gnomes=# \d
    No relations found.

So you think long and hard about your database schema and write it down

    ~/Gnomes$ cat sql/handcrafted_schema.sql
    create table underpants (
      id serial primary key,
      type text,
      size text,
      color text
    );

But instead of going down the rabbit hole of manually keeping the
dev-DB on your laptop, the one on the workstation in the office, the
staging and the production one in sync (and don't forget all the
databases running on the laptops of the countless coding monkeys
you're going to hire after all the VC money starts flowing), you grab
a (free!) copy of `DBIx::SchemaChecksum`

    ~/Gnomes$ cpanm DBIx::SchemaChecksum
    .. wait a bit while the giant, on which shoulders we are standing, is being assembled
    Successfully installed DBIx-SchemaChecksum
    42 distribution installed

Now you can create a new `changes file`:

    ~/Gnomes$ dbchecksum new_changes_file --sqlsnippetdir sql --dsn dbi:Pg:dbname=gnomes --change_name "initial schema"
    New change-file ready at sql/inital_schema.sql

Let's take a look:

    ~/Gnomes$ cat sql/inital_schema.sql
    -- preSHA1sum:  54aa14e7b7e54cce8ae07c441f6bda316aa8458c
    -- postSHA1sum: xxx-New-Checksum-xxx
    -- inital schema

Each `changes file` contains two very import "header" lines masked as a SQL comment:

`preSHA1sum` is the checksum of the DB schema before the changes in
this file have been applied. `postSHA1sum` is (you probably guessed
it) the checksum we expect after the changes have been applied.
Currently the `postSHA1sum` is "xxx-New-Checksum-xxx" because we have
neither defined nor run the changes yet.

So let's append the handcrafted schema from earlier to the change file:

    ~/Gnomes$ cat sql/handcrafted_schema.sql >> sql/inital_schema.sql

The `changes file` now looks like this:

    ~/Gnomes$ cat sql/inital_schema.sql
    -- preSHA1sum:  54aa14e7b7e54cce8ae07c441f6bda316aa8458c
    -- postSHA1sum: xxx-New-Checksum-xxx
    -- inital schema

    create table underpants (
      id serial primary key,
      type text,
      size text,
      color text
    );

Let's apply this schema change, so we can finally start coding (you
just can't wait to get rich, can you?)

    ~/Gnomes$ dbchecksum apply_changes --sqlsnippetdir sql --dsn dbi:Pg:dbname=gnomes
    Apply inital_schema.sql? [y/n] [y]
    post checksum mismatch!
      expected 
      got      611481f7599cc286fa539dbeb7ea27f049744dc7
    ABORTING!

Woops! What happend here? Why couldn't the change be applied? Well, we
haven't yet defined the `postSHA1sum`, so we cannot be sure that the
database is in the state we expect it to be.

When you author a sql change, you will always have to first apply the
change to figure out the new `postSHA1sum`. As soon as
`DBIx::SchemaChecksum` tells you the checksum the DB will have after
the change is applied, you have to add the new checksum to your
`changes file`:

    ~/Gnomes$ vim sql/inital_schema.sql
    # replace xxx-New-Checksum-xxx with 611481f7599cc286fa539dbeb7ea27f049744dc7

    ~/Gnomes$ head -2 sql/inital_schema.sql 
    -- preSHA1sum:  54aa14e7b7e54cce8ae07c441f6bda316aa8458c
    -- postSHA1sum: 611481f7599cc286fa539dbeb7ea27f049744dc7

Now we can try again:

    ~/Gnomes$ dbchecksum apply_changes --sqlsnippetdir sql --dsn dbi:Pg:dbname=gnomes
    Apply inital_schema.sql? [y/n] [y]
    post checksum OK
    No more changes

Yay, this looks much better!

Now you can finally start to collect underpants!

### Teamwork

Some weeks later (you have now convinced a friend to join you in your quest for fortune) a `git pull` drops a new file into your `sql` directory. It seems that your colleague needs some tweaks to the database:

    ~/Gnomes$ cat sql/underpants_need_washing.sql
    -- preSHA1sum:  611481f7599cc286fa539dbeb7ea27f049744dc7
    -- postSHA1sum: 094ef4321e60b50c1d34529c312ecc2fcbbdfb51
    -- underpants need washing
    
    ALTER TABLE underpants ADD COLUMN needs_washing BOOLEAN NOT NULL DEFAULT false;

Seems reasonable, so you apply it:

    ~/Gnomes$ dbchecksum apply_changes --sqlsnippetdir sql --dsn dbi:Pg:dbname=gnomes
    Apply underpants_need_washing.sql? [y/n] [y]
    post checksum OK
    No more changes

Now that was easy!

### Making things even easier: Config file

`DBIx::SchemaChecksum` uses [MooseX::App](https://metacpan.org/pod/MooseX%3A%3AApp) to power the commandline
interface. We use the `Config` and `ConfigHome` plugins, so you can
pack some of the flags into a config file, for even less typing (and typos):

    ~/Gnomes$ cat dbchecksum.yml
    global:
      sqlsnippetdir: sql
      dsn: dbi:Pg:dbname=gnomes

Now run:

    ~/Gnomes$ dbchecksum apply_changes --config dbchecksum.yml
    db checksum 094ef4321e60b50c1d34529c312ecc2fcbbdfb51 matching sql/underpants_need_washing.sql

Or you can store the config file into your `~/.dbchecksum/config.yml`:

    ~/Gnomes$ cat ~/.dbchecksum/config.yml
    global:
      sqlsnippetdir: sql
      dsn: dbi:Pg:dbname=gnomes

And it magically works:

    ~/Gnomes$ dbchecksum apply_changes
    db checksum 094ef4321e60b50c1d34529c312ecc2fcbbdfb51 matching sql/underpants_need_washing.sql

### Profit!

This section is left empty as an exercise for the reader!

## Anatomy of a changes-file

`sqlsnippetdir` points to a directory containing so-called `changes
files`. For a file to be picked up by `dbchecksum` it needs to use
the extension `.sql`.

The file itself has to contain a header formated as sql comments, i.e.
starting with `--`. The header has to contain the `preSHA1sum` and
should include the `postSHA1sum`.

If the `postSHA1sum` is missing, we assume that you don't know it yet and try to apply the change. As the new checksum will not match the empty `postSHA1sum` the change will fail. But we will report the new checksum, which you can now insert into the changes file.

After the header, the changes file should list all sql commands you
want to apply to change the schema, seperated by a semicolon `;`,
just as you would type them into your sql prompt.

    -- preSHA1sum:  b1387d808800a5969f0aa9bcae2d89a0d0b4620b
    -- postSHA1sum: 55df89fd956a03d637b52d13281bc252896f602f
    
    CREATE TABLE nochntest (foo TEXT);

Not all commands need to actually alter the schema, you can also
include sql that just updates some data. In fact, some schmema changes
even require that: for example, if you want to add a `NOT NULL`
constraint to a column, you first have to make sure that the column in
fact does not contain a `NULL`.

    -- preSHA1sum:  c50519c54300ec2670618371a06f9140fa552965
    -- postSHA1sum: 48dd6b3710a716fb85b005077dc534a8f9c11cba
    
    UPDATE foo SET some_field = 42 WHERE some_field IS NULL;
    ALTER TABLE foo ALTER some_filed SET NOT NULL;

### Creating functions / stored procedures

Functions usually contain semicolons inside the function definition,
so we cannot split the file on semicolon. Luckily, you can specifiy a different splitter using `-- split-at`. We usually use `----` (again, the SQL comment marker) so the changes file is still valid SQL.

    -- preSHA1sum  c50519c54300ec2670618371a06f9140fa552965
    -- postSHA1sum 48dd6b3710a716fb85b005077dc534a8f9c11cba
    -- split-at ------

    ALTER TABLE underpants
          ADD COLUMN modified timestamp with time zone DEFAULT now() NOT NULL;
    ------
    CREATE FUNCTION update_modified() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
    BEGIN
        if NEW <> OLD THEN
          NEW.modified = now();
        END IF;
        RETURN NEW;
    END;
    $$;
    ------
    CREATE TRIGGER underpants_modified
           BEFORE UPDATE ON underpants
           FOR EACH ROW EXECUTE PROCEDURE update_modified();

## TIPS & TRICKS

We have been using `DBIx::SchemaChecksum` since 2008 and encountered
a few issues. Here are our solutions:

### Using 'checksum --show\_dump' to find inconsistencies between databases

Sometimes two databases will produce different checksums. This can be
caused by a number of things. A good method to figure out what's
causing the problem is running `<dbchecksum checksum --show_dump ` some\_name>>
on the databases causing the problem. Then you can use
`diff` or `vim -d` to inspect the raw dump.

Some problems we have encountered, and how to fix them:

- Manual changes

    Somebody did a manual change to a database (maybe an experiment on a
    local DB, or some quick-fix on a live DB).

    **Fix:** Revert the change. Maybe make a proper change file if the
    change makes sense for the project.

- Bad search-path

    The `search_paths` of the DBs differ. This can cause subtile
    diferences in the way keys and references are reported, thus causing a
    different checksum.

    **Fix:** Make sure all DBs use the same `search_path`.

- Other schema-related troubles

    Maybe the two instances use different values for `--schemata`?

    **Fix:** Use the same `--schemata` everywhere. Put them in a
    config-file or write a wrapper script.

- Just weird diffs

    Maybe the systems are using different version of the database server,
    client, `DBI` or `DBD::*`. While we try hard to filter out
    version-specific differences, this might still cause problems.

    **Fix:** Use the same versions on all machines.

### Use show\_update\_path if DBIx::SchemaChecksum cannot run on the database server

Sometimes it's impossible to get `DBIx::SchemaChecksum` installed on
the database server (or on some other machine, I have horrible
recollections about a colleague using Windows..). And the sysadmin
won't let you access the database over the network...

**Fix:** Prepare all changes on your local machine, and run them manually on the target machine.

    ~/Gnomes$ dbchecksum show_update_path --from_checksum 54aa14e7b7e54cce8ae07c441f6bda316aa8458c
    inital_schema.sql (611481f7599cc286fa539dbeb7ea27f049744dc7)
    underpants_need_washing.sql (094ef4321e60b50c1d34529c312ecc2fcbbdfb51)
    No update found that's based on 094ef4321e60b50c1d34529c312ecc2fcbbdfb51.

Now you could import the changes manually on the server. But it's even
easier using the `--output` flag:

    ~/Gnomes$ dbchecksum show_update_path --output psql --dbname gnomes --from_checksum 54aa14e7b7e54cce8ae07c441f6bda316aa8458c
    psql gnomes -1 -f inital_schema.sql
    psql gnomes -1 -f underpants_need_washing.sql
    # No update found that's based on 094ef4321e60b50c1d34529c312ecc2fcbbdfb51.

You could pipe this into `changes.sh` and then run that.

Or use `--output concat`:

    ~/Gnomes$ dbchecksum show_update_path --output concat --from_checksum 54aa14e7b7e54cce8ae07c441f6bda316aa8458c > changes.sql
    ~/Gnomes$ cat changes.sql
    -- file: inital_schema.sql
    -- preSHA1sum:  54aa14e7b7e54cce8ae07c441f6bda316aa8458c
    -- postSHA1sum: 611481f7599cc286fa539dbeb7ea27f049744dc7
    -- inital schema
    
    create table underpants (
      id serial primary key,
      type text,
      size text,
      color text
    );
    
    -- file: underpants_need_washing.sql
    -- preSHA1sum:  611481f7599cc286fa539dbeb7ea27f049744dc7
    -- postSHA1sum: 094ef4321e60b50c1d34529c312ecc2fcbbdfb51
    -- underpants need washing
    
    ALTER TABLE underpants ADD COLUMN needs_washing BOOLEAN NOT NULL DEFAULT false;
    
    -- No update found that's based on 094ef4321e60b50c1d34529c312ecc2fcbbdfb51.

Happyness!

# METHODS

You will only need those methods if you want to use the library itself instead of using the `dbchecksum` wrapper script.

## checksum

    my $sha1_hex = $self->checksum();

Gets the schemadump and runs it through Digest::SHA1, returning the current checksum.

## schemadump

    my $schemadump = $self->schemadump;

Returns a string representation of the whole schema (as a Data::Dumper Dump).

Lazy Moose attribute.

## \_build\_schemadump\_schema

    my $hashref = $self->_build_schemadump_schema( $schema );

This is the main entry point for checksum calculations per schema.
Method-modifiy it if you need to alter the complete schema data
structure before/after checksumming.

Returns a HashRef like:

    {
        tables => $hash_ref
    }

## \_build\_schemadump\_tables

    my $hashref = $self->_build_schemadump_tables( $schema );

Iterate through all tables in a schema, calling
[\_build\_schemadump\_table](https://metacpan.org/pod/_build_schemadump_table) for each table and collecting the results
in a HashRef

## \_build\_schemadump\_table

    my $hashref = $self->_build_schemadump_table( $schema, $table );

Get metadata on a table (columns, primary keys & foreign keys) via DBI
introspection.

This is a good place to method-modify if you need some special processing for your database

Returns a hashref like

    {
        columns      => $data,
        primary_keys => $data,
        foreign_keys => $data,
    }

## \_build\_schemadump\_column

    my $hashref = $self->_build_schemadump_column( $schema, $table, $column, $raw_dbi_data );

Does some cleanup on the data returned by DBI.

## update\_path

    my $update_info = $self->update_path

Lazy Moose attribute that returns the data structure needed by [apply\_sql\_update](https://metacpan.org/pod/apply_sql_update).

## \_build\_update\_path

`_build_update_path` reads in all files ending in ".sql" in `$self->sqlsnippetdir`.
It builds something like a linked list of files, which are chained by their
`preSHA1sum` and `postSHA1sum`.

## get\_checksums\_from\_snippet

    my ($pre, $post) = $self->get_checksums_from_snippet( $filename );

Returns a list of the preSHA1sum and postSHA1sum for the given file in ` sqlnippetdir`.

The file has to contain this info in SQL comments, eg:

    -- preSHA1sum: 89049e457886a86886a4fdf1f905b69250a8236c
    -- postSHA1sum: d9a02517255045167053ea92dace728e1389f8ca

    alter table foo add column bar;

## dbh

Database handle (DBH::db). Moose attribute

## catalog

The database catalog searched for data. Not implemented by all DBs. See `DBI::table_info`

Default `%`.

Moose attribute

## schemata

An Arrayref containing names of schematas to include in checksum calculation. See `DBI::table_info`

Default `%`.

Moose attribute

## sqlsnippetdir

Path to the directory where the sql change files are stored.

Moose attribute

## verbose

Be verbose or not. Default: 0

## driveropts

Additional options for the specific database driver.

# GLOBAL OPTIONS

## Connecting to the database

These options define how to connect to your database.

### dsn

**Required**. The `Data Source Name (DSN)` as used by [DBI](https://metacpan.org/pod/DBI) to connect to your database.

Some examples: `dbi:SQLite:dbname=sqlite.db`,
`dbi:Pg:dbname=my_project;host=db.example.com;port=5433`,
`dbi:Pg:service=my_project_dbadmin`

### user

Username to use to connect to your database.

### password

Password to use to connect to your database.

## Defining the schema dump

These options define which parts of the schema are relevant to the checksum

### catalog

Default: `%`

Needed during [DBI](https://metacpan.org/pod/DBI) introspection. `Pg` does not need it.

### schemata

Default: `%` (all schemata)

If you have several schemata in your database, but only want to consider some for the checksum, use `--schemata` to list the ones you care about. Can be specified more than once to list several schemata:

    dbchecksum apply --schemata foo --schemata bar

### driveropts

Some database drivers might implement further options only relevant
for the specific driver. As of now, this only applies to
[DBIx::SchemaChecksum::Driver::Pg](https://metacpan.org/pod/DBIx%3A%3ASchemaChecksum%3A%3ADriver%3A%3APg), which defines the driveropts
`triggers`, `sequences` and `functions`

# SEE ALSO

["dbchecksum" in bin](https://metacpan.org/pod/bin#dbchecksum) for a command line frontend powered by [MooseX::App](https://metacpan.org/pod/MooseX%3A%3AApp)

There are quite a lot of other database schema management tools out
there, but nearly all of them need to store meta-info in some magic
table in your database.

## Talks

You can find more information on the rational, usage & implementation
in the slides for my talk at the Austrian Perl Workshop 2012,
available here: [http://domm.plix.at/talks/dbix\_schemachecksum.html](http://domm.plix.at/talks/dbix_schemachecksum.html)

# ACKNOWLEDGMENTS

Thanks to

- Klaus Ita and Armin Schreger for writing the initial core code. I
just glued it together and improved it a bit over the years.
- revdev, a nice little software company run by Koki, domm
([http://search.cpan.org/~domm/](http://search.cpan.org/~domm/)) and Maroš ([http://search.cpan.org/~maros/](http://search.cpan.org/~maros/)) from 2008 to 2011. We initially wrote `DBIx::SchemaChecksum` for our work at revdev.
- [validad.com](https://www.validad.com/) which grew out of
revdev and still uses (and supports) `DBIx::SchemaChecksum` every
day.
- [Farhad](https://twitter.com/Grauwolf) from [Spherical
Elephant](https://www.sphericalelephant.com) for nagging me into
writing proper docs.
-

# AUTHORS

- Thomas Klausner <domm@plix.at>
- Maroš Kollár <maros@cpan.org>
- Klaus Ita <koki@worstofall.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2021 by Thomas Klausner, Maroš Kollár, Klaus Ita.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

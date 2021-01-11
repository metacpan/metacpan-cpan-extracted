package DBIx::SchemaChecksum;

# ABSTRACT: Manage your datebase schema via checksums
our $VERSION = '1.103'; # VERSION

use 5.010;
use Moose;

use DBI;
use Digest::SHA1;
use Data::Dumper;
use Path::Class;
use Carp;
use File::Find::Rule;

has 'dbh' => (
    is => 'ro',
    required => 1
);

has 'catalog' => (
    is => 'ro',
    isa => 'Str',
    default => '%',
    documentation => q[might be required by some DBI drivers]
);

has 'schemata' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { ['%'] },
    documentation => q[List of schematas to include in checksum]
);

has 'sqlsnippetdir' => (
    isa => 'Str',
    is => 'ro',
    documentation => q[Directory containing sql update files],
);

has 'driveropts' => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub {{}},
    documentation => q[Driver specific options],
);

has 'verbose' => (
    is => 'rw',
    isa => 'Bool',
    default => 0
);

has '_update_path' => (
    is => 'rw',
    isa => 'Maybe[HashRef]',
    lazy_build => 1,
    builder => '_build_update_path',
);

has '_schemadump' => (
    isa=>'Str',
    is=>'rw',
    lazy_build=>1,
    clearer=>'reset_checksum',
    builder => '_build_schemadump',
);

sub BUILD {
    my ($self) = @_;

    # Apply driver role to instance
    my $driver = $self->dbh->{Driver}{Name};
    my $class = __PACKAGE__.'::Driver::'.$driver;
    if (Class::Load::try_load_class($class)) {
        $class->meta->apply($self);
    }
    return $self;
}



sub checksum {
    my $self = shift;
    return Digest::SHA1::sha1_hex($self->_schemadump);
}


sub _build_schemadump {
    my $self = shift;

    my %relevants = ();

    foreach my $schema ( @{ $self->schemata } ) {
        my $schema_relevants = $self->_build_schemadump_schema($schema);
        while (my ($type,$type_value) = each %{$schema_relevants}) {
            my $ref = ref($type_value);
            if ($ref eq 'ARRAY') {
                $relevants{$type} ||= [];
                foreach my $value (@{$type_value}) {
                    push(@{$relevants{$type}}, $value);
                }
            }
            elsif ($ref eq 'HASH') {
                while (my ($key,$value) = each %{$type_value}) {
                    $relevants{$type}{$key} = $value;
                }
            }
        }
    }

    my $dumper = Data::Dumper->new( [ \%relevants ] );
    $dumper->Sortkeys(1);
    $dumper->Indent(1);
    my $dump = $dumper->Dump;

    return $dump;
}


sub _build_schemadump_schema {
    my ($self,$schema) = @_;

    my %relevants = ();
    $relevants{tables}    = $self->_build_schemadump_tables($schema);

    return \%relevants;
}


sub _build_schemadump_tables {
    my ($self,$schema) = @_;

    my $dbh = $self->dbh;

    my %relevants;
    foreach my $table ( $dbh->tables( $self->catalog, $schema, '%' ) ) {
        next
            unless $table =~ m/^"?(?<schema>[^"]+)"?\."?(?<table>[^"]+)"?$/;
        my $this_schema = $+{schema};
        my $table = $+{table};

        my $table_data = $self->_build_schemadump_table($this_schema,$table);
        next
            unless $table_data;
        $relevants{$this_schema.'.'.$table} = $table_data;
    }

    return \%relevants;
}


sub _build_schemadump_table {
    my ($self,$schema,$table) = @_;

    my %relevants = ();

    my $dbh = $self->dbh;

    # Primary key
    my @primary_keys = $dbh->primary_key( $self->catalog, $schema, $table );
    $relevants{primary_keys} = \@primary_keys
        if scalar @primary_keys;

    # Columns
    my $sth_col = $dbh->column_info( $self->catalog, $schema, $table, '%' );
    my $column_info = $sth_col->fetchall_hashref('COLUMN_NAME');
    while ( my ( $column, $data ) = each %$column_info ) {
        my $column_data = $self->_build_schemadump_column($schema,$table,$column,$data);
        $relevants{columns}->{$column} = $column_data
            if $column_data;
    }

    # Foreign keys (only use a few selected meta-fields)
    my $sth_fk = $dbh->foreign_key_info( undef, undef, undef, $self->catalog, $schema, $table );
    if ($sth_fk) {
        my $fk={};
        while (my $data = $sth_fk->fetchrow_hashref) {
            my %useful = map { $_ => $data->{$_}} qw(UK_COLUMN_NAME UK_TABLE_NAME UK_TABLE_SCHEM);
            $fk->{$data->{FK_COLUMN_NAME}} = \%useful;
        }
        $relevants{foreign_keys} = $fk if keys %$fk;
    }

    return \%relevants;
}


sub _build_schemadump_column {
    my ($self,$schema,$table,$column,$data) = @_;

    my $relevants = { map { $_ => $data->{$_} } qw(COLUMN_NAME COLUMN_SIZE NULLABLE TYPE_NAME COLUMN_DEF) };

    # some cleanup
    if (my $default = $relevants->{COLUMN_DEF}) {
        if ( $default =~ /nextval/ ) {
            $default =~ m{'([\w\.\-_]+)'};
            if ($1) {
                my $new = $1;
                $new =~ s/^\w+\.//;
                $default = 'nextval:' . $new;
            }
        }
        $default=~s/["'\(\)\[\]\{\}]//g;
        $relevants->{COLUMN_DEF}=$default;
    }

    $relevants->{TYPE_NAME} =~ s/^(?:.+\.)?(.+)$/$1/g;

    return $relevants;
}


sub _build_update_path {
    my $self = shift;
    my $dir = $self->sqlsnippetdir;
    croak("Please specify sqlsnippetdir") unless $dir;
    croak("Cannot find sqlsnippetdir: $dir") unless -d $dir;

    say "Checking directory $dir for checksum_files" if $self->verbose;

    my %update_info;
    my @files = File::Find::Rule->file->name('*.sql')->in($dir);

    foreach my $file ( sort @files ) {
        my ( $pre, $post ) = $self->get_checksums_from_snippet($file);

        if ( !$pre && !$post ) {
            say "skipping $file (has no checksums)" if $self->verbose;
            next;
        }

        if ( $pre eq $post ) {
            if ( $update_info{$pre} ) {
                my @new = ('SAME_CHECKSUM');
                foreach my $item ( @{ $update_info{$pre} } ) {
                    push( @new, $item ) unless $item eq 'SAME_CHECKSUM';
                }
                $update_info{$pre} = \@new;
            }
            else {
                $update_info{$pre} = ['SAME_CHECKSUM'];
            }
        }

        if (   $update_info{$pre}
            && $update_info{$pre}->[0] eq 'SAME_CHECKSUM' )
        {
            if ( $post eq $pre ) {
                splice( @{ $update_info{$pre} },
                    1, 0, Path::Class::File->new($file), $post );
            }
            else {
                push( @{ $update_info{$pre} },
                    Path::Class::File->new($file), $post );
            }
        }
        else {
            $update_info{$pre} = [ Path::Class::File->new($file), $post ];
        }
    }

    return $self->_update_path( \%update_info ) if %update_info;
    return;
}


sub get_checksums_from_snippet {
    my ($self, $filename) = @_;
    die "need a filename" unless $filename;

    my %checksums;

    open( my $fh, "<", $filename ) || croak "Cannot read $filename: $!";
    while (<$fh>) {
        if (m/^--\s+(pre|post)SHA1sum:?\s+([0-9A-Fa-f]{40,})\s+$/) {
            $checksums{$1} = $2;
        }
    }
    close $fh;
    return map { $checksums{$_} || '' } qw(pre post);
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::SchemaChecksum - Manage your datebase schema via checksums

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    my $sc = DBIx::SchemaChecksum->new( dbh => $dbh );
    print $sc->checksum;

=head1 DESCRIPTION

When you're dealing with several instances of the same database (eg.
developer, testing, stage, production), it is crucial to make sure
that all databases use the same schema. This can be quite an
hair-pulling experience, and this module should help you keep your
hair (if you're already bald, it won't make your hair grow back,
sorry...)

C<DBIx::SchemaChecksum> gets schema information (tables, columns,
primary keys, foreign keys and some more depending on your DB) and
generates a SHA1 digest. This digest can then be used to easily verify
schema consistency across different databases, and to build an update
graph of changes. Therefor, C<DBIx::SchemaChecksum> does not requires
you to add a meta-table to your database to keep track of which
changes have already been deployed.

B<Caveat:> The same schema might produce different checksums on
different database versions.

B<Caveat:> C<DBIx::SchemaChecksum> only works with database engines
that support changes to the schema inside a transaction. We know this
works with PostgreSQL and SQLite. We know it does not work with MySQL
and Oracle. We don't know how other database engines behave, but would
be happy to hear about your experiences.

=head2 RUNNING DBIx::SchemaChecksum

Please take a look at the L<dbchecksum|bin/dbchecksum> script included
in this distribution. It provides a nice and powerful commandline
interface to make working with your schema a breeze.

=head2 EXAMPLE WORKFLOW

So you have this genious idea for a new startup that will make you
incredibly rich and famous...

=head3 Collect underpants

Usually such ideas involve a database. So you grab your L<favourite database engine|http://postgresql.org/> and start a new database:

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
a (free!) copy of C<DBIx::SchemaChecksum>

  ~/Gnomes$ cpanm DBIx::SchemaChecksum
  .. wait a bit while the giant, on which shoulders we are standing, is being assembled
  Successfully installed DBIx-SchemaChecksum
  42 distribution installed

Now you can create a new C<changes file>:

  ~/Gnomes$ dbchecksum new_changes_file --sqlsnippetdir sql --dsn dbi:Pg:dbname=gnomes --change_name "initial schema"
  New change-file ready at sql/inital_schema.sql

Let's take a look:

  ~/Gnomes$ cat sql/inital_schema.sql
  -- preSHA1sum:  54aa14e7b7e54cce8ae07c441f6bda316aa8458c
  -- postSHA1sum: xxx-New-Checksum-xxx
  -- inital schema

Each C<changes file> contains two very import "header" lines masked as a SQL comment:

C<preSHA1sum> is the checksum of the DB schema before the changes in
this file have been applied. C<postSHA1sum> is (you probably guessed
it) the checksum we expect after the changes have been applied.
Currently the C<postSHA1sum> is "xxx-New-Checksum-xxx" because we have
neither defined nor run the changes yet.

So let's append the handcrafted schema from earlier to the change file:

  ~/Gnomes$ cat sql/handcrafted_schema.sql >> sql/inital_schema.sql

The C<changes file> now looks like this:

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
haven't yet defined the C<postSHA1sum>, so we cannot be sure that the
database is in the state we expect it to be.

When you author a sql change, you will always have to first apply the
change to figure out the new C<postSHA1sum>. As soon as
C<DBIx::SchemaChecksum> tells you the checksum the DB will have after
the change is applied, you have to add the new checksum to your
C<changes file>:

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

=head3 Teamwork

Some weeks later (you have now convinced a friend to join you in your quest for fortune) a C<git pull> drops a new file into your C<sql> directory. It seems that your colleague needs some tweaks to the database:

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

=head3 Making things even easier: Config file

C<DBIx::SchemaChecksum> uses L<MooseX::App> to power the commandline
interface. We use the C<Config> and C<ConfigHome> plugins, so you can
pack some of the flags into a config file, for even less typing (and typos):

  ~/Gnomes$ cat dbchecksum.yml
  global:
    sqlsnippetdir: sql
    dsn: dbi:Pg:dbname=gnomes

Now run:

  ~/Gnomes$ dbchecksum apply_changes --config dbchecksum.yml
  db checksum 094ef4321e60b50c1d34529c312ecc2fcbbdfb51 matching sql/underpants_need_washing.sql

Or you can store the config file into your F<~/.dbchecksum/config.yml>:

  ~/Gnomes$ cat ~/.dbchecksum/config.yml
  global:
    sqlsnippetdir: sql
    dsn: dbi:Pg:dbname=gnomes

And it magically works:

  ~/Gnomes$ dbchecksum apply_changes
  db checksum 094ef4321e60b50c1d34529c312ecc2fcbbdfb51 matching sql/underpants_need_washing.sql

=head3 Profit!

This section is left empty as an exercise for the reader!

=head2 Anatomy of a changes-file

C<sqlsnippetdir> points to a directory containing so-called C<changes
files>. For a file to be picked up by C<dbchecksum> it needs to use
the extension F<.sql>.

The file itself has to contain a header formated as sql comments, i.e.
starting with C<-->. The header has to contain the C<preSHA1sum> and
should include the C<postSHA1sum>.

If the C<postSHA1sum> is missing, we assume that you don't know it yet and try to apply the change. As the new checksum will not match the empty C<postSHA1sum> the change will fail. But we will report the new checksum, which you can now insert into the changes file.

After the header, the changes file should list all sql commands you
want to apply to change the schema, seperated by a semicolon C<;>,
just as you would type them into your sql prompt.

  -- preSHA1sum:  b1387d808800a5969f0aa9bcae2d89a0d0b4620b
  -- postSHA1sum: 55df89fd956a03d637b52d13281bc252896f602f
  
  CREATE TABLE nochntest (foo TEXT);

Not all commands need to actually alter the schema, you can also
include sql that just updates some data. In fact, some schmema changes
even require that: for example, if you want to add a C<NOT NULL>
constraint to a column, you first have to make sure that the column in
fact does not contain a C<NULL>.

  -- preSHA1sum:  c50519c54300ec2670618371a06f9140fa552965
  -- postSHA1sum: 48dd6b3710a716fb85b005077dc534a8f9c11cba
  
  UPDATE foo SET some_field = 42 WHERE some_field IS NULL;
  ALTER TABLE foo ALTER some_filed SET NOT NULL;

=head3 Creating functions / stored procedures

Functions usually contain semicolons inside the function definition,
so we cannot split the file on semicolon. Luckily, you can specifiy a different splitter using C<-- split-at>. We usually use C<----> (again, the SQL comment marker) so the changes file is still valid SQL.

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

=head2 TIPS & TRICKS

We have been using C<DBIx::SchemaChecksum> since 2008 and encountered
a few issues. Here are our solutions:

=head3 Using 'checksum --show_dump' to find inconsistencies between databases

Sometimes two databases will produce different checksums. This can be
caused by a number of things. A good method to figure out what's
causing the problem is running C<<dbchecksum checksum --show_dump > some_name>>
on the databases causing the problem. Then you can use
C<diff> or C<vim -d> to inspect the raw dump.

Some problems we have encountered, and how to fix them:

=over

=item * Manual changes

Somebody did a manual change to a database (maybe an experiment on a
local DB, or some quick-fix on a live DB).

B<Fix:> Revert the change. Maybe make a proper change file if the
change makes sense for the project.

=item * Bad search-path

The C<search_paths> of the DBs differ. This can cause subtile
diferences in the way keys and references are reported, thus causing a
different checksum.

B<Fix:> Make sure all DBs use the same C<search_path>.

=item * Other schema-related troubles

Maybe the two instances use different values for C<--schemata>?

B<Fix:> Use the same C<--schemata> everywhere. Put them in a
config-file or write a wrapper script.

=item * Just weird diffs

Maybe the systems are using different version of the database server,
client, C<DBI> or C<DBD::*>. While we try hard to filter out
version-specific differences, this might still cause problems.

B<Fix:> Use the same versions on all machines.

=back

=head3 Use show_update_path if DBIx::SchemaChecksum cannot run on the database server

Sometimes it's impossible to get C<DBIx::SchemaChecksum> installed on
the database server (or on some other machine, I have horrible
recollections about a colleague using Windows..). And the sysadmin
won't let you access the database over the network...

B<Fix:> Prepare all changes on your local machine, and run them manually on the target machine.

  ~/Gnomes$ dbchecksum show_update_path --from_checksum 54aa14e7b7e54cce8ae07c441f6bda316aa8458c
  inital_schema.sql (611481f7599cc286fa539dbeb7ea27f049744dc7)
  underpants_need_washing.sql (094ef4321e60b50c1d34529c312ecc2fcbbdfb51)
  No update found that's based on 094ef4321e60b50c1d34529c312ecc2fcbbdfb51.

Now you could import the changes manually on the server. But it's even
easier using the C<--output> flag:

  ~/Gnomes$ dbchecksum show_update_path --output psql --dbname gnomes --from_checksum 54aa14e7b7e54cce8ae07c441f6bda316aa8458c
  psql gnomes -1 -f inital_schema.sql
  psql gnomes -1 -f underpants_need_washing.sql
  # No update found that's based on 094ef4321e60b50c1d34529c312ecc2fcbbdfb51.

You could pipe this into F<changes.sh> and then run that.

Or use C<--output concat>:

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

=head1 METHODS

You will only need those methods if you want to use the library itself instead of using the C<dbchecksum> wrapper script.

=head2 checksum

    my $sha1_hex = $self->checksum();

Gets the schemadump and runs it through Digest::SHA1, returning the current checksum.

=head2 schemadump

    my $schemadump = $self->schemadump;

Returns a string representation of the whole schema (as a Data::Dumper Dump).

Lazy Moose attribute.

=head2 _build_schemadump_schema

    my $hashref = $self->_build_schemadump_schema( $schema );

This is the main entry point for checksum calculations per schema.
Method-modifiy it if you need to alter the complete schema data
structure before/after checksumming.

Returns a HashRef like:

    {
        tables => $hash_ref
    }

=head2 _build_schemadump_tables

    my $hashref = $self->_build_schemadump_tables( $schema );

Iterate through all tables in a schema, calling
L<_build_schemadump_table> for each table and collecting the results
in a HashRef

=head2 _build_schemadump_table

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

=head2 _build_schemadump_column

    my $hashref = $self->_build_schemadump_column( $schema, $table, $column, $raw_dbi_data );

Does some cleanup on the data returned by DBI.

=head2 update_path

    my $update_info = $self->update_path

Lazy Moose attribute that returns the data structure needed by L<apply_sql_update>.

=head2 _build_update_path

C<_build_update_path> reads in all files ending in ".sql" in C<< $self->sqlsnippetdir >>.
It builds something like a linked list of files, which are chained by their
C<preSHA1sum> and C<postSHA1sum>.

=head2 get_checksums_from_snippet

    my ($pre, $post) = $self->get_checksums_from_snippet( $filename );

Returns a list of the preSHA1sum and postSHA1sum for the given file in C< sqlnippetdir>.

The file has to contain this info in SQL comments, eg:

  -- preSHA1sum: 89049e457886a86886a4fdf1f905b69250a8236c
  -- postSHA1sum: d9a02517255045167053ea92dace728e1389f8ca

  alter table foo add column bar;

=head2 dbh

Database handle (DBH::db). Moose attribute

=head2 catalog

The database catalog searched for data. Not implemented by all DBs. See C<DBI::table_info>

Default C<%>.

Moose attribute

=head2 schemata

An Arrayref containing names of schematas to include in checksum calculation. See C<DBI::table_info>

Default C<%>.

Moose attribute

=head2 sqlsnippetdir

Path to the directory where the sql change files are stored.

Moose attribute

=head2 verbose

Be verbose or not. Default: 0

=head2 driveropts

Additional options for the specific database driver.

=head1 GLOBAL OPTIONS

=head2 Connecting to the database

These options define how to connect to your database.

=head3 dsn

B<Required>. The C<Data Source Name (DSN)> as used by L<DBI> to connect to your database.

Some examples: C<dbi:SQLite:dbname=sqlite.db>,
C<dbi:Pg:dbname=my_project;host=db.example.com;port=5433>,
C<dbi:Pg:service=my_project_dbadmin>

=head3 user

Username to use to connect to your database.

=head3 password

Password to use to connect to your database.

=head2 Defining the schema dump

These options define which parts of the schema are relevant to the checksum

=head3 catalog

Default: C<%>

Needed during L<DBI> introspection. C<Pg> does not need it.

=head3 schemata

Default: C<%> (all schemata)

If you have several schemata in your database, but only want to consider some for the checksum, use C<--schemata> to list the ones you care about. Can be specified more than once to list several schemata:

  dbchecksum apply --schemata foo --schemata bar

=head3 driveropts

Some database drivers might implement further options only relevant
for the specific driver. As of now, this only applies to
L<DBIx::SchemaChecksum::Driver::Pg>, which defines the driveropts
C<triggers>, C<sequences> and C<functions>

=head1 SEE ALSO

L<bin/dbchecksum> for a command line frontend powered by L<MooseX::App>

There are quite a lot of other database schema management tools out
there, but nearly all of them need to store meta-info in some magic
table in your database.

=head2 Talks

You can find more information on the rational, usage & implementation
in the slides for my talk at the Austrian Perl Workshop 2012,
available here: L<http://domm.plix.at/talks/dbix_schemachecksum.html>

=head1 ACKNOWLEDGMENTS

Thanks to

=over

=item * Klaus Ita and Armin Schreger for writing the initial core code. I
just glued it together and improved it a bit over the years.

=item * revdev, a nice little software company run by Koki, domm
(L<http://search.cpan.org/~domm/>) and Maroš (L<http://search.cpan.org/~maros/>) from 2008 to 2011. We initially wrote C<DBIx::SchemaChecksum> for our work at revdev.

=item * L<validad.com|https://www.validad.com/> which grew out of
revdev and still uses (and supports) C<DBIx::SchemaChecksum> every
day.

=item * L<Farhad|https://twitter.com/Grauwolf> from L<Spherical
Elephant|https://www.sphericalelephant.com> for nagging me into
writing proper docs.

=item

=back

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@plix.at>

=item *

Maroš Kollár <maros@cpan.org>

=item *

Klaus Ita <koki@worstofall.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2021 by Thomas Klausner, Maroš Kollár, Klaus Ita.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

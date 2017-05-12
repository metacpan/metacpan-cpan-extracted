package DBIx::VersionedDDL;
use Moose;
use MooseX::Attribute::ENV;
use DBI;
use DBI::Const::GetInfoType;
use Carp;
use File::Basename;

with 'MooseX::Object::Pluggable';

has 'user'    => (is => 'ro', isa => 'Str',     required => 0);
has 'pass'    => (is => 'ro', isa => 'Str',     required => 0);
has 'dsn'     => (is => 'ro', isa => 'Str',     required => 0);
has 'ddl_dir' => (is => 'ro', isa => 'Str',     required => 1);
has 'debug'   => (is => 'ro', isa => 'Str',     required => 0, default => 0);
has 'dbh'     => (is => 'rw', isa => 'DBI::db', required => 0);

has 'script_processor' => (
    is                 => 'rw',
    isa                => 'Str',
    required           => 1,
    traits             => ['ENV'],
    env_package_prefix => 1,
    default            => 'DefaultScriptProcessor',
);

=head1 NAME

DBIx::VersionedDDL - Upgrade and downgrade database schemas to a specified version.

=head1 VERSION

Version 0.17

=cut

our $VERSION = '0.17';

=head1 SYNOPSIS

This module is a utility that can upgrade or downgrade a schema. 

    use DBIx::VersionedDDL;

    my $sv = DBIx::VersionedDDL->new(
        user => 'scott',
        pass => 'tiger',
        dsn  => 'DBI:Oracle:orcl',
        ddl_dir => '/home/jdoe/ddl'
    );
    
    # Migrate the schema to version 7.
    $sv->migrate(7);
    
or alternatively:

    use DBIx::VersionedDDL;

    my $dbh = DBI->connect('DBI:Oracle:orcl', 'scott', 'tiger');
    
    my $sv = DBIx::VersionedDDL->new(
        dbh     => $dbh,
        ddl_dir => '/home/jdoe/ddl'
    );
    
    # Migrate the schema to version 7.
    $sv->migrate(7);
    
DBIx::VersiondDDL installs a version table (schema_version) in
the schema that stores the current version number of this
schema. The developer or DBA who maintains the schema will place
a series of upgrade and downgrade scripts in a ddl directory.
The scripts will use the following naming convention:

    +-----------------+-------------------+
    | Upgrade Scripts | Downgrade Scripts |
    +-----------------+-------------------+
    | upgrade1.sql    | downgrade1.sql    |
    | upgrade2.sql    | downgrade2.sql    |
    | upgrade3.sql    | downgrade3.sql    |
    | upgrade4.sql    | downgrade4.sql    |
    | ....            | ....              |
    +-----------------+-------------------+

Each downgrade script reverses the changes of the upgrade
script. The scripts to run are determined by the value in the
version table If the current schema is at version 5 and the
administrator wishes to upgrade to version 10, upgrade scripts
6-10 would be run by the utility, and the version table entry
will be incremented at each step.

If the administrator wishes to downgrade to version 6, the
utility will run downgrade scripts 10-7.

This utility expects SQL statements to be separated by
semi-colons by default, but an explicit separator can be
specified.

=head2 Leaving the schema in an indeterminate state.

DDL statements are not transactionally aware, so you can not
roll back if there is an error in your DDL. You will need to
manually resolve such errors.

Any error will be saved to the schema_version table. The version
number is set to the script that was running when the error was
encountered.

=head2 Supplying an active database handle

The database handle will autocommit any updates to the schema
tables. If an active handle is supplied, it should not be shared
with any external transactions. The best approach is to clone
an active handle before passing it to the utility:

    my $dbh = DBI->connect('DBI:Oracle:orcl', 'scott', 'tiger');
    
    my $sv = DBIx::VersionedDDL->new(
        dbh     => $dbh->clone,
        ddl_dir => '/home/jdoe/ddl'
    );

The schema_version table has three columns:

    +---------+---------------------------------------------------+
    | Column  | Description                                       |
    +---------+---------------------------------------------------+
    | version | The current version of the schema                 |
    | status  | The status of the script that updated the version |
    |         | record. It will be either 'success' or 'error'    |
    | message | Any message generated when an error occurs        |
    +---------+---------------------------------------------------+

=head1 METHODS

=head2 new

The following attributes can be supplied at creation time by passing
values to the new method.

=over 4

=item * B<user>. The database user account

=item * B<pass>. The user password.

=item * B<dsn>. The database DSN

=item * B<ddl_dir>. The directory that hosts the migration scripts

=item * B<debug>. Whether debug messages are shown

=item * B<dbh>. An active database handle. This can be used as an alternative
to the user, pass and dsn parameters

=item * B<script_processor>. Optional. A plugin that processes the migration
scripts. See L</PROVIDING YOUR OWN PROCESSOR VIA A PLUGIN>

=back

=head2 migrate

Migrate from the current schema version to the specified one:

    $sv->migrate(7);
    
If a version is not provided, the schema will be upgraded (or downgraded!)
to the maximum version specified by upgrade(n).sql:

    $sv->migrate
    
=head2 get_message

Returns the message value in the schema_version table

=cut

sub migrate {
    my $self              = shift;
    my $requested_version = shift;

    unless (defined $requested_version) {
        $requested_version = $self->_get_max_version;
    }

    croak 'No version provided' unless $requested_version =~ /^\d+$/;

    $self->_create_version_table unless $self->_version_table_exists;

    my $current_version = $self->_get_current_version;

    croak "Invalid version" unless ($requested_version =~ /^\d+$/);
    croak "Invalid DDL directory" unless (-d $self->ddl_dir);

    return 1 if $requested_version == $current_version;

    my ($version, $script, $stop_version, $prefix);
    if ($requested_version > $current_version) {
        $prefix       = 'upgrade';
        $version      = $current_version + 1;
        $stop_version = $requested_version;
    } else {
        $prefix       = 'downgrade';
        $version      = $current_version;
        $stop_version = $requested_version;
    }

    eval {
        while (1)
        {
            printf("%s%s.sql\n", $prefix, $version) if $self->debug;
            $script = sprintf("%s%s.sql", $prefix, $version);
            $self->_run($script);

            if ($prefix eq 'upgrade') {
                $self->_update_version($version, 'success', undef);
                last if $version == $stop_version;
                $version++;
            } else {
                $version--;
                $self->_update_version($version, 'success', undef);
                last if $version == $stop_version;
            }
        }
    };

    if ($@) {
        my $error = $@;
        $version-- if $prefix eq 'downgrade';
        $self->_update_version($version, 'error',
            basename($script) . ': ' . $error);
        return 0;
    }

    return 1;
}

sub _get_max_version {
    my $self    = shift;
    my $version = 0;
    foreach my $file (glob($self->ddl_dir . "/upgrade*.sql")) {
        if ($file =~ /upgrade(\d+).sql/) {
            $version = $1 if $1 > $version;
        }
    }
    return $version;
}

# Set up the application
sub BUILD {
    my $self = shift;

    unless ($self->dbh) {
        croak "No database connect info" unless $self->dsn;

        my $dbh =
          DBI->connect($self->dsn, $self->user, $self->pass, {RaiseError => 1})
          || croak DBI::errstr;

        $self->dbh($dbh);
    }

    # Set this just in case it was unset in an external dbh
    $self->dbh->{AutoCommit} = 1;
    $self->dbh->{RaiseError} = 1;
    $self->dbh->{PrintError} = 0;

    croak "No DDL dir: " . $self->ddl_dir unless -d $self->ddl_dir;

    $self->load_plugins($self->script_processor,);
}

# Determine whether or not the version table exists
sub _version_table_exists {
    my $self   = shift;
    my $table  = 'schema_version';
    my $driver = lc $self->_get_driver;
    my $schema;

    # Oracle stores its tables in upper case while other dbs such as MySQL
    # use the case specified at table creation time
    if ($driver eq 'oracle') {
        $table  = uc $table;
        $schema = uc $self->dbh->get_info($GetInfoType{SQL_USER_NAME});
    } elsif ($driver eq 'mysql') {
        $schema =
          (split /:/, $self->dbh->get_info($GetInfoType{SQL_DATA_SOURCE_NAME}))
          [2];
    }

    my $sth = $self->dbh->table_info(undef, $schema, $table, 'TABLE');

    while (my $table_info = $sth->fetchrow_hashref()) {
        # Depending on whether FetchHashKeyName has been set to lower or
        # upper case, we should check both versions

        my $table_col =
          (defined $table_info->{table_name})
          ? 'table_name'
          : 'TABLE_NAME';

        if ($table_info->{$table_col} eq $table) {
            return 1;
        }
    }

    return 0;
}

# create the version table
sub _create_version_table {
    my $self = shift;

    # 3 Columns:
    #   * version: The schema version number
    #   * message: Any message generated by the schema upgrade/downgrade
    #              Generally only populated following a migration error.
    #   * status:  The status following the upgrade. Either "success" or
    #              error
    my $sql = q{
        create table schema_version(
            version integer,
            message varchar(4000),
            status  varchar(8)
        )
    };
    $self->dbh->do($sql);
    $sql = q{insert into schema_version(version) values(0)};
    $self->dbh->do($sql);
}

# Determine the current schema version
sub _get_current_version {
    my $self = shift;
    my $sql  = q{select version from schema_version};

    my ($version) = $self->dbh->selectrow_array($sql);
    return $version;
}

sub get_message {
    my $self = shift;
    my $sql  = q{select message from schema_version};

    my ($message) = $self->dbh->selectrow_array($sql);
    return $message;
}

# Run the specified SQL script
sub _run {
    my $self = shift;
    my $script = shift || croak "No script";
    $script = $self->ddl_dir . '/' . $script;
    croak "Cannot find $script" unless -f $script;

    my @statements = $self->process_script($script);

    foreach my $statement (@statements) {
        next if $statement =~ /^\s*$/;
        next unless $statement;
        $self->dbh->do($statement);
    }
}

# get the database type that we're connected to.
sub _get_driver {
    my $self = shift;
    return $self->dbh->get_info($GetInfoType{SQL_DBMS_NAME});
}

# update the version table
sub _update_version {
    my $self    = shift;
    my $version = shift;
    my $status  = shift || 'success';
    my $message = shift;

    my $sql = q{
        update schema_version
        set version = ?,
            status  = ?,
            message = ?
    };

    $self->dbh->do($sql, undef, $version, $status, $message);
}

=head1 PROVIDING YOUR OWN PROCESSOR VIA A PLUGIN

You can supply your own functionality to parse migration scripts
via a plugin. The plugin must contain a I<process_script> method
that takes a script name as an argument and returns an array of
SQL statements. The name of your plugin can either be set in the
environment variable I<SCRIPT_PROCESSOR> or the I<script_processor>
attribute as part of the constructor. If your plugin is called
DBIx::VersionedDDL::Plugin::MyProcessor, then SCRIPT_PROCESSOR should
be set to I<MyProcessor>.

For an example, refer to the source of L<DBIx::VersionedDDL::Plugin::DefaultScriptProcessor>

=head2 Populating plugin attributes

Any attributes should be populated once the Versioned object is created:

    my $sv = DBIx::VersionedDDL->new(
        user => 'scott',
        pass => 'tiger',
        dsn  => 'DBI:Oracle:orcl',
        ddl_dir => '/home/jdoe/ddl'
    );
    
    $sv->separator('/');

=head1 SCHEMA DEFINITION

The definition of a schema can differ between database products. For
Oracle a schema is a:

    collection of database objects, including logical structures
    such as tables, views, sequences, stored procedures, synonyms,
    indexes, clusters, and database links. A schema has the name of
    the user who controls it.
    
In this context, the user parameter should be the owner of the schema.
With other databases, such as MySQL, the schema is analogous to a
database. The user parameter should be an account that has full
privileges to the database  so that it can apply the DDL and update
the schema_version table.

=head1 SEE ALSO

L<migrate_schema> is a script supplied with this distribution that
supports the invocation of DBIx::VersionedDDL from the command line.

    migrate_schema -user=scott -pass=tiger -dsn=DBI:Oracle:orcl \
        -version=5 -ddl_dir=/my/ddl/dir
    
For more information:

    man migrate_schema

=head1 AUTHOR

Dan Horne, C<< <dhorne at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Plugin functionality added by Jiri Pavlovsky.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-versionedddl at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-VersionedDDL>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::VersionedDDL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-VersionedDDL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-VersionedDDL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-VersionedDDL>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-VersionedDDL/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Dan Horne.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut

1;    # End of DBIx::VersionedDDL

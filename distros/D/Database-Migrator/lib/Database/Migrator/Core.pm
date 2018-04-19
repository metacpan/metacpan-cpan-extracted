package Database::Migrator::Core;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.14';

use Database::Migrator::Types qw( ArrayRef Bool Dir File Maybe Str );
use DBI;
use Eval::Closure qw( eval_closure );
use IPC::Run3 qw( run3 );
use Log::Dispatch;
use Moose::Util::TypeConstraints qw( duck_type );
use MooseX::Getopt::OptionTypeMap;
use Try::Tiny;

use Moose::Role;

with 'MooseX::Getopt::Dashes';

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    Maybe [Str] => '=s',
);

requires qw(
    _create_database
    _driver_name
    _drop_database
    _run_ddl
);

has database => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has [qw( username password host port )] => (
    is      => 'ro',
    isa     => Maybe [Str],
    default => undef,
);

has migration_table => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has migrations_dir => (
    is       => 'ro',
    isa      => Dir,
    coerce   => 1,
    required => 1,
);

has schema_file => (
    is       => 'ro',
    isa      => File,
    coerce   => 1,
    required => 1,
);

has _database_exists => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_database_exists',
);

has __pending_migrations => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => ArrayRef [Dir],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_pending_migrations',
    handles  => {
        _pending_migrations    => 'elements',
        has_pending_migrations => 'count',
    },
);

has dbh => (
    traits   => ['NoGetopt'],
    is       => 'ro',
    isa      => 'DBI::db',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_dbh',
);

has logger => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    isa     => duck_type( [qw( debug info )] ),
    lazy    => 1,
    builder => '_build_logger',
);

has verbose => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has quiet => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has dry_run => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);

    $p->{username} = delete $p->{user}
        if exists $p->{user};

    return $p;
};

sub BUILD { }
after BUILD => sub {
    my $self = shift;

    die 'Cannot be both quiet and verbose'
        if $self->quiet() && $self->verbose();
};

sub create_or_update_database {
    my $self = shift;

    if ( $self->_database_exists() ) {
        my $database = $self->database();
        $self->logger()->debug("The $database database already exists");
    }
    else {
        $self->_create_database();
        $self->_run_ddl( $self->schema_file() );
    }

    $self->_run_migrations();

    return;
}

sub _run_migrations {
    my $self = shift;

    $self->_run_one_migration($_) for $self->_pending_migrations();
}

sub _run_one_migration {
    my $self      = shift;
    my $migration = shift;

    my $name = $migration->basename();

    $self->logger()->info("Running migration - $name");

    my @files = grep { !$_->is_dir() } $migration->children( no_hidden => 1 );

    for my $file ( sort _numeric_or_alpha_sort @files ) {
        my $basename = $file->basename();
        if ( $file =~ /\.sql/ ) {
            $self->logger()->debug(" - running $basename as sql");
            $self->_run_ddl($file);
        }
        elsif ( -x $file ) {
            $self->logger->debug(
                " - running $basename as a separate program");

            next if $self->dry_run;

            my @command = ( $file->absolute->stringify );
            my $stderr  = q{};
            run3( \@command, \undef, \undef, \$stderr );
            if ( $? != 0 || $stderr ne q{} ) {
                die "$file failed: $stderr";
            }
        }
        else {
            $self->logger()->debug(" - running $basename as perl code");

            my $perl = $file->slurp();

            my $sub = eval_closure( source => $perl );

            next if $self->dry_run();

            $sub->($self);
        }
    }

    return if $self->dry_run();

    my $table = $self->dbh()->quote_identifier( $self->migration_table() );
    $self->dbh()
        ->do( "INSERT INTO $table (migration) VALUES (?)", undef, $name );

    return;
}

sub _build_pending_migrations {
    my $self = shift;

    my $table = $self->migration_table();

    my %ran;
    if ( grep { $_ =~ /\b\Q$table\E\b/ } $self->dbh()->tables() ) {
        my $quoted = $self->dbh()->quote_identifier($table);

        %ran
            = map { $_ => 1 }
            @{ $self->dbh()
                ->selectcol_arrayref("SELECT migration FROM $quoted") || [] };
    }

    return [
        sort _numeric_or_alpha_sort grep { !$ran{ $_->basename() } }
            grep                         { $_->is_dir() }
            $self->migrations_dir()->children( no_hidden => 1 )
    ];
}

sub _build_logger {
    my $self = shift;

    my $outputs
        = $self->quiet()
        ? [ 'Null', min_level => 'emerg' ]
        : [
        'Screen',
        min_level => ( $self->verbose() ? 'debug' : 'info' ),
        newline => 1,
        ];

    return Log::Dispatch->new( outputs => [$outputs] );
}

sub _build_database_exists {
    my $self = shift;

    ## no critic (RequireBlockTermination)
    return try { $self->_build_dbh(); 1 } || 0;
}

sub _build_dbh {
    my $self = shift;

    return DBI->connect(
        'dbi:' . $self->_driver_name() . ':database=' . $self->database(),
        $self->username(),
        $self->password(), {
            RaiseError         => 1,
            PrintError         => 1,
            PrintWarn          => 1,
            ShowErrorStatement => 1,
        },
    );
}

sub _numeric_or_alpha_sort {
    my ( $a_num, $a_alpha ) = $a->basename() =~ /^(\d+)(.+)/;
    my ( $b_num, $b_alpha ) = $b->basename() =~ /^(\d+)(.+)/;

    $a_num ||= 0;
    $b_num ||= 0;

    $a_alpha ||= q{};
    $b_alpha ||= q{};

    return ( $a_num <=> $b_num or $a_alpha cmp $b_alpha );
}

1;

# ABSTRACT: Core role for Database::Migrator implementation classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Database::Migrator::Core - Core role for Database::Migrator implementation classes

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  package Database::Migrator::SomeDB;

  use Moose;
  with 'Database::Migrator::Core';

  sub _build_database_exists { }
  sub _build_dbh             { }
  sub _create_database       { }

=head1 DESCRIPTION

This role implements the bulk of the migration logic, leaving a few details up
to DBMS-specific classes.

You can then subclass these DBMS-specific classes to provide defaults for
various attributes, or to override some of the implementation.

=for Pod::Coverage   BUILD
  create_or_update_database

=head1 PUBLIC ATTRIBUTES

This role defines the following public attributes. These attributes may be
provided via the command line or you can set defaults for them in a subclass.

=over 4

=item * database

The name of the database that will be created or migrated. This is required.

=item * username, password, host, port

These parameters are used when connecting to the database. They are all
optional.

=item * migration_table

The name of the table which stores the name of applied migrations. This is
required.

=item * migrations_dir

The directory containing migrations. This is required, but it is okay if the
directory is empty.

=item * schema_file

The full path to the file containing the initial schema for the database. This
will be used to create the database if it doesn't already exist. This is required.

=item * verbose

This affects the verbosity of output logging. Defaults to false.

=item * quiet

If this is true, then no output will logged at all. Defaults to false.

=item * dry_run

If this is true, no migrations are actually run. Instead, the code just logs
what it I<would> do. Defaults to false.

=back

=head1 METHODS

This role provide just one public method, C<create_or_update_database()>.

It will create a new database if none exists.

It will run all unapplied migrations on this schema once it does exist.

=head1 REQUIRED METHODS

If you want to create your own implementation class, you must implement the
following methods. All of these methods should throw an error

=head2 $migration->_create_database()

This should create an I<empty> database. This role will take care of executing
the DDL for defining the schema.

=head2 $migration->_driver_name()

This return a string containing the DBI driver name, such as "mysql" or "Pg".

=head2 $migration->_drop_database()

This should drop the database. Right now it is only used for testing.

=head2 $migration->_run_ddl($ddl)

Given a string containing one or more DDL statements, this method must run
that DDL against the database.

=head1 OVERRIDEABLE ATTRIBUTES AND METHODS

There are a number of attributes methods in this role that you may wish to
override in a custom subclass of an implementation.

For any attribute where you provide a default value, make sure to also set C<<
required => 0 >> as well.

=over 4

=item * database attribute

You can provide a default database name.

=item * username, password, host, and port attributes

You can provide a default values for these connection attributes.

=item * migration_table

You can provide a default table name.

=item * migrations_dir

You can provide a default directory.

=item * schema_file

You can provide a default file name.

=item * _build_logger()

You must return an object with C<debug()> and C<info()> methods.

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Database-Migrator/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 - 2018 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

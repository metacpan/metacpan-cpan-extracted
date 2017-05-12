package Test::Database::Migrator;

use strict;
use warnings;
use namespace::autoclean;
use autodie;

our $VERSION = '0.12';

use File::Temp qw( tempdir );
use Database::Migrator::Types qw( ClassName Dir File Str );
use Log::Dispatch;
use Log::Dispatch::TestDiag;
use Path::Class qw( dir );
use Test::Fatal;
use Test::More 0.88;

use Moose;

has class => (
    is       => 'ro',
    isa      => ClassName,
    required => 1,
);

has database => (
    is      => 'ro',
    isa     => Str,
    default => 'DatabaseMigrator_test_' . $$,
);

has _tempdir => (
    is       => 'ro',
    isa      => Dir,
    init_arg => undef,
    lazy     => 1,
    default  => sub { dir( tempdir( CLEANUP => 1 ) ) },
);

has _schema_file => (
    is       => 'ro',
    isa      => File,
    init_arg => undef,
    lazy     => 1,
    default  => sub { $_[0]->_tempdir()->file('schema.sql') },
);

has _migrations_dir => (
    is       => 'ro',
    isa      => Dir,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_migrations_dir',
);

has _dbh => (
    is        => 'ro',
    isa       => 'DBI::db',
    init_arg  => undef,
    lazy      => 1,
    builder   => '_build_dbh',
    predicate => '_has_dbh',
);

sub run_tests {
    my $self = shift;

    $self->_write_ddl_file( $self->_schema_file(), $self->_schema_ddl() );

    ok(
        !$self->_new_migrator()->_database_exists(),
        $self->database() . ' does not exist yet'
    );

    $self->_check_initial_database();
    $self->_test_migrations();
}

sub _write_ddl_file {
    my $self = shift;
    my $file = shift;
    my $ddl  = shift;

    open my $fh, '>', $file;
    print {$fh} $ddl
        or die $!;
    close $fh;
}

sub _check_initial_database {
    my $self = shift;

    $self->_new_migrator()->create_or_update_database();

    my $migrator = $self->_new_migrator();

    ok(
        $migrator->_database_exists(),
        $self->database() . ' exists'
    );

    is_deeply(
        [ $self->_tables() ],
        [qw( applied_migration foo )],
        'newly created schema has the expected tables'
    );
}

sub _schema_ddl {
    return <<'EOF';
CREATE TABLE applied_migration (
    migration  VARCHAR(250)   PRIMARY KEY
);

CREATE TABLE foo (
    foo_id     INTEGER        PRIMARY KEY,
    foo_name   VARCHAR(50)    NOT NULL
);
EOF
}

sub _test_migrations {
    my $self = shift;

    $self->_write_first_migration();
    $self->_write_second_migration();

    $self->_new_migrator()->create_or_update_database();

    is_deeply(
        [ $self->_tables() ],
        [qw( applied_migration bar baz foo )],
        'migrated schema has the expected tables'
    );

    is_deeply(
        [ $self->_indexes_on('bar') ],
        ['bar_bar_name'],
        'bar table has the expected indexes'
    );

    is_deeply(
        [ $self->_indexes_on('baz') ],
        ['baz_baz_name'],
        'baz table has the expected indexes'
    );

    my $migrations = $self->_dbh()
        ->selectcol_arrayref('SELECT migration FROM applied_migration') || [];

    is_deeply(
        $migrations,
        [
            '01-first',
            '02-second',
        ],
        'migrations were recorded in the applied_migration table'
    );

    is(
        exception { $self->_new_migrator()->create_or_update_database() },
        undef,
        'no error running migrator again after migrations have been applied'
    );
}

# This migration writes out two separate files to test that the files in a
# given migration are run in sorted order. If they're not then the migration
# will fail entirely.
sub _write_first_migration {
    my $self = shift;

    my $dir = $self->_migrations_dir()->subdir('01-first');
    ## no critic (Lax::ProhibitLeadingZeros::ExceptChmod, ValuesAndExpressions::ProhibitLeadingZeros)
    $dir->mkpath( 0, 0755 );
    ## use critic

    my $create_tables = <<'EOF';
CREATE TABLE bar (
    bar_id     INTEGER        PRIMARY KEY,
    bar_name   VARCHAR(50)    NOT NULL
);

CREATE TABLE baz (
    baz_id     INTEGER        PRIMARY KEY,
    baz_name   VARCHAR(50)    NOT NULL
);
EOF

    $self->_write_ddl_file(
        $dir->file('01-create-tables.sql'),
        $create_tables,
    );

    $self->_write_ddl_file(
        $dir->file('02-create-bar-table-index.sql'),
        'CREATE INDEX bar_bar_name ON bar (bar_name)',
    );

    return;
}

sub _write_second_migration {
    my $self = shift;

    my $dir = $self->_migrations_dir()->subdir('02-second');
    ## no critic (Lax::ProhibitLeadingZeros::ExceptChmod, ValuesAndExpressions::ProhibitLeadingZeros)
    $dir->mkpath( 0, 0755 );
    ## use critic

    open my $fh, '>', $dir->file('01-create-baz-table-index.sql');
    print {$fh} <<'EOF' or die $!;
CREATE INDEX baz_baz_name ON baz (baz_name);
EOF
    close $fh;

    return;
}

sub _new_migrator {
    my $self = shift;

    return $self->class()->new(
        database        => $self->database(),
        migration_table => 'applied_migration',
        schema_file     => $self->_schema_file(),
        migrations_dir  => $self->_migrations_dir(),
        logger          => _logger(),
    );
}

sub _logger {
    return Log::Dispatch->new(
        outputs => [ [ 'TestDiag', min_level => 'info' ] ],
    );
}

sub _build_migrations_dir {
    my $self = shift;

    my $dir = $self->_tempdir()->subdir('migrations');
    ## no critic (Lax::ProhibitLeadingZeros::ExceptChmod, ValuesAndExpressions::ProhibitLeadingZeros)
    $dir->mkpath( 0, 0755 );
    ## use critic

    return $dir;
}

sub _build_dbh {
    my $self = shift;

    return $self->_new_migrator()->dbh();
}

sub DEMOLISH {
    my $self = shift;

    if ( $ENV{DATABASE_MIGRATOR_TEST_WAIT} ) {
        print "\n  Waiting to clean up the test database\n\n"
            or die $!;
        ## no critic (InputOutput::ProhibitExplicitStdin)
        my $x = <STDIN>;
    }

    $self->_dbh()->disconnect() if $self->_has_dbh();

    $self->_new_migrator()->_drop_database();
}

=for Pod::Coverage .*

=cut

__PACKAGE__->meta()->make_immutable();

1;

use strict;
use warnings;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );

use Test::Requires qw(DBI DBD::Pg Test::PostgreSQL);
use DBI;
use Test::PostgreSQL;
use Test::More;
use Test::Exception;

plan tests => 10;

require_ok('DBIx::Schema::Changelog::Driver::Pg');
use_ok 'DBIx::Schema::Changelog::Driver::Pg';

require_ok('DBIx::Schema::Changelog::Action::Trigger');
use_ok 'DBIx::Schema::Changelog::Action::Trigger';

my $driver = DBIx::Schema::Changelog::Driver::Pg->new();
my $object = DBIx::Schema::Changelog::Action::Trigger->new( driver => $driver );
is( $object->add( undef, 1 ), 3, 'Add Trigger is failing' );
my $alter = $object->alter( undef, 1 );
is( $alter->{add},  3, 'Alter Trigger is failing' );
is( $alter->{drop}, 3, 'Alter Trigger is failing' );
is( $object->drop( undef, 1 ), 3, 'Drop Trigger is failing' );

can_ok( 'DBIx::Schema::Changelog::Action::Trigger',
    @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'DBIx::Schema::Changelog::Action::Trigger' );

SKIP: {
    eval { require Test::PostgreSQL };
    my $pg = Test::PostgreSQL->new();
    skip "Test::PostgreSQL not installed", 0 unless $pg;

    my $dbh = DBI->connect(
        $pg->dsn( dbname => 'test' ),
        '', '', { AutoCommit => 1, RaiseError => 1, },
    );
    $object = DBIx::Schema::Changelog::Action::Trigger->new(
        driver => $driver,
        dbh    => $dbh
    );

    $dbh->disconnect();
    done_testing;
}


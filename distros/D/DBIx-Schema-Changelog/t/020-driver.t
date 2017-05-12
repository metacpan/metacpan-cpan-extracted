use Test::More tests => 8;
use Test::Requires qw(Test::Exception);
use Test::Exception;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );
use strict;
use warnings;
use DBI;
use DBIx::Schema::Changelog::Driver::SQLite;

require_ok('DBIx::Schema::Changelog::Role::Driver');
use_ok 'DBIx::Schema::Changelog::Role::Driver';

require_ok('DBIx::Schema::Changelog::Driver::SQLite');
use_ok 'DBIx::Schema::Changelog::Driver::SQLite';

my $dbh    = DBI->connect("dbi:SQLite:database=.tmp.sqlite");
my $driver = DBIx::Schema::Changelog::Driver::SQLite->new(
    max_version => 3.8,
    dbh         => $dbh
);
is( $driver->check_version('3.7'), 1, 'min version check' );

dies_ok { $driver->check_version('3.0') }
'underneath min version expecting to die';
dies_ok { $driver->check_version('3.9') } 'above min version expecting to die';
dies_ok { $driver->type('xml') } q~It's a Pg type and should die in SQLite~;


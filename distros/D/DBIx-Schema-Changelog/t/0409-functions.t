use strict;
use warnings;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );

use DBI;
use Test::More;
use Test::Exception;

plan tests => 5;

require_ok('DBIx::Schema::Changelog::Driver::SQLite');
use_ok 'DBIx::Schema::Changelog::Driver::SQLite';

require_ok('DBIx::Schema::Changelog::Action::Functions');
use_ok 'DBIx::Schema::Changelog::Action::Functions';

my $driver = DBIx::Schema::Changelog::Driver::SQLite->new();
my $obj = DBIx::Schema::Changelog::Action::Functions->new( driver => $driver );
isa_ok( $obj, 'DBIx::Schema::Changelog::Action::Functions' );




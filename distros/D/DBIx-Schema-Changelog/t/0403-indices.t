use Test::More tests => 6;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );
use strict;
use warnings;
use DBIx::Schema::Changelog::Driver::SQLite;
my $driver = DBIx::Schema::Changelog::Driver::SQLite->new();

require_ok('DBIx::Schema::Changelog::Action::Indices');
use_ok 'DBIx::Schema::Changelog::Action::Indices';

my $object = DBIx::Schema::Changelog::Action::Indices->new( driver => $driver );

can_ok( 'DBIx::Schema::Changelog::Action::Indices', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'DBIx::Schema::Changelog::Action::Indices' );

is( $object->alter(), undef, 'Sub is not used' );
is( $object->drop(),  undef, 'Sub is not used' );

use Test::More tests => 6;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );
use strict;
use warnings;


require_ok( 'DBIx::Schema::Changelog::Action::Sql' );
use_ok 'DBIx::Schema::Changelog::Action::Sql';

my $object = DBIx::Schema::Changelog::Action::Sql->new();

can_ok('DBIx::Schema::Changelog::Action::Sql', @{['add', 'alter', 'drop']});
isa_ok($object, 'DBIx::Schema::Changelog::Action::Sql');

is( $object->alter(), undef, 'Sub is not used' );
is( $object->drop(),  undef, 'Sub is not used' );

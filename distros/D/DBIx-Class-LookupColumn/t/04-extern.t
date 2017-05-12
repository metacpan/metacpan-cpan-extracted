use Test::More;
use Test::Exception;
use strict;
use warnings;
use Data::Dumper;

use lib qw(t/lib);
use DDP;
use Test::DBIx::Class -config_path => [[qw/t etc schema /], [qw/t etc schema1 schema1/]], 'User';

my $schema = Schema();

isa_ok Schema, 'Schema1'
  => 'Got Correct Schema';

fixtures_ok 'core', "loading core fixtures from file";

fixtures_ok 'core2', "loading perms fixtures from file";


my $result = 'Schema1::Result::User';
use_ok($result, "package $result can be used");

$result->load_components( qw/LookupColumn/ );
$result->add_lookup(  'permission', 'permission_type_id', 'PermissionType' );

{ # what if we defined twice the lookup, names should clash
	throws_ok { $result->add_lookup(  'permission', 'permission_type_id', 'PermissionType' ) } qr/already defined/i, 'collision detected => dies';

}

done_testing;

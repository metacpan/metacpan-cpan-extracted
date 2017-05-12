use Test::More;
use Test::Exception;
use strict;
use warnings;
use Data::Dumper;

use v5.14.2;
use lib qw(t/lib);
use DDP;
use Test::DBIx::Class -config_path => [[qw/t etc schema /], [qw/t etc schema1 schema1/]], 'User', 'PermissionType';
use Smart::Comments -ENV;


my $schema = Schema();


isa_ok $schema, 'Schema1'
  => 'Got Correct Schema';
 
 
fixtures_ok 'core', "loading core fixtures from file";

fixtures_ok 'core2', "loading perms fixtures from file";

{

my $result = 'Schema1::Result::User';
use_ok($result, "package $result can be used");
$result->load_components( qw/LookupColumn/ );

# called the add_lookup from outside
$result->add_lookup(  'permission', 'permission_type_id', 'PermissionType',
	{
		name_checker => 'is_the_permission',
		name_accessor => 'get_the_permission',
    	name_setter   => 'set_the_permission',		
	}
 );


# default accessors existence test
my $flash = User->find( {first_name => 'Flash' } );
dies_ok { $flash->permission }  "default should die because of the accessor passed in argument";
dies_ok { $flash->is_permission('User') }  "default should die because of the checker passed in argument";
dies_ok { $flash->set_permission('Administrator') }  "default should die because of the setter passed in argument";


# optional accessors existence test
my $perm_name = PermissionType->find( $flash->permission_type_id )->name;
my $perm;
lives_ok { $perm = $flash->get_the_permission }  "testing existence of lookup name accessor";
lives_ok { $flash->set_the_permission('Administrator') }  "testing existence of lookup setter";
my $is_user;
lives_ok { $is_user = $flash->is_the_permission('Administrator') }  "testing existence of lookup setter";
	
# correctness test
ok( $perm eq $perm_name, "lookup name accessor is right" );
ok( ! ($perm_name eq 'Administrator'), "lookup setter accessor is right" );
my $new_perm_name = PermissionType->find( $flash->permission_type_id )->name;
ok( $new_perm_name eq 'Administrator', "lookup setter accessor is right" );
ok( $is_user , "lookup checker accessor is right" );
	

}

done_testing;

use Test::More;
use Test::Exception;
use strict;
use warnings;
use Data::Dumper;

use v5.14.2;
use lib qw(t/lib);
use DDP;
use Test::DBIx::Class -config_path => [[qw/t etc schema /], [qw/t etc schema3 schema3/]], 'User', 'PermissionType';
use Smart::Comments -ENV;


my $schema = Schema();


isa_ok $schema, 'Schema3'
  => 'Got Correct Schema';
 
 
fixtures_ok 'core', "loading core fixtures from file";

fixtures_ok 'core2', "loading perms fixtures from file";



{
	my $flash = User->find( {first_name => 'Flash' } );
	ok($flash && $flash->first_name eq 'Flash', "got flash");
	
	my $perm_row = PermissionType->find( $flash->permission_type_id );
	ok($perm_row, "got permission row for flash");
	my $perm_name = $perm_row->name;
	ok($perm_name, "got permission row name for flash: $perm_name");
	
	
	# accessor existence test
	my $perm;
	lives_ok { $perm = $flash->permission }  "testing existence of lookup name accessor";
	lives_ok { $flash->set_permission('Administrator') }  "testing existence of lookup setter";
	my $is_user;
	lives_ok { $is_user = $flash->is_permission('Administrator') }  "testing existence of lookup setter";
	
	# correctness test
	ok( $perm eq $perm_name, "lookup name accessor is right" );
	ok( ! ($perm_name eq 'Administrator'), "lookup setter accessor is right" );
	my $new_perm_name = PermissionType->find( $flash->permission_type_id )->name;
	ok( $new_perm_name eq 'Administrator', "lookup setter accessor is right" );
	ok( $is_user , "lookup checker accessor is right" );
	
	
}


done_testing;

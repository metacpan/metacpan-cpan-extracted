use Test::More;
use Test::Exception;
use strict;
use warnings;
use Data::Dumper;


use DBIx::Class::LookupColumn::Manager;

use lib qw(t/lib);
use DDP;
use Test::DBIx::Class -config_path => [[qw/t etc schema /], [qw/t etc schemaUserDepartmentPermission schema_class/]], 'User', 'PermissionType', 'DepartmentType';

my $schema = Schema();


isa_ok $schema, 'SchemaUserDepartmentPermission'
  => 'Got Correct Schema';

 
fixtures_ok 'core4', "loading core fixtures from file";

fixtures_ok 'core2', "loading core fixtures from file";

fixtures_ok 'core3', "loading core fixtures from file";

	
my $administrator_cached_1	= DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID(  $schema, 'PermissionType', 'name', 1 );
my $marketing_cached_1		= DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID(  $schema, 'DepartmentType', 'name', 3 );

my $administrator			= PermissionType->find( 1 )->name;
my $marketing				= DepartmentType->find( 3 )->name;
ok( $administrator_cached_1	=~/$administrator/ , "FETCH_NAME_BY_ID fetched the right value $administrator_cached_1"  );
ok( $marketing_cached_1		=~/$marketing/ , "FETCH_NAME_BY_ID fetched the right value $marketing_cached_1	"  );

DBIx::Class::LookupColumn::Manager->RESET_CACHE_LOOKUP_TABLE( 'PermissionType' );
my $cache = DBIx::Class::LookupColumn::Manager->_GET_CACHE;
ok( !exists( $cache->{'PermissionType'} ), "cash test, table PermissionType is empty now"  );
ok( exists ( $cache->{'DepartmentType'} ), "cash test, DepartmentType's data is still remaining"  );


DBIx::Class::LookupColumn::Manager->RESET_CACHE;
$cache = DBIx::Class::LookupColumn::Manager->_GET_CACHE;
my @cache_keys = keys %$cache; 
ok(  !scalar( @cache_keys ), "cash test, completely empty now"  );


done_testing;

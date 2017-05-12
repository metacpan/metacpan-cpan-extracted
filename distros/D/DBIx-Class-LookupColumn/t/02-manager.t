use Test::More;
use Test::Exception;
use strict;
use warnings;
use Data::Dumper;


use DBIx::Class::LookupColumn::Manager;

use lib qw(t/lib);
use DDP;
use Test::DBIx::Class -config_path => [[qw/t etc schema /], [qw/t etc schema2 schema2/]], 'PermissionType';

my $schema = Schema();



isa_ok $schema, 'Schema2'
  => 'Got Correct Schema';

 
fixtures_ok 'core2', "loading core fixtures from file";
	
my @permissions = ResultSet('PermissionType')->all;
ok( @permissions , "got permissions: " . scalar( @permissions ) );

my $leader = PermissionType->find( {name => 'Leader'} );
ok( $leader, "got Leader value" );


my $administrator_cached_1 = DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID(  $schema, 'PermissionType', 'name', 1 );
my $administrator_dbic_row = PermissionType->find( 1 );
ok( $administrator_cached_1 =~ $administrator_dbic_row->name, "got name of id nr. 1 with FETCH_NAME_BY_ID : $administrator_cached_1"  );

my $id_user_cached = DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME(  $schema, 'PermissionType', 'name', 'User' );
my $user_dbic_row = PermissionType->find( {name=>'User'} );
ok( $id_user_cached =~ $user_dbic_row->id, "got of id User with FETCH_ID_BY_NAME : $id_user_cached"  );


# BEGIN tests about the cache system
my $administrator_faker_dbic_row = $administrator_dbic_row->update( {name =>'Faker'} );
my $administrator_cached_2 = DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID(  $schema, 'PermissionType', 'name', 1 );

# test whether no additionnal db query is done
ok( $administrator_cached_2 =~/Administrator/ , "cash test, without an additionnal db query, in the cache : $administrator_cached_2"  );

$administrator_dbic_row->update( {permission_type_id =>10} );
my $id_faker = DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME(  $schema, 'PermissionType', 'name', 'Administrator' );
ok( $id_faker =~ /1/, "cash test, without an additionnal db query, in the cache : $id_faker"  );
# END tests about the cache system



# exception is thrown value in Lookup table inexistent
dies_ok {DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID( $schema, 'PermissionType', 'name', 0 ) }  "FETCH_NAME_BY_ID: should die on bad id";
dies_ok {DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID( $schema, 'PermissionType', 'Homer', 1) }  "FETCH_NAME_BY_ID: should die on bad field name";
dies_ok {DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME( $schema, 'PermissionType', 'name', 'Faker' ) }  "FETCH_ID_BY_NAME: should die on bad name";
dies_ok {DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME( $schema, 'PermissionType', 'Homer', 'Administrator') }  "FETCH_ID_BY_NAME: should die on bad field name";
dies_ok {DBIx::Class::LookupColumn::Managerr->FETCH_ID_BY_NAME( $schema, 'Function', 'name', 'Director') }  "FETCH_ID_BY_NAME: should die on unknown table";
	

done_testing;

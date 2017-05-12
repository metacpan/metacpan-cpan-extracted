use Test::More;
use Test::Exception;
use strict;
use warnings;
use Data::Dumper;


use lib qw(t/lib);
use DDP;
use Test::DBIx::Class -config_path => [[qw/t etc schema /], [qw/t etc schemaLkpDetection schema_class/]], 'User', 'PermissionType', 'DepartmentType', 'StudyType';


my $schema = Schema();

isa_ok Schema, 'SchemaLkpDetection'
  => 'Got Correct Schema';

 
fixtures_ok 'core4', "loading core fixtures from file";

fixtures_ok 'core2', "loading core fixtures from file";

fixtures_ok 'core3', "loading core fixtures from file";

fixtures_ok 'core5', "loading core fixtures from file";


my $result = 'SchemaLkpDetection';
use_ok($result, "package $result can be used");


$result->load_components( qw/+DBIx::Class::LookupColumn::Auto/ );


my @tables = $schema->sources;

dies_ok{
		$result->add_lookups(
		targets => [ "User" ],
		verbose => 1
	);
} 'lookups args is missing ';


dies_ok{
		$result->add_lookups(
		lookups => [ "PermissionType", "DepartmentType" ],
		verbose => 1
	);
} 'targets args is missing ';



$result->add_lookups(
		targets => ["User"],
		lookups => [ "PermissionType", "StudyType" ],
		lookup_field_name_builder => sub{ 'helloColumn'; },
		verbose => 1
);

dies_ok { User->find( {first_name => 'Flash' } )->permissiontype } "this field in the lookup table does not exist";


done_testing;

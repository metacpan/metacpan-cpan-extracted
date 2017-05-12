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


$result->add_lookups(
		targets => ["User"],
		lookups => [ "PermissionType", "StudyType" ],
		relation_name_builder => sub{
				my ( $class, %args) = @_;
				$args{lookup} =~ /^(.+)Type$/;
				lc( $1 );
		},
		verbose => 1
);


ok( User->find( {first_name => 'Flash' } )->permission, "this accessor does exist" );
dies_ok { User->find( {first_name => 'Flash' } )->permissiontype } "this accessor does not exist";


done_testing;

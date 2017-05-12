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
	targets => [ grep { ! /Type$/ } @tables ],
	lookups => [ grep {   /Type$/ } @tables ],
	
	relation_name_builder => sub{
			my ( $class, %args) = @_;
			
			$args{lookup} =~ /^(.+)Type$/;
			lc( $1 );
	},
	lookup_field_name_builder => sub{
			'name';	
		}
);

{ # what if we defined twice the lookup, names should clash
	throws_ok { 
					$result->add_lookups(
						targets => [ grep { ! /Type$/ } @tables ],
						lookups => [ grep {   /Type$/ } @tables ],
						
						relation_name_builder => sub{
							my ( $class, %args) = @_;
								
							$args{lookup} =~ /^(.+)Type$/;
							lc( $1 );
						},
						lookup_field_name_builder => sub{
								'name';	
						}
					)

				} qr/already defined/i, 'collision detected => dies';

}


my $flash = User->find( {first_name => 'Flash' } );
my $flash_perm_name = PermissionType->find( $flash->permission_type_id )->name;
my $flash_department_name = DepartmentType->find( $flash->department_type_id )->name; 

# with the lookup detection 
my $flash_perm_lookup = User->find( {first_name => 'Flash' } )->permission; 
ok( $flash_perm_name =~ $flash_perm_lookup, "add_lookups is now working $flash_perm_lookup"  );

# with the lookup detection 
my $flash_department_lookup = User->find( {first_name => 'Flash' } )->department; 
ok( $flash_department_lookup =~ $flash_department_name, "add_lookups is now working $flash_department_lookup"  );


done_testing;

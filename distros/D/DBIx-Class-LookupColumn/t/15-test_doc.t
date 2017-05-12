use Test::More;

use strict;
use warnings;

use lib qw(t/lib);
use DDP;
use Test::DBIx::Class -config_path => [[qw/t etc schema /], [qw/t etc schemaForThesisDocumentation schema_class/]], 'User', 'PermissionType';
use Data::Dumper;

my $schema = Schema();

isa_ok Schema, 'SchemaForThesisDocumentation'
  => 'Got Correct Schema';

fixtures_ok 'core9_for_doc', "loading core fixtures from file";
fixtures_ok 'core10_for_doc', "loading core fixtures from file";

my @users = ResultSet('User')->all;
ok( @users, "got users: " . scalar(@users) );

my $flash = User->find( {first_name => 'Itachi'} );
ok($flash, "got Itachi");

my @users_rs = $schema->resultset( "User" )->search( {last_name => "Uchiwa"} );
# suppose we want the permissionType of users whose last name is "Uchiwa";
foreach my $user (@users_rs){	
	warn $user->first_name. " ". $user->permissionType()->name. "\n";	
} 
# produces 
# Itachi Guest
# Sasuke User

warn "\n";
warn "\n";

# suppose we want the users with a user permissionType
my $perm_rs = $schema->resultset( "PermissionType" )->find( {name => "User"} );
my @users_all = $perm_rs->users();
map{ warn $_->first_name ." ".$_->last_name ."\n" } @users_all;
 
# produces 
# Sasuke Uchiwa
# Naruto Uzumaki
# Sakura Haruno


# suppose we want all users and display their own permission
my @all = $schema->resultset( "User" )->all();

map{ warn $_->first_name ." ".$_->last_name ." ".$_->permissionType()->name ."\n" } @all;
 # produces 
# Itachi Uchiwa Guest
# Sasuke Uchiwa User
# Naruto Uzumaki User
# Kakashi Hatake Administrator 
# Sakura Haruno User




my $result = 'SchemaForThesisDocumentation';
use_ok($result, "package $result can be used");

$result->load_components( qw/LookupColumn::Auto/ );

my @tables = $schema->sources;

$result->add_lookups(
		targets => [ grep{ !/Type$/  }@tables ],
		lookups => [ grep{ /Type$/} @tables],
		relation_name_builder => sub{
			my ( $class, %args) = @_;	
			$args{lookup} =~ /^(.+)Type$/;
			lc( $1 );
		},
		lookup_field_name_builder => sub { 'name' }
);



# print only Guests
map{ warn $_->first_name . " ". $_->last_name } grep{ $_->is_permission('Guest') }@all;
# produces 
# Itachi Uchiwa


# change right from User to Guest
map{ warn $_->set_permission( 'Guest' ) } grep{ $_->is_permission('User') } @all;
# just a test for checking if it does work with parentheses
map{ warn $_->first_name() . " ". $_->last_name() } grep{ $_->is_permission('Guest') } @all;
# produces 
# Kakashi Hatake



my $sasuke = $schema->resultset('User')->find( {first_name => 'Kakashi', last_name => 'Hatake'} ) ;
my $kakashi_is_admin1 = $sasuke->permissionType()->name eq 'Administrator';
my $kakashi_is_admin2 = $sasuke->is_permission( 'Administrator' );
warn $kakashi_is_admin1;
warn $kakashi_is_admin2;




done_testing;

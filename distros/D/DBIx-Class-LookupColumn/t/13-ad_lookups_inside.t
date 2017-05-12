use Test::More;
use Test::Exception;
use strict;
use warnings;
use Data::Dumper;
use Class::MOP;
use Smart::Comments -ENV;
use lib qw(t/lib);
use DDP;
use 5.14.2;

use Test::DBIx::Class -config_path => [[qw/t etc schema /], [qw/t etc schema_ad_lookups_inside schema_class/]], 'Actor', 'ActorRole', 'RoleType';

my $schema = Schema();

isa_ok Schema, 'Schema_ad_lookups_inside'
  => 'Got Correct Schema';

 
fixtures_ok 'core6', "loading core fixtures from file";

fixtures_ok 'core7', "loading core fixtures from file";

fixtures_ok 'core8', "loading core fixtures from file";



my $result = 'Schema_ad_lookups_inside';
use_ok($result, "package $result can be used");


my $actor = $schema->resultset('Actor')->find ( 1 );


# GETTER
# with our accessor
my @roles_played = $actor->role_names();
# classical way
my @roles_played_classical = map { $_->roletype()->name } $actor->actorroles();
ok( @roles_played ~~ @roles_played_classical, "getter : same result" ); 


# SETTER
my $right_value = "Warlock";
my $wrong_value = "Warloc";

# with our accessor
my $played_warlock = $actor->has_role ( $right_value );
#classical way
my $played_warlock_classical =  $right_value ~~ @roles_played_classical; 

ok( $played_warlock ~~ $played_warlock_classical, "checker : same result" ); 
dies_ok{ $actor->has_role ( $wrong_value )} "throws an exception because $wrong_value does not exist in the DB";
lives_ok{ $wrong_value ~~ @roles_played_classical } "does not throw an exception with the classical way";



done_testing;

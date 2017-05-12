#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 34;

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
    use_ok("Class::Trait::Config");
}

can_ok( "Class::Trait::Config", 'new' );
my $trait_config = Class::Trait::Config->new();

isa_ok( $trait_config, 'Class::Trait::Config' );

# check the expected contents of an
# empty Class::Trait::Config object

can_ok( $trait_config, 'name' );
ok( !$trait_config->name );

can_ok( $trait_config, 'sub_traits' );
is( ref( $trait_config->sub_traits ), "ARRAY", '... its an array reference' );
ok( eq_array( $trait_config->sub_traits, [] ), '... both should be empty' );

can_ok( $trait_config, 'requirements' );
is( ref( $trait_config->requirements ), "HASH", '... its an hash reference' );
ok( eq_hash( $trait_config->requirements, {} ), '... both should be empty' );

can_ok( $trait_config, 'methods' );
is( ref( $trait_config->methods ), "HASH", '... its an hash reference' );
ok( eq_hash( $trait_config->methods, {} ), '... both should be empty' );

can_ok( $trait_config, 'overloads' );
is( ref( $trait_config->overloads ), "HASH", '... its an hash reference' );
ok( eq_hash( $trait_config->overloads, {} ), '... both should be empty' );

can_ok( $trait_config, 'conflicts' );
is( ref( $trait_config->conflicts ), "HASH", '... its an hash reference' );
ok( eq_hash( $trait_config->conflicts, {} ), '... both should be empty' );

# create some variables to put
# into the $trait_config object

my $name         = "Trait Config Test";
my $sub_traits   = [ "Sub Trait Test 1", "Sub Trait Test 2" ];
my $requirements = { "test" => 1 };
my $methods      = {
    "untest" => sub { not $_[0]->test() }
};
my $overloads = { "=="       => 1, "!=" => 1 };
my $conflicts = { "toString" => 1 };

# add in those same variables

$trait_config->name($name);
$trait_config->sub_traits($sub_traits);
$trait_config->requirements($requirements);
$trait_config->methods($methods);
$trait_config->overloads($overloads);
$trait_config->conflicts($conflicts);

# now test that they were successfully inserted

is( $trait_config->name, $name, '... it should assigned now' );

is( ref( $trait_config->sub_traits ), "ARRAY", '... its an array reference' );
ok( eq_array( $trait_config->sub_traits, $sub_traits ),
    '... both should not be empty' );

is( ref( $trait_config->requirements ), "HASH", '... its an hash reference' );
ok( eq_hash( $trait_config->requirements, $requirements ),
    '... both should not be empty' );

is( ref( $trait_config->methods ), "HASH", '... its an hash reference' );
ok( eq_hash( $trait_config->methods, $methods ),
    '... both should not be empty' );

is( ref( $trait_config->overloads ), "HASH", '... its an hash reference' );
ok( eq_hash( $trait_config->overloads, $overloads ),
    '... both should not be empty' );

is( ref( $trait_config->conflicts ), "HASH", '... its an hash reference' );
ok( eq_hash( $trait_config->conflicts, $conflicts ),
    '... both should not be empty' );

# clone test

can_ok( $trait_config, 'clone' );

my $trait_config_clone = $trait_config->clone();
isa_ok( $trait_config_clone, 'Class::Trait::Config' );

isnt( $trait_config, $trait_config_clone, '... these should be different' );

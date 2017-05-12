#!/usr/bin/perl -w

use Test::More tests => 14;
use Activator::Registry;

my $test_yaml_file = "$ENV{PWD}/t/data/Registry-test.yml";

# object instantiation
my $reg = Activator::Registry->new( $test_yaml_file );
ok( defined ( $reg ), 'instantiate' );

# basic functionality
my $list = $reg->get( 'list_of_5_letters');
ok( defined ( $list ), 'key defined');
ok( @$list == 5, 'key is list' );
ok( @$list[4] eq 'e', 'value match' );

# deep structs maintained
my $deep = $reg->get( 'deep_hash' );
ok( exists ( $deep->{level_1} ), 'deep key level 1 exists' );
ok( exists ( $deep->{level_1}->{level_2} ), 'deep key level 2 exists' );
ok( exists ( $deep->{level_1}->{level_2}->{level_3} ), 'deep key level 3 exists' );
ok( defined ( $deep->{level_1}->{level_2}->{level_3} ), 'deep key level 3 defined' );
ok( $deep->{level_1}->{level_2}->{level_3} eq 'this is level 3', 'deep value match' );

# key does not exist
my $dne_value = $reg->get('dne_value');
ok( !defined( $dne_value ), 'non-existent key returns undef' );

# deep get
my $deep_key = 'deep_hash->level_1->level_2->level_3';
my $deep_val = $reg->get( $deep_key );
ok( $deep_val && $deep_val eq 'this is level 3', 'deep arrow syntax: value match' );
eval {
    $deep_val = $reg->get( "${deep_key}->level_4" );
};
ok( defined $@, 'deep get of non-existent key throws exception' );

# deep register
my $success = $reg->register( $deep_key, 'modified' );
ok( $success, 'deep arrow syntax: register existing key returns true' );
$deep_val = $reg->get( $deep_key );
ok( $deep_val && $deep_val eq 'modified', 'deep arrow syntax: register value match' );

    
## # create a test file to reload
my $dyn_test_yaml_file = "$ENV{PWD}/t/data/Registry-dyn.yml";
## my $test_yaml = YAML::LoadFile( $dyn_test_yaml_file );
## system( "rm -f $dyn_test_yaml_file");
## YAML::DumpFile( $dyn_test_yaml_file, $test_yaml );
## ok( -f $dyn_test_yaml_file, 'create dynamic test yaml file' );
## system( "echo '  dyn_value: set' >> $dyn_test_yaml_file");
## 
## # turn on dynamic load
## $reg->register('DYNAMIC_YAML_REGISTRY', 1 );
## 
## # create a "new" object: it's a singleton, so it'll be the same
## my $reg2 = Activator::Registry->new( $dyn_test_yaml_file );
## $dyn_value = $reg2->get('dyn_value');
## ok( defined( $dyn_value ), 'key dynamically added' );
## ok( $dyn_value eq 'set', 'dynamic value match' );
## ok( $dyn_value eq 'set', 'singleton dynamic value match' );

#!/usr/bin/perl -w

use Test::More tests => 9;
use Activator::Registry;
use Activator::Log;
use Data::Dumper;

BEGIN {
    $ENV{ACT_REG_YAML_FILE} ||= "$ENV{PWD}/t/data/Registry-test.yml";
}

Activator::Log->level('DEBUG');

# basic functionality
my $realm = Activator::Registry->get_realm( 'default');
my $list = Activator::Registry->get( 'list_of_5_letters');
ok( defined ( $list ), 'key defined');
ok( ref( $list ) eq 'ARRAY', 'key is list' );
ok( scalar @$list == 5, 'list is correct size' );
ok( @$list[4] eq 'e', 'value match' );

# deep structs maintained
my $deep = Activator::Registry->get( 'deep_hash' );
ok( exists ( $deep->{level_1} ), 'deep key level 1 exists' );
ok( exists ( $deep->{level_1}->{level_2} ), 'deep key level 2 exists' );
ok( exists ( $deep->{level_1}->{level_2}->{level_3} ), 'deep key level 3 exists' );
ok( defined ( $deep->{level_1}->{level_2}->{level_3} ), 'deep key level 3 defined' );
ok( $deep->{level_1}->{level_2}->{level_3} eq 'this is level 3', 'deep value match' );

# TODO: test dynamic reload of yaml

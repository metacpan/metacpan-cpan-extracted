#!/usr/bin/perl -w

use Test::More tests => 8;
use Activator::Registry;

BEGIN {
    $ENV{ACT_REG_YAML_FILE} ||= "$ENV{PWD}/t/data/Registry-test-no-act-realm.yml";
}

# basic functionality
my $list = Activator::Registry->get( 'list_of_5_letters');
ok( defined ( $list ), 'key defined');
ok( @$list == 5, 'key is list' );
ok( @$list[4] eq 'e', 'value match' );

# deep structs maintained
my $deep = Activator::Registry->get( 'deep_hash' );
ok( exists ( $deep->{level_1} ), 'deep key level 1 exists' );
ok( exists ( $deep->{level_1}->{level_2} ), 'deep key level 2 exists' );
ok( exists ( $deep->{level_1}->{level_2}->{level_3} ), 'deep key level 3 exists' );
ok( defined ( $deep->{level_1}->{level_2}->{level_3} ), 'deep key level 3 defined' );
ok( $deep->{level_1}->{level_2}->{level_3} eq 'this is level 3', 'deep value match' );

# TODO: test dynamic reload of yaml

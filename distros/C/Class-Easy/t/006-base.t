#!/usr/bin/perl
package My::Class;

use Class::Easy::Base;

has x => (is => 'rw');
has 'y';

sub instance {
	return shift;
}

1;

package main;

use Class::Easy::Import;
use Test::More qw(no_plan);
use Data::Dumper;

my $c = My::Class->new (x => 1, y => 2);

ok $c->x == 1;     # return 1

$c->x (3); # store 3

ok $c->x == 3;

ok !$c->can ('package_path');
ok !$c->can ('lib_path');

SKIP: {
	eval {require File::Spec};

	skip "File::Spec is almoststandard, but not installed", 2 if $@;

	$c->attach_paths;

	ok $c->can ('package_path'), $c->package_path;
	ok $c->can ('lib_path'), $c->lib_path . ' - produce wrong values for packages with no dedicated file';
};


$c->set_field_values (x => 5);

ok $c->x == 5;

eval {$c->set_field_values (y => 3);};

ok $c->y == 2, 'ok cannot set ro field'; 

my $subs = $c->list_all_subs;

ok keys %{$subs->{inherited}} == 1;

# warn Dumper $subs;

ok keys %{$subs->{method}} == 1;
#! /usr/bin/env perl

# test for Config::Nested::Section

use 5;
use warnings;
use strict;

# Standard modules.
use Data::Dumper;
use Storable qw(dclone);
use Carp;

use Test::More tests => 19;

# Tests
BEGIN { use_ok('Config::Nested::Section'); }

my $c;
ok($c = new Config::Nested::Section(), "constructor");

my $obj;
ok($obj = new Config::Nested::Section(
		list	=> [],
		path	=> [],
		owner	=> '',
		location=> '',
		colour	=> {},
		contents=> [],
		hash1	=> {},
		hash2	=> {},
		number	=> 0,
	), "constructor with arguments");
#warn "obj = ", Dumper($obj);

# Construction.....
ok(ref $obj->owner() eq '', "init scalar");
ok(ref $obj->colour() eq 'HASH', "init hash");
ok(ref $obj->path() eq 'ARRAY', "init array");

# settings.
ok('' eq $obj->owner(), "assign 0");

eval { $obj->badmember(); };
ok($@ ne '', "Bad member call should fail");

ok('Fred' eq $obj->owner('Fred'), "assign 1");
ok('here' eq $obj->location('here'), "assign 2");

ok($obj->list(qw(a b c d e)), "assign list");
ok($obj->list->[0] eq 'a', "assign list check");

my $obj2 = $obj->new();
my $obj3 = $obj->new(scalar => 'name');

$obj2->owner('Harold');
ok('Fred' eq $obj->owner(), "clone and assign");
ok('Harold' eq $obj2->owner(), "clone and assign");
ok('name' eq $obj3->scalar(), "new member");

unshift @{$obj->list}, 'zero';
$obj2->colour->{head} = 'blue';
ok('blue' eq $obj2->colour->{head}, "clone and assign hash");
ok(!defined $obj->colour->{head}, "clone and assign hash");

#warn "obj = ", Dumper($obj);
#warn "obj2= ", Dumper($obj2);
#warn "obj3= ", Dumper($obj3);

#eval { $obj->job; }; print $@;

my $b = new Config::Nested::Section(path => [], contact => {});
$b->path->[0] ='first step';
$b->contact->{'parent'} ='Mum';
#warn "b=", Dumper($b);
ok('first step' eq $b->path->[0], "b 1");
ok('Mum' eq $b->contact->{'parent'}, "b 2");



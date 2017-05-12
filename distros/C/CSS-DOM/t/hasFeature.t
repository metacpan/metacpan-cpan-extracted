#!/usr/bin/perl -T

use strict; use warnings;

use Test::More tests => 24;

use CSS::DOM;
my $o = new CSS::DOM;
my $c = 'CSS::DOM';

for (qw/css2 cSs2 stylesheets stYleSHeEts/) {
	ok!$c->hasFeature($_ => '1.0'), qq'class->hasFeature("$_","1.0")';
	ok $c->hasFeature($_ => '2.0'), qq'class->hasFeature("$_","2.0")';
	ok $c->hasFeature($_),          qq'class->hasFeature("$_")';
	ok!$o->hasFeature($_ => '1.0'), qq'\$obj->hasFeature("$_","1.0")';
	ok $o->hasFeature($_ => '2.0'), qq'\$obj->hasFeature("$_","2.0")';
	ok $o->hasFeature($_),          qq'\$obj->hasFeature("$_")';
}

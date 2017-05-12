#!perl -w

use strict;
use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 6) : (skip_all => 'require Test::LeakTrace');

use Test::LeakTrace;

use B::Foreach::Iterator;

no_leaks_ok{
	foreach (1){
		my $x = iter();
	}
} 'iter()';


no_leaks_ok{
	foreach(1 .. 3){
		iter->next
	}
} 'iter->next for 1 .. 2';

no_leaks_ok{
	foreach('a' .. 'c'){
		iter->next
	}
} q{iter->next for 'a' .. 'c'};


no_leaks_ok{
	my @a = (1 .. 3);
	foreach(@a){
		iter->next
	}
} q{iter->next for @a};

no_leaks_ok{
	my @a = (reverse 1 .. 3);
	foreach(@a){
		iter->next
	}
} q{iter->next for reverse @a};

no_leaks_ok{
	FOO: foreach(1){
		my $x = iter('FOO')->label
	}
} q{iter->label};

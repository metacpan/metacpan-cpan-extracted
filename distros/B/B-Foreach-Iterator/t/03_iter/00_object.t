#!perl -w

use strict;
use Test::More tests => 9;

use B::Foreach::Iterator;

foreach (1){
	my $iter = iter;

	{
		isa_ok $iter, 'B::Foreach::Iterator';
		is $iter->label, undef;
	}

	FOO: foreach (2){
		isa_ok iter(), 'B::Foreach::Iterator';
		is iter()->label, 'FOO';

		foreach(3){
			is iter('FOO')->label, 'FOO';
		}
	}
}

my $iter;
foreach(1){
	$iter = iter;
};

eval{
	$iter->label;
};
like $@, qr/Out of scope/, 'out of scope';

foreach(1){
	eval{
		$iter->label;
	};
	like $@, qr/Out of scope/, 'out of scope';
}

eval{
	iter('FOO');
};
like $@, qr/FOO/, 'label not found';

eval{
	BAR: foreach (3){
		iter('FOO');
	}
};
like $@, qr/FOO/, 'label not found';

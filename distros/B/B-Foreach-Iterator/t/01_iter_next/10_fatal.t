#!perl -w

use strict;
use Test::More tests => 3;

use B::Foreach::Iterator;

eval{
	iter->next;
};

like $@, qr/No foreach loops found/;

eval{
	while(1){

		iter->next;

		last;
	}
};

like $@, qr/No foreach loops found/;

eval{
	for(;;){

		iter->next;

		last;
	}
};

like $@, qr/No foreach loops found/;

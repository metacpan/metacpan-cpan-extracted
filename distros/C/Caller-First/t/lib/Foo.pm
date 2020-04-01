package Foo;
use strict;
use warnings;
use Caller::First qw/all/;

sub new {
	bless {}, shift;
}

sub test {
	return caller_first();
}

1;

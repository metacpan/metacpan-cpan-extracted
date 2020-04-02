package Bar;
use strict;
use warnings;
use Caller::Reverse qw/caller_first/;
use parent 'Foo';

sub testing {
	caller_first();
}


1;

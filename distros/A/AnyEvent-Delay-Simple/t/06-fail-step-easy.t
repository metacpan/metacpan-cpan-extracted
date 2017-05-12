#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::Loop;
use AnyEvent::Delay::Simple qw(easy_delay);


local $ENV{PERL_ANYEVENT_LOG} = 'log=nolog';

#
# Suppose that exception raises into step callback.
#
my $cv = AE::cv;
my $val;

easy_delay(
	sub { $val = 'foo'; return 'foo'; },
	sub {
		die('bar');
		$val = 'bar';
	},
	sub { $val = 'qux'; return 'qux'; },
	sub {
		ok @_ == 1;
		like $_[0], qr/^bar/;
		$cv->send();
	},
	sub { fail; $cv->send(); }
);
eval { $cv->recv(); };
fail if $@;
is $val, 'foo';


done_testing;

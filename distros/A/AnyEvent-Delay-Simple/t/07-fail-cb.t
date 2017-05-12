#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::Loop;
use AnyEvent::Delay::Simple qw(delay);


local $ENV{PERL_ANYEVENT_LOG} = 'log=nolog';

#
# Suppose that exception raises into condvar callback.
#
my $cv = AE::cv;
my $val;

delay(
	sub { pop()->send('foo'); $val = 'foo'; },
	sub {
		pop()->cb(sub { die('bar'); });
		$val = 'bar';
	},
	sub { pop()->send('qux'); $val = 'qux'; },
	sub {
		pass;
		ok @_ == 2;
		like $_[0], qr/^bar/;
		$cv->send();
	},
	sub { fail; $cv->send(); }
);
eval { $cv->recv(); };
fail if $@;
is $val, 'bar';


done_testing;

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::Loop;
use AnyEvent::Delay::Simple qw(delay);


local $ENV{PERL_ANYEVENT_LOG} = 'log=nolog';

#
# Suppose that exception raises into step callback.
#
my $cv = AE::cv;
my $val;

delay(
	sub { pop()->send('foo'); $val = 'foo'; },
	sub {
		die('bar');
		$val = 'bar';
	},
	sub { pop()->send('qux'); $val = 'qux'; },
	sub {
		ok @_ == 2;
		like $_[0], qr/^bar/;
		$cv->send();
	},
	sub { fail; $cv->send(); }
);
eval { $cv->recv(); };
fail if $@;
is $val, 'foo';


done_testing;

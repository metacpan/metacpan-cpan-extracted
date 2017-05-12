#!/usr/bin/perl

# Benchmark a variety of different Aspect use cases.
#
# Set 1 shows the main Aspect uses with Sub::Uplevel 0.22
#
# C:\cpan\trunk\Aspect>perl -Mblib benchmark\advice.pl
# Benchmark: timing 500000 iterations of after, after_returning, after_throwing, around, before, control, deep1, deep10, deep5...
#      after: 14 wallclock secs (12.76 usr +  0.00 sys = 12.76 CPU) @ 39181.88/s (n=500000)
# after_returning: 15 wallclock secs (13.56 usr +  0.02 sys = 13.57 CPU) @ 36840.55/s (n=500000)
# after_throwing: 14 wallclock secs (13.31 usr +  0.00 sys = 13.31 CPU) @ 37574.21/s (n=500000)
#     around: 26 wallclock secs (23.53 usr +  0.00 sys = 23.53 CPU) @ 21253.99/s (n=500000)
#     before:  4 wallclock secs ( 3.82 usr +  0.00 sys =  3.82 CPU) @ 130821.56/s (n=500000)
#    control:  0 wallclock secs ( 0.09 usr +  0.00 sys =  0.09 CPU) @ 5319148.94/s (n=500000)
#             (warning: too few iterations for a reliable count)
#      deep1: 40 wallclock secs (37.99 usr +  0.00 sys = 37.99 CPU) @ 13162.40/s (n=500000)
#     deep10: 26 wallclock secs (23.24 usr +  0.02 sys = 23.26 CPU) @ 21496.13/s (n=500000)
#      deep5: 34 wallclock secs (31.79 usr +  0.00 sys = 31.79 CPU) @ 15726.73/s (n=500000)
#
#
#
#
# Set 2 shows the main Aspect uses with the frame warning in Sub::Uplevel disabled
#
# C:\cpan\trunk\Aspect>perl -Mblib benchmark\advice.pl
# Benchmark: timing 500000 iterations of after, after_returning, after_throwing, around, before, control, deep1, deep10, deep5...
#      after:  5 wallclock secs ( 6.12 usr +  0.00 sys =  6.12 CPU) @ 81766.15/s (n=500000)
# after_returning:  7 wallclock secs ( 7.33 usr +  0.00 sys =  7.33 CPU) @ 68194.22/s (n=500000)
# after_throwing:  7 wallclock secs ( 6.33 usr +  0.00 sys =  6.33 CPU) @ 78951.52/s (n=500000)
#     around:  9 wallclock secs ( 9.13 usr +  0.00 sys =  9.13 CPU) @ 54788.52/s (n=500000)
#     before:  4 wallclock secs ( 3.87 usr +  0.00 sys =  3.87 CPU) @ 129232.36/s (n=500000)
#    control:  1 wallclock secs ( 0.08 usr +  0.00 sys =  0.08 CPU) @ 6410256.41/s (n=500000)
#             (warning: too few iterations for a reliable count)
#      deep1: 11 wallclock secs (10.72 usr +  0.00 sys = 10.72 CPU) @ 46650.49/s (n=500000)
#     deep10:  9 wallclock secs ( 9.14 usr +  0.00 sys =  9.14 CPU) @ 54698.61/s (n=500000)
#      deep5: 10 wallclock secs (10.27 usr +  0.00 sys = 10.27 CPU) @ 48709.21/s (n=500000)

use strict;
use Sub::Uplevel;
use Aspect;





######################################################################
# Test Class

SCOPE: {
	package Foo;

	sub control {
		return 1;
	}

	sub before {
		return 1;
	}

	sub after {
		return 1;
	}

	sub after_returning {
		return 1;
	}

	sub after_throwing {
		return 1;
	}

	sub around {
		return 1;
	}

	sub deep1 {
		deep2(@_);
	}

	sub deep2 {
		deep3(@_);
	}

	sub deep3 {
		deep4(@_);
	}

	sub deep4 {
		deep5(@_);
	}

	sub deep5 {
		deep6(@_);
	}

	sub deep6 {
		deep7(@_);
	}

	sub deep7 {
		deep8(@_);
	}

	sub deep8 {
		deep9(@_);
	}

	sub deep9 {
		deep10(@_);
	}

	sub deep10 {
		return 1;
	}
}





######################################################################
# Aspect Setup

my $foo = 1;

before {
	$foo++;
} call 'Foo::before';

after {
	$foo++;
} call 'Foo::after';

after {
	$foo++;
} call 'Foo::after_returning' & returning;

after {
	$foo++;
} call 'Foo::after_throwing' & throwing;

around {
	$foo++;
	$_->proceed
} call 'Foo::around';

around {
	$foo++;
	$_->proceed;
} call 'Foo::deep10';





######################################################################
# Benchmark Execution

use Benchmark qw{ :all :hireswallclock };

timethese( 100000, {
	control         => 'Foo::control()',
	before          => 'Foo::before()',
	after           => 'Foo::after()',
	after_returning => 'Foo::after_returning()',
	after_throwing  => 'Foo::after_throwing()',
	around          => 'Foo::around()',
	deep1           => 'Foo::deep1()',
	deep5           => 'Foo::deep5()',
	deep10          => 'Foo::deep10()',
	uplevel         => 'Sub::Uplevel::uplevel( 1, \&Foo::control )',
} );

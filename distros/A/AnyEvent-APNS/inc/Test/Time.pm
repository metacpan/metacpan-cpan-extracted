#line 1
package Test::Time;
use strict;
use warnings;

use Test::More;

our $VERSION = '0.04';
our $time = CORE::time();

my $pkg = __PACKAGE__;
my $in_effect = 1;

sub in_effect {
	$in_effect;
}

sub import {
	my ($class, %opts) = @_;
	$time = $opts{time} if defined $opts{time};

	*CORE::GLOBAL::time = sub() {
		if (in_effect) {
			$time;
		} else {
			CORE::time();
		}
	};

	*CORE::GLOBAL::sleep = sub(;$) {
		if (in_effect) {
			my $sleep = shift || 1;
			$time += $sleep;
			note "sleep $sleep";
		} else {
			CORE::sleep(shift);
		}
	}
};

sub unimport {
	$in_effect = 0;
}

1;
__END__

=encoding utf8

#line 90

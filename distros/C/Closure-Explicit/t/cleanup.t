use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Refcount;
use Scalar::Util qw(weaken);

use Closure::Explicit qw(callback);

{
	my $x = [];
	my $y = 123;
	my $weak_copy;
	{
		my $code = callback {
			my $x = shift;
			die "wrong value" unless $x && ref $x;
			print "$y\n";
		} weaken => [qw($x)], allowed => [qw($y)];
		$weak_copy = $code;
	}
	ok($weak_copy, 'have a copy');
	weaken $weak_copy;
	ok(!$weak_copy, 'no more copy');
}
done_testing();


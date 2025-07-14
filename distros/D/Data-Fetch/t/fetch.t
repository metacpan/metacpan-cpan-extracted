#!perl -wT

use strict;
use warnings;
use threads;
use Test::Most tests => 29;
use Test::Warn;

BEGIN {
	use_ok('Data::Fetch');
}

FETCH: {
	warning_like {
		my $one = Data::Value->new(1);
		my $fetch = new_ok('Data::Fetch');
		$fetch->prime(object => $one, message => 'get');
		ok($fetch->get(object => $one, message => 'get') == 1);
		is($fetch->get(object => $one, message => 'get'), 1, 'test cache works on primed value');

		my $two = Data::Value->new(2);
		$fetch->prime(object => $two, message => 'get');
		ok($fetch->get(object => $two, message => 'get') == 2);
		ok($fetch->get(object => $two, message => 'get') == 2);
		$two->set(22);
		ok($two->get() == 22);
		is($fetch->get(object => $two, message => 'get'), 2, 'Check values are cached');

		my $three = Data::Value->new(3);
		$fetch->prime(object => $three, message => 'get', arg => 'prefix');
		ok($fetch->get(object => $three, message => 'get', arg => 'prefix') eq 'prefix: 3');
		ok($fetch->get(object => $three, message => 'get', arg => 'prefix') eq 'prefix: 3');

		# This primed value is never used, which may produce
		#	a warning because of the thread leak
		my $four = Data::Value->new(4);
		$fetch->prime(object => $four, message => 'get', arg => 'prefix');

		my $five = Data::Value->new(5);
		$five->set(55);
		$fetch->prime(object => $five, message => 'get');
		ok($fetch->get(object => $five, message => 'get') == 55);

		# Test returning a list ref.  Note that returning an array isn't yet supported
		my @in = (7, 8);
		my $six = Data::Value->new(\@in);
		$fetch->prime(object => $six, message => 'get');
		my @res = @{$fetch->get(object => $six, message => 'get')};
		is(scalar(@res), 2, 'Check 2 items returned');
		is($res[0], 7, 'Check first item is correct');
		is($res[1], 8, 'Check second item is correct');

		# Primed array
		my $seven = Array::Value->new();
		@res = $fetch->prime(object => $seven, message => 'get');
		@res = $fetch->get(object => $seven, message => 'get');
		is(scalar(@res), 2, 'Test array context returns the correct number of elements');
		is($res[0], 'a', 'Test first element of array is correct');
		is($res[1], 'b', 'Test second element of array is correct');

		# Primed array with arguments
		my $eight = Array::Value->new();
		@res = $fetch->prime(object => $eight, message => 'get', arg => 'array');
		@res = $fetch->get(object => $eight, message => 'get', arg => 'array');
		is(scalar(@res), 2, 'Test array context returns the correct number of elements');
		is($res[0], 'array: a', 'Test first element of array is correct with arguments');
		is($res[1], 'array: b', 'Test second element of array is correct with arguments');

		# Unprimed array
		my $nine = Array::Value->new();
		$fetch = new_ok('Data::Fetch');
		@res = $fetch->get(object => $nine, message => 'get');
		is(scalar(@res), 2, 'Test array context returns the correct number of elements');
		is($res[0], 'a', 'Test first element of array is correct');
		is($res[1], 'b', 'Test second element of array is correct');
		@res = $fetch->get(object => $nine, message => 'get');	# Check caching works on an array
		is($res[1], 'b', 'Test second element of cached array is correct');

		my $ten = Data::Value->new();
		$fetch->prime(object => $ten, message => 'get');
		is($fetch->get(object => $ten, message => 'get'), undef, 'Test routines that return undef');
		is($fetch->get(object => $ten, message => 'get'), undef, 'Test routine returns undef on second call');
	} qr/primed but not used at/, 'test leak is caught';

	# Clean the leaked thread
	my @threads = threads->list();
	cmp_ok(scalar(@threads), '<=', 1, 'There is no more than one thread left');
	foreach my $t(@threads) {
		$t->join();
	}
}

package Data::Value;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	if(my $value = shift) {
		return bless { value => $value }, $class;
	}
	return bless { }, $class;
}

sub get {
	my $self = shift;
	my $arg = shift;

	if($arg) {
		return "$arg: $self->{value}";
	}
	return $self->{value};
}

sub set {
	my $self = shift;
	my $arg = shift;

	$self->{value} = $arg;
}

1;

package Array::Value;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	if(my $value = shift) {
		return bless { value => $value }, $class;
	}
	return bless { }, $class;
}

sub get {
	my $self = shift;
	my $arg = shift;

	if($arg) {
		return("$arg: a", "$arg: b");
	}

	return('a', 'b');
}

1;

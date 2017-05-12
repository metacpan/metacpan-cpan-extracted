#!perl -wT

use strict;
use warnings;
use Test::Most tests => 17;
use Test::NoWarnings;

BEGIN {
	use_ok('Data::Fetch');
}

FETCH: {
	my $simple = Data::Value->new(1);
	my $fetch = new_ok('Data::Fetch');
	$fetch->prime(object => $simple, message => 'get');
	ok($fetch->get(object => $simple, message => 'get') == 1);
	ok($fetch->get(object => $simple, message => 'get') == 1);

	$simple = Data::Value->new(2);
	$fetch->prime(object => $simple, message => 'get');
	ok($fetch->get(object => $simple, message => 'get') == 2);
	ok($fetch->get(object => $simple, message => 'get') == 2);
	$simple->set(22);
	ok($simple->get() == 22);
	is($fetch->get(object => $simple, message => 'get'), 2, 'Check values are cached');

	$simple = Data::Value->new(3);
	$fetch->prime(object => $simple, message => 'get', arg => 'prefix');
	ok($fetch->get(object => $simple, message => 'get', arg => 'prefix') eq 'prefix: 3');
	ok($fetch->get(object => $simple, message => 'get', arg => 'prefix') eq 'prefix: 3');

	$simple = Data::Value->new(4);
	$fetch->prime(object => $simple, message => 'get', arg => 'prefix');

	$simple = Data::Value->new(5);
	$simple->set(55);
	$fetch->prime(object => $simple, message => 'get');
	ok($fetch->get(object => $simple, message => 'get') == 55);

	# Test returning a list ref.  Note that returning an array isn't yet supported
	my @in = (7, 8);
	$simple = Data::Value->new(\@in);
	$fetch->prime(object => $simple, message => 'get');
	my @res = @{$fetch->get(object => $simple, message => 'get')};
	is(scalar(@res), 2, 'Check 2 items returned');
	is($res[0], 7, 'Check first item is correct');
	is($res[1], 8, 'Check second item is correct');

	# $simple = Array::Value->new();
	# $fetch->prime(object => $simple, message => 'get');
	# @res = $fetch->get(object => $simple, message => 'get');
	# ok(scalar(@res) == 2);
	# ok($res[0] == 7);
	# ok($res[1] == 8);

	$simple = Data::Value->new();
	$fetch->prime(object => $simple, message => 'get');
	is($fetch->get(object => $simple, message => 'get'), undef, 'Test routines that return undef');
	is($fetch->get(object => $simple, message => 'get'), undef, 'Test routine returns undef on second call');
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

# package Array::Value;
# 
# sub new {
	# my $proto = shift;
	# my $class = ref($proto) || $proto;
# 
	# return unless(defined($class));
# 
	# return bless { }, $class;
# }
# 
# sub get {
	# my $self = shift;
# 
	# return('a', 'b');
# }
# 
1;

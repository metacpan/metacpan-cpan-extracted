#!perl -wT

use strict;
use warnings;
use Test::Most tests => 33;
use Test::NoWarnings;
use CHI;

BEGIN {
	use_ok('Class::Simple::Cached');
}

CLASS: {
	my $cache = CHI->new(driver => 'RawMemory', global => 1);
	$cache->on_set_error('die');
	$cache->on_get_error('die');
	my $l = new_ok('Class::Simple::Cached' => [ cache => $cache, object => x->new() ]);

	cmp_ok($l->isa('x'), '==', 1, 'isa finds embedded object');
	cmp_ok($l->isa('Class::Simple::Cached'), '==', 1, 'isa finds class');
	cmp_ok($l->isa('UNIVERSAL'), '==', 1, 'isa enhericance works');
	cmp_ok($l->isa('CHI'), '==', 0, 'isa works out when not object');

	ok($l->calls() == 0);
	ok($l->barney('betty') eq 'betty');
	ok($l->calls() == 1);
	ok($l->barney() eq 'betty');
	ok($l->calls() == 1);
	ok($l->barney() eq 'betty');
	ok($l->calls() == 1);
	my @abc = $l->abc();
	ok(scalar(@abc) == 3);
	ok($abc[0] eq 'a');
	ok($abc[1] eq 'b');
	ok($abc[2] eq 'c');
	@abc = $l->abc();
	ok(scalar(@abc) == 3);
	ok($abc[0] eq 'a');
	ok($abc[1] eq 'b');
	ok($abc[2] eq 'c');
	my @a = $l->a();
	ok(scalar(@a) == 1);
	ok($a[0] eq 'a');
	@a = $l->a();
	ok(scalar(@a) == 1);
	ok($a[0] eq 'a');

	# FIXME: why is this test different from t/hash.t?
	my @empty = $l->empty();
	ok(scalar(@empty) == 0);
	ok(!defined($l->empty()));
	ok(!defined($l->empty()));

	# White box test the cache
	ok($cache->get('barney') eq 'betty');
	my $a = $cache->get('a');
	ok(ref($a) eq 'ARRAY');
	my $abc = $cache->get('abc');
	ok(ref($abc) eq 'ARRAY');
	ok(scalar(@{$abc}) == 3);

	if(defined($ENV{'TEST_VERBOSE'})) {
		foreach my $key($cache->get_keys()) {
			diag("$key = ", $cache->get($key));
		}
	}
}

package x;

sub new {
	my $proto = shift;

	my $class = ref($proto) || $proto;

	return bless { calls => 0 }, $class;
}

sub barney {
	my $self = shift;
	my $param = shift;

	$self->{'calls'}++;
	if($param) {
		return $self->{'x'} = $param;
	}
	return $self->{'x'};
}

sub abc {
	return ('a', 'b', 'c');
}

sub a {
	return 'a';
}

sub empty {
}

sub calls {
	my $self = shift;

	return $self->{'calls'};
}

1;

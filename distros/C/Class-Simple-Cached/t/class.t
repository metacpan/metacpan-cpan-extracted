#!perl -wT

use strict;
use warnings;
use Test::Most tests => 19;
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

	ok($l->calls() == 0);
	ok($l->barney('betty') eq 'betty');
	ok($l->calls() == 1);
	ok($l->barney() eq 'betty');
	ok($l->calls() == 1);
	ok($l->barney() eq 'betty');
	ok($l->calls() == 1);
	my @abc = $l->abc();
	ok(scalar(@abc) == 3);
	my @a = $l->a();
	ok(scalar(@a) == 1);
	ok($a[0] eq 'a');

	ok(!defined($l->empty()));
	ok(!defined($l->empty()));

	# White box test the cache
	ok($cache->get('barney') eq 'betty');
	my $a = $cache->get('a');
	ok(ref($a) eq 'ARRAY');
	my $abc = $cache->get('abc');
	ok(ref($abc) eq 'ARRAY');
	ok(scalar(@{$abc}) == 3);

	# foreach my $key($cache->get_keys()) {
		# diag($key);
	# }
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

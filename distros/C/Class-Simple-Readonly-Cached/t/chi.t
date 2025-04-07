#!perl -w

use strict;
use warnings;
use Test::Most tests => 42;
use Test::NoWarnings;
use CHI;

BEGIN {
	use_ok('Class::Simple::Readonly::Cached');
}

CHI: {
	my $cache = CHI->new(driver => 'RawMemory', global => 1);
	$cache->on_set_error('die');
	$cache->on_get_error('die');
	my $l = new_ok('Class::Simple::Readonly::Cached' => [ cache => $cache, object => t::x->new() ]);

	cmp_ok($l->isa('t::x'), '==', 1, 'isa finds embedded object');
	cmp_ok($l->isa('Class::Simple::Readonly::Cached'), '==', 1, 'isa finds class');
	cmp_ok($l->isa('UNIVERSAL'), '==', 1, 'isa inheritance works');
	cmp_ok($l->isa('CHI'), '==', 0, 'isa works out when not object');

	ok($l->barney('betty') eq 'betty');
	ok($l->barney() eq 'betty');
	ok($l->barney() eq 'betty');
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

	ok($l->echo('foo') eq 'foo');
	ok($l->echo('foo') eq 'foo');
	ok($l->echo('bar') eq 'bar');
	ok($l->echo('bar') eq 'bar');
	ok($l->echo('foo') eq 'foo');

	my @empty = $l->empty();
	ok(scalar(@empty) == 0);

	ok(!defined($l->empty()));
	ok(!defined($l->empty()));

	@empty = $l->notdefined();
	ok(scalar(@empty) == 1);
	ok(!defined($empty[0]));
	@empty = $l->notdefined();
	ok(scalar(@empty) == 1);
	ok(!defined($empty[0]));

	# White box test the cache
	ok($cache->get('Class::Simple::Readonly::Cached::barney::') eq 'betty');
	ok($cache->get('Class::Simple::Readonly::Cached::barney::betty') eq 'betty');
	ok($cache->get('Class::Simple::Readonly::Cached::echo::foo') eq 'foo');
	ok($cache->get('Class::Simple::Readonly::Cached::echo::bar') eq 'bar');
	my $a = $cache->get('Class::Simple::Readonly::Cached::a::');
	ok(ref($a) eq 'ARRAY');
	my $abc = $cache->get('Class::Simple::Readonly::Cached::abc::');
	ok(ref($abc) eq 'ARRAY');

	# foreach my $key($cache->get_keys()) {
		# diag($key);
	# }

	# diag(Data::Dumper->new([$cached->state()])->Dump());
	my $hits = $l->state()->{'hits'};
	my $count;
	while(my($k, $v) = each %{$hits}) {
		$count += $v;
	}
	is($count, 8, 'cache contains 8 hits');

	my $misses = $l->state()->{'misses'};
	$count = 0;
	while(my($k, $v) = each %{$misses}) {
		$count += $v;
	}
	is($count, 9, 'cache contains 9 misses');

	diag($l->x()->x());
}

package t::x;

sub new {
	my $proto = shift;

	my $class = ref($proto) || $proto;

	return bless { }, $class;
}

sub barney {
	return 'betty';
}

sub abc {
	return ('a', 'b', 'c');
}

sub a {
	return 'a';
}

sub x {
	my $rc = Class::Simple->new();
	$rc->x('y');

	return $rc;
}

sub empty {
}

sub notdefined {
	return (undef);
}

sub echo {
	my $self = shift;

	if(wantarray) {
		return @_;
	}

	return $_[0];
}

1;

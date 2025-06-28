#!perl -w

use strict;
use warnings;
use Class::Simple;
use Test::Most tests => 51;
use Test::NoWarnings;

BEGIN {
	use_ok('Class::Simple::Readonly::Cached');
}

HASH: {
	my $cache = {};
	my $cached = new_ok('Class::Simple::Readonly::Cached' => [ cache => $cache, object => x->new() ]);

	ok($cached->can('object'));
	ok($cached->can('barney'));
	ok($cached->can('abc'));
	ok(!$cached->can('xyz'));
	ok($cached->isa('Class::Simple::Readonly::Cached'));

	ok($cached->barney('betty') eq 'betty');
	ok($cached->barney() eq 'betty');
	ok($cached->barney() eq 'betty');
	my @abc = $cached->abc();
	ok(scalar(@abc) == 3);
	ok($abc[0] eq 'a');
	ok($abc[1] eq 'b');
	ok($abc[2] eq 'c');
	@abc = $cached->abc();
	ok(scalar(@abc) == 3);
	ok($abc[0] eq 'a');
	ok($abc[1] eq 'b');
	ok($abc[2] eq 'c');

	my $uncached = x->new();

	# Check reading scalar after reading array
	my $abc = $cached->abc();
	my $abc2 = $uncached->abc();
	cmp_ok($abc, 'eq', $abc2, 'test reading scalar after reading array');

	# Check reading array after reading scalar
	my $def = $cached->def();
	ok($def eq 'f');
	my $def2 = $uncached->def();
	ok($def eq $def2);
	my @def = $cached->def();
	ok(scalar(@def) == 3);

	my @a = $cached->a();
	ok(scalar(@a) == 1);
	ok($a[0] eq 'a');
	@a = $cached->a();
	ok(scalar(@a) == 1);
	ok($a[0] eq 'a');

	ok($cached->echo('foo') eq 'foo');
	ok($cached->echo('foo') eq 'foo');
	ok($cached->echo('bar') eq 'bar');
	ok($cached->echo('bar') eq 'bar');
	ok($cached->echo('foo') eq 'foo');

	my @empty = $cached->empty();
	ok(scalar(@empty) == 0);

	ok(!defined($cached->empty()));
	ok(!defined($cached->empty()));

	# White box test the cache
	ok($cache->{'Class::Simple::Readonly::Cached::barney::'} eq 'betty');
	ok($cache->{'Class::Simple::Readonly::Cached::barney::betty'} eq 'betty');
	ok($cache->{'Class::Simple::Readonly::Cached::echo::foo'} eq 'foo');
	ok($cache->{'Class::Simple::Readonly::Cached::echo::bar'} eq 'bar');
	my $a = $cache->{'Class::Simple::Readonly::Cached::a::'};
	ok(ref($a) eq 'ARRAY');
	$abc = $cache->{'Class::Simple::Readonly::Cached::abc::'};
	ok(ref($abc) eq 'ARRAY');

	ok(ref($cached->object()) eq 'x');

	# foreach my $key(sort keys %{$cache}) {
		# diag($key);
	# }

	# diag(Data::Dumper->new([$cached->state()])->Dump());
	my $hits = $cached->state()->{'hits'};
	my $count;
	while(my($k, $v) = each %{$hits}) {
		$count += $v;
	}
	ok($count == 9);
	my $misses = $cached->state()->{'misses'};
	$count = 0;
	while(my($k, $v) = each %{$misses}) {
		$count += $v;
	}
	ok($count == 9);

	# Test caching objects that return objects
	my $simple = new_ok('Class::Simple');
	my $one = new_ok('Class::Simple');
	$one->one('1');
	$simple->one($one);
	my $two = new_ok('Class::Simple');
	$two->two('2');
	$two->two($two);

	$cached = new_ok('Class::Simple::Readonly::Cached' => [ cache => $cache, object => $simple ]);
	cmp_ok($one->one(), '==', 1);
	cmp_ok($cached->one()->one(), '==', 1);
	cmp_ok($cached->one()->one(), '==', 1);

}

package x;

sub new {
	my $proto = shift;

	my $class = ref($proto) || $proto;

	return bless { }, $class;
}

sub barney {
	my $self = shift;
	my $param = shift;

	return 'betty';
}

sub abc {
	return ('a', 'b', 'c');
}

sub def {
	return ('d', 'e', 'f');
}

sub a {
	return 'a';
}

sub empty {
}

sub echo {
	my $self = shift;

	if(wantarray) {
		return @_;
	}

	return $_[0];
}

1;

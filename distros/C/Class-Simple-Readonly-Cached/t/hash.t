#!perl -wT

use strict;
use warnings;
use Test::Most tests => 41;
use Test::NoWarnings;
use CHI;

BEGIN {
	use_ok('Class::Simple::Readonly::Cached');
}

HASH: {
	my $cache = {};
	my $cached = new_ok('Class::Simple::Readonly::Cached' => [ cache => $cache, object => x->new() ]);

	ok($cached->calls() == 0);
	ok($cached->barney('betty') eq 'betty');
	ok($cached->calls() == 1);
	ok($cached->barney() eq 'betty');
	ok($cached->calls() == 1);
	ok($cached->barney() eq 'betty');
	ok($cached->calls() == 1);
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
	ok($abc eq $abc2);

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
	ok($cache->{'barney::'} eq 'betty');
	ok($cache->{'barney::betty'} eq 'betty');
	ok($cache->{'echo::foo'} eq 'foo');
	ok($cache->{'echo::bar'} eq 'bar');
	my $a = $cache->{'a::'};
	ok(ref($a) eq 'ARRAY');
	$abc = $cache->{'abc::'};
	ok(ref($abc) eq 'ARRAY');

	ok(ref($cached->object()) eq 'x');

	# foreach my $key(sort keys %{$cache}) {
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

sub calls {
	my $self = shift;

	return $self->{'calls'};
}

1;

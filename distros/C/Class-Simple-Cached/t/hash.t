#!perl -wT

use strict;
use warnings;
use Test::Most tests => 31;
use Test::NoWarnings;

BEGIN {
	use_ok('Class::Simple::Cached');
}

CLASS: {
	my %cache;

	my $cached = new_ok('Class::Simple::Cached' => [ cache => \%cache, object => x->new() ]);

	ok($cached->can('barney'));
	ok(!$cached->can('xyz'));
	ok($cached->can('xyz') || $cached->isa('Class::Simple::Cached'));

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
	my @a = $cached->a();
	ok(scalar(@a) == 1);
	ok($a[0] eq 'a');
	@a = $cached->a();
	ok(scalar(@a) == 1);
	ok($a[0] eq 'a');

	# FIXME: why is this test different from t/chi.t?
	my @empty = $cached->empty();
	ok(scalar(@empty) == 0);
	@empty = $cached->empty();
	ok(scalar(@empty) == 0);

	# White box test the cache
	ok($cache{'barney'} eq 'betty');
	my $a = $cache{'a'};
	ok(ref($a) eq 'ARRAY');
	my $abc = $cache{'abc'};
	ok(ref($abc) eq 'ARRAY');
	ok(scalar(@{$abc}) == 3);

	if(defined($ENV{'TEST_VERBOSE'})) {
		while(my($k, $v) = each(%cache)) {
			diag("$k = $v");
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
	return;
}

sub calls {
	my $self = shift;

	return $self->{'calls'};
}

1;

#!perl -wT

use strict;
use warnings;
use Test::Most tests => 8;
use Test::NoWarnings;
use utf8;

BEGIN {
	use_ok('Class::Simple::Readonly::Cached');
}

HASH: {
	my $cache = {};
	my $cached = new_ok('Class::Simple::Readonly::Cached' => [ cache => $cache, object => x->new() ]);


	ok($cached->utf8('Mrkvička') eq 'Mrkvička');
	ok($cached->utf8() eq 'Mrkvička');
	ok($cached->utf8() eq 'Mrkvička');

	# White box test the cache
	ok($cache->{'utf8::'} eq 'Mrkvička');

	# foreach my $key(sort keys %{$cache}) {
		# diag($key);
	# }

	# diag(Data::Dumper->new([$cached->state()])->Dump());
	my $misses = $cached->state()->{'misses'};
	my $fail;
	while(my($k, $v) = each %{$misses}) {
		if($v != 1) {
			$fail = $k;
			last;
		}
	}
	ok(!defined($fail));
	diag($fail) if($fail);
}

package x;

sub new {
	my $proto = shift;

	my $class = ref($proto) || $proto;

	return bless { }, $class;
}

sub utf8 {
	my $self = shift;
	my $param = shift;

	return 'Mrkvička';
}

1;

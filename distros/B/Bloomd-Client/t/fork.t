#!perl
#
# This file is part of Bloomd-Client
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use feature ':5.10';

BEGIN {
    unless ( $ENV{BLOOMD_HOST} && $ENV{BLOOMD_PORT} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable BLOOMD_HOST and BLOOMD_PORT should be defined to test against a real bloomd server' );
    }
}

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More;
use Test::Exception;
use Bloomd::Client;

my $b = Bloomd::Client->new(
	host => $ENV{BLOOMD_HOST}, 
	port => $ENV{BLOOMD_PORT},
	timeout =>undef );
ok $b, 'client created';

my $filter = '__test_filter__' . $$;
ok $b->create($filter, 100_000, 0.0001, 1 ), 'filter created';
ok $b->set($filter, 'u1'), 'set u1';
ok $b->set($filter, 'u2'), 'set u2';

my @childs;
for(1..10) {
	my $child = fork();
	if (!$child) {
		for my $i(1..10) {
			$b->set($filter, 'uf_' . $i . '_' . $$);
		}
		exit;
	} else {
		push @childs, $child;
	}
}

waitpid($_, WHOHANGS) for @childs;

ok $b->set($filter, 'u3'), 'set u3';
for my $child(@childs) {
	for my $i(1..10) {
		ok $b->check($filter, 'uf_' . $i . '_' . $child), 'uf_' . $i . '_' . $child;
	}
}

done_testing;

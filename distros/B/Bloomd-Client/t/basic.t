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

subtest "should die if host/port is invalid" => sub { 
	throws_ok( sub{ Bloomd::Client->new(host => undef) }, qr/Str/, "should not accept host undef");
	throws_ok( sub{ Bloomd::Client->new(host => "")    }, qr/Str/, "should not accept host empty string");
	throws_ok( sub{ Bloomd::Client->new(port => undef) }, qr/Int/, "should not accept port undef");
	throws_ok( sub{ Bloomd::Client->new(port => "")    }, qr/Int/, "should not accept port empty string");
};

subtest "should not die if timeout is undefined" => sub {
	my $b = Bloomd::Client->new(
		host => $ENV{BLOOMD_HOST}, 
		port => $ENV{BLOOMD_PORT},
		timeout =>undef );
	ok $b, 'client created';
	
	lives_ok { 
		$b->create("__test_undef_timeout_$$");
	};
};

subtest "should not die if timeout is 0" => sub {
	my $b = Bloomd::Client->new(
		host => $ENV{BLOOMD_HOST}, 
		port => $ENV{BLOOMD_PORT},
		timeout =>0 );
	ok $b, 'client created';
	
	lives_ok { 
		$b->create("__test_zero_timeout_$$");
	};
};
my $b = Bloomd::Client->new(host => $ENV{BLOOMD_HOST}, port => $ENV{BLOOMD_PORT});
ok $b, 'client created';

#$b->drop('__test_filter__');
#$b->flush('__test_filter__'), "flushed";

my $filter = '__test_filter__' . $$;

diag " using test filter name: $filter";
ok $b->create($filter, 100_000, 0.0001, 1 ), 'filter created';

is((scalar grep { $_->{name} eq $filter } @{$b->list()}), 1, 'filter listed');

is_deeply $b->info($filter),
  { capacity => 100_000,
    checks => 0,
    check_hits => 0,
    check_misses => 0,
    in_memory => 1,
    page_ins => 0,
    page_outs => 0,
    probability => '0.000100',
    sets => 0,
    set_hits => 0,
    set_misses => 0,
    size => 0,
    storage => 300046
  },
  "filter info";

ok $b->set($filter, 'u1'), 'set u1';
ok $b->set($filter, 'u2'), 'set u2';

ok $b->check($filter, 'u1'), 'check u1';
ok $b->check($filter, 'u2'), 'check u2';
ok !$b->check($filter, 'u3'), 'check u3';

is_deeply $b->multi( $filter, qw(u1 u2 u3) ),
  { u1 => 1, u2 => 1, u3 => '' },
  'multi check';

$b->bulk($filter, qw(v1 v2 u2));

is_deeply $b->multi( $filter, qw(v1 v2 u2) ),
  { v1 => 1, u2 => 1, v2 => 1 },
  'multi check after bulk';

ok $b->drop($filter);

done_testing;


#my $ret = $b->set(foobar => 'u1');
#$ret = $b->set(foobar => 'u2');

#$ret = $b->check(foobar => 'u3');

# 20-iobasic.t - Tests of basic I/O operations

# $Id: 20-iobasic.t,v 1.1 2004/10/24 01:00:39 lem Exp $

use Test::More;
use NetAddr::IP;

my $tests = 119;

my $db = "test-$$.db";		# The test database name
my $class = 'db';		# Which connect methods to use

plan tests => 1 + $tests;

END { unlink $db; }		# Get rid of test db if needed

SKIP:
{
    skip "Failed to use DBS::BL", $tests
	unless use_ok('DNS::BL');
    
    # When 'connect' has not been invoked, an error should
    # occur whenever an I/O support method is invoked.
    my $bl;

    isa_ok($bl = new DNS::BL, "DNS::BL", 'new DNS::BL');

    my @r;

    ##
    ## These are the basic setup tests. With this we insure
    ## an empty database is created.
    ##

    # Test basic connection
    my $com = "connect $class file $db";
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");

    # The db should be empty. Try it.
    $com = "print within any as internal";
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1] but should be empty"
	unless is($r[0], &DNS::BL::DNSBL_ENOTFOUND, "result $com");

    # At this point, the db file should exist...
    ok(-f $db, "Database was created on disk");

    # These tests involve loading up some entries in the database
    # to excercise the addition and collision verification

    die "Failed to use NetAddr::IP"
	unless use_ok('NetAddr::IP');

    # Load some test data
    for my $ip (map { NetAddr::IP->new($_) } qw(10.0.0.0/24 10.0.1.0/24))
    {
	$com = qq{add ip $ip text "$ip $$ test entry"};
	eval { @r = $bl->parse($com); };
	diag "->parse($com) failed miserably: $@"
	    unless ok(!$@, "Parsing of $com");
	diag "$com returned $r[0] / $r[1] to addition"
	    unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");
    }

    # Attempt a collision load (these should collide)
    for my $mask (0 .. 24)
    {
	$com = qq{add ip 10.0.0.0/$mask text "10.0.0.0/$mask $$ collission"};
	eval { @r = $bl->parse($com); };
	diag "->parse($com) failed miserably: $@"
	    unless ok(!$@, "Parsing of $com");
	diag "$com returned $r[0] / $r[1] to addition with collission"
	    unless is($r[0], &DNS::BL::DNSBL_ECOLLISSION, "result $com");
    }

    # Verify the entries in the database
    $com = qq{print within any as internal};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1] to print any"
	unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");
    is(scalar @r, 4, "Correct number of elements returned");
    splice @r, 0, 2;
    for my $r (@r)
    {
	ok((grep { $r->addr eq $_ } qw(10.0.0.0/24 10.0.1.0/24)), 
	   "Proper entry " . $r->addr);
	is($r->desc, $r->addr . " $$ test entry", 
	   "Correct test entry " . $r->addr);
    }

    # Attempt to bypass collision checking
    for my $ip (map { NetAddr::IP->new($_) } qw(10.0.0.0/24 10.0.1.0/24))
    {
	$com = qq{add ip $ip text "$ip $$ 2nd test entry" without checking};
	eval { @r = $bl->parse($com); };
	diag "->parse($com) failed miserably: $@"
	    unless ok(!$@, "Parsing of $com");
	diag "$com returned $r[0] / $r[1] to addition"
	    unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");
    }

    # Verify the entries in the database
    $com = qq{print within any as internal};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");
    is(scalar @r, 4, "Correct number of elements returned");
    splice @r, 0, 2;
    for my $r (@r)
    {
	ok((grep { $r->addr eq $_ } qw(10.0.0.0/24 10.0.1.0/24)), 
	   "Proper entry " . $r->addr);
	is($r->desc, $r->addr . " $$ 2nd test entry", 
	   "Correct test entry " . $r->addr);
    }

    # Test the ->read method with a larger net
    $com = qq{print within 10/8 as internal};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");
    is(scalar @r, 4, "Correct number of elements returned");
    splice @r, 0, 2;
    for my $r (@r)
    {
	ok((grep { $r->addr eq $_ } qw(10.0.0.0/24 10.0.1.0/24)), 
	   "Proper entry " . $r->addr);
	is($r->desc, $r->addr . " $$ 2nd test entry", 
	   "Correct test entry " . $r->addr);
    }

    # Test the ->read method with a smaller net
    $com = qq{print within 10.0.1.0/25 as internal};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_ENOTFOUND, "result $com");
    is(scalar @r, 2, "Correct number of elements returned");

    # Test the ->match method with a larger net
    $com = qq{print matching 10/8 as internal};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_ENOTFOUND, "result $com");
    is(scalar @r, 2, "Correct number of elements returned");

    # Test the ->match method with a smaller net
    $com = qq{print matching 10.0.1.0/25 as internal};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");
    is(scalar @r, 3, "Correct number of elements returned");
    is($r[2]->addr, '10.0.1.0/24', "Correct entry " . $r[2]->addr);
    is($r[2]->desc, "10.0.1.0/24 $$ 2nd test entry", 
	   "Correct test entry 10.0.1.0/24");

    # Test the ->delete method with a smaller net
    $com = qq{delete within 10.0.1.0/25};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_ENOTFOUND, "result of $com");
    is(scalar @r, 2, "Correct number of elements returned");

    # Test the ->delete method with a larger net
    $com = qq{delete within 10.0.1.0/23};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_OK, "result of $com");
    is(scalar @r, 2, "Correct number of elements returned");

    # Test the ->punch method... First add one network
    for my $ip (map { NetAddr::IP->new($_) } qw(10.0.0.0/24 10.0.1.0/24))
    {
	$com = qq{add ip $ip text "$ip $$ test entry"};
	eval { @r = $bl->parse($com); };
	diag "->parse($com) failed miserably: $@"
	    unless ok(!$@, "Parsing of $com");
	diag "$com returned $r[0] / $r[1]"
	    unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");
    }

    # Now punch a /25 through one of the /24s
    $com = qq{punch hole 10.0.0.0/25};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");

    # We should have now 10.0.0.128/25 listed
    $com = qq{print within 10.0.0.0/24 as internal};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");
    is(scalar @r, 3, "Correct number of elements returned");
    is($r[2]->addr, '10.0.0.128/25', "Correct entry " . $r[2]->addr);
    is($r[2]->desc, "10.0.0.0/24 $$ test entry", 
	   "Correct test entry 10.0.1.0/25");

    # Now punch a /8 through the whole thing
    $com = qq{punch hole 10.0.0.0/8};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_OK, "result $com");

    # Verify the database to be empty
    $com = qq{print within any as internal};
    eval { @r = $bl->parse($com); };
    diag "->parse($com) failed miserably: $@"
	unless ok(!$@, "Parsing of $com");
    diag "$com returned $r[0] / $r[1]"
	unless is($r[0], &DNS::BL::DNSBL_ENOTFOUND, "result $com");
    is(scalar @r, 2, "Correct number of elements returned");
};

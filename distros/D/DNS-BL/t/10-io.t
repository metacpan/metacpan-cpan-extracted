# 10-io.t - Tests basic I/O method registration and calling

# $Id: 10-io.t,v 1.1.1.1 2004/10/08 15:08:32 lem Exp $

use Test::More;

my @methods = qw/read match write erase commit/;

my $tests = 1 + 19 * @methods;

plan tests => $tests + 1;

SKIP:
{
    skip "Failed to use DBS::BL", $tests
	unless use_ok('DNS::BL');
    
    # When 'connect' has not been invoked, an error should
    # occur whenever an I/O support method is invoked.
    my $bl;

    isa_ok($bl = new DNS::BL, "DNS::BL", 'new DNS::BL');

    my @r;
    my $r;

    for my $m (@methods)
    {
	@r = $bl->$m;
	$r = $bl->$m;

	is($r, &DNS::BL::DNSBL_ECONNECT(), 
	   "Error from call to $m() in scalar context");
	is(@r, 2,
	   "Number of elements returned in call to $m in list context");
	is($r[0], &DNS::BL::DNSBL_ECONNECT(), 
	   "1st element of error return in call to $m in list context");
	ok($r[1] =~ m/connect/,
	   "2nd element of error return in call to $m in list context");
    }

    # Now we set special handlers...

    my $good = 1;

    for my $m (@methods)
    {
	$r = $bl->set("_$m", sub { ok($good, "Invoked the handler for $m");
				   isa_ok($_[0], 'DNS::BL', 
					  'Correct type of $self');
				   return wantarray?(&DNS::BL::DNSBL_OK, 'OK')
				       :&DNS::BL::DNSBL_OK();
			       });
	ok(! defined $r, "Proper result for ->set(_$m, ...)");
    }

    # And re-test the calls
    for my $m (@methods)
    {
	@r = $bl->$m;
	$r = $bl->$m;

	is($r, &DNS::BL::DNSBL_OK(), 
	   "Error from call to $m() in scalar context");
	is(@r, 2,
	   "Number of elements returned in call to $m in list context");
	is($r[0], &DNS::BL::DNSBL_OK(), 
	   "1st element of error return in call to $m in list context");
	is($r[1], 'OK',
	   "2nd element of error return in call to $m in list context");
    }

    # Now we should be able to remove the old handlers...
    for my $m (@methods)
    {
	$r = $bl->set("_$m", undef);
	ok(defined $r, "Proper result for ->set(_$m, ...)");
	is(ref $r, 'CODE', "Correct type of result");
    }

    $good = 0;
    # A call to our handlers must now yield errors
    for my $m (@methods)
    {
	@r = $bl->$m;
	$r = $bl->$m;

	is($r, &DNS::BL::DNSBL_ECONNECT(), 
	   "Error from call to $m() in scalar context");
	is(@r, 2,
	   "Number of elements returned in call to $m in list context");
	is($r[0], &DNS::BL::DNSBL_ECONNECT(), 
	   "1st element of error return in call to $m in list context");
	ok($r[1] =~ m/connect/,
	   "2nd element of error return in call to $m in list context");
    }
};

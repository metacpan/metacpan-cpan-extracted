# 10-entry.t - Basic functionality of the DNS::BL::Entry class

# $Id: 10-entry.t,v 1.2 2004/10/11 12:52:10 lem Exp $

use Test::More;
use NetAddr::IP;

my @addr	= map { new NetAddr::IP $_ } qw(127.0.0.1 10/8 localhost 
						default);
my @desc	= (q{All your base are belong to us},
		   q{},
		   q{a},
		   );

my @values	= qw/127.0.0.2 10.10.90.90/;

my @time	= (0, 1024, 75600, time);

my $tests = 2 + 2 * @addr + 2 * @desc + 2 * @time + 2 * @values;
plan tests => $tests + 1;

SKIP:
{
    skip "Failed to use DBS::BL::Entry", $tests
	unless use_ok('DNS::BL::Entry');

    my $entry	= new DNS::BL::Entry;
    my $latest	= undef;

    # Check ->addr() with valid values
    for my $ip (@addr)
    {
	my $last = $entry->addr($ip);
	is($last, $latest, "addr() returns previous value");
	is($entry->addr, $ip, "addr() returned $ip");
	$latest = $entry->addr;
    }

    # Verify that ->addr() won't be disturbed by garbage
    $entry->addr('loopback');
    is($entry->addr('!'), NetAddr::IP->new('loopback'),
       "addr() inmediately impervous to garbage");
    is($entry->addr, NetAddr::IP->new('loopback'),
       "addr() remains impervous to garbage");

    # Verify ->desc()
    $latest = undef;
    for my $desc (@desc)
    {
	my $last = $entry->desc($desc);
	is($last, $latest, "desc() returns previous value");
	is($entry->desc, $desc, "desc() returned '$desc'");
	$latest = $entry->desc;
    }

    # Verify ->value()
    $latest = '127.0.0.1';
    for my $value (@values)
    {
	my $last = $entry->value($value);
	is($last, $latest, "value() returns previous value");
	is($entry->value, $value, "value() returned '$value'");
	$latest = $entry->value;
    }

    # Verify ->time()
    $latest = undef;
    for my $time (@time)
    {
	my $last = $entry->time($time);
	is($last, $latest, "time() returns previous value") if $latest;
	is($entry->time, $time, "time() returned '$time'");
	$latest = $entry->time;
    }

    # Verify that ->time() won't be disturbed by garbage
    $entry->time(70000);
    is($entry->time('!'), 70000,
       "time() inmediately impervous to garbage");
    is($entry->time, 70000,
       "time() remains impervous to garbage");
};

__END__

$Log: 10-entry.t,v $
Revision 1.2  2004/10/11 12:52:10  lem
DNS::BL::Entry now takes ->value

Revision 1.1.1.1  2004/10/08 15:08:32  lem
Initial import


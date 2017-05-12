# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use Cisco::ShowIPRoute::Parser;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $ip = '10.25.159.33';
my $log = './testlogs/RN-48GE-03-MSFC-02.log';
my $router = new Cisco::ShowIPRoute::Parser($log);
my @rts =  $router->getroutes($ip);
if(@rts == 2 && $rts[0] eq '10.25.144.253' && $rts[1] eq '10.25.144.254')
{
	ok(1);
}
else
{
	ok(0);
}

my $log = './testlogs/RN-48GE-01-MSFC-02.log';
my $router = new Cisco::ShowIPRoute::Parser($log);
my @rts =  $router->getroutes($ip);
if(@rts == 1 && $rts[0] eq '10.25.155.42')
{
	ok(1);
}
else
{
	ok(0);
}

# Should be directly connected
my $log = './testlogs/TCNZA-AU-SYD-R1.log';
my $router = new Cisco::ShowIPRoute::Parser($log);
my @rts =  $router->getroutes($ip);
if(@rts == 1 && $rts[0] eq 'is directly connected, FastEthernet0/0' )
{
	ok(1);
}
else
{
	ok(0);
}

# Should be directly connected
my $log = './testlogs/RN-48GE-01-7609-01.log';
my $router = new Cisco::ShowIPRoute::Parser($log);
my @rts =  $router->getroutes('192.168.88.5');
if(@rts == 2 && $rts[0] eq '10.25.160.252' )
{
	ok(1);
}
else
{
	ok(0);
}

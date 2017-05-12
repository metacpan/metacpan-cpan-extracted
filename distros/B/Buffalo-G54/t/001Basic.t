######################################################################
# Test suite for Buffalo::G54
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
# vim:filetype=perl
use warnings;
use strict;
use Test::More;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
#Log::Log4perl->infiltrate_lwp();
use Buffalo::G54;

my($ip, $user, $password);

if($ENV{BUFFALO}) {
    plan tests => 4;
} else {
    plan skip_all => "ENV BUFFALO not set to ip:user:passwd";
} 

my $buf = Buffalo::G54->new();

ok($buf->connect(), "Connect");
like($buf->version(), qr/^[\d.]+$/, "Version");

my $status = $buf->wireless();

if($status == 1) {
    $buf->wireless("off");
}

$buf->wireless("on");

$status = $buf->wireless();
ok($status, "Wireless switched on");

$buf->wireless("off");
$status = $buf->wireless();
ok($status == 0, "Wireless switched off");

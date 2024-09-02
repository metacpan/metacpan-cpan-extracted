# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Acme-Free-API-Geodata-GeoIP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('Acme::Free::API::Geodata::GeoIP') };

my $geoip = Acme::Free::API::Geodata::GeoIP->new(debug => 0);
ok(defined($geoip), 'Initialization');

my %map = (
    '24.48.0.1' => 'Videotron',
    '94.130.141.212' => 'Hetzner',
);

foreach my $ip (sort keys %map) {
    my $org = $map{$ip};

    my $result = $geoip->lookup($ip);
    ok(defined($result), "Lookup $ip");

    next if(!defined($result));

    ok(defined($result->{org}), 'Contains org');
    next if(!defined($result->{org}));

    my $ismatch = 0;
    if($result->{org} =~ /$org/i) {
        $ismatch = 1;
    }
    ok($ismatch, "Matches org $org");
}


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


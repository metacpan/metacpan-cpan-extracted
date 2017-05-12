use strict;
use warnings;

use Test::More tests => 6;

#==============================================================================#

BEGIN { use_ok('DNS::EasyDNS') };

my $ez = DNS::EasyDNS->new();

ok(ref($ez) eq "DNS::EasyDNS", "Object has correct type");

ok($ez->isa("LWP::UserAgent"), "Object inheritance ok");

ok($ez->can("update"), "Object has update method");

ok(!$ez->update(
	username => 'test',
	password => 'bogus',
	hostname => 'bogus',
), "Check a bogus request");

ok($@ =~ /^HTTP request failed /, "HTTP Error looks correct");

#==============================================================================#

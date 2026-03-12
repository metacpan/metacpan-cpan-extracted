use strict;
use warnings;
use Test::More tests => 16;

BEGIN { use_ok('DNS::Robot') }

# Constructor
my $dr = DNS::Robot->new();
isa_ok($dr, 'DNS::Robot');

# Version
ok(defined $DNS::Robot::VERSION, 'VERSION is defined');
like($DNS::Robot::VERSION, qr/^\d+\.\d+$/, 'VERSION looks like a number');

# All 11 methods exist
can_ok($dr, 'dns_lookup');
can_ok($dr, 'whois_lookup');
can_ok($dr, 'ssl_check');
can_ok($dr, 'spf_check');
can_ok($dr, 'dkim_check');
can_ok($dr, 'dmarc_check');
can_ok($dr, 'mx_lookup');
can_ok($dr, 'ns_lookup');
can_ok($dr, 'ip_lookup');
can_ok($dr, 'http_headers');
can_ok($dr, 'port_check');

# Constructor with custom options
my $custom = DNS::Robot->new(
    base_url   => 'https://example.com/api',
    user_agent => 'TestAgent/1.0',
    timeout    => 10,
);
isa_ok($custom, 'DNS::Robot');

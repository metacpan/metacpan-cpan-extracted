use strict;
use warnings;
use Test::More tests => 13;

use DNS::Robot;

my $dr = DNS::Robot->new();

# Missing required params should die
eval { $dr->dns_lookup() };
like($@, qr/domain.*required/i, 'dns_lookup dies without domain');

eval { $dr->whois_lookup() };
like($@, qr/domain.*required/i, 'whois_lookup dies without domain');

eval { $dr->ssl_check() };
like($@, qr/domain.*required/i, 'ssl_check dies without domain');

eval { $dr->spf_check() };
like($@, qr/domain.*required/i, 'spf_check dies without domain');

eval { $dr->dkim_check() };
like($@, qr/domain.*required/i, 'dkim_check dies without domain');

eval { $dr->dmarc_check() };
like($@, qr/domain.*required/i, 'dmarc_check dies without domain');

eval { $dr->mx_lookup() };
like($@, qr/domain.*required/i, 'mx_lookup dies without domain');

eval { $dr->ns_lookup() };
like($@, qr/domain.*required/i, 'ns_lookup dies without domain');

eval { $dr->ip_lookup() };
like($@, qr/ip.*required/i, 'ip_lookup dies without ip');

eval { $dr->http_headers() };
like($@, qr/url.*required/i, 'http_headers dies without url');

eval { $dr->port_check() };
like($@, qr/host.*required/i, 'port_check dies without host');

eval { $dr->port_check(host => 'example.com') };
like($@, qr/port.*required/i, 'port_check dies without port');

# Custom base_url is accepted
my $custom = DNS::Robot->new(base_url => 'https://test.example.com/api');
isa_ok($custom, 'DNS::Robot');

use strict;
use warnings;

use Test2::V0;

use EasyDNS::DDNS::Util ();

my $u1 = 'https://user:token@api.cp.easydns.com/dyn/generic.php?hostname=a&myip=1.2.3.4';
my $r1 = EasyDNS::DDNS::Util::redact_basic_auth_in_url($u1);

like($r1, qr/user:\*\*\*\@api\.cp\.easydns\.com/i, 'basic auth redacted');
unlike($r1, qr/token/, 'token not present');

done_testing;


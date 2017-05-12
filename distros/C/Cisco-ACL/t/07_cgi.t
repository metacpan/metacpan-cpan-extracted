#
# $Id: 07_cgi.t 86 2004-06-18 20:18:01Z james $
#

use Test::More tests => 4;

# test failure on parameter non-existence
my $parm_missing_rx = qr/missing input param/;

my $out = qx|$^X bin/aclmaker.pl|;
like($out, $parm_missing_rx, 'cgi abends on missing args');

$out = qx|$^X bin/aclmaker.pl permit_or_deny=permit|;
like($out, $parm_missing_rx, 'cgi abends on missing args');

$out = qx|$^X bin/aclmaker.pl permit_or_deny=permit src_addr=10.1.1.1|;
like($out, $parm_missing_rx, 'cgi abends on missing args');

# test with proper parms
$out = qx|$^X bin/aclmaker.pl permit_or_deny=deny src_addr=192.168.0.1/24 src_port=any dst_addr=any dst_port=25 protocol=tcp|;
like($out, qr/deny tcp 192.168.0.0 0.0.0.255 any eq 25/,
'cgi generates an acl');

#
# EOF

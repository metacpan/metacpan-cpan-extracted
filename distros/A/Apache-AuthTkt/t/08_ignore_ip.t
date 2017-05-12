# Testing ignore_ip handling via new, mutator, and ticket

use File::Basename;
use Test::More tests => 8;
BEGIN { use_ok( Apache::AuthTkt ) }
use strict;

my $at;
my $dir = dirname($0);

# Constructor
ok($at = Apache::AuthTkt->new(secret => 'squirrel', ignore_ip => 1), 'constructor ok');
is($at->ignore_ip, 1, sprintf("post-constructor accessor value ok (%s)", $at->ignore_ip));

# Mutator
is($at->ignore_ip(2), 2, "mutator ok");
is($at->ignore_ip, 2, sprintf("post-mutator accessor value ok (%s)", $at->ignore_ip));

# Generate some reference tickets
$ENV{REMOTE_ADDR} = '1.2.3.4';
my $ts = 1108811260;
my $t_ref_ip    = $at->ticket(uid => 'foo', ts => $ts, ip_addr => '1.2.3.4');
my $t_ref_noip1 = $at->ticket(uid => 'foo', ts => $ts, ip_addr => '0.0.0.0');
my $t_ref_noip2 = $at->ticket(uid => 'foo', ts => $ts, ip_addr => 0);
my $t_ref_noip3 = $at->ticket(uid => 'foo', ts => $ts, ip_addr => undef);
isnt($t_ref_ip,  $t_ref_noip1, "ref_ip and ref_noip tickets differ");
is($t_ref_noip1, $t_ref_noip2, "ref_noip tickets 1 and 2 match");
is($t_ref_noip1, $t_ref_noip3, "ref_noip tickets 1 and 3 match");


# vim:ft=perl

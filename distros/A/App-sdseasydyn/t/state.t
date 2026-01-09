use strict;
use warnings;

use Test2::V0;

use File::Temp qw/tempdir/;
use File::Spec ();

use EasyDNS::DDNS::State;

my $tdir = tempdir(CLEANUP => 1);
my $path = File::Spec->catfile($tdir, 'last_ip');

my $st = EasyDNS::DDNS::State->new(path => $path);

is($st->getLastIp, '', 'missing state file -> empty');

ok($st->setLastIp('1.2.3.4'), 'setLastIp ok');
is($st->getLastIp, '1.2.3.4', 'getLastIp returns stored');

ok($st->setLastIp('5.6.7.8'), 'overwrite ok');
is($st->getLastIp, '5.6.7.8', 'updated stored');

done_testing;


# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 61; }
    else { plan skip_all => 'Working directory is not in AFS file system ...'; }

    use_ok('AFS::VOS');
}

# vos->new(verbose=0, timeout=90, noauth=0, localauth=0, tcell=NULL, crypt=0)
my $vos = AFS::VOS->new('no_verb');
like($AFS::CODE, qr/Flag "verb" should be numeric/, 'vos->new(no_verb)');
$vos = AFS::VOS->new(0, 'no_timeout');
like($AFS::CODE, qr/Flag "timeout" should be numeric/, 'vos->new(0 no_timeout)');
$vos = AFS::VOS->new(0, 90, 'no_auth');
like($AFS::CODE, qr/Flag "noauth" should be numeric/, 'vos->new(0 90 no_auth)');
$vos = AFS::VOS->new(0, 90, 0, 'no_localauth');
like($AFS::CODE, qr/Flag "localauth" should be numeric/, 'vos->new(0 90 0 no_localauth)');
$vos = AFS::VOS->new(0, 90, 0, 0, 'xyz');
like($AFS::CODE, qr/can\'t find cell/, 'vos->new(0 90 0 0 no_cell)');
$vos = AFS::VOS->new(0, 90, 0, 0, '', 'no_crypt');
like($AFS::CODE, qr/Flag "crypt" should be numeric/, 'vos->new(0 90 0 0 empty_cell no_crypt)');
$vos = AFS::VOS->new;
is(ref($vos), 'AFS::VOS', 'vos->new()');
undef $vos;
$vos = AFS::VOS->new(0, 90, 0, 0, '');
is(ref($vos), 'AFS::VOS', 'vos->new(0 90 0 0 empty_cell)');
undef $vos;

is(leak_test(), 1210, 'vos leak_test');

$vos = AFS::VOS->new;
$vos->release('novolume');
like($AFS::CODE, qr/no such entry/, 'vos->release(novolume)');
$vos->release('root.afs', 'a');
like($AFS::CODE, qr/Flag "force" should be numeric/, 'vos->release(root.afs a)');

use AFS::VLDB;
my $vldb = AFS::VLDB->new;
my $vldblist = $vldb->listvldbentry('root.afs');
my $server = $vldblist->{'root.afs'}->{'server'}->[0]->{'name'};
my $part   = $vldblist->{'root.afs'}->{'server'}->[0]->{'partition'};

$vos->restore($server, $part, 'root.afs', 'dfile', 'id', 'no_inter');
like($AFS::CODE, qr/Flag "inter" should be numeric/, 'vos->restore(server part volume dfile id no_inter)');
$vos->restore($server, $part, 'root.afs', 'dfile', 'id', 0, 'ovwrt', 'no_offl');
like($AFS::CODE, qr/Flag "offline" should be numeric/, 'vos->restore(server part volume dfile id 0 ovwrt no_offl)');
$vos->restore($server, $part, 'root.afs', 'dfile', 'id', 0, 'ovwrt', 0, 'no_ronly');
like($AFS::CODE, qr/Flag "readonly" should be numeric/, 'vos->restore(server part volume dfile id 0 ovwrt 0 no_ronly)');

$vos->dump('root.afs', 'no_time', 'dump_file', $server, $part, 0, 0);
like($AFS::CODE, qr/failed to parse date/, 'vos->dump(volume no_time dump_file server part 0 0)');
$vos->dump('root.afs', 0, 'dump_file', $server, $part, 0, 'no_omit');
like($AFS::CODE, qr/Flag "omit" should be numeric/, 'vos->dump(volume time dump_file server part 0 no_omit)');
$vos->dump('root.afs', 0, 'dump_file', $server, $part, 'no_clone', 0);
like($AFS::CODE, qr/Flag "clone" should be numeric/, 'vos->dump(volume time dump_file server part no_clone 0)');
$vos->dump('no_volume', 0, 'dump_file', $server, $part, 0, 0);
like($AFS::CODE, qr/VLDB: no such entry/, 'vos->dump(no_volume time dump_file server part 0 0)');
$vos->dump('root.afs', 0, 'dump_file', 'no_server', $part, 0, 0);
like($AFS::CODE, qr/Invalid server name/, 'vos->dump(volume time dump_file no_server part 0 0)');
$vos->dump('root.afs', 0, 'dump_file', $server, 'no_part', 0, 0);
like($AFS::CODE, qr/Invalid partition name/, 'vos->dump(volume time dump_file server no_part 0 0)');

my $vollist = $vos->listvol($server, $part, 1, 'a');
like($AFS::CODE, qr/Flag "extended" should be numeric/, 'vos->listvol(server part fast no_extended)');
$vollist = $vos->listvol($server, $part, 'a', 1);
like($AFS::CODE, qr/Flag "fast" should be numeric/, 'vos->listvol(server part no_fast extended)');
$vollist = $vos->listvol($server, $part, 1, 1);
like($AFS::CODE, qr/FAST and EXTENDED flags are mutually exclusive/, 'vos->listvol(server part fast extended)');
$vollist = $vos->listvol($server, 'no_part', 1, 0);
like($AFS::CODE, qr/could not interpret partition name/, 'vos->listvol(server no_part fast extended)');
$vollist = $vos->listvol($server, $part);
isa_ok($vollist->{$part}->{'root.afs'}, 'HASH', 'vos->listvol(server partition)');

$vos->zap($server, $part, 'root.afs', 0, 'a');
like($AFS::CODE, qr/Flag "backup" should be numeric/, 'vos->zap(server part volume force no_backup)');
$vos->zap($server, $part, 'root.afs', 'a', 0);
like($AFS::CODE, qr/Flag "force" should be numeric/, 'vos->zap(server part volume no_force backup)');
$vos->zap($server, $part, 'no_volume', 0, 0);
like($AFS::CODE, qr/VLDB: no such entry/, 'vos->zap(server part no_volume 0 0)');
$vos->zap($server, 'no_part', 'root.afs', 0, 0);
like($AFS::CODE, qr/could not interpret partition name/, 'vos->zap(server no_part volume 0 0)');
$vos->zap('no_server', $part, 'root.afs', 0, 0);
like($AFS::CODE, qr/not found in host table/, 'vos->zap(no_server part volume 0 0)');

$vos->offline($server, $part, 'root.afs', 0, 'a');
like($AFS::CODE, qr/Flag "sleep" should be numeric/, 'vos->offline(server part volume busy no_sleep)');
$vos->offline($server, $part, 'root.afs', 'a', 0);
like($AFS::CODE, qr/Flag "busy" should be numeric/, 'vos->offline(server part volume no_busy sleep)');
$vos->offline($server, $part, 'no_volume', 0, 0);
like($AFS::CODE, qr/VLDB: no such entry/, 'vos->offline(server part no_volume 0 0)');
$vos->offline($server, 'no_part', 'root.afs', 0, 0);
like($AFS::CODE, qr/could not interpret partition name/, 'vos->offline(server no_part volume 0 0)');
$vos->offline('no_server', $part, 'root.afs', 0, 0);
like($AFS::CODE, qr/not found in host table/, 'vos->offline(no_server part volume 0 0)');

$vos->listpart('no_server');
like($AFS::CODE, qr/not found in host table/, 'vos->listpart(no_server)');
my @partlist = $vos->listpart($server);
ok($#partlist > -1, 'vos->listpart(server)');

$vos->partinfo('no_server');
like($AFS::CODE, qr/not found in host table/, 'vos->partinfo(no_server)');
$vos->partinfo($server, 'no_part');
like($AFS::CODE, qr/could not interpret partition name/, 'vos->partinfo(no_part)');
isa_ok($vos->partinfo($server), 'HASH', 'vos->partinfo(server)');

$vos->status('no_server');
like($AFS::CODE, qr/not found in host table/, 'vos->status(no_server)');
my $status = $vos->status($server);
like($status, qr/transactions/, 'vos->status(server)');

$vos->backupsys('prefix', $server, $part, 0, 'xprefix', 'noaction');
like($AFS::CODE, qr/Flag "noaction" should be numeric/, 'vos->backupsys(prefix server part exclude xprefix no_dryrun)');
$vos->backupsys('prefix', $server, $part, 'no_exclude', 'xprefix', 1);
like($AFS::CODE, qr/Flag "exclude" should be numeric/, 'vos->backupsys(prefix server part no_exclude xprefix dryrun)');
$vos->backupsys('prefix', 'no_server');
like($AFS::CODE, qr/not found in host table/, 'vos->backupsys(no_server)');
$vos->backupsys('prefix', $server, 'no_part');
like($AFS::CODE, qr/could not interpret partition name/, 'vos->backupsys(no_part)');

$vos->listvolume('no_volume');
like($AFS::CODE, qr/no such entry/, 'vos->listvolume(no_volume)');

$vos->DESTROY;
ok(! defined $vos, 'vos->DESTROY');

can_ok('AFS::VOS', qw(backup));
can_ok('AFS::VOS', qw(create));
can_ok('AFS::VOS', qw(dump));
can_ok('AFS::VOS', qw(move));
can_ok('AFS::VOS', qw(offline));
can_ok('AFS::VOS', qw(online));
can_ok('AFS::VOS', qw(release));
can_ok('AFS::VOS', qw(remove));
can_ok('AFS::VOS', qw(rename));
can_ok('AFS::VOS', qw(restore));
can_ok('AFS::VOS', qw(setquota));
can_ok('AFS::VOS', qw(zap));

sub leak_test {
    my $cell  = shift;

    my $count = 0;
    my $verb  = 1;
    while(1) {
        $count++;
        my $vos = AFS::VOS->new($verb);
        $vos->DESTROY();
        if ($count == 1210) { last; }
    }
    return $count;
}

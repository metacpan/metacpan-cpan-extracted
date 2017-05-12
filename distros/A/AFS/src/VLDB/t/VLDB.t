# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 56; }
    else { plan skip_all => 'Working directory is not in AFS file system ...'; }

    use_ok('AFS::VLDB');
}

my $vldb = AFS::VLDB->new;
is(ref($vldb), 'AFS::VLDB', 'vldb->new()');
undef $vldb;

# vldb->new(verbose=0, timeout=90, noauth=0, localauth=0, tcell=NULL, crypt=0)
$vldb = AFS::VLDB->new(0, 90, 0, 0, 'xyz');
like($AFS::CODE, qr/can\'t find cell/, 'vldb->new(0 90 0 0 no_cell)');

$vldb = AFS::VLDB->new(0, 90, 0, 0, '');
is(ref($vldb), 'AFS::VLDB', 'vldb->new(0 90 0 0 no_cell)');
undef $vldb;

is(leak_test(), 1210, 'vldb leak_test');

$vldb = AFS::VLDB->new;
my $vldblist = $vldb->listvldbentry('no_volume');
like($AFS::CODE, qr/no such entry/, 'vldb->listvldbentry(no_vol)');
$vldblist = $vldb->listvldbentry('root.afs');
isa_ok($vldblist, 'HASH', 'vldb->listvldbentry 1.level');
isa_ok($vldblist->{'root.afs'}, 'HASH', 'vldb->listvldbentry 2.level');

my $server = $vldblist->{'root.afs'}->{'server'}->[0]->{'name'};
my $part   = $vldblist->{'root.afs'}->{'server'}->[0]->{'partition'};
my $volid  = $vldblist->{'root.afs'}->{'RWrite'};
print "DEBUG: VOLID = $volid \n";
$vldblist = $vldb->listvldb($server, $part, 0);
isa_ok($vldblist, 'HASH', 'vldb->listvldb 1.level');
$vldblist = $vldb->listvldb('no_server', '/vicepa', 0);
like($AFS::CODE, qr/not found in host table/, 'vldb->listvldb(no_serv)');
$vldblist = $vldb->listvldb($server, 'no_partition', 0);
like($AFS::CODE, qr/could not interpret partition name/, 'vldb->listvldb(no_part)');

my @addrlist = $vldb->listaddrs('no_server');
like($AFS::CODE, qr/Can't get host info/, 'vldb->listaddrs(no_serv)');
@addrlist = $vldb->listaddrs($server);
is($addrlist[0]->{'name-1'}, $server, 'vldb->listaddrs(HOST)');
@addrlist = $vldb->listaddrs;
ok(defined $addrlist[0], 'vldb->listaddrs()');

my $ok = $vldb->lock('no_volume');
like($AFS::CODE, qr/no such entry/, 'vldb->lock');
ok(! $ok, 'vldb->lock');

$vldb->unlockvldb('no_server', '/vicepa');
like($AFS::CODE, qr/not found in host table/, 'vldb->unlockvldb(no_serv)');
$vldb->unlockvldb($server, 'no_partition');
like($AFS::CODE, qr/could not interpret partition name/, 'vldb->unlockvldb(no_part)');

$ok = $vldb->unlock('no_volume');
like($AFS::CODE, qr/no such entry/, 'vldb->unlock');
ok(! $ok, 'vldb->unlock');

$vldb->addsite('no_server', '/vicepa', 'root.afs');
like($AFS::CODE, qr/not found in host table/, 'vldb->addsite(no_serv)');
$vldb->addsite($server, 'no_partition', 'root.afs');
like($AFS::CODE, qr/could not interpret partition name/, 'vldb->addsite(no_part)');
$vldb->addsite($server, $part, 'no_volume');
like($AFS::CODE, qr/no such entry/, 'vldb->addsite(no_vol)');

$vldb->changeloc('root.afs', 'no_server', '/vicepa');
like($AFS::CODE, qr/not found in host table/, 'vldb->changeloc(no_serv)');
$vldb->changeloc('root.afs', $server, 'no_partition');
like($AFS::CODE, qr/could not interpret partition name/, 'vldb->changeloc(no_part)');
$vldb->changeloc('no_volume', $server, $part);
like($AFS::CODE, qr/no such entry/, 'vldb->changeloc(no_vol)');

my ($succ, $fail) = $vldb->delentry('no_volume');
like($AFS::CODE, qr/no such entry/, 'vldb->delentry(no_vol)');
ok(! $succ, 'succ = vldb->delentry(no_vol)');
ok(! $fail, 'fail = vldb->delentry(no_vol)');

($succ, $fail) = $vldb->delgroups('', '', '', '');
like($AFS::CODE, qr/You must specify an argument/, 'vldb->delgroups(no arguments)');
ok(! $succ, 'succ = vldb->delgroups(no arguments)');
ok(! $fail, 'fail = vldb->delgroups(no arguments)');
($succ, $fail) = $vldb->delgroups('prefix', '', '', '');
like($AFS::CODE, qr/must provide SERVER with the PREFIX/, 'vldb->delgroups(no server-1)');
ok(! $succ, 'succ = vldb->delgroups(no server-1)');
ok(! $fail, 'fail = vldb->delgroups(no server-1)');
($succ, $fail) = $vldb->delgroups('prefix', 'no_server', '', '');
like($AFS::CODE, qr/ not found in host table/, 'vldb->delgroups(no_server)');
ok(! $succ, 'succ = vldb->delgroups(no_server)');
ok(! $fail, 'fail = vldb->delgroups(no_server)');
($succ, $fail) = $vldb->delgroups('prefix', '', 'partition', '');
like($AFS::CODE, qr/must provide SERVER with the PARTITION/, 'vldb->delgroups(no server-2)');
ok(! $succ, 'succ = vldb->delgroups(no server-2)');
ok(! $fail, 'fail = vldb->delgroups(no server-2)');
($succ, $fail) = $vldb->delgroups('prefix', $server, 'no_partition', '');
like($AFS::CODE, qr/could not interpret partition name/, 'vldb->delgroups(no_part)');
ok(! $succ, 'succ = vldb->delgroups(no_part)');
ok(! $fail, 'fail = vldb->delgroups(no_part)');

$vldb->remsite('no_server', '/vicepa', 'root.afs');
like($AFS::CODE, qr/not found in host table/, 'vldb->remsite(no_server part vol_name)');
$vldb->remsite('no_server', '/vicepa', $volid);
like($AFS::CODE, qr/not found in host table/, 'vldb->remsite(no_server part vol_ID)');
$vldb->remsite($server, 'no_partition', 'root.afs');
like($AFS::CODE, qr/could not interpret partition name/, 'vldb->remsite(server no_part vol_name)');
$vldb->remsite($server, $part, 'no_volume');
like($AFS::CODE, qr/no such entry/, 'vldb->remsite(server part no_vol)');

$vldb->syncserv('no_server', '/vicepa');
like($AFS::CODE, qr/not found in host table/, 'vldb->syncserv(no_serv)');
$vldb->syncserv($server, 'no_partition');
like($AFS::CODE, qr/could not interpret partition name/, 'vldb->syncserv(no_part)');

$vldb->syncvldb('no_server', '/vicepa');
like($AFS::CODE, qr/not found in host table/, 'vldb->syncvldb(no_serv)');
$vldb->syncvldb($server, 'no_partition');
like($AFS::CODE, qr/could not interpret partition name/, 'vldb->syncvldb(no_part)');

$ok = $vldb->syncvldbentry('no_volume');
ok($ok, 'vldb->syncvldbentry(no_vol)');

$vldb->removeaddr('');
like($AFS::CODE, qr/invalid host address/, 'vldb->removeaddr(no arguments)');
$vldb->removeaddr('127.0.0.1');
like($AFS::CODE, qr/no such entry|Could not remove server/, 'vldb->removeaddr(invalid IP)');

$vldb->DESTROY;
ok(! defined $vldb, 'vldb->DESTROY');

sub leak_test {
    my $cell  = shift;

    my $count = 0;
    my $verb  = 1;
    while(1) {
        $count++;
        my $vldb = AFS::VLDB->new($verb);
        $vldb->DESTROY();
        if ($count == 1210) { last; }
    }
    return $count;
}

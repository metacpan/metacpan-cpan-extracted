# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 39; }
    else { plan skip_all => 'Working directory is not in AFS file system ...'; }

    use_ok('AFS::BOS');
}

use AFS::VLDB;
use AFS::Cell 'localcell';
my $vldb = AFS::VLDB->new;
my $vldblist = $vldb->listvldbentry('root.afs');
my $server = $vldblist->{'root.afs'}->{'server'}->[0]->{'name'};
my $l_cell = localcell;

my $bos = AFS::BOS->new($server);
is(ref($bos), 'AFS::BOS', 'bos->new()');
undef $bos;

is(leak_test(), 1210, 'bos leak_test');

$bos = AFS::BOS->new($server);
my ($cell, $hostlist) = $bos->listhosts;
is($cell, $l_cell, 'bos-listhost: Cellname OK');
ok(defined $$hostlist[0], 'bos->listhost: Host list OK');

my @users = $bos->listusers;
ok(defined $users[0], 'bos->listusers: User list OK');

$bos->setrestart('14:00', 'a', 0);
like($AFS::CODE, qr/Flag "general" should be numeric/, 'bos->setrestart(time no_integer newbinary)');

$bos->setrestart('14:00', 0, 'a');
like($AFS::CODE, qr/Flag "newbinary" should be numeric/, 'bos->setrestart(time general no_integer)');

$bos->setrestart('14:00', 1, 1);
like($AFS::CODE, qr/specify more than one restart time/, 'bos->setrestart(time general=1 newbinary=1)');

my ($generalTime, $newBinaryTime) = $bos->getrestart;
ok(defined $generalTime, 'bos->getrestart: GeneralTime OK');
ok(defined $newBinaryTime, 'bos->getrestart: NewBinaryTime OK');

my $result = $bos->status(0, [ 'fs', ]) || $bos->status(0, [ 'dafs', ]);
isa_ok($result->{fs} || $result->{dafs}, 'HASH', 'bos->status OK');

my %h = ( nog => 1 );
$bos->adduser(\%h);
like($AFS::CODE, qr/USER not an array reference/, 'bos->adduser(HASH)');

$bos->addhost('host', 'a');
like($AFS::CODE, qr/Flag "clone" should be numeric/, 'bos->addhost(host no_integer)');

$bos->addhost(\%h);
like($AFS::CODE, qr/HOST not an array reference/, 'bos->addhost(HASH)');

my $host = 'very_very_very_very_long_long_long_long_name_name_name_name_name_name';
$bos->addhost($host, 1);
like($AFS::CODE, qr/host name too long/, 'bos->addhost(long_name)');

can_ok('AFS::BOS', qw(addkey));
can_ok('AFS::BOS', qw(create));
can_ok('AFS::BOS', qw(delete));
can_ok('AFS::BOS', qw(exec));
can_ok('AFS::BOS', qw(getlog));
can_ok('AFS::BOS', qw(getrestricted));
can_ok('AFS::BOS', qw(listkeys));
can_ok('AFS::BOS', qw(prune));
$bos->removehost(\%h);
like($AFS::CODE, qr/HOST not an array reference/, 'bos->removehost(HASH)');

$host = 'z';
$bos->removehost($host);
SKIP: {
	skip "You lack rights for this test", 1 
		if $AFS::CODE =~ /you are not authorized for this operation/;
	like($AFS::CODE, qr/no such entity/, 'bos->removehost(unknown host)');
}
can_ok('AFS::BOS', qw(removekey));

$bos->removeuser(\%h);
like($AFS::CODE, qr/USER not an array reference/, 'bos->removeuser(HASH)');

my $user = 'z';
$bos->removeuser($user);
SKIP: {
	skip "You lack rights for this test", 1 
		if $AFS::CODE =~ /you are not authorized for this operation/;
	like($AFS::CODE, qr/no such user/, 'bos->removeuser(unknown user)');
}

can_ok('AFS::BOS', qw(restart_bos));
can_ok('AFS::BOS', qw(restart_all));
can_ok('AFS::BOS', qw(restart));
can_ok('AFS::BOS', qw(setauth));
can_ok('AFS::BOS', qw(setrestricted));
can_ok('AFS::BOS', qw(shutdown));
can_ok('AFS::BOS', qw(start));
can_ok('AFS::BOS', qw(startup));
can_ok('AFS::BOS', qw(stop));

$bos->DESTROY;
ok(! defined $bos, 'bos->DESTROY');

sub leak_test {
    my $count = 0;
    my $verb  = 1;
    while(1) {
        $count++;
        my $bos = AFS::BOS->new($verb);
        $bos->DESTROY();
        if ($count == 1210) { last; }
    }
    return $count;
}

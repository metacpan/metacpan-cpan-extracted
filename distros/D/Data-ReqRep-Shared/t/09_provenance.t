use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

# The tests below set the override themselves; one inherited from the environment would defeat them.
delete $ENV{DATA_REQREP_SHARED_UNSAFE_PIDNS};

# Header offsets (cache line 0): boot_id_hash at 52 (U32), pidns_ino at 56 (U64).
use constant { BOOT_OFF => 52, NSINO_OFF => 56 };

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/prov.shm";

sub patch {
    my ($off, $bytes, $p) = @_;
    $p //= $path;
    open my $fh, '+<', $p or die "$p: $!";
    binmode $fh;
    seek $fh, $off, 0 or die $!;
    print {$fh} $bytes or die $!;
    close $fh or die $!;
}

sub field {
    my ($off, $len, $p) = @_;
    $p //= $path;
    open my $fh, '<', $p or die "$p: $!";
    binmode $fh;
    seek $fh, $off, 0 or die $!;
    read $fh, my $buf, $len or die $!;
    close $fh;
    return $buf;
}

{
    my $srv = Data::ReqRep::Shared->new($path, 16, 4, 256);
    ok -e $path, 'segment created';
    undef $srv;
}

my $boot  = field(BOOT_OFF,  4);
my $nsino = field(NSINO_OFF, 8);
isnt unpack('L<', $boot),  0, 'boot id stamped into the header';
isnt unpack('Q<', $nsino), 0, 'pid namespace stamped into the header';

ok eval { Data::ReqRep::Shared::Client->new($path); 1 },
    'same boot and namespace attaches' or diag $@;

patch(BOOT_OFF, pack 'L<', unpack('L<', $boot) ^ 0xFFFF_FFFF);
ok !eval { Data::ReqRep::Shared::Client->new($path); 1 },
    'a segment from a previous boot is refused';
like $@, qr/before the current boot/, '  and says why';

patch(BOOT_OFF, $boot);
patch(NSINO_OFF, pack 'Q<', unpack('Q<', $nsino) ^ 0xFFFF);
ok !eval { Data::ReqRep::Shared::Client->new($path); 1 },
    'a segment from another PID namespace is refused';
like $@, qr/different PID namespace/, '  and says why';

{
    local $ENV{DATA_REQREP_SHARED_UNSAFE_PIDNS} = 1;
    ok eval { Data::ReqRep::Shared::Client->new($path); 1 },
        'the documented override attaches anyway' or diag $@;
}

ok !eval { Data::ReqRep::Shared::Client->new($path); 1 },
    'and the check is back on once the override is unset';

for my $on (qw(1 true yes on TRUE 1.0 y)) {
    local $ENV{DATA_REQREP_SHARED_UNSAFE_PIDNS} = $on;
    ok eval { Data::ReqRep::Shared::Client->new($path); 1 },
        "DATA_REQREP_SHARED_UNSAFE_PIDNS=$on turns the override on" or diag $@;
}

for my $off ('0', '0.0', 'false', 'FALSE', 'off', 'no', '', '0 ', ' no ') {
    local $ENV{DATA_REQREP_SHARED_UNSAFE_PIDNS} = $off;
    ok !eval { Data::ReqRep::Shared::Client->new($path); 1 },
        "DATA_REQREP_SHARED_UNSAFE_PIDNS=$off leaves the check on";
}

ok !eval { Data::ReqRep::Shared->new($path, 16, 4, 256); 1 },
    'a server attaching from another PID namespace is refused too';
like $@, qr/different PID namespace/, '  and says why';

my $ipath = "$dir/prov-int.shm";
{ my $s = Data::ReqRep::Shared::Int->new($ipath, 16, 4) }
patch(NSINO_OFF, pack('Q<', unpack('Q<', field(NSINO_OFF, 8, $ipath)) ^ 0xFFFF), $ipath);
ok !eval { Data::ReqRep::Shared::Int->new($ipath, 16, 4); 1 },
    'an Int server from another PID namespace is refused';
like $@, qr/different PID namespace/, '  and says why';
ok !eval { Data::ReqRep::Shared::Int::Client->new($ipath); 1 },
    'so is an Int client';
like $@, qr/different PID namespace/, '  and says why';

SKIP: {
    skip 'the TSan runtime crashes when the fd table is full', 4 if ($ENV{LD_PRELOAD} // '') =~ /tsan/;
    my $emdir = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>', "$emdir/em.pl" or die $!;
    print {$fh} <<'P';
my ($sc, $cc, $path, @geom) = @ARGV;
eval "require $sc; require $cc; 1" or die $@;
my @fds;
while (open my $fh, '<', '/dev/null') { push @fds, $fh }
pop @fds;
my $s = eval { $sc->new($path, @geom) };
my $err = $@;
@fds = ();
print $s ? "created\n" : "refused: $err";
print eval { $cc->new($path); 1 } ? "attached\n" : "attach failed: $@" if $s;
P
    close $fh;
    my @inc = map { "-I$_" } @INC;
    for my $v (['Str', 'Data::ReqRep::Shared', 'Data::ReqRep::Shared::Client', 4, 2, 64],
               ['Int', 'Data::ReqRep::Shared::Int', 'Data::ReqRep::Shared::Int::Client', 4, 2]) {
        my ($name, $sc, $cc, @geom) = @$v;
        my @cmd = ('sh', '-c', 'ulimit -n 64; exec "$@"', 'sh', $^X, @inc, "$emdir/em.pl", $sc, $cc, "$emdir/em$name.shm", @geom);
        my $out = do { open my $ph, '-|', @cmd or die $!; local $/; <$ph> };
        unlike $out, qr/attach failed/, "$name: a create with one free descriptor never leaves a file nobody can attach to" or diag $out;
        like $out, qr/^(?:created\nattached|refused: \S+->new: .+?: \S)/, '  it either works or says why' or diag $out;
    }
}

subtest 'unreadable pid namespace under UNSAFE_PIDNS stores 0 for boot_id_hash, not stack garbage' => sub {
    my $cc = $Config{cc} or plan skip_all => 'no C compiler';
    my $emdir = File::Temp::tempdir(DIR => '.', CLEANUP => 1);
    open my $fh, '>', "$emdir/prov_zero.c" or die $!;
    print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include "reqrep.h"

int stat(const char *pathname, struct stat *statbuf) {
    if (strstr(pathname, "/proc/self/ns/pid")) {
        errno = ENOENT;
        return -1;
    }
    return -1;
}

int main(void) {
    if (reqrep_pidns_ino()) { printf("stat override not in effect\n"); return 77; }
    setenv("DATA_REQREP_SHARED_UNSAFE_PIDNS", "1", 1);
    ReqRepProvenance prov;
    memset(&prov, 0xAA, sizeof(prov));
    char errbuf[REQREP_ERR_BUFLEN];
    int r = reqrep_read_provenance(&prov, errbuf);
    printf("r=%d boot=%u\n", r, prov.boot);
    return prov.boot == 0 ? 0 : 1;
}
C
    close $fh;
    require Cwd;
    my $inc = Cwd::abs_path('.');
    system($cc, "-I$inc", "$emdir/prov_zero.c", "-o", "$emdir/prov_zero", "-lpthread") == 0
        or plan skip_all => "cannot compile helper with $cc";
    my $out = qx{"$emdir/prov_zero" 2>&1};
    my $exit = $? >> 8;
    plan skip_all => 'this libc does not let the helper replace stat()' if $exit == 77;
    is $exit, 0, 'boot_id_hash is 0 on unreadable pidns under UNSAFE_PIDNS'
        or diag "Output: $out";
};

done_testing;

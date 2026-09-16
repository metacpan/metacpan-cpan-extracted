use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

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
    undef $srv;                       # unmap, leave the file in place
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

done_testing;

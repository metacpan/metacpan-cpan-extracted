our $cpu;
our $phys;

use Test2::V0;

BEGIN {

    *CORE::GLOBAL::readpipe = sub {
        my $cmd = shift;
        return ($cpu || '')."\n" if $cmd =~ /hw.ncpu/;
        return ($phys || '')."\n" if $cmd =~ /hw.phys/;
        return `$cmd`
    };

};

my $mockfile = eval "require Test::MockFile";
eval "use Benchmark::DKbench";


subtest "bsd_cpu" => sub {
    is([Benchmark::DKbench::bsd_cpu()], [], 'Undef');
    $cpu = 8;
    is([Benchmark::DKbench::bsd_cpu()], [undef, 8, 8], 'ncpu defined');
    $phys = 4;
    is([Benchmark::DKbench::bsd_cpu()], [undef, 4, 8], 'ncpu, phys defined');
};

if ($mockfile) {
    subtest "linux_cpu" => sub {
        my @samples = cpuinfo();
        my $cpuinfo = Test::MockFile->file('/proc/cpuinfo');
        is([Benchmark::DKbench::linux_cpu()], [], 'Undef');
        $cpuinfo = undef;
        $cpuinfo = Test::MockFile->file('/proc/cpuinfo', $samples[0]);
        is([Benchmark::DKbench::linux_cpu()], [undef, 2, 2], '2 Cores');
        $cpuinfo = undef;
        $cpuinfo = Test::MockFile->file('/proc/cpuinfo', $samples[1]);
        is([Benchmark::DKbench::linux_cpu()], [2, 2, 4], '2:2:4');
    };
}

sub cpuinfo {
    return (
'processor  : 0
BogoMIPS    : 48.00
Features    : fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm ssbs sb paca pacg dcpodp flagm2 frint
CPU implementer : 0x00
CPU architecture: 8
CPU variant : 0x0
CPU part    : 0x000
CPU revision    : 0

processor   : 1
BogoMIPS    : 48.00
Features    : fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm ssbs sb paca pacg dcpodp flagm2 frint
CPU implementer : 0x00
CPU architecture: 8
CPU variant : 0x0
CPU part    : 0x000
CPU revision    : 0
',
'processor   : 0
physical id : 0
core id     : 0
cpu cores   : 1

processor   : 1
physical id : 0
core id     : 0
cpu cores   : 1

processor   : 2
physical id : 1
core id     : 0
cpu cores   : 1

processor   : 3
physical id : 1
core id     : 0
cpu cores   : 1
'
);
}

done_testing;

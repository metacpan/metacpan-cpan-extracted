# 01-get.t
# Basic sanity checks for BSD::Sysctl
#
# Copyright (C) 2006, 2009 David Landgren

use strict;
use Test::More tests => 23;

use BSD::Sysctl qw(sysctl sysctl_exists);

ok(BSD::Sysctl::_mib_exists('kern.maxproc'), 'mib exists');

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.ostype');
    ok($sysctl_info, 'mib lookup kern.ostype');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    is($fmt, BSD::Sysctl::FMT_A, '... display format type A');
    is_deeply(\@oid, [1, 1], '... oid 1.1');
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.ipc.maxsockbuf');
    ok($sysctl_info, 'mib lookup kern.ipc.maxsockbuf');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    # This is FMT_INT for FreeBSD 4.x, deal with it
    # is($fmt, BSD::Sysctl::FMT_ULONG, '... display format type ULONG');
    is_deeply(\@oid, [1, 30, 1], '... oid 1.30.1');
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.ipc.maxsockbuf');
    ok($sysctl_info, 'mib lookup kern.ipc.maxsockbuf');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    # TODO: this will require a revision when OpenBSD or NetBSD support is added
    my $osrelease = sysctl('kern.osrelease');
    ok($osrelease, "sysctl('kern.osrelease')");
    if ($osrelease =~ /^4\./) {
        # FreeBSD 4.x stores this in a smaller data type
        is($fmt, BSD::Sysctl::FMT_INT, '... display format type INT (on 4.x)');
    }
    else {
        is($fmt, BSD::Sysctl::FMT_ULONG, '... display format type ULONG');
    }
    is_deeply(\@oid, [1, 30, 1], '... oid 1.30.1');
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.geom.confxml');
    ok($sysctl_info, 'mib lookup kern.geom.confxml');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    is($fmt, BSD::Sysctl::FMT_A, '... display format type A');
    my $confxml = sysctl('kern.geom.confxml');
    ok($confxml, 'value of "kern.geom.confxml" is defined');
    like($confxml, qr(^\s*<([^>]+)>.*</\1>\s*$)m, 'value of "kern.geom.confxml" is XML');
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('net.inet.ip.portrange.last');
    my $portrange_last = BSD::Sysctl::_mib_lookup('net.inet.ip.portrange.last');
    cmp_ok($portrange_last, '>',   1024, 'min value of net.inet.ip.portrange.last');
    cmp_ok($portrange_last, '<=', 65535, 'max value of net.inet.ip.portrange.last');
}

ok(sysctl_exists('kern.maxusers'), 'kern.maxusers exists');
ok(!sysctl_exists('kern.maxbananas'), 'kern.maxbananas does not exist');

{
    my $load_avg = sysctl('vm.loadavg');
    is(ref($load_avg), 'ARRAY', 'vm.loadavg is an array');
    is(scalar(@$load_avg), 3, 'vm.loadavg has 3 elements');
}

{
    my $sysctl_openfiles = BSD::Sysctl->new('kern.openfiles');
    my $nr_files = $sysctl_openfiles->get();
    cmp_ok($nr_files, '>', 0, "got the number of open files ($nr_files, in case you were wondering)");
    $nr_files = $sysctl_openfiles->get();
    cmp_ok($nr_files, '>', 0, "got the number of open files again (now $nr_files)");
}

is(scalar(keys %BSD::Sysctl::MIB_CACHE), 7, 'cached mib count')
    or do { diag("cached: [$_]") for sort keys %BSD::Sysctl::MIB_CACHE };

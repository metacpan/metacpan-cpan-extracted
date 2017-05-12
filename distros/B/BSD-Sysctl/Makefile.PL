use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

my $module_name = 'BSD::Sysctl';

if ($Config{osname} ne 'freebsd') {
    die "OS unsupported ($Config{osname}). Here's a nickel, go buy yourself a real OS.\n";
}

my %define;
my $maxlen = 0;
while (<DATA>) {
    chomp;
    next unless my ($key, $num, $str) = ($_ =~ /^(\S+)\t(\S+)\t(\S+)/);
    if ($str eq 'auto') {
        if ($key =~ /^[ST],(.*)/) {
            $str = 'FMT_' . uc($1);
        }
        else {
            die "$0: cannot resolve auto name from $key\n";
        }
    }
    $maxlen = length($str) if $maxlen < length($str);
    $define{$key} = [$str, $num];
}

open my $out_h,  '>', 'bsd-sysctl.h'  or die "Cannot open C header for output: $!\n";
open my $out_pl, '>', 'bsd-sysctl.pl' or die "Cannot open Perl header for output: $!\n";

my $years = (gmtime)[5]+1900;
$years = ($years == 2006) ? $years : "2006-$years";

print $out_h <<EOH;
/* bsd-sysctl.h -- defines for $module_name
 *
 * Copyright (C) $years, David Landgren, all rights reserved.
 * This file genned by $0 at @{[scalar gmtime]}
 */

EOH

# bootinfo.h header file not available on the AMD64 platform
if (-r '/usr/include/machine/bootinfo.h') {
    print $out_h "#include <machine/bootinfo.h>\n";
}

print $out_pl <<EOH;
# bsd-sysctl.pl -- constants for $module_name
#
# Copyright (C) $years, David Landgren, all rights reserved.
# This file genned by $0 at @{[scalar gmtime]}

EOH

for my $key (sort keys %define) {
    printf $out_h "#define %-${maxlen}s %2d\n", @{$define{$key}};
    printf $out_pl "use constant %-${maxlen}s => %2d;\n", @{$define{$key}};
}

print $out_pl "\n1;\n";

close $out_h;
close $out_pl;

WriteMakefile(
    NAME          => $module_name,
    AUTHOR        => 'David Landgren',
    ABSTRACT_FROM => 'Sysctl.pm',
    VERSION_FROM  => 'Sysctl.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'XSLoader' => 0
    },
    clean => {
        FILES => 'bsd-sysctl.h bsd-sysctl.pl',
    },
);

__DATA__
#
# List of constant definitions.
#
# This produces
#  -- bsd-sysctl.h (#defines for Sysctl.xs)
#  -- bsd-sysctl.pl (use constants for Sysctl.pm)
#
# auto string definitions are derived from the first
# field, for instance, S,bootinfo => FMT_BOOTINFO
# (This eliminates a chance to introduce typos).
# _key	numeric	string

A	1	FMT_A
I	2	FMT_INT
IU	3	FMT_UINT
L	4	FMT_LONG
LU	5	FMT_ULONG
N	6	FMT_N
S,bootinfo	7	auto
S,clockinfo	8	auto
S,devstat	9	auto
S,icmpstat	10	auto
S,igmpstat	11	auto
S,ipstat	12	auto
S,loadavg	13	auto
S,mbstat	14	auto
S,nfsrvstats	15	auto
S,nfsstats	16	auto
S,ntptimeval	17	auto
S,rip6stat	18	auto
S,tcpstat	19	auto
S,timeval	20	auto
S,udpstat	21	auto
S,vmtotal	22	auto
S,xinpcb	23	auto
S,xvfsconf	24	auto
T,struct_cdev	25	auto
Q	26	FMT_64
QU	27	FMT_U64

#!/usr/bin/env perl
# Full install rehearsal: `make install DESTDIR=...` into a temp prefix,
# then load the installed module from a fresh perl with @INC pointing
# at the install tree. Catches MANIFEST omissions, broken Makefile.PL
# INST_* paths, and POD/XS files that don't make it into the install
# tree -- problems that kwalitee + xt/manifest.t don't reach.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Find;

plan skip_all => 'set RELEASE_TESTING=1 to run install tests'
    unless $ENV{RELEASE_TESTING};
plan skip_all => 'no Makefile to test against (run perl Makefile.PL first)'
    unless -f 'Makefile';

my $prefix = tempdir(CLEANUP => 1);
diag "installing into $prefix";

# DESTDIR must be passed on the make command line (not via env) for
# ExtUtils::MakeMaker to honour it.
my $rc = system('make', 'install', "DESTDIR=$prefix") >> 8;
is($rc, 0, 'make install DESTDIR=... exited 0') or do {
    done_testing();
    exit;
};

# Walk the staged tree to find the installed files; the path depth
# depends on the installation perl's @INC layout.
my (@pm, @so);
find(sub {
    push @pm, $File::Find::name if $_ eq 'Encoder.pm'
        && $File::Find::name =~ m{/ClickHouse/Encoder\.pm$};
    push @so, $File::Find::name if $_ =~ /^Encoder\.(so|bundle|dll)$/;
}, $prefix);

ok(scalar @pm, 'installed Encoder.pm found in staged tree')
    or diag "no Encoder.pm under $prefix";
ok(scalar @so, 'installed Encoder.so/.bundle/.dll found in staged tree')
    or diag "no compiled XS under $prefix";

# Derive @INC paths from the staged files.
my @inc;
if (@pm) {
    (my $lib = $pm[0]) =~ s{/ClickHouse/Encoder\.pm$}{};
    push @inc, $lib;
}
if (@so) {
    (my $arch = $so[0]) =~ s{/auto/ClickHouse/Encoder/Encoder\.[^.]+$}{};
    push @inc, $arch unless grep { $_ eq $arch } @inc;
}

SKIP: {
    skip 'no install paths discovered, skipping load test', 2 unless @inc;
    # Avoid `->` in -e: shell would interpret > as a redirect when the
    # command is run via qx{}. Reference the package $VERSION directly.
    my @cmd = ($^X, (map { "-I$_" } @inc),
               '-MClickHouse::Encoder',
               '-e', 'print $ClickHouse::Encoder::VERSION');
    open my $pipe, '-|', @cmd or die "spawn @cmd: $!";
    my $out = do { local $/; <$pipe> };
    close $pipe;
    is($?, 0, 'installed module loads in a fresh perl process')
        or diag "stdout: $out\ncmd: @cmd";
    like($out, qr/\A\d/, 'VERSION prints a numeric value from the installed module');
}

done_testing();

use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

# The templates declare the memfd, file-sealing and futex constants themselves,
# because glibc before 2.27 and a container without kernel headers do not.  A
# wrong value there is invisible on a machine whose headers supply the real one
# and silently breaks sealing or parks a futex on the wrong operation where they
# do not -- which is the population those fallbacks exist for.  Compare every
# fallback against the system's own definition wherever there is one.

plan skip_all => 'Linux only' unless $^O eq 'linux';
plan skip_all => 'author tests' unless $ENV{AUTHOR_TESTING};
my $cc = $Config{cc} || 'cc';
system("$cc --version >/dev/null 2>&1") == 0
    or plan skip_all => "no working C compiler ($cc)";
-f 'shm_generic.h' or plan skip_all => 'run from the distribution root';

my @names = qw(MFD_CLOEXEC MFD_ALLOW_SEALING F_ADD_SEALS F_SEAL_SHRINK F_SEAL_GROW
               FUTEX_WAIT FUTEX_WAKE);
my %want;
{
    open my $fh, '<', 'shm_generic.h' or die $!;
    my $pending;
    while (<$fh>) {
        $pending = $1 if /^#ifndef\s+(\w+)\s*$/;
        next unless defined $pending;
        if (/^#define\s+\Q$pending\E\s+(\S+)/) {
            my $v = $1;
            $v =~ s/[uU]$//;
            $want{$pending} = oct $v if $v =~ /^0/;
            $want{$pending} = $v + 0  if $v =~ /^[1-9]/;
            undef $pending;
        }
    }
}
is scalar(grep { defined $want{$_} } @names), scalar @names,
    'every fallback constant was found in shm_generic.h'
    or diag explain \%want;

my $dir = tempdir(CLEANUP => 1);
open my $c, '>', "$dir/probe.c" or die $!;
print $c <<'HEAD';
#define _GNU_SOURCE
#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#if defined(__has_include)
#  if __has_include(<linux/memfd.h>)
#    include <linux/memfd.h>
#  endif
#  if __has_include(<linux/futex.h>)
#    include <linux/futex.h>
#  endif
#endif
int main(void) {
HEAD
printf {$c} "#ifdef %s\n    printf(\"%s=%%lld\\n\", (long long)%s);\n#endif\n", $_, $_, $_
    for @names;
print {$c} "    return 0;\n}\n";
close $c;

is system("$cc -o $dir/probe $dir/probe.c >/dev/null 2>&1"), 0, 'the probe compiles'
    or BAIL_OUT('cannot build the constant probe');

my %sys;
chomp(my @out = `$dir/probe`);
for (@out) { $sys{$1} = $2 if /^(\w+)=(-?\d+)$/ }

my $checked = 0;
for my $n (@names) {
    next unless exists $sys{$n};
    $checked++;
    is $want{$n}, $sys{$n}, "$n fallback matches the system definition";
}
cmp_ok $checked, '>', 0, 'at least one constant was checkable here'
    or diag 'no system header defined any of them: nothing to compare';

done_testing;

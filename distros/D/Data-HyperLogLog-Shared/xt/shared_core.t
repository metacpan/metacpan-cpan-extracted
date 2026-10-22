use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

my $dir = tempdir(CLEANUP => 1);
my $exe = "$dir/shared_core";
my @cc = shellwords($Config{cc});
system(@cc, '-D_GNU_SOURCE', '-O2', '-std=c11', '-pthread', '-I.',
       'xt/shared_core.c', '-lm', '-o', $exe) == 0 or BAIL_OUT('shared-core fixture did not compile');

for my $case (qw(allocation writer reader zombie-writer zombie-reader stress publication)) {
    system($exe, $case, "$dir/publication.hll");
    my $status = $?;
    is $status, 0, "shared core: $case";
    diag "signal ", $status & 127, ", exit ", $status >> 8 if $status;
}

done_testing;

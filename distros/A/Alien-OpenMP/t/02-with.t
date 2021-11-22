BEGIN {
    # https://bugs.llvm.org/show_bug.cgi?id=50579
    $ENV{LIBOMP_USE_HIDDEN_HELPER_TASK} = $ENV{LIBOMP_NUM_HIDDEN_HELPER_THREADS} = 0 if $^O eq 'darwin';
}
use strict;
use warnings;
use Test::More;
use Test::Needs 'Inline::C';
use Alien::OpenMP;
use File::Temp ();
Inline->import(
    C           => do { local $/ = undef; <DATA> },
    filters     => [ sub { (my $filt = $_[0]) =~ s/^__C__$//mg; $filt } ],
    with        => qw/Alien::OpenMP/,
    directory   => ( my $tmp = File::Temp::tempdir() ),
    build_noisy => !!$ENV{HARNESS_IS_VERBOSE}
);

for my $num_threads (qw/1 2 4 8 16 32 64 128 256/) {
    is test($num_threads), $num_threads, qq{Ensuring compiled OpenMP program works as expected. Threads = $num_threads};
}

{
    local %ENV = %ENV;
    $ENV{CC} = q{gcc};
    my $config_ref = Alien::OpenMP->Inline('C');
    like $config_ref->{CCFLAGSEX},  qr/-fopenmp/, q{inspecting value of CCFLAGSEX.};
    like $config_ref->{LDDLFLAGS},  qr/(?:-lomp|-fopenmp)/, q{inspecting value of LDDLFLAGS.};
    is $config_ref->{AUTO_INCLUDE}, q{#include <omp.h>}, q{inspecting value of AUTO_INCLUDE.};
}

done_testing;

__DATA__

__C__
#include <stdio.h>
int test(int num_threads) {
  omp_set_num_threads(num_threads);
  int ans = 0;
  #pragma omp parallel
    #pragma omp master
      ans = omp_get_num_threads(); // done in parallel section, but only by master thread (0)
  return ans;
}

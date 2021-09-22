
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/benchmark-perlformance',
    'bin/benchmark-perlformance-set-stable-system',
    'lib/Benchmark/Perl/Formance.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsArray.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsClassAccessor.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsClassAccessorFast.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsClassMethodMaker.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsClassXSAccessor.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsClassXSAccessorArray.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsHash.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsMoo.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsMoose.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsMouse.pm',
    'lib/Benchmark/Perl/Formance/Plugin/AccessorsObjectTinyRW.pm',
    'lib/Benchmark/Perl/Formance/Plugin/DPath.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Fib.pm',
    'lib/Benchmark/Perl/Formance/Plugin/FibMXDeclare.pm',
    'lib/Benchmark/Perl/Formance/Plugin/FibMoose.pm',
    'lib/Benchmark/Perl/Formance/Plugin/FibMouse.pm',
    'lib/Benchmark/Perl/Formance/Plugin/FibOO.pm',
    'lib/Benchmark/Perl/Formance/Plugin/FibOOSig.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Incubator.pm',
    'lib/Benchmark/Perl/Formance/Plugin/MatrixReal.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Mem.pm',
    'lib/Benchmark/Perl/Formance/Plugin/P6STD.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlCritic.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Prime.pm',
    'lib/Benchmark/Perl/Formance/Plugin/RegexpCommonTS.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Rx.pm',
    'lib/Benchmark/Perl/Formance/Plugin/RxCmp.pm',
    'lib/Benchmark/Perl/Formance/Plugin/RxMicro.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/binarytrees.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/fannkuch.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/fasta.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/knucleotide.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/mandelbrot.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/nbody.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/pidigits.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/regexdna.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/revcomp.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Shootout/spectralnorm.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Skeleton.pm',
    'lib/Benchmark/Perl/Formance/Plugin/SpamAssassin.pm',
    'lib/Benchmark/Perl/Formance/Plugin/Threads.pm',
    'lib/Benchmark/Perl/Formance/Plugin/ThreadsShared.pm',
    't/00-compile.t',
    't/00-load.t',
    't/author-eol.t',
    't/author-pod-syntax.t',
    't/basic.t',
    't/samplerun.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;

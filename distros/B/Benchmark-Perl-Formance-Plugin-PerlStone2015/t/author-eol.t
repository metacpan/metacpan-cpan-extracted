
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/01overview.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/02bits.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/03operator.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/04control.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/05regex.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/06subroutines.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/07lists.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/08capture.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/09data.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/10packages.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/11modules.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/12objects.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/13overloading.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/14tie.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/15unicode.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/16ioipc.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/17concurrency.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/18compiling.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/19commandline.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/binarytrees.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/dpath.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/fannkuch.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/fasta.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/fib.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/fiboo.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/mandelbrot.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/mem.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/nbody.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/regex.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/regexdna.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/revcomp.pm',
    'lib/Benchmark/Perl/Formance/Plugin/PerlStone2015/spectralnorm.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

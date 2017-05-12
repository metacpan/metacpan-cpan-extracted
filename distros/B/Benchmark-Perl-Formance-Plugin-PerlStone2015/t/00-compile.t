use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 31 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Benchmark/Perl/Formance/Plugin/PerlStone2015.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/01overview.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/02bits.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/03operator.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/04control.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/05regex.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/06subroutines.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/07lists.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/08capture.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/09data.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/10packages.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/11modules.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/12objects.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/13overloading.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/14tie.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/15unicode.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/16ioipc.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/17concurrency.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/18compiling.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/19commandline.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/binarytrees.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/dpath.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/fasta.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/fib.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/fiboo.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/mem.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/nbody.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/regex.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/regexdna.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/revcomp.pm',
    'Benchmark/Perl/Formance/Plugin/PerlStone2015/spectralnorm.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};



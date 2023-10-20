package Benchmark::DKbench;

use strict;
use warnings;

use Config;
use Digest;
use Digest::MD5 qw(md5_hex);
use Encode;
use File::Spec::Functions;
use List::Util qw(min max sum);
use Time::HiRes qw(CLOCK_MONOTONIC);
use Time::Piece;

use Astro::Coord::Constellations 'constellation_for_eq';
use Astro::Coord::Precession 'precess';
use Crypt::JWT qw(encode_jwt decode_jwt);
use CSS::Inliner;
use DateTime;
use DBI;
use File::ShareDir 'dist_dir';
use HTML::FormatText;
use HTML::TreeBuilder;
use Imager;
use Imager::Filter::Mandelbrot;
use Image::PHash;
use JSON::XS;
use Math::DCT ':all';
use Math::MatrixReal;
use MCE::Loop;
use SQL::Abstract::Classic;
use SQL::Inserter;
use System::CPU;
use System::Info;
use Text::Levenshtein::Damerau::XS;
use Text::Levenshtein::XS;

use Exporter 'import';
our @EXPORT    = qw(system_identity suite_run calc_scalability);
our $datadir   = dist_dir("Benchmark-DKbench");
my $mono_clock = $^O !~ /win/i || $Time::HiRes::VERSION >= 1.9764;

our $VERSION = '2.4';

=head1 NAME

Benchmark::DKbench - Perl CPU Benchmark

=head1 SYNOPSIS

 # Run the suite single-threaded and then multi-threaded on multi-core systems
 # Will print scores for the two runs and multi/single thread scalability
 dkbench

 # A dual-thread "quick" run (with times instead of scores)
 dkbench -j 2 -q

 # If BioPerl is installed, enable the BioPerl benchmarks by downloading Genbank data
 dkbench --setup

 # Force install the reference versions of all CPAN modules
 setup_dkbench --force

=head1 DESCRIPTION

A Perl benchmark suite for general compute, created to evaluate the comparative
performance of systems when running computationally intensive Perl (both pure Perl
and C/XS) workloads. It is a good overall indicator for generic CPU performance in
real-world scenarios. It runs single and multi-threaded (able to scale to hundreds
of CPUs) and can be fully customized to run the benchmarks that better suit your own
scenario.

=head1 INSTALLATION

See the L</"setup_dkbench"> script below for more on the installation of a couple
of optional benchmarks and standardizing your benchmarking environment, otherwise
here are some general guidelines for verious systems.

=head2 Linux / WSL etc

The only non-CPAN software required to install/run the suite is a build environment
for the C/XS modules (C compiler, make etc.) and Perl. On the most popular Linux
package managers you can easily set up such an environment (as root or with sudo):

 # Debian/Ubuntu etc
 apt-get update
 apt-get install build-essential perl cpanminus

 # CentOS/Red Hat
 yum update
 yum install gcc make patch perl perl-App-cpanminus

After that, you can use L<App::cpanminus> to install the benchmark suite (as
root/sudo is the easiest, will install for all users):

 cpanm -n Benchmark::DKbench

=head2 Solaris

You will need to install the Oracle Solaris Studio development package to have a
compiler environment, and to add its C<bin> directory to your PATH, before installing
the benchmark suite.

=head2 Strawberry Perl

If you are on Windows, you should be using the Windows Subsystem for Linux (WSL)
for running Perl or, if you can't (e.g. old Windows verions), cygwin instead.
The suite should still work on Strawberry Perl, as long as you don't try to run
tests when installing (some dependencies will not pass them). The simplest way is
with L<App::cpanminus> (most Strawberry Perl verions have it installed):

 cpanm -n Benchmark::DKbench

otherwise with the base CPAN shell:

 perl -MCPAN -e shell

 > notest install Benchmark::DKbench

and then note that the scripts get the batch extension appended, so C<dkbench.bat>
runs the suite (and C<setup_dkbench.bat> can assist with module versions, optional
benchmarks etc.).

Be aware that Strawberry Perl is slower, on my test system I get almost 50% slower
performance than WSL and 30% slower than cygwin.

=head1 SCRIPTS

You will most likely only ever need the main script C<dkbench> which launches the
suite, although C<setup_dkbench> can help with setup or standardizing/normalizing your
benchmarking environment.

=head2 C<dkbench>

The main script that runs the DKbench benchmark suite. If L<BioPerl> is installed,
you may want to start with C<dkbench --setup>. But beyond that, there are many
options to control number of threads, iterations, which benchmarks to run etc:

 dkbench [options]

 Options:
 --threads <i>, -j <i> : Number of benchmark threads (default is 1).
 --multi,       -m     : Multi-threaded using all your CPU cores/threads.
 --max_threads <i>     : Override the cpu detection to specify max cpu threads.
 --iter <i>,    -i <i> : Number of suite iterations (with min/max/avg at the end).
 --stdev               : Show relative standard deviation (for iter > 1).
 --include <regex>     : Run only benchmarks that match regex.
 --exclude <regex>     : Do not run benchmarks that match regex.
 --time,        -t     : Report time (sec) instead of score.
 --quick,       -q     : Quick benchmark run (implies -t).
 --no_mce              : Do not run under MCE::Loop (implies -j 1).
 --scale <i>,   -s <i> : Scale the bench workload by x times (incompatible with -q).
 --skip_bio            : Skip BioPerl benchmarks.
 --skip_prove          : Skip Moose prove benchmark.
 --time_piece          : Run optional Time::Piece benchmark (see benchmark details).
 --bio_codons          : Run optional BioPerl Codons benchmark (does not scale well).
 --sleep <i>           : Sleep for <i> secs after each benchmark.
 --setup               : Download the Genbank data to enable the BioPerl tests.
 --datapath <path>     : Override the path where the expected benchmark data is found.
 --ver <num>           : Skip benchmarks added after the specified version.
 --help         -h     : Show basic help and exit.

The default run (no options) will run all the benchmarks both single-threaded and
multi-threaded (using all detected CPU cores/hyperthreads) and show you scores and
multi vs single threaded scalability.

The scores are calibrated such that a reference CPU (Intel Xeon Platinum 8481C -
Sapphire Rapids) would achieve a score of 1000 in a single-core benchmark run using
the default software configuration (Linux/Perl 5.36.0 built with multiplicity and
threads, with reference CPAN module versions). Perl built without thread support and
multi(plicity) will be a bit faster (usually in the order of ~3-4%), while older Perl
versions will most likely be slower. Different CPAN module versions will also impact
scores, using C<setup_dkbench> is a way to ensure a reference environment for more
meaningful hardware comparisons.

The multi-thread scalability calculated by the suite should approach 100% if each
thread runs on a full core (i.e. no SMT), and the core can maintain the clock speed
it had on the single-thread runs. Note that the overall scalability is an average
of the benchmarks that drops non-scaling outliers (over 2*stdev less than the mean).

If you want to reduce the effects of thermal throttling, which will lower the speed
of (mainly multi-threaded) benchmarks as the CPU temperature increases, the C<sleep>
option can help by adding cooldown time between each benchmark.

The suite will report a Pass/Fail per benchmark. A failure may be caused if you have
different CPAN module version installed - this is normal, and you will be warned.

L<MCE::Loop> is used to run on the desired number of parallel threads, with minimal
overhead., There is an option to disable it, which forces a single-thread run.

=head2 C<setup_dkbench>

Simple installer to check/get the reference versions of CPAN modules and download
the Genbank data file required for the BioPerl benchmarks of the DKbench suite.

It assumes that you have some software already installed (see L</"INSTALLATION"> above),
try C<setup_dkbench --help> will give you more details.

 setup_dkbench [--force --sudo --test --data=s --help]

 Options:
 --sudo   : Will use sudo for cpanm calls.
 --force  : Will install reference CPAN module versions and re-download the genbank data.
 --test   : Will run the test suites for the CPAN module (default behaviour is to skip).
 --data=s : Data dir path to copy files from. Should not need if you installed DKbench.
 --help   : Print this help text and exit.

Running it without any options will fetch the data for the BioPerl tests (similar to
C<dkbench --setup>) and use C<cpanm> to install any missing libraries.

Using it with C<--force> will install the reference CPAN module versions, including
BioPerl which is not a requirement for DKbench, but enables the BioPerl benchmarks.

The reference Perl and CPAN versions are suggested if you want a fair comparison
between systems and also for the benchmark Pass/Fail results to be reliable.

=head1 BENCHMARKS

The suite consists of 21 benchmarks, 19 will run by default. However, the
C<BioPerl Monomers> requires the optional L<BioPerl> to be installed and Genbank
data to be downloaded (C<dkbench --setup> can do the latter), so you will only
see 18 benchmarks running just after a standard install. Because the overall score
is an average, it is generally unaffected by adding or skipping a benchmark or two.

The optional benchmarks are enabled with the C<--time_piece> and C<--bio_codons>
options.

=over 4

=item * C<Astro> : Calculates precession between random epochs and finds the
constellation for random equatorial coordinates using L<Astro::Coord::Precession>
and L<Astro::Coord::Constellations> respectively.

=item * C<BioPerl Codons> : Counts codons on a sample bacterial sequence. Requires
L<BioPerl> to be installed.
This test does not scale well on multiple threads, so is disabled by default (use
C<--bio_codons>) option. Requires data fetched using the C<--setup> option.

=item * C<BioPerl Monomers> : Counts monomers on 500 sample bacterial sequences using
L<BioPerl> (which needs to be installed). Requires data fetched using the C<--setup>
option.

=item * C<CSS::Inliner> : Inlines CSS on 2 sample wiki pages using L<CSS::Inliner>.

=item * C<Crypt::JWT> : Creates large JSON Web Tokens with RSA and EC crypto keys
using L<Crypt::JWT>.

=item * C<DateTime> : Creates and manipulates L<DateTime> objects.

=item * C<DBI/SQL> : Creates a mock L<DBI> connection (using L<DBD::Mock>) and passes
it insert/select statements using L<SQL::Inserter> and L<SQL::Abstract::Classic>.
The latter is quite slow at creating the statements, but it is widely used.

=item * C<Digest> : Creates MD5, SH1 and SHA-512 digests of a large string.

=item * C<Encode> : Encodes/decodes large strings from/to UTF-8/16, cp-1252.

=item * C<HTML::FormatText> : Converts HTML to text for 2 sample wiki pages using
L<HTML::FormatText>.

=item * C<Imager> : Loads a sample image and performs edits/manipulations with
L<Imager>, including filters like gaussian, unsharp mask, mandelbrot.

=item * C<JSON::XS> : Encodes/decodes random data structures to/from JSON using
L<JSON::XS>.

=item * C<Math::DCT> : Does 8x8, 18x18 and 32x32 DCT transforms with L<Math::DCT>.

=item * C<Math::MatrixReal> : Performs various manipulations on L<Math::MatrixReal>
matrices.

=item * C<Moose> : Creates L<Moose> objects.

=item * C<Moose prove> : Runs 110 tests from the Moose 2.2201 test suite. The least
CPU-intensive test (which is why there is the option C<--no_prove> to disable it),
most of the time will be spent loading the interpreter and the Moose module for each
test, which is behaviour representative of how a Perl test suite runs by default.

=item * C<Primes> : Calculates all primes up to 7.5 million. Small number with
repeat was chosen to keep low memory (this is a pure Perl function no Math libraries).

=item * C<Regex/Subst> : Concatenates 3 wiki pages into a byte string then matches
3 typical regexes (for names, emails, URIs), replaces html tags with their contents
(starting with the innermost) and does calls subst a few times.

=item * C<Regex/Subst utf8> : Exactly the same as C<Regex/Subst>, but reads into
a utf8 string. Perl version can make a big difference, as Unicode behaviour has
changed (old Perl versions are faster but less strict in general).

=item * C<Text::Levenshtein> : The edit distance for strings of various lengths (up
to 2500) are calculated using L<Text::Levenshtein::XS> and L<Text::Levenshtein::Damerau::XS>.

=item * C<Time::Piece> : Creates and manipulates/converts Time::Piece objects. It
is disabled by default because it uses the OS time libraries, so it might skew results
if you are trying to compare CPUs on different OS platforms. It can be enabled with
the C<--time_piece> option. For MacOS specifically, it can only be enabled if C<--no_mce>
is specified, as it runs extremely slow when forked.

=back

=head1 EXPORTED FUNCTIONS

You will normally not use the Benchmark::DKbench module itself, but here are the
exported functions that the C<dkbench> script uses for reference:

=head2 C<system_identity>

 my $cores = system_identity();

Prints out software/hardware configuration and returns then number of cores detected.

=head2 C<suite_run>

 my %stats = suite_run(\%options);

Runs the benchmark suite given the C<%options> and prints results. Returns a hash
with run stats.

The options accepted are the same as the C<dkbench> script (in their long form),
except C<help>, C<setup> and C<max_threads> which are command-line only.

=head2 C<calc_scalability>

 calc_scalability(\%options, \%stat_single, \%stat_multi);

Given the C<%stat_single> results of a single-threaded C<suite_run> and C<%stat_multi>
results of a multi-threaded run, will calculate and print the multi-thread scalability.

=head1 NOTES

The benchmark suite was created to compare the performance of various cloud offerings.
You can see the L<original perl blog post|http://blogs.perl.org/users/dimitrios_kechagias/2022/03/cloud-provider-performance-comparison-gcp-aws-azure-perl.html>
as well as the L<2023 follow-up|https://dev.to/dkechag/cloud-vm-performance-value-comparison-2023-perl-more-1kpp>.

The benchmarks for the first version were more tuned to what I would expect to run
on the servers I was testing, in order to choose the optimal types for the company
I was working for. The second version has expanded a bit over that, and is friendlier
to use.

Althought this benchmark is in general a good indicator of general CPU performance
and can be customized to your needs, no benchmark is as good as running your own
actual workload.

=head2 SCORES

Some sample DKbench score results from various systems for comparison (all on
reference setup with Perl 5.36.0 thread-multi):

 CPU                                     Cores/HT   Single   Multi   Scalability
 Intel i7-4750HQ @ 2.0 (MacOS)                4/8     612     2332      46.9%
 AMD Ryzen 5 PRO 4650U @ 2.1 (WSL)           6/12     905     4444      40.6%
 Apple M1 Pro @ 3.2 (MacOS)                 10/10    1283    10026      78.8%
 Apple M2 Pro @ 3.5 (MacOS)                 12/12    1415    12394      73.1%
 Ampere Altra @ 3.0 (Linux)                 48/48     708    32718      97.7%
 Intel Xeon Platinum 8481C @ 2.7 (Linux)   88/176    1000    86055      48.9%
 AMD EPYC Milan 7B13 @ 2.45 (Linux)       112/224     956   104536      49.3%
 AMD EPYC Genoa 9B14 @ 2.7 (Linux)        180/360    1197   221622      51.4%

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests either on L<GitHub|https://github.com/dkechag/Benchmark-DKbench> (preferred), or on RT (via the email
C<bug-Benchmark-DKbench at rt.cpan.org> or L<web interface|https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-DKbench>).

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 GIT

L<https://github.com/dkechag/Benchmark-DKbench>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2021-2023 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

sub benchmark_list {
    return {               # idx : 0 = result, 1 = ref time, 2 = func, 3 = quick test, 4 = normal test, 5 = ver
        'Astro'             => ['e71c7ae08f16fe26aea7cfdb72785873', 5.674, \&bench_astro, 20000, 80000],
        'BioPerl Codons'    => ['97c443c099886ca60e99f7ab9df689b5', 8.752, \&bench_bioperl_codons, 3, 5, 1],
        'BioPerl Monomers'  => ['d29ed0a5c205c803c112be1338d1f060', 5.241, \&bench_bioperl_mono, 6, 20],
        'Crypt::JWT'        => ['d41d8cd98f00b204e9800998ecf8427e', 6.451, \&bench_jwt, 250, 900],
        'CSS::Inliner'      => ['82c1b6de9ca0500a48f8a8df0998df3c', 4.603, \&bench_css, 2, 5],
        'DBI/SQL'           => ['2b8252daad9568a5b39038c696df4be3', 5.700, \&bench_dbi, 5000, 15000, 2.1],
        'DateTime'          => ['b08d2eeb994083b7422f6c9d86fed2c6', 6.198, \&bench_datetime, 5000, 15000],
        'Digest'            => ['4b69f6cf0f53cbf6c3444f2f767dd21d', 4.513, \&bench_digest, 50, 250],
        'Encode'            => ['PASS 1025',                        5.725, \&bench_encode, 40, 120],
        'HTML::FormatText'  => ['8c2589f0a5276252805e11301fc2ab56', 4.756, \&bench_formattext, 4, 10],
        'Imager'            => ['8829cb3703e884054eb025496f336c63', 6.792, \&bench_imager, 4, 16],
        'JSON::XS'          => ['PASS',                             5.388, \&bench_json, 600, 2200],
        'Math::DCT'         => ['766e3bfd7a2276f452bb3d1bd21939bc', 7.147, \&bench_dct, 25000, 100_000],
        'Math::MatrixReal'  => ['4606231b1309fb21ae1223fa0043fd76', 4.293, \&bench_matrixreal, 200, 650],
        'Moose'             => ['d1cb92c513f6378506dfa11f694cffac', 4.968, \&bench_moose, 10_000, 30_000],
        'Moose prove'       => ['PASS',                             7.974, \&bench_moose_prv, 0.5, 1],
        'Primes'            => ['4266f70a7a9efb3484cf5d98eba32244', 3.680, \&bench_primes_m, 2, 5],
        'Regex/Subst'       => ['30ce365b25f3d597578b3bdb14aa3f57', 4.652, \&bench_regex_asc, 8, 24],
        'Regex/Subst utf8'  => ['857eb4e63a4d174ca4a16fe678f7626f', 5.703, \&bench_regex_utf8, 3, 10],
        'Text::Levenshtein' => ['2948a300ed9131fa0ce82bb5eabb8ded', 5.539, \&bench_textlevenshtein, 7, 25, 2.1],
        'Time::Piece'       => ['2d4b149fe7f873a27109fc376d69211b', 5.907, \&bench_timepiece, 75_000, 275_000],
    };
}

sub system_identity {
    my ($physical, $cores, $ncpu) = System::CPU::get_cpu;
    $ncpu ||= 1;
    local $^O = 'linux' if $^O =~ /android/;
    my $info  = System::Info->sysinfo_hash;
    my $osn   = $info->{distro} || $info->{os} || $^O;
    my $model = System::CPU::get_name || '';
    my $arch  = System::CPU::get_arch || '';
    $arch = " ($arch)" if $arch;
    print "--------------- Software ---------------\nDKbench v$VERSION\n";
    printf "Perl $^V (%sthreads, %smulti)\n",
        $Config{usethreads}      ? '' : 'no ',
        $Config{usemultiplicity} ? '' : 'no ',;
    print "OS: $osn\n--------------- Hardware ---------------\n";
    print "CPU type: $model$arch\n";
    print "CPUs: $ncpu";
    my @extra;
    push @extra, "$physical Processors" if $physical && $physical > 1;
    push @extra, "$cores Cores" if $cores;
    push @extra, "$ncpu Threads" if $cores && $cores != $ncpu;
    print " (".join(', ', @extra).")" if @extra;
    print "\n".("-"x40)."\n";

    return $ncpu;
};

sub suite_run {
    my $opt = shift;
    $datadir = $opt->{datapath} if $opt->{datapath};
    $opt->{threads} //= 1;
    $opt->{scale} //= 1;
    $opt->{f} = $opt->{time} ? '%.3f' : '%5.0f';
    my %stats = (threads => $opt->{threads});

    MCE::Loop::init {
        max_workers => $opt->{threads},
        chunk_size  => 1,
    } unless $opt->{no_mce};

    foreach (1..$opt->{iter}) {
        print "Iteration $_ of $opt->{iter}...\n" if $opt->{iter} > 1;
        run_iteration($opt, \%stats);
    }

    total_stats($opt, \%stats) if $opt->{iter} > 1;

    return %stats;
}

sub calc_scalability {
    my ($opt, $stats1, $stats2) = @_;
    my $benchmarks = benchmark_list();
    my $threads = $stats2->{threads}/$stats1->{threads};
    my $display = $opt->{time} ? 'times' : 'scores';
    $opt->{f} = $opt->{time} ? '%.3f' : '%5.0f';
    my (@perf, @scal);
    print "Multi thread Scalability:\n".pad_to("Benchmark",24).pad_to("Multi perf xSingle",24).pad_to("Multi scalability %",24);
    print "\n";
    my $cnt;
    foreach my $bench (sort keys %$benchmarks) {
        next unless $stats1->{$bench}->{times} && $stats2->{$bench}->{times};
        $cnt++;
        my @res1 = min_max_avg($stats1->{$bench}->{times});
        my @res2 = min_max_avg($stats2->{$bench}->{times});
        push @perf, $res1[2]/$res2[2]*$threads if $res2[2];
        push @scal, $res1[2]/$res2[2]*100 if $res2[2];
        print pad_to("$bench:",24).pad_to(sprintf("%.2f",$perf[-1]),24).pad_to(sprintf("%2.0f",$scal[-1]),24)."\n";
    }
    print (("-"x40)."\n");
    my $avg1 = min_max_avg($stats1->{total}->{$display});
    my $avg2 = min_max_avg($stats2->{total}->{$display});
    print "DKbench summary ($cnt benchmark";
    print "s" if $cnt > 1;
    print " x$opt->{scale} scale" if $opt->{scale} && $opt->{scale} > 1;
    print ", $opt->{iter} iterations" if $opt->{iter} && $opt->{iter} > 1;
    print ", $stats2->{threads} thread";
    print "s" if $stats2->{threads} > 1;
    print "):\n";
    $opt->{f} .= "s" if $opt->{time};
    print pad_to("Single:").sprintf($opt->{f}, $avg1)."\n";
    print pad_to("Multi:").sprintf($opt->{f}, $avg2)."\n";
    my @newperf = Benchmark::DKbench::drop_outliers(\@perf, -1);
    my @newscal = Benchmark::DKbench::drop_outliers(\@scal, -1);
    @perf = min_max_avg(\@newperf);
    @scal = min_max_avg(\@newscal);
    print pad_to("Multi/Single perf:").sprintf("%.2fx\t(%.2f - %.2f)", $perf[2], $perf[0], $perf[1])."\n";
    print pad_to("Multi scalability:").sprintf("%2.1f%% \t(%.0f%% - %.0f%%)", $scal[2], $scal[0], $scal[1])."\n";
}

sub run_iteration {
    my ($opt, $stats) = @_;
    my $benchmarks = benchmark_list();
    my $title = $opt->{time} ? 'Time (sec)' : 'Score';
    print pad_to("Benchmark").pad_to($title);
    print "Pass/Fail" unless $opt->{time};
    print "\n";
    my ($total_score, $total_time, $i) = (0, 0, 0);
    foreach my $bench (sort keys %$benchmarks) {
        next if $opt->{skip_bio} && $bench =~ /Monomers/;
        next if $opt->{skip_prove} && $bench =~ /prove/;
        next if !$opt->{bio_codons} && $bench =~ /Codons/;
        next if !$opt->{time_piece} && $bench =~ /Time::Piece/;
        next if $opt->{ver} && $benchmarks->{$bench}->[5] && $opt->{ver} < $benchmarks->{$bench}->[5];
        next if $opt->{exclude} && $bench =~ /$opt->{exclude}/;
        next if $opt->{include} && $bench !~ /$opt->{include}/;
        if ($bench =~ /Bio/) {
            require Bio::SeqIO;
            require Bio::Tools::SeqStats;
         }
        my ($time, $res) = mce_bench_run($opt, $benchmarks->{$bench});
        my $score = int(1000*$opt->{threads}*$benchmarks->{$bench}->[1]/($time || 1)+0.5);
        $total_score += $score;
        $total_time += $time;
        $i++;
        push @{$stats->{$bench}->{times}}, $time;
        push @{$stats->{$bench}->{scores}}, $score;
        my $d = $stats->{$bench}->{$opt->{time} ? 'times' : 'scores'}->[-1];
        $stats->{$bench}->{fail}++ if $res ne 'Pass';
        print pad_to("$bench:").pad_to(sprintf($opt->{f}, $d));
        print "$res" unless $opt->{time};
        print "\n";
        sleep $opt->{sleep} if $opt->{sleep};
    }
    die "No tests to run\n" unless $i;
    my $s = int($total_score/$i+0.5);
    print pad_to("Overall $title: ").sprintf($opt->{f}."\n", $opt->{time} ? $total_time : $s);
    push @{$stats->{total}->{times}}, $total_time;
    push @{$stats->{total}->{scores}}, $s;
}

sub mce_bench_run {
    my $opt       = shift;
    my $benchmark = shift;
    $benchmark->[3] = $benchmark->[4] unless $opt->{quick};
    return bench_run($benchmark) if $opt->{no_mce};

    my @stats = mce_loop {
        my ($mce, $chunk_ref, $chunk_id) = @_;
        for (@{$chunk_ref}) {
            my ($time, $res) = bench_run($benchmark);
            MCE->gather([$time, $res]);
        }
    }
    (1 .. $opt->{threads} * $opt->{scale});

    my ($res, $time) = ('Pass', 0);
    foreach (@stats) {
        $time += $_->[0];
        $res = $_->[1] if $_->[1] ne 'Pass';
    }

    return $time/($opt->{threads}*$opt->{scale} || 1), $res;
}

sub bench_run {
    my ($benchmark, $srand) = @_;
    $srand //= 1;
    srand($srand); # For repeatability
    my $t0   = _get_time();
    my $out  = $benchmark->[2]->($benchmark->[3]);
    my $time = sprintf("%.3f", _get_time()-$t0);
    my $r    = $out eq $benchmark->[0] ? 'Pass' : "Fail ($out)";
    return $time, $r;
}

sub bench_astro {
    my $iter = shift;
    my $d    = Digest->new("MD5");
    my $precessed = precess([rand(24), rand(180)-90], rand(200)+1900, rand(200)+1900)
        for (1..$iter*10);
    my $constellation_abbrev;
    $d->add(constellation_for_eq(rand(24), rand(180)-90, rand(200)+1900))
        for (1..$iter);
    return $d->hexdigest;
}

sub bench_bioperl_codons {
    my $skip = shift;
    my $iter = shift;
    my $d    = Digest->new("MD5");
    my $file = catfile($datadir, "gbbct5.seq");
    foreach (1..$iter) {
        my $in = Bio::SeqIO->new(-file => $file, -format => "genbank");
        $in->next_seq for (1..$skip);
        my $seq = $in->next_seq;
        my $seq_stats = Bio::Tools::SeqStats->new($seq);
        my $codon_ref = $seq_stats->count_codons();
        $d->add($_, $codon_ref->{$_}) for sort keys %$codon_ref;
    }
    return $d->hexdigest;
}

sub bench_bioperl_mono {
    my $iter = shift;
    my $file = catfile($datadir, "gbbct5.seq");
    my $in   = Bio::SeqIO->new(-file => $file, -format => "genbank");
    my $d    = Digest->new("MD5");
    my $builder = $in->sequence_builder();
    $builder->want_none();
    $builder->add_wanted_slot('display_id','seq');
    for (1..$iter) {
        my $seq = $in->next_seq;
        my $seq_stats = Bio::Tools::SeqStats->new($seq);
        my $weight = $seq_stats->get_mol_wt();
        $d->add(int($weight->[0]));
        my $monomer_ref = $seq_stats->count_monomers();
        $d->add($_, $monomer_ref->{$_}) for sort keys %$monomer_ref;
    }
    return $d->hexdigest;
}

sub bench_css {
    my $iter = shift;
    my $d    = Digest->new("MD5");
    my $file;
    my $html;
    for (1..$iter) {
        my $inliner = new CSS::Inliner();
        my $i = $_ % 2 + 1;
        $file = catfile($datadir, "wiki$i.html");
        $inliner->read_file({ filename => $file });
        $html = $inliner->inlinify();
        $d->add(Encode::encode_utf8($html));
    }
    return $d->hexdigest;
}

sub bench_datetime {
    my $iter = shift;
    my @tz   = map {DateTime::TimeZone->new( name => $_ )} qw(UTC Europe/London America/New_York);
    my $d    = Digest->new("MD5");
    my $str;

    for (1..$iter) {
        my $dt  = DateTime->now();
        my $dt1 = DateTime->from_epoch(
            epoch => 946684800 + rand(100000000),
        );
        my $dt2 = DateTime->from_epoch(
            epoch => 946684800 + rand(100000000),
        );
        $str = $dt2->strftime('%FT%T')."\n";
        $d->add($str);
        eval {$dt2->set_time_zone($tz[int(rand(3))])};
        my $dur = $dt2->subtract_datetime($dt1);
        eval {$dt2->add_duration($dur)};
        eval {$dt2->subtract(days => int(rand(1000)+1))};
        $dt->week;
        $dt->epoch;
        $d->add($dt2->strftime('%FT%T'));
        eval {$dt2->set( year => int(rand(2030)))};
        $d->add($dt2->ymd('/'));
    }
    return $d->hexdigest;
}

sub bench_dbi {
    my $iter = shift;
    my $d    = Digest->new("MD5");
    my $dbh  = DBI->connect( 'DBI:Mock:', '', '' );
    my ($data, $cols) = _db_data();

    foreach (1..$iter) {
        my $inserter = SQL::Inserter->new(
            dbh    => $dbh,
            table  => 'table',
            cols   => $cols,
            buffer => 2
        );
        $inserter->insert($data->[int(rand(20))]) for 1..2;
        $d->add($dbh->last_insert_id);
        my $sql = SQL::Abstract::Classic->new();
        my ($stmt, @bind) = $sql->insert('table', $data->[int(rand(20))]);
        $d->add($dbh->quote($stmt));
        ($stmt, @bind) = $sql->select('table', $cols->[int(rand(20))], [map {_rand_where()} 1..int(rand(3)+1)]);
        $d->add($dbh->quote($stmt._random_str(5)));
        my $dbh2 = DBI->connect( 'DBI:Mock:', '', '' );
    }
    return $d->hexdigest;
}

sub bench_dct {
    my $iter = shift;
    my $d    = Digest->new("MD5");
    $d->add(bench_dct_sz(@$_)) foreach [$iter, 32], [$iter, 18], [$iter*8,8];

    return $d->hexdigest;
}

sub bench_dct_sz {
    my $iter = shift;
    my $sz   = shift;
    my $d    = Digest->new("MD5");
    my @arrays;
    push @arrays, [map { rand(256) } ( 1..$sz*$sz )] foreach 1..10;
    foreach (1..$iter) {
        my $dct = dct2d($arrays[$iter % 10], $sz);
        $d->add($dct->[0]) if $_ % 10 == 1;
    }
    return $d->hexdigest;
}

sub bench_digest {
    my $iter = shift;
    my $str  = _read_wiki_files();
    my $d    = Digest->new("MD5");
    my $hex;
    foreach (1..$iter) {
        my $d2 = Digest->new("MD5");
        $d2->add($str);
        $hex = $d2->hexdigest;
        $d->add($hex);
        $d2 = Digest->new("SHA-512");
        $d2->add($str);
        $hex = $d2->hexdigest;
        $d->add($hex);
        $d2 = Digest->new("SHA-1");
        $d2->add($str);
        $hex = $d2->hexdigest;
        $d->add($hex);
    }
    return $d->hexdigest;
}

sub bench_encode {
    my $iter    = shift;
    my $str     = _read_wiki_files('utf8');
    my $UTF8    = Encode::find_encoding('UTF-8');
    my $UTF16   = Encode::find_encoding('UTF-16');
    our $cp1252 = Encode::find_encoding('cp-1252');
    my $res   = 'PASS';
    my $unenc = 0;

    foreach (1..$iter) {
        my $bytes = encode_utf8($str);
        $res = 'Fail' unless length($bytes) > length($str);
        my $cp = decode_utf8($bytes);
        my $enc = rand(1) > 0.25 ? $UTF8 : $UTF16;
        $bytes = $enc->encode($cp);
        $cp = $enc->decode($bytes);
        $res = 'Fail' unless $cp eq $str;
        my $str2 = $cp1252->encode($cp);
        $enc->encode($cp1252->decode($str2));
        $unenc = () = $str2 =~ /\?/g; # Non-encodable
    }
    return "$res $unenc";
}

sub bench_imager {
    my $iter = shift;
    my $d    = Digest->new("MD5");

    my $data;
    open (my $fh, '<:raw', catfile($datadir,'M31.bmp')) or die $!;
    read($fh, $data, -s $fh);
    close($fh);

    foreach (1..$iter) {
        my $img = Imager->new(data=>$data, type=>'bmp') or die Imager->errstr();
        my $thumb = $img->scale(scalefactor=>.3);
        my $newimg = $img->scale(scalefactor=>1.15);
        $newimg->filter(type=>'autolevels');
        $newimg->filter(type=>"gaussian", stddev=>0.5);
        $newimg->paste(left=>40,top=>20,img=>$thumb);
        $newimg->rubthrough(src=>$thumb,tx=>30, ty=>50);
        $newimg->compose(src => $thumb, tx => 30, ty => 20, combine => 'color');
        $newimg->flip(dir=>"h");
        $newimg->flip(dir=>"vh");
        $d->add(scalar(Image::PHash->new($newimg)->pHash));
        $newimg = $img->crop(left=>50, right=>100, top=>10, bottom=>100);
        $newimg = $img->crop(left=>50, top=>10, width=>50, height=>90);
        $newimg = $img->copy();
        $newimg->filter(type=>"unsharpmask", stddev=>1, scale=>0.5);
        $newimg = $img->rotate(degrees=>20);
        $newimg->filter(type=>"contrast", intensity=>1.4);
        $newimg = $img->convert(matrix => [[0, 1, 0], [1, 0, 0], [0, 0, 1]]);
        $newimg = $img->convert(preset=>'grey');
        $d->add(scalar(Image::PHash->new($newimg)->pHash));
        $img->filter(type=>'mandelbrot');
    }
    return $d->hexdigest;
}

sub bench_json {
    my $iter = shift;
    my $res  = 'PASS';
    for (1..$iter) {
        my $len = int(rand(40)) + 1;
        my $obj = rand_hash($len);
        my $str = encode_json($obj);
        foreach (1..100) {
            $obj = decode_json($str);
            $str = encode_json($obj);
        }
        my $obj2 = decode_json($str);
        $res = 'FAIL' unless compare_obj($obj, $obj2);
    }
    return $res;
}

sub bench_jwt {
    my $iter = shift;
    my $d    = Digest->new("MD5");
    my $data = _random_str(5000);
    my $rsa ='-----BEGIN PRIVATE KEY-----
    MIIBVAIBADANBgkqhkiG9w0BAQEFAASCAT4wggE6AgEAAkEAqPfgaTEWEP3S9w0t
    gsicURfo+nLW09/0KfOPinhYZ4ouzU+3xC4pSlEp8Ut9FgL0AgqNslNaK34Kq+NZ
    jO9DAQIDAQABAkAgkuLEHLaqkWhLgNKagSajeobLS3rPT0Agm0f7k55FXVt743hw
    Ngkp98bMNrzy9AQ1mJGbQZGrpr4c8ZAx3aRNAiEAoxK/MgGeeLui385KJ7ZOYktj
    hLBNAB69fKwTZFsUNh0CIQEJQRpFCcydunv2bENcN/oBTRw39E8GNv2pIcNxZkcb
    NQIgbYSzn3Py6AasNj6nEtCfB+i1p3F35TK/87DlPSrmAgkCIQDJLhFoj1gbwRbH
    /bDRPrtlRUDDx44wHoEhSDRdy77eiQIgE6z/k6I+ChN1LLttwX0galITxmAYrOBh
    BVl433tgTTQ=
    -----END PRIVATE KEY-----';
    my $key = '-----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgYirTZSx+5O8Y6tlG
    cka6W6btJiocdrdolfcukSoTEk+hRANCAAQkvPNu7Pa1GcsWU4v7ptNfqCJVq8Cx
    zo0MUVPQgwJ3aJtNM1QMOQUayCrRwfklg+D/rFSUwEUqtZh7fJDiFqz3
    -----END PRIVATE KEY-----';
    foreach (1..$iter) {
        my $extra   = _random_str(100);
        my $data_in = $data.$extra;
        my $token   = encode_jwt(
            payload       => $data_in,
            alg           => 'ES256',
            key           => \$key,
        );

        my $data_out = _decode_jwt2(token=>$token, key=>\$key);
        $d->add($token) if $data_in eq $data_out.$extra;

        $token   = encode_jwt(
            payload       => $data_in,
            alg           => 'RS256',
            key           => \$rsa,
        );

        $data_out = _decode_jwt2(token=>$token, key=>\$rsa);
        $d->add($token) if $data_in eq $data_out.$extra;
    }
    return $d->hexdigest;
}

sub bench_formattext {
    my $iter = shift;
    my $d    = Digest->new("MD5");
    my $file;
    for (0..$iter-1) {
        my $i = $_ % 2;
        $file = catfile($datadir, "wiki$i.html");
        my $tree = HTML::TreeBuilder->new->parse_file($file);
        my $formatter = HTML::FormatText->new();
        my $text = $formatter->format($tree);
        $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 30);
        $d->add(Encode::encode_utf8($formatter->format($tree)));
    }
    return $d->hexdigest;
}

sub bench_matrixreal {
    my $iter    = shift;
    my $d       = Digest->new("MD5");
    my $smatrix = Math::MatrixReal->new_random(13);
    my $matrix  = Math::MatrixReal->new_random(20);
    my $bmatrix = Math::MatrixReal->new_random(72);

    for (1..$iter) {
        my $r = rand(10);
        my $m1 = $r*$bmatrix;
        my $m2 = $bmatrix*$r;
        my $m3 = $bmatrix->multiply_scalar($bmatrix,$r);
        # Should be zero
        $d->add($m1->element(1, 1) + $m2->element(1, 1) - 2 * $bmatrix->element(1, 1))
            if $_ % 10 == 1;

        my $m = $matrix->det;
        $d->add($m) if $_ % 10 == 1;
        $m =$matrix->decompose_LR->det_LR;
        $d->add($m) if $_ % 10 == 1;
        $m1 = $matrix ** 2;
        $m2 = $matrix * $matrix;
        #should be zero
        $d->add($m1->element(1, 1) - $m2->element(1, 1))
            if $_ % 10 == 1;
        $m1 = $smatrix->inverse();
        $m2 = $smatrix ** -1;
        $m3 = $smatrix->decompose_LR->invert_LR;
        $d->add($m1->element(1, 1), $m2->element(1, 1), $m3->element(1, 1))
            if $_ % 10 == 1;
    }

    return $d->hexdigest;
}

sub bench_moose {
    my $iter = shift;
    my $cnt  = 0;

    for (1..$iter) {
        my $p    = rand(1000);
        my $root = Benchmark::DKbench::MooseTree->new(node => 'root');
        $root->price($p);
        $root->node;
        $root->cost;
        my $lchild = $root->left;
        $lchild->node('child');
        $lchild->price($p);
        $lchild->tax;
        my $child = $root->right;
        $child->cost;
        my $grandchild = $child->left;
        $grandchild->node('grandchild');
        $grandchild->has_parent;
        $grandchild->parent;
        $grandchild->price($p);
        $grandchild->cost;
        my $ggchild = $grandchild->right;
        $ggchild->cost;
        $cnt += 5;
    }
    return md5_hex("$cnt objects");
}

sub bench_moose_prv {
    my $iter = shift;
    my $tdir = catfile($datadir, 't');
    my $result;
    if ($iter < 1) {
        $tdir = catfile($tdir, 'recipes');
        $result = `prove -rQ $tdir`;
    } else {
        $result = `prove -rQ $tdir` for (1..$iter);
    }
    if ($result =~ /Result: (\w*)/) {
        return $1;
    } else  {
        return '?';
    }
}

sub bench_primes_m {
    my $iter = shift;
    return bench_primes($iter, 7_500_000);
}

sub bench_primes {
    my $iter = shift;
    my $max  = shift;
    my @primes;
    @primes = _get_primes($max) for (1..$iter);
    return md5_hex(scalar(@primes)." primes up to $max");
}

sub bench_regex_asc {
    my $iter = shift;
    return bench_regex_subst($iter, '');
}

sub bench_regex_utf8 {
    my $iter = shift;
    return bench_regex_subst($iter, 'utf8');
}

sub bench_regex_subst {
    my $iter  = shift;
    my $enc   = shift;
    my $str   = _read_wiki_files($enc);
    my $match = bench_regex($str, $iter);
    my $repl  = bench_subst($str, $iter);
    return md5_hex($match, $repl);
}

sub bench_regex {
    my $str  = shift;
    my $iter = shift;
    my $count;
    for (1..$iter) {
        $count = 0;
        $count += () = $str =~ /\b[A-Z][a-z]+/g;
        $count += () = $str =~ /([\w\.+-]+)@[\w\.-]+\.([\w\.-]+)/g;
        $count += () = $str =~ m![\w]+://[^/\s?#]+[^\s?#]+(?:\?[^\s#]*)?(?:#[^\s]*)?!g;
    }
    return "$count Matched";
}

sub bench_subst {
    my $str  = shift;
    my $iter = shift;
    my $count;
    for (1..$iter) {
        my $copy = $str;
        $count = 0;
        while (my $s = $copy =~ s#<([^>]+)>([^>]*?)</\1>#$2#g) {
            $count += $s;
        }
        $copy = substr($copy, int(rand(100))+1) for 1..10;
    }
    return "$count Replaced";
}

sub bench_textlevenshtein {
    my $iter = shift;
    my $d    = Digest->new("MD5");
    my $data = _fuzzy_data();
    my $diff;
    foreach (1..$iter) {
        foreach my $sz (qw/10 100 1000 2500/) {
            my $n = scalar @{$data->{$sz}};
            my $i = int(rand($n));
            $diff = Text::Levenshtein::XS::distance(
                $data->{$sz}->[$i], $data->{$sz}->[$_]
            ) for 0..$n-1;
            $d->add($diff || -1);
            next if $sz > 1000;
            $diff = Text::Levenshtein::Damerau::XS::xs_edistance(
                $data->{$sz}->[$i], $data->{$sz}->[$_]
            ) for 0..$n-1;
            $d->add($diff);
        }
    }
    return $d->hexdigest;
}

sub bench_timepiece {
    my $iter = shift;
    my $t    = Time::Piece::localtime(1692119499);
    my $d    = Digest->new("MD5");
    my $day  = 3600*24;
    local $ENV{TZ} = 'UTC';

    for (1..$iter) {
        $t += int(rand(1000)-500)*$day;
        $t += 100000*$day if $t->year < 1970;
        my $str = $t->strftime("%w, %d %m %Y %H:%M:%S");
        eval '$t = Time::Piece->strptime($str, "%w, %d %m %Y %H:%M:%S")';
        my $jd = $t->julian_day;
        $d->add($str,$jd);
    }
    return $d->hexdigest;
}

sub total_stats {
    my ($opt, $stats) = @_;
    my $benchmarks = benchmark_list();
    my $display = $opt->{time} ? 'times' : 'scores';
    my $title   = $opt->{time} ? 'Time (sec)' : 'Score';
    print "Aggregates ($opt->{iter} iterations):\n".pad_to("Benchmark",24).pad_to("Avg $title").pad_to("Min $title").pad_to("Max $title");
    print pad_to("stdev %") if $opt->{stdev};
    print pad_to("Pass %") unless $opt->{time};
    print "\n";
    foreach my $bench (sort keys %$benchmarks) {
        next unless $stats->{$bench}->{$display};
        my $str = calc_stats($opt, $stats->{$bench}->{$display});
        print pad_to("$bench:",24).$str;
        print pad_to(
            sprintf("%d", 100 * ($opt->{iter}-($stats->{$bench}->{fail} || 0)) / $opt->{iter}))
            unless $opt->{time};
        print "\n";
    }
    my $str = calc_stats($opt, $stats->{total}->{$display});
    print pad_to("Overall Avg $title:", 24)."$str\n";
}

sub calc_stats {
    my $opt = shift;
    my $arr = shift;
    my $pad = shift;
    my ($min, $max, $avg) = min_max_avg($arr);
    my $str = join '', map {pad_to(sprintf($opt->{f}, $_), $pad)} ($avg,$min,$max);
    if ($opt->{stdev} && $avg) {
        my $stdev = avg_stdev($arr);
        $stdev *= 100/$avg;
        $str .= pad_to(sprintf("%0.2f%%", $stdev), $pad);
    }
    return $avg, $str;
}

sub min_max_avg {
    my $arr = shift;
    return (0, 0, 0) unless @$arr;
    return min(@$arr), max(@$arr), sum(@$arr)/scalar(@$arr);
}

sub avg_stdev {
    my $arr = shift;
    return (0, 0) unless @$arr;
    my $sum = sum(@$arr);
    my $avg = $sum/scalar(@$arr);
    my @sq;
    push @sq, ($avg - $_)**2 for (@$arr);
    my $dev = min_max_avg(\@sq);
    return $avg, sqrt($dev);
}

# $single = single tail of dist curve outlier, 1 for over (right), -1 for under (left)
sub drop_outliers {
    my $arr    = shift;
    my $single = shift;
    my ($avg, $stdev) = avg_stdev($arr);
    my @newarr;
    foreach (@$arr) {
        if ($single) {
            push @newarr, $_ unless $single*($_ - $avg) > 2*$stdev;
        } else {
            push @newarr, $_ unless abs($avg - $_) > 2*$stdev;
        }
    }
    return @newarr;
}

sub pad_to {
    my $str = shift;
    my $len = shift || 20;
    return $str." "x($len-length($str));
}

sub _read_wiki_files {
    my $enc = shift || '';
    my $str = "";
    for (0..2) {
        open my $fh, "<:$enc", catfile($datadir,"wiki$_.html") or die $!;
        $str .= do { local $/; <$fh> };
    }
    return $str;
}

sub _random_str {
    my $length = shift || 1;
    my $abc    = shift;
    my ($base, $rng) = $abc ? (65, 26) : (32, 95);
    my $str = "";
    $str .= chr(int(rand($rng))+$base) for 1..$length;
    return $str;
}

sub _random_uchar {
    my $chr = int(rand(800))+32;
    $chr += 128 if $chr > 127; # Skip Latin 1 supplement
    $chr += 288 if $chr > 591; # Skip pre-Greek blocks
    return chr($chr);
}

sub _fuzzy_data {
    my %data;
    push @{$data{10}}, join('', map {_random_uchar()} 1..(8+int(rand(5))))
        for 0..99;
    push @{$data{100}}, $data{10}->[$_]x10 for 0..49;
    push @{$data{1000}}, _random_str(50,1)x20 for 0..7;
    push @{$data{2500}}, _random_str(50,1)x50 for 0..3;
    return \%data;
}

sub _rand_where {
    my $p = rand();
    if ($p > 0.5) {
        return {foo => rand(10)};
    } elsif ($p > 0.2) {
        return {bar => {-in => [int($p*10)..int($p*20)]}};
    } else {
        my $op = $p > 0.1 ? '-and' : '-or';
        my @cond = map {_rand_where()} 1..int(rand(3)+1);
        return {$op => [@cond]};
    }
}

sub _db_data {
    my (@data, @cols);
    foreach (1..20) {
        my $d = {
        id   => int(rand(10000000)),
        date => \"NOW()",
        map {"data".$_ => "foo bar" x int(rand(5)+1)} 1..int(rand(20)+1)
        };
        push @data, $d;
        push @cols, [sort keys %$d];
    }
    return \@data, \@cols;
}

sub compare_obj {
    my ($obj1, $obj2) = @_;
    my $t1 = ref($obj1);
    my $t2 = ref($obj2);
    return 0 if $t1 ne $t2;
    return $obj1 eq $obj2 unless $t1;
    return $t1 eq 'ARRAY' ? compare_arr($obj1, $obj2) : compare_hash($obj1, $obj2);
}

sub compare_arr {
    my ($arr1, $arr2) = @_;
    my $sz = scalar @$arr1;
    return 0 if $sz != scalar @$arr2;
    for (0..$sz-1) {
        return 0 unless compare_obj($arr1->[$_], $arr2->[$_]);
    }
    return 1;
}

sub compare_hash {
    my ($h1, $h2) = @_;
    return 0 if scalar keys %$h1 != scalar keys %$h2;
    for (keys %$h1) {
        return 0 unless compare_obj($h1->{$_}, $h2->{$_});
    }
    return 1;
}

sub rand_arr {
    my $sz = shift;
    my @arr;
    for (1..$sz) {
        my $len  = int(rand(10)) + 1;
        my $item = rand(1) < 0.9 ? _random_uchar()x($len*5) : rand(1) < 0.5 ? rand_arr($len) : rand_hash($len);
        push @arr, $item;
    }
    return \@arr;
}

sub rand_hash {
    my $sz = shift;
    my %hash;
    for (1..$sz) {
        my $len  = int(rand(10)) + 1;
        my $item = rand(1) < 0.9 ? _random_uchar()x($len*5) : rand(1) < 0.5 ? rand_arr($len) : rand_hash($len);
        $hash{_random_uchar()x($len*4)} = $item;
    }
    return \%hash;
}

# modified from https://github.com/famzah/langs-performance/blob/master/primes.pl
sub _get_primes {
    my $n = shift;
    my @s = ();
    for (my $i = 3; $i < $n + 1; $i += 2) {
        push(@s, $i);
    }
    my $mroot = $n**0.5;
    my $half  = scalar @s;
    my $i     = 0;
    my $m     = 3;
    while ($m <= $mroot) {
        if ($s[$i]) {
            for (my $j = int(($m * $m - 3) / 2); $j < $half; $j += $m) {
                $s[$j] = 0;
            }
        }
        $i++;
        $m = 2 * $i + 3;
    }

    return 2, grep($_, @s);
}

# Fix for Crypt::JWT that was submitted as a patch. Will remove if it is merged.
sub _decode_jwt2 {
    my %args = @_;
    my ($header, $payload);

    if ($args{token} =~
        /^([a-zA-Z0-9_-]+)=*\.([a-zA-Z0-9_-]*)=*\.([a-zA-Z0-9_-]*)=*(?:\.([a-zA-Z0-9_-]+)=*\.([a-zA-Z0-9_-]+)=*)?$/
    ) {
        if (length($5)) {
            # JWE token (5 segments)
            ($header, $payload) =
                Crypt::JWT::_decode_jwe($1, $2, $3, $4, $5, undef, {}, {},
                %args);
        } else {
            # JWS token (3 segments)
            ($header, $payload) =
                Crypt::JWT::_decode_jws($1, $2, $3, {}, %args);
        }
    }
    return ($header, $payload) if $args{decode_header};
    return $payload;
}

sub _get_time {
    return $mono_clock ? Time::HiRes::clock_gettime(CLOCK_MONOTONIC) : Time::HiRes::time();
}

# Helper package for Moose benchmark

{
    package Benchmark::DKbench::MooseTree;

    use Moose;

    has 'price' => (is => 'rw', default    => 10);
    has 'tax'   => (is => 'rw', lazy_build => 1);
    has 'node'  => (is => 'rw', isa => 'Any');
    has 'parent' => (
        is        => 'rw',
        isa       => 'Benchmark::DKbench::MooseTree',
        predicate => 'has_parent',
        weak_ref  => 1,
    );
    has 'left' => (
        is        => 'rw',
        isa       => 'Benchmark::DKbench::MooseTree',
        predicate => 'has_left',
        lazy      => 1,
        builder   => '_build_child_tree',
    );
    has 'right' => (
        is        => 'rw',
        isa       => 'Benchmark::DKbench::MooseTree',
        predicate => 'has_right',
        lazy      => 1,
        builder   => '_build_child_tree',
    );
    before 'right', 'left' => sub {
        my ($self, $tree) = @_;
        $tree->parent($self) if defined $tree;
    };

    sub _build_tax {
        my $self = shift;
        $self->price * 0.2;
    }

    sub _build_child_tree {
        my $self = shift;
        return Benchmark::DKbench::MooseTree->new( parent => $self );
    }

    sub cost {
        my $self = shift;
        $self->price + $self->tax;
    }
}

1;
package Bencher::Scenario::INIParsingModules;

use 5.010001;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-19'; # DATE
our $DIST = 'Bencher-Scenario-INIParsingModules'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark INI parsing modules',
    modules => {
        # minimum versions
        #'Foo' => {version=>'0.31'},
    },
    participants => [
        {
            module => 'Config::IOD::INI::Reader',
            code_template => 'state $iod = Config::IOD::INI::Reader->new; $iod->read_file(<filename>)',
        },
        {
            module => 'Config::INI::Reader',
            code_template => 'Config::INI::Reader->read_file(<filename>)',
        },
        {
            module => 'Config::IniFiles',
            code_template => 'Config::IniFiles->new(-file => <filename>)',
        },
        {
            module => 'Config::Simple::Conf',
            code_template => 'Config::Simple::Conf->new(<filename>)',
        },
        {
            module => 'Config::INI::Tiny',
            code_template => 'state $cfg = Config::INI::Tiny->new; $cfg->to_hash(do { local $/; open my $fh, "<", <filename> or die; scalar readline($fh) } )',
        },
        {
            module => 'Config::Tiny',
            code_template => 'Config::Tiny->read(<filename>)',
        },
    ],

    datasets => [
    ],
};

my $dir = dist_dir('INI-Examples')
    or die "Can't find share dir for INI-Examples";
for my $filename (glob "$dir/examples/*bench*.ini") {
    my $basename = $filename; $basename =~ s!.+/!!;
    push @{ $scenario->{datasets} }, {
        name => $basename,
        args => {filename => $filename},
    };
}

1;
# ABSTRACT: Benchmark INI parsing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::INIParsingModules - Benchmark INI parsing modules

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::INIParsingModules (from Perl distribution Bencher-Scenario-INIParsingModules), released on 2024-02-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m INIParsingModules

To run module startup overhead benchmark:

 % bencher --module-startup -m INIParsingModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Config::INI::Reader> 0.029

L<Config::INI::Tiny> 0.106

L<Config::IOD::INI::Reader> 0.345

L<Config::IniFiles> 3.000003

L<Config::Simple::Conf> 2.007

L<Config::Tiny> 2.30

=head1 BENCHMARK PARTICIPANTS

=over

=item * Config::IOD::INI::Reader (perl_code)

Code template:

 state $iod = Config::IOD::INI::Reader->new; $iod->read_file(<filename>)



=item * Config::INI::Reader (perl_code)

Code template:

 Config::INI::Reader->read_file(<filename>)



=item * Config::IniFiles (perl_code)

Code template:

 Config::IniFiles->new(-file => <filename>)



=item * Config::Simple::Conf (perl_code)

Code template:

 Config::Simple::Conf->new(<filename>)



=item * Config::INI::Tiny (perl_code)

Code template:

 state $cfg = Config::INI::Tiny->new; $cfg->to_hash(do { local $/; open my $fh, "<", <filename> or die; scalar readline($fh) } )



=item * Config::Tiny (perl_code)

Code template:

 Config::Tiny->read(<filename>)



=back

=head1 BENCHMARK DATASETS

=over

=item * extra-bench-basic-compat.ini

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-10400 CPU @ 2.90GHz (6 cores) >>, OS: I<< GNU/Linux Debian version 12 >>, OS kernel: I<< Linux version 6.1.0-13-amd64 >>.

Benchmark command (default options):

 % bencher -m INIParsingModules

Result formatted as table:

 #table1#
 +--------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant              | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Config::IniFiles         |       343 |     2.91  |                 0.00% |               992.43% | 1.8e-06 |      20 |
 | Config::Tiny             |      1400 |     0.715 |               307.40% |               168.15% |   4e-07 |      21 |
 | Config::INI::Reader      |      1440 |     0.696 |               318.78% |               160.86% | 2.6e-07 |      20 |
 | Config::Simple::Conf     |      2550 |     0.393 |               641.94% |                47.24% | 3.2e-07 |      20 |
 | Config::IOD::INI::Reader |      2600 |     0.38  |               666.95% |                42.44% | 5.7e-07 |      20 |
 | Config::INI::Tiny        |      3750 |     0.267 |               992.43% |                 0.00% | 2.3e-07 |      20 |
 +--------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

           Rate   C:I   C:T  CI:R  CS:C  CII:R  CI:T 
  C:I     343/s    --  -75%  -76%  -86%   -86%  -90% 
  C:T    1400/s  306%    --   -2%  -45%   -46%  -62% 
  CI:R   1440/s  318%    2%    --  -43%   -45%  -61% 
  CS:C   2550/s  640%   81%   77%    --    -3%  -32% 
  CII:R  2600/s  665%   88%   83%    3%     --  -29% 
  CI:T   3750/s  989%  167%  160%   47%    42%    -- 
 
 Legends:
   C:I: participant=Config::IniFiles
   C:T: participant=Config::Tiny
   CI:R: participant=Config::INI::Reader
   CI:T: participant=Config::INI::Tiny
   CII:R: participant=Config::IOD::INI::Reader
   CS:C: participant=Config::Simple::Conf

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m INIParsingModules --module-startup

Result formatted as table:

 #table2#
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant              | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Config::IniFiles         |      25   |              22.2 |                 0.00% |               804.11% | 2.8e-05 |      20 |
 | Config::INI::Reader      |      16   |              13.2 |                54.78% |               484.14% | 8.8e-05 |      20 |
 | Config::IOD::INI::Reader |       9.3 |               6.5 |               169.29% |               235.74% | 3.8e-05 |      21 |
 | Config::Simple::Conf     |       7.7 |               4.9 |               223.96% |               179.08% | 6.1e-05 |      21 |
 | Config::INI::Tiny        |       7.3 |               4.5 |               243.23% |               163.41% | 9.7e-06 |      20 |
 | Config::Tiny             |       4   |               1.2 |               530.17% |                43.47% | 3.7e-05 |      26 |
 | perl -e1 (baseline)      |       2.8 |               0   |               804.11% |                 0.00% | 1.1e-05 |      20 |
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate   C:I  CI:R  CII:R  CS:C  CI:T   C:T  perl -e1 (baseline) 
  C:I                   40.0/s    --  -36%   -62%  -69%  -70%  -84%                 -88% 
  CI:R                  62.5/s   56%    --   -41%  -51%  -54%  -75%                 -82% 
  CII:R                107.5/s  168%   72%     --  -17%  -21%  -56%                 -69% 
  CS:C                 129.9/s  224%  107%    20%    --   -5%  -48%                 -63% 
  CI:T                 137.0/s  242%  119%    27%    5%    --  -45%                 -61% 
  C:T                  250.0/s  525%  300%   132%   92%   82%    --                 -30% 
  perl -e1 (baseline)  357.1/s  792%  471%   232%  175%  160%   42%                   -- 
 
 Legends:
   C:I: mod_overhead_time=22.2 participant=Config::IniFiles
   C:T: mod_overhead_time=1.2 participant=Config::Tiny
   CI:R: mod_overhead_time=13.2 participant=Config::INI::Reader
   CI:T: mod_overhead_time=4.5 participant=Config::INI::Tiny
   CII:R: mod_overhead_time=6.5 participant=Config::IOD::INI::Reader
   CS:C: mod_overhead_time=4.9 participant=Config::Simple::Conf
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-INIParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-INIParsingModules>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-INIParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

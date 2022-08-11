package Bencher::Scenario::INIParsingModules;

use 5.010001;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-10'; # DATE
our $DIST = 'Bencher-Scenario-INIParsingModules'; # DIST
our $VERSION = '0.002'; # VERSION

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
            code_template => 'Config::INI::Tiny->new->to_hash(do { local $/; open my $fh, "<", <filename> or die; scalar readline($fh) } )',
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

This document describes version 0.002 of Bencher::Scenario::INIParsingModules (from Perl distribution Bencher-Scenario-INIParsingModules), released on 2022-08-10.

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

L<Config::INI::Reader> 0.025

L<Config::INI::Tiny> 0.105

L<Config::IOD::INI::Reader> 0.345

L<Config::IniFiles> 3.000003

L<Config::Simple::Conf> 2.006

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

 Config::INI::Tiny->new->to_hash(do { local $/; open my $fh, "<", <filename> or die; scalar readline($fh) } )



=back

=head1 BENCHMARK DATASETS

=over

=item * extra-bench-basic-compat.ini

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m INIParsingModules >>):

 #table1#
 +--------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant              | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Config::IniFiles         |       262 |     3.81  |                 0.00% |               999.44% | 3.1e-06 |      20 |
 | Config::INI::Reader      |      1100 |     0.93  |               308.82% |               168.93% | 9.6e-07 |      20 |
 | Config::Simple::Conf     |      1800 |     0.55  |               592.50% |                58.76% | 6.9e-07 |      20 |
 | Config::IOD::INI::Reader |      1940 |     0.516 |               639.37% |                48.70% | 4.3e-07 |      20 |
 | Config::INI::Tiny        |      2900 |     0.35  |               999.44% |                 0.00% | 4.2e-07 |      21 |
 +--------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

           Rate   C:I  CI:R  CS:C  CII:R  CI:T 
  C:I     262/s    --  -75%  -85%   -86%  -90% 
  CI:R   1100/s  309%    --  -40%   -44%  -62% 
  CS:C   1800/s  592%   69%    --    -6%  -36% 
  CII:R  1940/s  638%   80%    6%     --  -32% 
  CI:T   2900/s  988%  165%   57%    47%    -- 
 
 Legends:
   C:I: participant=Config::IniFiles
   CI:R: participant=Config::INI::Reader
   CI:T: participant=Config::INI::Tiny
   CII:R: participant=Config::IOD::INI::Reader
   CS:C: participant=Config::Simple::Conf

Benchmark module startup overhead (C<< bencher -m INIParsingModules --module-startup >>):

 #table2#
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant              | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Config::IniFiles         |      35   |              28.6 |                 0.00% |               447.31% | 5.1e-05 |      20 |
 | Config::INI::Reader      |      22   |              15.6 |                54.81% |               253.54% | 3.3e-05 |      20 |
 | Config::IOD::INI::Reader |      13   |               6.6 |               166.37% |               105.47% | 1.5e-05 |      20 |
 | Config::INI::Tiny        |      12   |               5.6 |               185.94% |                91.41% | 1.4e-05 |      20 |
 | Config::Simple::Conf     |      12   |               5.6 |               187.40% |                90.43% | 1.3e-05 |      21 |
 | perl -e1 (baseline)      |       6.4 |               0   |               447.31% |                 0.00% | 1.9e-05 |      20 |
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   C:I  CI:R  CII:R  CI:T  CS:C  perl -e1 (baseline) 
  C:I                   28.6/s    --  -37%   -62%  -65%  -65%                 -81% 
  CI:R                  45.5/s   59%    --   -40%  -45%  -45%                 -70% 
  CII:R                 76.9/s  169%   69%     --   -7%   -7%                 -50% 
  CI:T                  83.3/s  191%   83%     8%    --    0%                 -46% 
  CS:C                  83.3/s  191%   83%     8%    0%    --                 -46% 
  perl -e1 (baseline)  156.2/s  446%  243%   103%   87%   87%                   -- 
 
 Legends:
   C:I: mod_overhead_time=28.6 participant=Config::IniFiles
   CI:R: mod_overhead_time=15.6 participant=Config::INI::Reader
   CI:T: mod_overhead_time=5.6 participant=Config::INI::Tiny
   CII:R: mod_overhead_time=6.6 participant=Config::IOD::INI::Reader
   CS:C: mod_overhead_time=5.6 participant=Config::Simple::Conf
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

This software is copyright (c) 2022, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-INIParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

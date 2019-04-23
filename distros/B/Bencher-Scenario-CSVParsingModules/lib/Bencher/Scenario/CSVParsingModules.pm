package Bencher::Scenario::CSVParsingModules;

our $DATE = '2019-04-23'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);

our $scenario = {
    summary => 'Benchmark CSV parsing modules',
    modules => {
        # minimum versions
        #'Foo' => {version=>'0.31'},
    },
    participants => [
        {
            module => 'Text::CSV_PP',
            code_template => 'my $csv = Text::CSV_PP->new({binary=>1}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }',
        },
        {
            module => 'Text::CSV_XS',
            code_template => 'my $csv = Text::CSV_XS->new({binary=>1}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }',
        },
        {
            name => 'naive-split',
            code_template => 'open my $fh, "<", <filename>; my $rows = []; while (defined(my $row = <$fh>)) { chomp $row; push @$rows, [split /,/, $row] }',
        },
    ],

    datasets => [
    ],
};

my $dir = dist_dir('CSV-Examples')
    or die "Can't find share dir for CSV-Examples";
for my $filename (glob "$dir/examples/*bench*.csv") {
    my $basename = $filename; $basename =~ s!.+/!!;
    push @{ $scenario->{datasets} }, {
        name => $basename,
        args => {filename => $filename},
    };
}

1;
# ABSTRACT: Benchmark CSV parsing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CSVParsingModules - Benchmark CSV parsing modules

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::CSVParsingModules (from Perl distribution Bencher-Scenario-CSVParsingModules), released on 2019-04-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CSVParsingModules

To run module startup overhead benchmark:

 % bencher --module-startup -m CSVParsingModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::CSV_PP> 1.95

L<Text::CSV_XS> 1.31

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::CSV_PP (perl_code)

Code template:

 my $csv = Text::CSV_PP->new({binary=>1}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }



=item * Text::CSV_XS (perl_code)

Code template:

 my $csv = Text::CSV_XS->new({binary=>1}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }



=item * naive-split (perl_code)

Code template:

 open my $fh, "<", <filename>; my $rows = []; while (defined(my $row = <$fh>)) { chomp $row; push @$rows, [split /,/, $row] }



=back

=head1 BENCHMARK DATASETS

=over

=item * bench-100x100.csv

=item * bench-10x10.csv

=item * bench-1x1.csv

=item * bench-5x5.csv

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m CSVParsingModules >>):

 #table1#
 +--------------+-------------------+-----------+-----------+------------+---------+---------+
 | participant  | dataset           | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +--------------+-------------------+-----------+-----------+------------+---------+---------+
 | Text::CSV_PP | bench-100x100.csv |        15 |   65      |          1 | 8.1e-05 |      20 |
 | Text::CSV_XS | bench-100x100.csv |       460 |    2.2    |         30 | 5.7e-06 |      21 |
 | naive-split  | bench-100x100.csv |       460 |    2.2    |         30 | 3.8e-06 |      20 |
 | Text::CSV_PP | bench-10x10.csv   |       960 |    1      |         63 | 3.6e-06 |      20 |
 | Text::CSV_PP | bench-5x5.csv     |      2540 |    0.394  |        166 | 2.1e-07 |      20 |
 | Text::CSV_PP | bench-1x1.csv     |      6700 |    0.15   |        440 | 4.3e-07 |      20 |
 | Text::CSV_XS | bench-10x10.csv   |     11000 |    0.088  |        750 | 1.1e-07 |      20 |
 | Text::CSV_XS | bench-5x5.csv     |     17000 |    0.06   |       1100 |   8e-08 |      20 |
 | Text::CSV_XS | bench-1x1.csv     |     22100 |    0.0453 |       1440 | 1.3e-08 |      20 |
 | naive-split  | bench-10x10.csv   |     25000 |    0.04   |       1600 | 5.3e-08 |      20 |
 | naive-split  | bench-5x5.csv     |     51000 |    0.019  |       3400 | 1.4e-07 |      20 |
 | naive-split  | bench-1x1.csv     |     99000 |    0.01   |       6500 | 2.9e-08 |      21 |
 +--------------+-------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m CSVParsingModules --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Text::CSV_PP        |      27   |                   20.3 |       1    | 8.9e-05 |      20 |
 | Text::CSV_XS        |      24   |                   17.3 |       1.12 | 2.2e-05 |      20 |
 | perl -e1 (baseline) |       6.7 |                    0   |       4    | 4.9e-05 |      22 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-CSVParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-CSVParsingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-CSVParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

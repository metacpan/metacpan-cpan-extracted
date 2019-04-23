package Bencher::Scenario::TSVParsingModules;

our $DATE = '2019-04-23'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);

our $scenario = {
    summary => 'Benchmark TSV parsing modules',
    modules => {
        # minimum versions
        #'Foo' => {version=>'0.31'},
    },
    participants => [
        {
            module => 'Text::CSV_PP',
            code_template => 'my $csv = Text::CSV_PP->new({binary=>1, sep_char=>"\t", quote_char=>undef, escape_char=>undef}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }',
        },
        {
            module => 'Text::CSV_XS',
            code_template => 'my $csv = Text::CSV_XS->new({binary=>1, sep_char=>"\t", quote_char=>undef, escape_char=>undef}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }',
        },
        {
            name => 'naive-split',
            code_template => 'open my $fh, "<", <filename>; my $rows = []; while (defined(my $row = <$fh>)) { chomp $row; push @$rows, [split /\t/, $row] }',
        },
    ],

    datasets => [
    ],
};

my $dir = dist_dir('TSV-Examples')
    or die "Can't find share dir for TSV-Examples";
for my $filename (glob "$dir/examples/*bench*.tsv") {
    my $basename = $filename; $basename =~ s!.+/!!;
    push @{ $scenario->{datasets} }, {
        name => $basename,
        args => {filename => $filename},
    };
}

1;
# ABSTRACT: Benchmark TSV parsing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TSVParsingModules - Benchmark TSV parsing modules

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::TSVParsingModules (from Perl distribution Bencher-Scenario-TSVParsingModules), released on 2019-04-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TSVParsingModules

To run module startup overhead benchmark:

 % bencher --module-startup -m TSVParsingModules

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

 my $csv = Text::CSV_PP->new({binary=>1, sep_char=>"\t", quote_char=>undef, escape_char=>undef}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }



=item * Text::CSV_XS (perl_code)

Code template:

 my $csv = Text::CSV_XS->new({binary=>1, sep_char=>"\t", quote_char=>undef, escape_char=>undef}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }



=item * naive-split (perl_code)

Code template:

 open my $fh, "<", <filename>; my $rows = []; while (defined(my $row = <$fh>)) { chomp $row; push @$rows, [split /\t/, $row] }



=back

=head1 BENCHMARK DATASETS

=over

=item * bench-100x100.tsv

=item * bench-10x10.tsv

=item * bench-1x1.tsv

=item * bench-5x5.tsv

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m TSVParsingModules >>):

 #table1#
 +--------------+-------------------+-----------+-----------+------------+---------+---------+
 | participant  | dataset           | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +--------------+-------------------+-----------+-----------+------------+---------+---------+
 | Text::CSV_PP | bench-100x100.tsv |      15.3 |    65.5   |          1 | 3.9e-05 |      20 |
 | Text::CSV_XS | bench-100x100.tsv |     450   |     2.2   |         29 | 2.9e-06 |      20 |
 | naive-split  | bench-100x100.tsv |     450   |     2.2   |         29 |   4e-06 |      20 |
 | Text::CSV_PP | bench-10x10.tsv   |     960   |     1     |         63 | 1.5e-06 |      20 |
 | Text::CSV_PP | bench-5x5.tsv     |    2400   |     0.42  |        160 | 6.4e-07 |      20 |
 | Text::CSV_PP | bench-1x1.tsv     |    6400   |     0.16  |        420 | 4.3e-07 |      20 |
 | Text::CSV_XS | bench-10x10.tsv   |   11000   |     0.093 |        710 | 2.1e-07 |      20 |
 | Text::CSV_XS | bench-5x5.tsv     |   15000   |     0.066 |        990 | 1.1e-07 |      20 |
 | Text::CSV_XS | bench-1x1.tsv     |   19200   |     0.052 |       1260 | 2.6e-08 |      21 |
 | naive-split  | bench-10x10.tsv   |   25000   |     0.04  |       1600 | 4.9e-08 |      24 |
 | naive-split  | bench-5x5.tsv     |   53000   |     0.019 |       3500 | 2.7e-08 |      20 |
 | naive-split  | bench-1x1.tsv     |   99000   |     0.01  |       6500 | 1.3e-08 |      21 |
 +--------------+-------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m TSVParsingModules --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+-----------+------------------------+------------+-----------+---------+
 | Text::CSV_PP        |      27   |                   20.9 |        1   | 4.3e-05   |      20 |
 | Text::CSV_XS        |      24   |                   17.9 |        1.1 |   0.00013 |      21 |
 | perl -e1 (baseline) |       6.1 |                    0   |        4.4 | 4.6e-05   |      20 |
 +---------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-TSVParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-TSVParsingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-TSVParsingModules>

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

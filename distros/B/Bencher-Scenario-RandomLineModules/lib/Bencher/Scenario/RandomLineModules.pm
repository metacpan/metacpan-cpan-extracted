package Bencher::Scenario::RandomLineModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

sub _create_file {
    my ($num_lines) = @_;

    require File::Temp;
    my ($fh, $filename) = File::Temp::tempfile();
    for (1..$num_lines) {
        print $fh sprintf("%049d\n", $_);
    }
    $filename;
}

our $scenario = {
    summary => 'Benchmark modules which pick random line(s) from a file',
    participants => [
        {
            fcall_template => 'File::Random::Pick::random_line(<filename>)',
        },
        {
            module => 'File::RandomLine',
            code_template => 'my $rl = File::RandomLine->new(<filename>); $rl->next',
        },
    ],

    datasets => [
        {name=>'1k_line'  , _lines=>1_000     , args=>{filename=>undef}},
        {name=>'10k_line' , _lines=>10_000    , args=>{filename=>undef}},
        {name=>'100k_line', _lines=>100_000   , args=>{filename=>undef}, include_by_default=>0},
        {name=>'1M_line'  , _lines=>1_000_000 , args=>{filename=>undef}, include_by_default=>0},
        {name=>'10M_line' , _lines=>10_000_000, args=>{filename=>undef}, include_by_default=>0},
    ],

    before_gen_items => sub {
        my %args = @_;
        my $sc    = $args{scenario};

        my $dss = $sc->{datasets};
        for my $ds (@$dss) {
            $log->infof("Creating temporary file with %d lines ...", $ds->{_lines});
            my $filename = _create_file($ds->{_lines});
            $log->infof("Created file %s", $filename);
            $ds->{args}{filename} = $filename;
        }
    },

    before_return => sub {
        my %args = @_;
        my $sc    = $args{scenario};

        my $dss = $sc->{datasets};
        for my $ds (@$dss) {
            my $filename = $ds->{args}{filename};
            next unless $filename;
            $log->infof("Unlinking %s", $filename);
            unlink $filename;
        }
    },
};

1;
# ABSTRACT: Benchmark modules which pick random line(s) from a file

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RandomLineModules - Benchmark modules which pick random line(s) from a file

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::RandomLineModules (from Perl distribution Bencher-Scenario-RandomLineModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RandomLineModules

To run module startup overhead benchmark:

 % bencher --module-startup -m RandomLineModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::Random::Pick> 0.02

L<File::RandomLine> 0.20

=head1 BENCHMARK PARTICIPANTS

=over

=item * File::Random::Pick::random_line (perl_code)

Function call template:

 File::Random::Pick::random_line(<filename>)



=item * File::RandomLine (perl_code)

Code template:

 my $rl = File::RandomLine->new(<filename>); $rl->next



=back

=head1 BENCHMARK DATASETS

=over

=item * 1k_line

=item * 10k_line

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RandomLineModules >>):

 #table1#
 +---------------------------------+----------+-----------+-----------+------------+---------+---------+
 | participant                     | dataset  | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------------------+----------+-----------+-----------+------------+---------+---------+
 | File::Random::Pick::random_line | 10k_line |       450 |     2.2   |       1    | 5.1e-06 |      20 |
 | File::Random::Pick::random_line | 1k_line  |      4340 |     0.23  |       9.76 | 2.1e-07 |      20 |
 | File::RandomLine                | 1k_line  |     95000 |     0.011 |     210    | 1.3e-08 |      20 |
 | File::RandomLine                | 10k_line |     95000 |     0.01  |     210    | 2.6e-08 |      21 |
 +---------------------------------+----------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m RandomLineModules --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | File::RandomLine    | 0.82                         | 4                  | 16             |      15   |                    9.2 |        1   | 9.9e-05 |      21 |
 | File::Random::Pick  | 1.6                          | 5                  | 19             |       9   |                    3.2 |        1.6 | 5.1e-05 |      20 |
 | perl -e1 (baseline) | 0.93                         | 4.3                | 16             |       5.8 |                    0   |        2.5 | 2.4e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-RandomLineModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-RandomLineModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-RandomLineModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

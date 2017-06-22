package Bencher::Scenario::Glob;

our $DATE = '2017-06-11'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Cwd qw(getcwd);

our $scenario = {
    summary => 'Benchmark glob()',
    participants => [
        {
            name => 'glob',
            code_template => 'my @res = glob(<pattern>); scalar @res',
        },
    ],

    datasets => [
        {name=>'1_10k'  , result =>     1, args=>{pattern => '000[1]'}},
        {name=>'10_10k' , result =>    10, args=>{pattern => '000*'}},
        {name=>'100_10k', result =>   100, args=>{pattern => '00*'}},
        {name=>'1k_10k' , result =>  1000, args=>{pattern => '0*'}},
        {name=>'10k_10k', result => 10_000, args=>{pattern => '*'}},
    ],

    before_gen_items => sub {
        require File::Temp;

        my %args = @_;

        my $dir = File::Temp::tempdir(CLEANUP => 1);
        $args{stash}{dir} = $dir;
        for my $i (0..9999) {
            my $f = sprintf("%04d", $i);
            open my $fh, ">", "$dir/$f" or die "Can't create $f: $!";
        }
    },

    before_bench => sub {
        my %args = @_;
        $args{stash}{prev_dir} = getcwd();
        my $dir = $args{stash}{dir};
        chdir $dir or die "Can't chdir to tempdir '$dir': $!";
    },

    after_bench => sub {
        my %args = @_;
        my $dir = $args{stash}{prev_dir};
        chdir $dir or die "Can't chdir back to '$dir': $!";
    },
};

1;
# ABSTRACT: Benchmark glob()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Glob - Benchmark glob()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Glob (from Perl distribution Bencher-Scenario-Glob), released on 2017-06-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Glob

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * glob (perl_code)

Code template:

 my @res = glob(<pattern>); scalar @res



=back

=head1 BENCHMARK DATASETS

=over

=item * 1_10k

=item * 10_10k

=item * 100_10k

=item * 1k_10k

=item * 10k_10k

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.5 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m Glob >>):

 #table1#
 +---------+-----------+-----------+------------+---------+---------+
 | dataset | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------+-----------+-----------+------------+---------+---------+
 | 10k_10k |       110 |      8.8  |       1    | 2.6e-05 |      20 |
 | 1k_10k  |       374 |      2.67 |       3.29 | 4.3e-07 |      20 |
 | 100_10k |       494 |      2.03 |       4.34 | 4.3e-07 |      20 |
 | 10_10k  |       510 |      1.96 |       4.48 | 2.1e-07 |      20 |
 | 1_10k   |       512 |      1.95 |       4.5  | 2.7e-07 |      20 |
 +---------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Glob>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Glob>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Glob>

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

package Bencher::Scenario::TOMLParsingModules;

our $DATE = '2019-04-09'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);

our $scenario = {
    summary => 'Benchmark TOML parsing modules',
    modules => {
        # minimum versions
    },
    extra_modules => ['File::Slurper'],
    participants => [
        {
            module => 'TOML',
            code_template => 'TOML::from_toml(File::Slurper::read_text(<filename>))',
        },
        {
            module => 'TOML::Parser',
            code_template => 'state $parser = TOML::Parser->new; $parser->parse(File::Slurper::read_text(<filename>))',
        },
    ],

    datasets => [
    ],
};

my $dir = dist_dir('TOML-Examples')
    or die "Can't find share dir for TOML-Examples";
for my $filename (glob "$dir/examples/iod/extra-bench-*.toml") {
    my $basename = $filename; $basename =~ s!.+/!!;
    push @{ $scenario->{datasets} }, {
        name => $basename,
        args => {filename => $filename},
    };
}

1;
# ABSTRACT: Benchmark TOML parsing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TOMLParsingModules - Benchmark TOML parsing modules

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::TOMLParsingModules (from Perl distribution Bencher-Scenario-TOMLParsingModules), released on 2019-04-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TOMLParsingModules

To run module startup overhead benchmark:

 % bencher --module-startup -m TOMLParsingModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<TOML> 0.97

L<TOML::Parser> 0.91

=head1 BENCHMARK PARTICIPANTS

=over

=item * TOML (perl_code)

Code template:

 TOML::from_toml(File::Slurper::read_text(<filename>))



=item * TOML::Parser (perl_code)

Code template:

 state $parser = TOML::Parser->new; $parser->parse(File::Slurper::read_text(<filename>))



=back

=head1 BENCHMARK DATASETS

=over

=item * extra-bench-typical1.toml

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m TOMLParsingModules >>):

 #table1#
 +--------------+-----------+-----------+------------+---------+---------+
 | participant  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------+-----------+-----------+------------+---------+---------+
 | TOML::Parser |       770 |      1300 |          1 | 3.2e-06 |      20 |
 | TOML         |       780 |      1300 |          1 |   2e-06 |      20 |
 +--------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m TOMLParsingModules --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | TOML                |      30   |                   25.1 |        1   | 9.1e-05 |      20 |
 | TOML::Parser        |      24   |                   19.1 |        1.3 | 6.2e-05 |      20 |
 | perl -e1 (baseline) |       4.9 |                    0   |        6.2 | 2.3e-05 |      21 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-TOMLParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-TOMLParsingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-TOMLParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

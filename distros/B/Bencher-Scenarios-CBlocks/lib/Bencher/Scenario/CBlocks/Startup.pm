package Bencher::Scenario::CBlocks::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of C::Blocks compared to plain perl',
    modules => {
    },
    participants => [
        {
            name => 'perl',
            perl_cmdline=>["-Mstrict", "-Mwarnings", "-e1"],
        },
        {
            name => 'load_cblocks',
            perl_cmdline=>["-Mstrict", "-Mwarnings", "-MC::Blocks", "-e1"]},
        {
            name => 'load_cblocks_perlapi_types',
            perl_cmdline=>["-Mstrict", "-Mwarnings", "-MC::Blocks", "-MC::Blocks::PerlAPI", "-MC::Blocks::Types=uint", "-e", 'my uint $foo=0; cblock { $foo=5; }'],
            description => <<'_',

This is "some idea for the minimal cost of really using C::Blocks".

_
        },
    ],
};

1;
# ABSTRACT: Benchmark startup of C::Blocks compared to plain perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CBlocks::Startup - Benchmark startup of C::Blocks compared to plain perl

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::CBlocks::Startup (from Perl distribution Bencher-Scenarios-CBlocks), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CBlocks::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (command)



=item * load_cblocks (command)



=item * load_cblocks_perlapi_types (command)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m CBlocks::Startup >>):

 #table1#
 +----------------------------+-----------+-----------+------------+-----------+---------+
 | participant                | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +----------------------------+-----------+-----------+------------+-----------+---------+
 | load_cblocks_perlapi_types |        25 |      40   |        1   |   0.00011 |      21 |
 | load_cblocks               |        43 |      23   |        1.7 |   0.0001  |      21 |
 | perl                       |       120 |       8.2 |        4.9 | 3.9e-05   |      20 |
 +----------------------------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-CBlocks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-CBlocks>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-CBlocks>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

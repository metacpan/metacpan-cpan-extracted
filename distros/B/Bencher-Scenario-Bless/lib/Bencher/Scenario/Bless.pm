package Bencher::Scenario::Bless;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark bless() and unblessing',

    participants => [
        {name=>'bless-hashref-same'          , code_template=>'state $ref = {}; bless($ref, "Foo")'},
        {name=>'bless-hashref-different'     , code_template=>'bless({}, "Foo")'},
        {name=>'bless-damn-hashref-different', module => 'Acme::Damn', code_template=>'Acme::Damn::damn(bless({}, "Foo"))'},
    ],
};

1;
# ABSTRACT: Benchmark bless() and unblessing

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Bless - Benchmark bless() and unblessing

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Bless (from Perl distribution Bencher-Scenario-Bless), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Bless

To run module startup overhead benchmark:

 % bencher --module-startup -m Bless

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Acme::Damn> 0.08

=head1 BENCHMARK PARTICIPANTS

=over

=item * bless-hashref-same (perl_code)

Code template:

 state $ref = {}; bless($ref, "Foo")



=item * bless-hashref-different (perl_code)

Code template:

 bless({}, "Foo")



=item * bless-damn-hashref-different (perl_code)

Code template:

 Acme::Damn::damn(bless({}, "Foo"))



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Bless >>):

 #table1#
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | bless-damn-hashref-different |   6414180 |   155.905 |    1       |   0     |      20 |
 | bless-hashref-different      |   8572170 |   116.657 |    1.33644 |   0     |      20 |
 | bless-hashref-same           |  15300000 |    65.3   |    2.39    | 4.4e-11 |      28 |
 +------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m Bless --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Acme::Damn          | 840                          | 4.2                | 16             |      11   |                    5.6 |          1 | 2.4e-05 |      20 |
 | perl -e1 (baseline) | 844                          | 4.2                | 16             |       5.4 |                    0   |          2 | 9.8e-06 |      21 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Bless>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Bless>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Bless>

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

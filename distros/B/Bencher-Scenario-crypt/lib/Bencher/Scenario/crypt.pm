package Bencher::Scenario::crypt;

our $DATE = '2016-01-21'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various algorithms of crypt()',
    on_failure => 'skip',
    participants => [
        {
            name => 'crypt',
            code_template => 'state $i = 0; my $c = crypt(++$i, <salt>); die "crypt fails/unsupported" unless $c; $c',
        }
    ],
    datasets => [
        {name=>'des', args=>{salt=>'aa'}},
        {name=>'md5-crypt', args=>{salt=>'$1$12345678$'}},

        {name=>'bcrypt-8', args=>{salt=>'$2b$8$1234567890123456789012$'}},
        {name=>'bcrypt-10', args=>{salt=>'$2b$10$1234567890123456789012$'}},
        {name=>'bcrypt-12', args=>{salt=>'$2b$12$1234567890123456789012$'}},
        {name=>'bcrypt-14', args=>{salt=>'$2b$14$1234567890123456789012$'}},

        {name=>'ssha256-5k', args=>{salt=>'$5$rounds=5000$1234567890123456$'}},
        {name=>'ssha256-50k', args=>{salt=>'$5$rounds=50000$1234567890123456$'}},
        {name=>'ssha256-500k', args=>{salt=>'$5$rounds=500000$1234567890123456$'}},

        {name=>'ssha512-5k', args=>{salt=>'$6$rounds=5000$1234567890123456$'}},
        {name=>'ssha512-50k', args=>{salt=>'$6$rounds=50000$1234567890123456$'}},
        {name=>'ssha512-500k', args=>{salt=>'$6$rounds=500000$1234567890123456$'}},
    ],
};

1;
# ABSTRACT: Benchmark various algorithms of crypt()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::crypt - Benchmark various algorithms of crypt()

=head1 VERSION

This document describes version 0.01 of Bencher::Scenario::crypt (from Perl distribution Bencher-Scenario-crypt), released on 2016-01-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m crypt

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * crypt (perl_code)

Code template:

 state $i = 0; my $c = crypt(++$i, <salt>); die "crypt fails/unsupported" unless $c; $c



=back

=head1 BENCHMARK DATASETS

=over

=item * des

=item * md5-crypt

=item * bcrypt-8

=item * bcrypt-10

=item * bcrypt-12

=item * bcrypt-14

=item * ssha256-5k

=item * ssha256-50k

=item * ssha256-500k

=item * ssha512-5k

=item * ssha512-50k

=item * ssha512-500k

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m crypt >>):

 +--------------+-----------+-----------+---------+---------+
 | dataset      | rate (/s) | time (ms) | errors  | samples |
 +--------------+-----------+-----------+---------+---------+
 | ssha512-500k | 2.85      | 351       | 0.00021 | 20      |
 | ssha256-500k | 3.61      | 277       | 0.00011 | 20      |
 | ssha512-50k  | 28.1      | 35.6      | 5.4e-05 | 20      |
 | ssha256-50k  | 36.3      | 27.5      | 3.2e-05 | 20      |
 | ssha512-5k   | 281       | 3.56      | 3.9e-06 | 21      |
 | ssha256-5k   | 364       | 2.75      | 4.9e-06 | 20      |
 | md5-crypt    | 5.92e+03  | 0.169     | 2.5e-07 | 23      |
 | des          | 2.4e+05   | 0.0041    | 3.5e-08 | 20      |
 +--------------+-----------+-----------+---------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-crypt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-crypt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-crypt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

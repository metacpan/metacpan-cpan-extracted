package Bencher::Scenario::EnsuringAllPatternsInString;

our $DATE = '2016-01-31'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

my @ajrand = qw(f e j b a i g d c h);
my @bjrand = qw(f e j b   i g d c h);

our $scenario = {
    summary => 'Ensuring all patterns are in a string',
    description => <<'_',

This scenario is inspired by <http://perlmonks.org/?node_id=1153410>. I want to
know how much faster/slower using the single regex with look-around assertions
is compared to using multiple regex.

As I expect, the single_re technique becomes exponentially slow as the number of
patterns and length of string increases.

_
    participants => [
        {
            name => 'single_re',
            summary => 'Uses look-around assertions',
            code_template => <<'_',
state $re = do {
    my $re = join "", map {"(?=.*?".quotemeta($_).")"} @{<patterns>};
    qr/$re/;
};
<string> =~ $re;
_
        },
        {
            name => 'multiple_re',
            code_template => <<'_',
state $re = [map {my $re=quotemeta; qr/$re/} @{<patterns>}];
for (@$re) { return 0 unless <string> =~ $_ }
1;
_
        },
    ],
    datasets => [
        {
            name => 'dataset',
            args => {
                'patterns@' => {
                    '2short'  => ['a','b'],
                    '5short'  => ['a'..'e'],
                    '10short' => ['a'..'j'],
                    '2long'   => [map {$_ x 20} 'a','b'],
                    '5long'   => [map {$_ x 20} 'a'..'e'],
                    '10long'  => [map {$_ x 20} 'a'..'j'],
                },
                'string@' => {
                    'match_short'    => join("", map {$_ x 20} @ajrand),
                    'match_medium'   => join("", map {$_ x 200} @ajrand),
                    'match_long'     => join("", map {$_ x 2000} @ajrand),
                    'nomatch_short'  => join("", map {$_ x 20} @bjrand),
                    'nomatch_medium' => join("", map {$_ x 200} @bjrand),
                    'nomatch_long'   => join("", map {$_ x 2000} @bjrand),
                },
            },
        },
    ],
};

1;
# ABSTRACT: Ensuring all patterns are in a string

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::EnsuringAllPatternsInString - Ensuring all patterns are in a string

=head1 VERSION

This document describes version 0.01 of Bencher::Scenario::EnsuringAllPatternsInString (from Perl distribution Bencher-Scenario-EnsuringAllPatternsInString), released on 2016-01-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m EnsuringAllPatternsInString

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * single_re (perl_code)

Uses look-around assertions.

Code template:

 state $re = do {
     my $re = join "", map {"(?=.*?".quotemeta($_).")"} @{<patterns>};
     qr/$re/;
 };
 <string> =~ $re;




=item * multiple_re (perl_code)

Code template:

 state $re = [map {my $re=quotemeta; qr/$re/} @{<patterns>}];
 for (@$re) { return 0 unless <string> =~ $_ }
 1;




=back

=head1 BENCHMARK DATASETS

=over

=item * dataset

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.0 >>, CPU: I<< Intel(R) Core(TM) i5-2557M CPU @ 1.70GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17 >>, OS kernel: I<< Linux version 3.13.0-32-generic >>.

Benchmark with default options (C<< bencher -m EnsuringAllPatternsInString >>):

 +-------------+--------------+----------------+-------------+-------------+---------+---------+
 | participant | arg_patterns | arg_string     | rate (/s)   | time (ms)   | errors  | samples |
 +-------------+--------------+----------------+-------------+-------------+---------+---------+
 | single_re   | 2long        | nomatch_long   | 7.9         | 1.3e+02     | 0.00017 | 20      |
 | single_re   | 10short      | nomatch_long   | 7.9         | 1.3e+02     | 0.00017 | 20      |
 | single_re   | 10long       | nomatch_long   | 7.93        | 126         | 6.1e-05 | 20      |
 | single_re   | 5long        | nomatch_long   | 7.99        | 125         | 3.2e-05 | 20      |
 | single_re   | 2short       | nomatch_long   | 7.99        | 125         | 3.4e-05 | 20      |
 | single_re   | 5short       | nomatch_long   | 8           | 125         | 2.2e-05 | 20      |
 | single_re   | 2long        | nomatch_medium | 7.2e+02     | 1.4         | 2.2e-06 | 20      |
 | single_re   | 2short       | nomatch_medium | 7.2e+02     | 1.4         | 2e-06   | 20      |
 | single_re   | 5long        | nomatch_medium | 722         | 1.38        | 1.3e-06 | 21      |
 | single_re   | 10long       | nomatch_medium | 7.2e+02     | 1.4         | 1.4e-06 | 20      |
 | single_re   | 5short       | nomatch_medium | 723         | 1.38        | 6.6e-07 | 22      |
 | single_re   | 10short      | nomatch_medium | 724         | 1.38        | 2.7e-07 | 20      |
 | single_re   | 10short      | match_long     | 6.48e+03    | 0.154       | 5.3e-08 | 20      |
 | single_re   | 10long       | match_long     | 7265.3      | 0.137641    | 1.8e-11 | 20      |
 | multiple_re | 10short      | match_long     | 1.4e+04     | 0.073       | 8e-08   | 20      |
 | single_re   | 5short       | match_long     | 1.41e+04    | 0.0707      | 2.7e-08 | 20      |
 | single_re   | 5long        | match_long     | 1.42e+04    | 0.0707      | 2.7e-08 | 20      |
 | multiple_re | 5short       | match_long     | 26746.6     | 0.037388    | 0       | 20      |
 | single_re   | 5long        | nomatch_short  | 3.2e+04     | 0.0313      | 1.2e-08 | 24      |
 | single_re   | 10short      | nomatch_short  | 35592       | 0.028096    | 9.2e-11 | 20      |
 | single_re   | 5short       | nomatch_short  | 35889.7     | 0.0278632   | 0       | 25      |
 | single_re   | 10long       | nomatch_short  | 35928.1     | 0.0278334   | 0       | 20      |
 | single_re   | 2short       | nomatch_short  | 3.6e+04     | 0.0278      | 1.3e-08 | 20      |
 | single_re   | 2long        | nomatch_short  | 3.6e+04     | 0.0278      | 1.3e-08 | 20      |
 | multiple_re | 10long       | match_long     | 4.1e+04     | 0.024       | 2.5e-08 | 22      |
 | single_re   | 2long        | match_long     | 4.55e+04    | 0.022       | 6.7e-09 | 20      |
 | single_re   | 2short       | match_long     | 4.55e+04    | 0.022       | 6.7e-09 | 20      |
 | multiple_re | 2short       | nomatch_long   | 62297.9     | 0.0160519   | 0       | 25      |
 | single_re   | 10long       | match_medium   | 6.59e+04    | 0.0152      | 6.4e-09 | 22      |
 | single_re   | 10short      | match_medium   | 6.59e+04    | 0.0152      | 5.6e-09 | 28      |
 | multiple_re | 10short      | nomatch_long   | 70080.2     | 0.0142694   | 0       | 21      |
 | multiple_re | 5short       | nomatch_long   | 70169.7     | 0.0142512   | 0       | 20      |
 | multiple_re | 5long        | match_long     | 7e+04       | 0.01        | 1.9e-07 | 20      |
 | multiple_re | 2short       | match_long     | 74256.9     | 0.0134668   | 0       | 38      |
 | multiple_re | 10short      | match_medium   | 8.5e+04     | 0.012       | 1.3e-08 | 20      |
 | single_re   | 5long        | match_medium   | 1.2e+05     | 0.0081      | 1e-08   | 20      |
 | single_re   | 5short       | match_medium   | 1.23e+05    | 0.00811     | 3.2e-09 | 22      |
 | multiple_re | 10long       | match_medium   | 1.34e+05    | 0.00745     | 3.3e-09 | 20      |
 | multiple_re | 5short       | match_medium   | 1.63e+05    | 0.00612     | 1.7e-09 | 20      |
 | multiple_re | 10short      | match_short    | 1.7e+05     | 0.006       | 2.1e-08 | 21      |
 | multiple_re | 10long       | match_short    | 1.8e+05     | 0.0055      | 1.4e-08 | 22      |
 | multiple_re | 2long        | nomatch_long   | 227527      | 0.00439508  | 0       | 30      |
 | multiple_re | 10long       | nomatch_long   | 227880      | 0.00438827  | 0       | 20      |
 | multiple_re | 5long        | nomatch_long   | 2.28e+05    | 0.00438     | 1.7e-09 | 20      |
 | multiple_re | 2long        | match_long     | 2.38e+05    | 0.0042      | 1.5e-09 | 25      |
 | multiple_re | 5long        | match_medium   | 265748      | 0.00376296  | 0       | 23      |
 | multiple_re | 5short       | match_short    | 3.3e+05     | 0.003       | 3.3e-09 | 21      |
 | single_re   | 2short       | match_medium   | 3.37e+05    | 0.00297     | 2.5e-09 | 20      |
 | single_re   | 2long        | match_medium   | 3.3937e+05  | 0.0029466   | 1.9e-11 | 20      |
 | multiple_re | 5long        | match_short    | 3e+05       | 0.003       | 3e-08   | 21      |
 | single_re   | 10long       | match_short    | 350707      | 0.00285138  | 0       | 20      |
 | single_re   | 10short      | match_short    | 3.56e+05    | 0.00281     | 2.5e-09 | 20      |
 | multiple_re | 2short       | match_medium   | 3.8e+05     | 0.0026      | 3.3e-09 | 21      |
 | multiple_re | 2short       | nomatch_medium | 4.5e+05     | 0.00222     | 8.3e-10 | 20      |
 | multiple_re | 5short       | nomatch_medium | 5.12e+05    | 0.00195     | 8.3e-10 | 20      |
 | multiple_re | 10short      | nomatch_medium | 513294      | 0.0019482   | 0       | 20      |
 | single_re   | 5short       | match_short    | 5.5e+05     | 0.0018      | 4.2e-09 | 20      |
 | single_re   | 5long        | match_short    | 5.6e+05     | 0.0018      | 2.5e-09 | 20      |
 | multiple_re | 2short       | match_short    | 635493      | 0.00157358  | 0       | 35      |
 | multiple_re | 2long        | match_medium   | 636004      | 0.00157232  | 0       | 20      |
 | multiple_re | 2long        | match_short    | 8e+05       | 0.0013      | 1.6e-09 | 23      |
 | multiple_re | 2long        | nomatch_medium | 9.2e+05     | 0.0011      | 1.7e-09 | 20      |
 | single_re   | 2short       | match_short    | 9.2e+05     | 0.0011      | 1.7e-09 | 20      |
 | single_re   | 2long        | match_short    | 9.5e+05     | 0.0011      | 1.2e-09 | 20      |
 | multiple_re | 10long       | nomatch_medium | 9.9e+05     | 0.001       | 7.1e-09 | 20      |
 | multiple_re | 5long        | nomatch_medium | 1e+06       | 0.00096     | 1.2e-09 | 20      |
 | multiple_re | 2short       | nomatch_short  | 1.16957e+06 | 0.000855018 | 0       | 22      |
 | multiple_re | 10short      | nomatch_short  | 1.3e+06     | 0.00075     | 1.2e-09 | 20      |
 | multiple_re | 5short       | nomatch_short  | 1.35e+06    | 0.000739    | 3.9e-10 | 23      |
 | multiple_re | 2long        | nomatch_short  | 1.5e+06     | 0.00069     | 1.7e-09 | 20      |
 | multiple_re | 10long       | nomatch_short  | 1.6e+06     | 0.00062     | 8.3e-10 | 20      |
 | multiple_re | 5long        | nomatch_short  | 1.7e+06     | 0.00058     | 8.3e-10 | 20      |
 +-------------+--------------+----------------+-------------+-------------+---------+---------+

=head1 DESCRIPTION

This scenario is inspired by <http://perlmonks.org/?node_id=1153410>. I want to
know how much faster/slower using the single regex with look-around assertions
is compared to using multiple regex.

As I expect, the single_re technique becomes exponentially slow as the number of
patterns and length of string increases.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-EnsuringAllPatternsInString>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-EnsuringAllPatternsInString>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-EnsuringAllPatternsInString>

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

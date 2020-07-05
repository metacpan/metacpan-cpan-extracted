package Bencher::Scenario::URIEscaping;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-18'; # DATE
our $DIST = 'Bencher-Scenario-URIEscaping'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use utf8;
use warnings;

# we do this so URI::XSEscape does not override URI::Escape's functions, because
# obviously we want to test both
$ENV{PERL_URI_XSESCAPE} = 0;

our $scenario = {
    summary => 'Benchmark URI escaping using various modules',

    precision => 0.001,
    module_startup_precision => 0.05,

    participants => [
        {fcall_template => 'URI::Escape::uri_escape(<str>)', tags=>['escape']},
        {fcall_template => 'URI::Escape::uri_escape_utf8(<str>)', tags=>['escape', 'utf8']},
        {fcall_template => 'URI::Escape::uri_unescape(<str>)', tags=>['unescape']},
        {fcall_template => 'URI::XSEscape::uri_escape(<str>)', tags=>['escape']},
        {fcall_template => 'URI::XSEscape::uri_escape_utf8(<str>)', tags=>['escape', 'utf8']},
        {fcall_template => 'URI::XSEscape::uri_unescape(<str>)', tags=>['unescape']},
        {fcall_template => 'URI::Escape::XS::uri_escape(<str>)', tags=>['escape']},
        #{fcall_template => 'URI::Escape::XS::uri_escape_utf8(<str>)', tags=>['escape', 'utf8']},
        {fcall_template => 'URI::Escape::XS::uri_unescape(<str>)', tags=>['unescape']},

        {fcall_template => 'URI::Encode::uri_encode(<str>)', tags=>['escape']},
        {fcall_template => 'URI::Encode::uri_decode(<str>)', tags=>['unescape']},
        {fcall_template => 'URI::Encode::XS::uri_encode(<str>)', tags=>['escape']},
        {fcall_template => 'URI::Encode::XS::uri_decode(<str>)', tags=>['unescape']},
    ],

    datasets => [
        {
            name => 'empty',
            tags => ['escape'],
            include_participant_tags => ['escape'],
            args => {str=>''},
        },
        # sample data from URI-XSEscape distribution
        {
            name => 'ascii53',
            tags => ['escape'],
            include_participant_tags => ['escape'],
            args => {str=>'I said this: you / them ~ us & me _will_ "do-it" NOW!'},
        },
        # sample data from URI-XSEscape distribution
        {
            name => 'utf36',
            tags => ['escape', 'utf8'],
            include_participant_tags => ['escape & utf8'],
            args => {str=>'http://www.google.co.jp/search?q=小飼弾'},
        },
        # sample data from URI-XSEscape distribution
        {
            name => 'u_ascii53',
            tags => ['unescape'],
            include_participant_tags => ['unescape'],
            args => {str=>'I%20said%20this%3a%20you%20%2f%20them%20~%20us%20%26%20me%20_will_%20%22do-it%22%20NOW%21'},
        },

        # sample data from URI-Escape-XS distribution
        {
            name => 'ascii66',
            tags => ['escape'],
            include_participant_tags => ['escape'],
            args => {str=>'https://stackoverflow.com/questions/3629212/how can perls xsub die'},
        },
        # sample data from URI-Escape-XS distribution
        {
            name => 'u_ascii66',
            tags => ['unescape'],
            include_participant_tags => ['unescape'],
            args => {str=>'https%3A%2F%2Fstackoverflow.com%2Fquestions%2F3629212%2Fhow%20can%20perls%20xsub%20die'},
        },
    ],
};

1;
# ABSTRACT: Benchmark URI escaping using various modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::URIEscaping - Benchmark URI escaping using various modules

=head1 VERSION

This document describes version 0.006 of Bencher::Scenario::URIEscaping (from Perl distribution Bencher-Scenario-URIEscaping), released on 2020-06-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m URIEscaping

To run module startup overhead benchmark:

 % bencher --module-startup -m URIEscaping

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<URI::Escape> 3.31

L<URI::XSEscape> 0.001000

L<URI::Escape::XS> 0.14

L<URI::Encode> 1.1.1

L<URI::Encode::XS> 0.11

=head1 BENCHMARK PARTICIPANTS

=over

=item * URI::Escape::uri_escape (perl_code) [escape]

Function call template:

 URI::Escape::uri_escape(<str>)



=item * URI::Escape::uri_escape_utf8 (perl_code) [escape, utf8]

Function call template:

 URI::Escape::uri_escape_utf8(<str>)



=item * URI::Escape::uri_unescape (perl_code) [unescape]

Function call template:

 URI::Escape::uri_unescape(<str>)



=item * URI::XSEscape::uri_escape (perl_code) [escape]

Function call template:

 URI::XSEscape::uri_escape(<str>)



=item * URI::XSEscape::uri_escape_utf8 (perl_code) [escape, utf8]

Function call template:

 URI::XSEscape::uri_escape_utf8(<str>)



=item * URI::XSEscape::uri_unescape (perl_code) [unescape]

Function call template:

 URI::XSEscape::uri_unescape(<str>)



=item * URI::Escape::XS::uri_escape (perl_code) [escape]

Function call template:

 URI::Escape::XS::uri_escape(<str>)



=item * URI::Escape::XS::uri_unescape (perl_code) [unescape]

Function call template:

 URI::Escape::XS::uri_unescape(<str>)



=item * URI::Encode::uri_encode (perl_code) [escape]

Function call template:

 URI::Encode::uri_encode(<str>)



=item * URI::Encode::uri_decode (perl_code) [unescape]

Function call template:

 URI::Encode::uri_decode(<str>)



=item * URI::Encode::XS::uri_encode (perl_code) [escape]

Function call template:

 URI::Encode::XS::uri_encode(<str>)



=item * URI::Encode::XS::uri_decode (perl_code) [unescape]

Function call template:

 URI::Encode::XS::uri_decode(<str>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty [escape]

=item * ascii53 [escape]

=item * utf36 [escape, utf8]

=item * u_ascii53 [unescape]

=item * ascii66 [escape]

=item * u_ascii66 [unescape]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with default options (C<< bencher -m URIEscaping >>):

 #table1#
 +--------------------------------+-----------+--------------+--------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | participant                    | dataset   | ds_tags      | p_tags       | rate (/s) | time (μs)  | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-----------+--------------+--------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | URI::Encode::uri_encode        | ascii53   | escape       | escape       |      3410 | 293        |                 0.00% |            982933.13% | 2.8e-07 |     104 |
 | URI::Encode::uri_decode        | u_ascii53 | unescape     | unescape     |      3480 | 288        |                 1.99% |            963720.81% | 2.1e-07 |      20 |
 | URI::Encode::uri_encode        | ascii66   | escape       | escape       |      3550 | 282        |                 4.00% |            945139.90% | 2.1e-07 |      20 |
 | URI::Encode::uri_decode        | u_ascii66 | unescape     | unescape     |      3550 | 282        |                 4.06% |            944547.08% | 2.4e-07 |      24 |
 | URI::Encode::uri_encode        | empty     | escape       | escape       |      3680 | 272        |                 7.92% |            910775.23% | 2.1e-07 |      20 |
 | URI::Escape::uri_escape        | ascii53   | escape       | escape       |    132879 |   7.52563  |              3796.93% |             25125.81% | 5.5e-12 |      20 |
 | URI::Escape::uri_escape_utf8   | ascii53   | escape       | escape, utf8 |    138000 |   7.27     |              3933.67% |             24270.69% |   3e-09 |      24 |
 | URI::Escape::uri_escape_utf8   | utf36     | escape, utf8 | escape, utf8 |    160000 |   6.1      |              4728.44% |             20259.23% | 6.1e-09 |      24 |
 | URI::Escape::uri_unescape      | u_ascii53 | unescape     | unescape     |    165285 |   6.05014  |              4747.31% |             20179.99% | 4.8e-12 |      22 |
 | URI::Escape::uri_escape_utf8   | ascii66   | escape       | escape, utf8 |    214000 |   4.67     |              6179.44% |             15554.80% | 4.6e-09 |      42 |
 | URI::Escape::uri_escape        | ascii66   | escape       | escape       |    226080 |   4.4232   |              6530.22% |             14726.55% | 5.7e-12 |      20 |
 | URI::Escape::uri_unescape      | u_ascii66 | unescape     | unescape     |    274380 |   3.64458  |              7946.72% |             12116.57% |   0     |      20 |
 | URI::Escape::uri_escape_utf8   | empty     | escape       | escape, utf8 |   1730000 |   0.576    |             50780.41% |              1832.05% | 5.7e-10 |      24 |
 | URI::Escape::uri_escape        | empty     | escape       | escape       |   2400610 |   0.41656  |             70302.45% |              1296.31% |   0     |      20 |
 | URI::Escape::XS::uri_escape    | ascii53   | escape       | escape       |   2440000 |   0.41     |             71373.22% |              1275.39% | 2.1e-10 |      20 |
 | URI::Escape::XS::uri_escape    | ascii66   | escape       | escape       |   2438740 |   0.410048 |             71420.59% |              1274.48% |   0     |      20 |
 | URI::XSEscape::uri_escape_utf8 | ascii66   | escape       | escape, utf8 |   2663000 |   0.3755   |             78006.67% |              1158.58% | 5.7e-12 |      25 |
 | URI::XSEscape::uri_escape_utf8 | ascii53   | escape       | escape, utf8 |   2726030 |   0.366834 |             79845.81% |              1129.62% |   0     |      20 |
 | URI::Escape::XS::uri_unescape  | u_ascii53 | unescape     | unescape     |   2900000 |   0.35     |             84295.89% |              1064.79% | 3.9e-10 |      23 |
 | URI::XSEscape::uri_escape_utf8 | utf36     | escape, utf8 | escape, utf8 |   2890000 |   0.346    |             84571.59% |              1061.00% |   3e-10 |      21 |
 | URI::Escape::XS::uri_escape    | empty     | escape       | escape       |   3000000 |   0.334    |             87784.28% |              1018.55% |   1e-10 |      20 |
 | URI::Escape::XS::uri_unescape  | u_ascii66 | unescape     | unescape     |   3187000 |   0.3138   |             93354.20% |               951.89% | 4.8e-12 |      20 |
 | URI::XSEscape::uri_escape_utf8 | empty     | escape       | escape, utf8 |   3800000 |   0.27     |            110522.39% |               788.64% | 3.1e-10 |      37 |
 | URI::XSEscape::uri_unescape    | u_ascii53 | unescape     | unescape     |   4852000 |   0.2061   |            142183.42% |               590.90% | 1.7e-11 |      20 |
 | URI::XSEscape::uri_unescape    | u_ascii66 | unescape     | unescape     |   4986000 |   0.2006   |            146111.46% |               572.34% | 5.8e-12 |      20 |
 | URI::XSEscape::uri_escape      | ascii66   | escape       | escape       |   5293000 |   0.1889   |            155112.72% |               533.35% | 5.5e-12 |      20 |
 | URI::XSEscape::uri_escape      | ascii53   | escape       | escape       |   5670000 |   0.176    |            166067.23% |               491.59% |   1e-10 |      21 |
 | URI::XSEscape::uri_escape      | empty     | escape       | escape       |   9980000 |   0.1      |            292476.83% |               235.99% | 5.2e-11 |      20 |
 | URI::Encode::XS::uri_decode    | u_ascii66 | unescape     | unescape     |  12000000 |   0.082    |            356094.65% |               175.98% | 1.2e-10 |      56 |
 | URI::Encode::XS::uri_encode    | ascii66   | escape       | escape       |  12550000 |   0.07966  |            368038.76% |               167.03% | 5.8e-12 |      20 |
 | URI::Encode::XS::uri_encode    | ascii53   | escape       | escape       |  13000000 |   0.075    |            389431.92% |               152.36% | 1.1e-10 |      45 |
 | URI::Encode::XS::uri_decode    | u_ascii53 | unescape     | unescape     |  13500000 |   0.07407  |            395844.46% |               148.28% | 5.7e-12 |      26 |
 | URI::Encode::XS::uri_encode    | empty     | escape       | escape       |  33500000 |   0.0298   |            982933.13% |                 0.00% | 4.9e-12 |      20 |
 +--------------------------------+-----------+--------------+--------------+-----------+------------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m URIEscaping --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | URI::Encode         |        17 |                12 |                 0.00% |               235.22% | 9.2e-05   |      20 |
 | URI::Escape::XS     |        10 |                 5 |                75.36% |                91.16% |   0.00033 |      20 |
 | URI::Escape         |         9 |                 4 |                85.44% |                80.77% |   0.00015 |      20 |
 | URI::XSEscape       |         8 |                 3 |               117.22% |                54.32% |   0.00018 |      22 |
 | URI::Encode::XS     |         7 |                 2 |               144.39% |                37.17% |   0.00014 |      20 |
 | perl -e1 (baseline) |         5 |                 0 |               235.22% |                 0.00% |   0.00016 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

L<URI::Encode::XS> is the fastest, but it does not support custom list of safe
characters. If you don't want to encode C</> as C<%2F>, for example, you're out
of luck. For URI escaping with custom character list support, the fastest is
L<URI::XSEscape> followed by L<URI::Escape::XS>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-URIEscaping>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-URIEscaping>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-URIEscaping>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

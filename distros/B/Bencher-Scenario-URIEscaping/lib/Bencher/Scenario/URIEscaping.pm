package Bencher::Scenario::URIEscaping;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.004'; # VERSION

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

This document describes version 0.004 of Bencher::Scenario::URIEscaping (from Perl distribution Bencher-Scenario-URIEscaping), released on 2017-01-25.

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

L<URI::XSEscape> 0.000008

L<URI::Escape::XS> 0.14

L<URI::Encode> 1.1.1

L<URI::Encode::XS> 0.09

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m URIEscaping >>):

 #table1#
 +--------------------------------+-----------+------------+------------+------------+---------+---------+
 | participant                    | dataset   | rate (/s)  | time (μs)  | vs_slowest |  errors | samples |
 +--------------------------------+-----------+------------+------------+------------+---------+---------+
 | URI::Encode::uri_encode        | empty     |     2510   | 398        |     1      |   4e-07 |      23 |
 | URI::Encode::uri_decode        | u_ascii53 |     2640   | 379        |     1.05   | 1.9e-07 |      25 |
 | URI::Encode::uri_encode        | ascii53   |     2640   | 378        |     1.05   | 2.6e-07 |      21 |
 | URI::Encode::uri_decode        | u_ascii66 |     2700   | 370        |     1.08   | 2.1e-07 |      20 |
 | URI::Encode::uri_encode        | ascii66   |     2720   | 368        |     1.08   | 2.1e-07 |      20 |
 | URI::Escape::uri_escape_utf8   | ascii53   |    84850.3 |  11.7855   |    33.7805 |   0     |      20 |
 | URI::Escape::uri_escape        | ascii53   |    97657.3 |  10.2399   |    38.8793 |   0     |      32 |
 | URI::Escape::uri_escape_utf8   | utf36     |   102000   |   9.8      |    40.6    | 3.1e-09 |      23 |
 | URI::Escape::uri_unescape      | u_ascii53 |   118000   |   8.46     |    47.1    | 8.4e-09 |      28 |
 | URI::Escape::uri_escape_utf8   | ascii66   |   142000   |   7.05     |    56.5    | 3.1e-09 |      23 |
 | URI::Escape::uri_escape        | ascii66   |   150000   |   6.7      |    59      | 6.8e-09 |      77 |
 | URI::Escape::uri_unescape      | u_ascii66 |   199000   |   5.02     |    79.3    | 1.7e-09 |      20 |
 | URI::Escape::uri_escape_utf8   | empty     |  1200000   |   0.85     |   470      | 8.9e-10 |      70 |
 | URI::Escape::XS::uri_escape    | ascii53   |  1542000   |   0.6484   |   614      | 1.1e-11 |      28 |
 | URI::Escape::XS::uri_escape    | ascii66   |  1700000   |   0.58     |   680      | 6.2e-10 |      36 |
 | URI::XSEscape::uri_escape_utf8 | ascii66   |  1710000   |   0.583    |   683      | 1.9e-10 |      23 |
 | URI::XSEscape::uri_escape_utf8 | ascii53   |  1800000   |   0.54     |   730      | 5.8e-10 |      41 |
 | URI::Escape::uri_escape        | empty     |  1920000   |   0.521    |   764      | 1.8e-10 |      26 |
 | URI::XSEscape::uri_escape_utf8 | utf36     |  1990000   |   0.502    |   793      | 2.1e-10 |      20 |
 | URI::Escape::XS::uri_escape    | empty     |  2136070   |   0.468149 |   850.412  |   0     |      27 |
 | URI::Escape::XS::uri_unescape  | u_ascii53 |  2140000   |   0.467    |   853      | 2.1e-10 |      20 |
 | URI::Escape::XS::uri_unescape  | u_ascii66 |  2210000   |   0.453    |   878      | 3.8e-10 |      95 |
 | URI::XSEscape::uri_escape_utf8 | empty     |  2400000   |   0.41     |   960      | 4.7e-10 |      64 |
 | URI::XSEscape::uri_escape      | ascii66   |  2851000   |   0.3508   |  1135      | 1.1e-11 |      20 |
 | URI::XSEscape::uri_unescape    | u_ascii53 |  3200000   |   0.31     |  1300      | 3.1e-10 |      20 |
 | URI::XSEscape::uri_unescape    | u_ascii66 |  3300000   |   0.31     |  1300      | 3.1e-10 |      20 |
 | URI::XSEscape::uri_escape      | ascii53   |  3403000   |   0.2939   |  1355      | 9.5e-12 |      20 |
 | URI::Encode::XS::uri_decode    | u_ascii66 |  5900000   |   0.17     |  2300      | 2.3e-10 |      65 |
 | URI::XSEscape::uri_escape      | empty     |  7099810   |   0.140849 |  2826.57   |   0     |      20 |
 | URI::Encode::XS::uri_decode    | u_ascii53 |  7190760   |   0.139067 |  2862.78   |   0     |      24 |
 | URI::Encode::XS::uri_encode    | ascii66   |  8700000   |   0.11     |  3500      | 1.8e-10 |      29 |
 | URI::Encode::XS::uri_encode    | ascii53   |  9100000   |   0.11     |  3600      | 1.3e-10 |      50 |
 | URI::Encode::XS::uri_encode    | empty     | 24900000   |   0.0402   |  9900      |   1e-11 |      21 |
 +--------------------------------+-----------+------------+------------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m URIEscaping --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | URI::Encode         | 1.07                         | 4.43               | 18.1           |     18.2  |                  12.82 |       1    | 1.8e-05 |     418 |
 | URI::Escape::XS     | 1.07                         | 4.41               | 18.1           |     11.6  |                   6.22 |       1.57 | 1.1e-05 |     494 |
 | URI::Escape         | 1.29                         | 4.56               | 16.4           |     11.4  |                   6.02 |       1.6  | 1.1e-05 |     664 |
 | URI::XSEscape       | 1.29                         | 4.62               | 16.4           |      9.82 |                   4.44 |       1.85 | 9.6e-06 |     406 |
 | URI::Encode::XS     | 1.07                         | 4.54               | 18.1           |      8.71 |                   3.33 |       2.09 | 8.5e-06 |      26 |
 | perl -e1 (baseline) | 1.29                         | 4.57               | 16.4           |      5.38 |                   0    |       3.38 | 5.4e-06 |     326 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

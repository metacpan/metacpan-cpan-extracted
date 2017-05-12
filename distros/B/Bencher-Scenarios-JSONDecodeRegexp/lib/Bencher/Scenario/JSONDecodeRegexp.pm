package Bencher::Scenario::JSONDecodeRegexp;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark JSON decoding',
    participants => [
        {
            fcall_template => 'JSON::Decode::Regexp::from_json(<data>)',
        },
        {
            module => 'JSON::PP',
            function => 'decode',
            code_template => 'state $json = JSON::PP->new->allow_nonref; $json->decode(<data>)',
        },
    ],
    datasets => [
        {name => 'str-a'   , args=>{data=>'"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345\f\r\b\t\r"'},
         summary => "a 100-character string with some escape sequences"},
        {name => 'array0'  , args=>{data=>'[]'}},
        {name => 'array1'  , args=>{data=>'[1]'}},
        {name => 'array10' , args=>{data=>'[1,2,3,4,5,6,7,8,9,10]'}},
        {name => 'array100', args=>{data=>'[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100]'}},
        {name => 'hash0'   , args=>{data=>'{}'}},
        {name => 'hash1'   , args=>{data=>'{"1":1}'}},
        {name => 'hash10'  , args=>{data=>'{"01":1,"02":1,"03":1,"04":1,"05":1,"06":1,"07":1,"08":1,"09":1,"10":1}'}},
        {name => 'hash100' , args=>{data=>'{"001":1,"002":1,"003":1,"004":1,"005":1,"006":1,"007":1,"008":1,"009":1,"010":1,"011":1,"012":1,"013":1,"014":1,"015":1,"016":1,"017":1,"018":1,"019":1,"020":1,"021":1,"022":1,"023":1,"024":1,"025":1,"026":1,"027":1,"028":1,"029":1,"030":1,"031":1,"032":1,"033":1,"034":1,"035":1,"036":1,"037":1,"038":1,"039":1,"040":1,"041":1,"042":1,"043":1,"044":1,"045":1,"046":1,"047":1,"048":1,"049":1,"050":1,"051":1,"052":1,"053":1,"054":1,"055":1,"056":1,"057":1,"058":1,"059":1,"060":1,"061":1,"062":1,"063":1,"064":1,"065":1,"066":1,"067":1,"068":1,"069":1,"070":1,"071":1,"072":1,"073":1,"074":1,"075":1,"076":1,"077":1,"078":1,"079":1,"080":1,"081":1,"082":1,"083":1,"084":1,"085":1,"086":1,"087":1,"088":1,"089":1,"090":1,"091":1,"092":1,"093":1,"094":1,"095":1,"096":1,"097":1,"098":1,"099":1,"100":1}'}},
    ],
};

1;
# ABSTRACT: Benchmark JSON decoding

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::JSONDecodeRegexp - Benchmark JSON decoding

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::JSONDecodeRegexp (from Perl distribution Bencher-Scenarios-JSONDecodeRegexp), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m JSONDecodeRegexp

To run module startup overhead benchmark:

 % bencher --module-startup -m JSONDecodeRegexp

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<JSON::Decode::Regexp> 0.09

L<JSON::PP> 2.27300

=head1 BENCHMARK PARTICIPANTS

=over

=item * JSON::Decode::Regexp::from_json (perl_code)

Function call template:

 JSON::Decode::Regexp::from_json(<data>)



=item * JSON::PP::decode (perl_code)

Code template:

 state $json = JSON::PP->new->allow_nonref; $json->decode(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * str-a

a 100-character string with some escape sequences

=item * array0

=item * array1

=item * array10

=item * array100

=item * hash0

=item * hash1

=item * hash10

=item * hash100

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m JSONDecodeRegexp --include-path archive/JSON-Decode-Regexp-0.03/lib --include-path archive/JSON-Decode-Regexp-0.04/lib --include-path archive/JSON-Decode-Regexp-0.06/lib --include-path archive/JSON-Decode-Regexp-0.07/lib --include-path archive/JSON-Decode-Regexp-0.09/lib --multimodver JSON::Decode::Regexp >>:

 #table1#
 {dataset=>"array0"}
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                     | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Regexp::from_json | 0.06   |     11000 |     87    |        1   | 1.9e-07 |      24 |
 | JSON::Decode::Regexp::from_json | 0.03   |     17000 |     60    |        1.4 | 1.9e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.04   |     17000 |     60    |        1.4 | 1.9e-07 |      24 |
 | JSON::PP::decode                |        |    230000 |      4.3  |       20   | 1.1e-08 |      29 |
 | JSON::Decode::Regexp::from_json | 0.07   |    280000 |      3.6  |       24   | 6.7e-09 |      20 |
 | JSON::Decode::Regexp::from_json | 0.09   |    281000 |      3.56 |       24.5 | 1.5e-09 |      24 |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"array1"}
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                     | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Regexp::from_json | 0.06   |     11000 |      94   |        1   | 4.5e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.03   |     15000 |      68   |        1.4 | 1.9e-07 |      24 |
 | JSON::Decode::Regexp::from_json | 0.04   |     16000 |      62   |        1.5 | 1.1e-07 |      20 |
 | JSON::PP::decode                |        |    130000 |       7.8 |       12   | 8.6e-09 |      27 |
 | JSON::Decode::Regexp::from_json | 0.07   |    160000 |       6.1 |       15   | 3.5e-08 |      20 |
 | JSON::Decode::Regexp::from_json | 0.09   |    180000 |       5.5 |       17   | 6.7e-09 |      20 |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"array10"}
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                     | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Regexp::from_json | 0.03   |      7700 |     130   |       1    | 2.7e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.06   |      8700 |     110   |       1.1  | 2.1e-07 |      21 |
 | JSON::Decode::Regexp::from_json | 0.04   |     12000 |      86   |       1.5  | 1.1e-07 |      20 |
 | JSON::PP::decode                |        |     29000 |      35   |       3.7  | 5.3e-08 |      20 |
 | JSON::Decode::Regexp::from_json | 0.07   |     40000 |      30   |       5    | 4.9e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.09   |     39000 |      25.7 |       5.09 | 1.2e-08 |      24 |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"array100"}
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                     | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Regexp::from_json | 0.03   |      1300 |       768 |       1    | 6.4e-07 |      20 |
 | JSON::PP::decode                |        |      3200 |       320 |       2.4  | 3.1e-06 |      20 |
 | JSON::Decode::Regexp::from_json | 0.06   |      3400 |       300 |       2.6  | 4.1e-07 |      22 |
 | JSON::Decode::Regexp::from_json | 0.04   |      3410 |       293 |       2.62 | 2.6e-07 |      21 |
 | JSON::Decode::Regexp::from_json | 0.09   |      4500 |       220 |       3.5  | 4.3e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.07   |      4700 |       210 |       3.6  | 2.4e-07 |      25 |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"hash0"}
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                     | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Regexp::from_json | 0.06   |     11000 |      87   |       1    | 1.3e-07 |      21 |
 | JSON::Decode::Regexp::from_json | 0.04   |     17300 |      58   |       1.51 | 2.7e-08 |      20 |
 | JSON::Decode::Regexp::from_json | 0.03   |     19000 |      53   |       1.6  |   1e-07 |      21 |
 | JSON::PP::decode                |        |    230000 |       4.4 |      20    | 6.7e-09 |      20 |
 | JSON::Decode::Regexp::from_json | 0.09   |    333000 |       3   |      29.1  | 6.9e-10 |      29 |
 | JSON::Decode::Regexp::from_json | 0.07   |    380000 |       2.7 |      33    | 3.3e-09 |      20 |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"hash1"}
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                     | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Regexp::from_json | 0.06   |      8900 |    110    |        1   | 3.6e-07 |      28 |
 | JSON::Decode::Regexp::from_json | 0.03   |     13000 |     74    |        1.5 | 1.1e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.04   |     14000 |     71    |        1.6 | 1.3e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.07   |     78000 |     13    |        8.8 | 2.7e-08 |      20 |
 | JSON::PP::decode                |        |     87000 |     12    |        9.7 | 1.2e-08 |      24 |
 | JSON::Decode::Regexp::from_json | 0.09   |    123000 |      8.16 |       13.7 | 3.2e-09 |      22 |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"hash10"}
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                     | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Regexp::from_json | 0.03   |    4200   |   240     |    1       | 6.9e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.06   |    5100   |   190     |    1.2     | 2.6e-07 |      21 |
 | JSON::Decode::Regexp::from_json | 0.04   |    6200   |   160     |    1.5     | 3.9e-07 |      24 |
 | JSON::Decode::Regexp::from_json | 0.07   |   11000   |    88     |    2.7     | 1.1e-07 |      27 |
 | JSON::PP::decode                |        |   15000   |    69     |    3.5     | 8.4e-08 |      32 |
 | JSON::Decode::Regexp::from_json | 0.09   |   19302.4 |    51.807 |    4.58605 |   0     |      20 |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"hash100"}
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                     | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Regexp::from_json | 0.03   |       430 |     2.3   |       1    | 9.1e-06 |      25 |
 | JSON::Decode::Regexp::from_json | 0.06   |      1000 |     0.96  |       2.4  | 1.8e-06 |      20 |
 | JSON::Decode::Regexp::from_json | 0.04   |      1100 |     0.93  |       2.5  | 1.5e-06 |      20 |
 | JSON::Decode::Regexp::from_json | 0.07   |      1200 |     0.85  |       2.7  | 1.1e-06 |      20 |
 | JSON::PP::decode                |        |      1510 |     0.663 |       3.52 | 4.8e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.09   |      2070 |     0.482 |       4.84 | 2.6e-07 |      21 |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table9#
 {dataset=>"str-a"}
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                     | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Regexp::from_json | 0.06   |      9200 | 110       |     1      | 2.1e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.04   |     13000 |  78       |     1.4    | 2.7e-07 |      20 |
 | JSON::Decode::Regexp::from_json | 0.03   |     14000 |  71       |     1.5    | 2.7e-07 |      28 |
 | JSON::PP::decode                |        |     16000 |  61       |     1.8    |   8e-08 |      20 |
 | JSON::Decode::Regexp::from_json | 0.07   |     80000 |  10       |     9      | 1.8e-07 |      31 |
 | JSON::Decode::Regexp::from_json | 0.09   |    107785 |   9.27774 |    11.7003 |   0     |      20 |
 +---------------------------------+--------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-JSONDecodeRegexp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-JSONDecodeRegexp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-JSONDecodeRegexp>

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

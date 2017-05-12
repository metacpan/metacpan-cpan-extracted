package Bencher::Scenario::RegexpAssemble;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

$main::chars = ["a".."z"];

my $code_template_assemble_with_ra = 'my $ra = Regexp::Assemble->new; for (1.. <num> ) { $ra->add(join("", map {$main::chars->[rand @$main::chars]} 1..10)) } $ra->re';
my $code_template_assemble_raw     = 'my @strs; for (1.. <num> ) { push @strs, join("", map {$main::chars->[rand @$main::chars]} 1..10) } my $re = "\\\\A(?:".join("|", map {quotemeta} sort {length($b) <=> length($a)} @strs).")\\\\z"; $re = qr/$re/';

our $scenario = {
    summary => 'Benchmark Regexp::Assemble',
    participants => [
        {
            name => 'assemble-with-ra',
            module=>'Regexp::Assemble',
            code_template => $code_template_assemble_with_ra,
            tags => ['assembling'],
        },
        {
            name => 'assemble-raw',
            code_template => $code_template_assemble_raw,
            tags => ['assembling'],
        },
        {
            name => 'match-with-ra',
            module=>'Regexp::Assemble',
            code_template => 'state $re = do { ' . $code_template_assemble_with_ra . ' }; state $str = join("", map {$main::chars->[rand @$main::chars]} 1..10); $str =~ $re',
            tags => ['matching'],
        },
        {
            name => 'match-raw',
            code_template => 'state $re = do { ' . $code_template_assemble_raw     . ' }; state $str = join("", map {$main::chars->[rand @$main::chars]} 1..10); $str =~ $re',
            tags => ['matching'],
        },
    ],
    datasets => [
        {name=>'10str'   , args=>{num=>10   }},
        {name=>'100str'  , args=>{num=>100  }},
        {name=>'1000str' , args=>{num=>1000 }},
        {name=>'10000str', args=>{num=>10000}},
    ],
};

1;
# ABSTRACT: Benchmark Regexp::Assemble

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RegexpAssemble - Benchmark Regexp::Assemble

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::RegexpAssemble (from Perl distribution Bencher-Scenario-RegexpAssemble), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RegexpAssemble

To run module startup overhead benchmark:

 % bencher --module-startup -m RegexpAssemble

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Regexp::Assemble> 0.37

=head1 BENCHMARK PARTICIPANTS

=over

=item * assemble-with-ra (perl_code) [assembling]

Code template:

 my $ra = Regexp::Assemble->new; for (1.. <num> ) { $ra->add(join("", map {$main::chars->[rand @$main::chars]} 1..10)) } $ra->re



=item * assemble-raw (perl_code) [assembling]

Code template:

 my @strs; for (1.. <num> ) { push @strs, join("", map {$main::chars->[rand @$main::chars]} 1..10) } my $re = "\\A(?:".join("|", map {quotemeta} sort {length($b) <=> length($a)} @strs).")\\z"; $re = qr/$re/



=item * match-with-ra (perl_code) [matching]

Code template:

 state $re = do { my $ra = Regexp::Assemble->new; for (1.. <num> ) { $ra->add(join("", map {$main::chars->[rand @$main::chars]} 1..10)) } $ra->re }; state $str = join("", map {$main::chars->[rand @$main::chars]} 1..10); $str =~ $re



=item * match-raw (perl_code) [matching]

Code template:

 state $re = do { my @strs; for (1.. <num> ) { push @strs, join("", map {$main::chars->[rand @$main::chars]} 1..10) } my $re = "\\A(?:".join("|", map {quotemeta} sort {length($b) <=> length($a)} @strs).")\\z"; $re = qr/$re/ }; state $str = join("", map {$main::chars->[rand @$main::chars]} 1..10); $str =~ $re



=back

=head1 BENCHMARK DATASETS

=over

=item * 10str

=item * 100str

=item * 1000str

=item * 10000str

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RegexpAssemble >>):

 #table1#
 +------------------+----------+-----------+---------------+------------+-----------+---------+
 | participant      | dataset  | rate (/s) |   time (ms)   | vs_slowest |  errors   | samples |
 +------------------+----------+-----------+---------------+------------+-----------+---------+
 | assemble-with-ra | 10000str |       2.1 | 470           |        1   |   0.0013  |      20 |
 | assemble-raw     | 10000str |      18   |  56           |        8.3 |   0.00014 |      20 |
 | assemble-with-ra | 1000str  |      22   |  46           |       10   |   0.00027 |      21 |
 | assemble-raw     | 1000str  |     200   |   5           |       90   | 6.7e-05   |      20 |
 | assemble-with-ra | 100str   |     250   |   4           |      120   | 3.2e-05   |      20 |
 | assemble-raw     | 100str   |    2000   |   0.5         |      900   | 7.8e-06   |      20 |
 | assemble-with-ra | 10str    |    2300   |   0.44        |     1100   |   4e-06   |      20 |
 | assemble-raw     | 10str    |   18000   |   0.055       |     8500   | 9.5e-08   |      25 |
 | match-with-ra    | 10000str |  400000   |   0.003       |   200000   | 3.8e-08   |      20 |
 | match-with-ra    | 1000str  |  455000   |   0.0022      |   212000   | 8.1e-10   |      21 |
 | match-with-ra    | 100str   |  707000   |   0.00142     |   330000   | 4.7e-10   |      20 |
 | match-with-ra    | 10str    | 1820000   |   0.000551    |   847000   |   2e-10   |      22 |
 | match-raw        | 1000str  | 2480630   |   0.000403123 |  1157140   |   0       |      20 |
 | match-raw        | 10000str | 2600000   |   0.000385    |  1210000   | 1.8e-10   |      30 |
 | match-raw        | 100str   | 2630000   |   0.00038     |  1230000   | 2.1e-10   |      20 |
 | match-raw        | 10str    | 2650000   |   0.000377    |  1240000   | 2.1e-10   |      20 |
 +------------------+----------+-----------+---------------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m RegexpAssemble --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Regexp::Assemble    | 0.82                         | 4.1                | 16             |      27   |                   19.9 |        1   |   0.00011 |      20 |
 | perl -e1 (baseline) | 3.7                          | 7.4                | 25             |       7.1 |                    0   |        3.8 | 1.3e-05   |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-RegexpAssemble>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-RegexpAssemble>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-RegexpAssemble>

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

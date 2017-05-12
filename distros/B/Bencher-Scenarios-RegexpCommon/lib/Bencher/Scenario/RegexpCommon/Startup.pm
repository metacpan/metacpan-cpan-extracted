package Bencher::Scenario::RegexpCommon::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our @modules = ("Regexp::Common","Regexp::Common::ANSIescape","Regexp::Common::CC","Regexp::Common::Chess","Regexp::Common::Emacs","Regexp::Common::Email::Address","Regexp::Common::IRC","Regexp::Common::Patch::DumpPatterns","Regexp::Common::RegexpPattern","Regexp::Common::SEN","Regexp::Common::URI","Regexp::Common::URI::RFC1035","Regexp::Common::URI::RFC1738","Regexp::Common::URI::RFC1808","Regexp::Common::URI::RFC2384","Regexp::Common::URI::RFC2396","Regexp::Common::URI::RFC2806","Regexp::Common::URI::fax","Regexp::Common::URI::file","Regexp::Common::URI::ftp","Regexp::Common::URI::gopher","Regexp::Common::URI::http","Regexp::Common::URI::news","Regexp::Common::URI::pop","Regexp::Common::URI::prospero","Regexp::Common::URI::tel","Regexp::Common::URI::telnet","Regexp::Common::URI::tv","Regexp::Common::URI::wais","Regexp::Common::VATIN","Regexp::Common::balanced","Regexp::Common::comment","Regexp::Common::debian","Regexp::Common::delimited","Regexp::Common::lingua","Regexp::Common::list","Regexp::Common::microsyntax","Regexp::Common::net","Regexp::Common::net::CIDR","Regexp::Common::number","Regexp::Common::profanity","Regexp::Common::profanity_us","Regexp::Common::time","Regexp::Common::whitespace","Regexp::Common::zip"); # PRECOMPUTED FROM: grep {!/\ARegexp::Common::(Entry|Other|WithActions.*|_.*)\z/} do { require App::lcpan::Call; @{ App::lcpan::Call::call_lcpan_script(argv=>["modules", "--namespace", "Regexp::Common"])->[2] } }

our $scenario = {
    summary => 'Benchmark module startup overhead of Regexp::Common modules',

    module_startup => 1,

    participants => [
        map { +{module=>$_} } @modules,
    ],
};

1;
# ABSTRACT: Benchmark module startup overhead of Regexp::Common modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RegexpCommon::Startup - Benchmark module startup overhead of Regexp::Common modules

=head1 VERSION

This document describes version 0.02 of Bencher::Scenario::RegexpCommon::Startup (from Perl distribution Bencher-Scenarios-RegexpCommon), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RegexpCommon::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Regexp::Common> 2016060801

L<Regexp::Common::ANSIescape> 14

L<Regexp::Common::CC> 2016060801

L<Regexp::Common::Chess> 0.1

L<Regexp::Common::Emacs> 14

L<Regexp::Common::Email::Address> 1.01

L<Regexp::Common::IRC> 0.04

L<Regexp::Common::Patch::DumpPatterns> 0.002

L<Regexp::Common::RegexpPattern> 0.001

L<Regexp::Common::SEN> 2016060801

L<Regexp::Common::URI> 2016060801

L<Regexp::Common::URI::RFC1035> 2016060801

L<Regexp::Common::URI::RFC1738> 2016060801

L<Regexp::Common::URI::RFC1808> 2016060801

L<Regexp::Common::URI::RFC2384> 2016060801

L<Regexp::Common::URI::RFC2396> 2016060801

L<Regexp::Common::URI::RFC2806> 2016060801

L<Regexp::Common::URI::fax> 2016060801

L<Regexp::Common::URI::file> 2016060801

L<Regexp::Common::URI::ftp> 2016060801

L<Regexp::Common::URI::gopher> 2016060801

L<Regexp::Common::URI::http> 2016060801

L<Regexp::Common::URI::news> 2016060801

L<Regexp::Common::URI::pop> 2016060801

L<Regexp::Common::URI::prospero> 2016060801

L<Regexp::Common::URI::tel> 2016060801

L<Regexp::Common::URI::telnet> 2016060801

L<Regexp::Common::URI::tv> 2016060801

L<Regexp::Common::URI::wais> 2016060801

L<Regexp::Common::VATIN> v1.0

L<Regexp::Common::balanced> 2016060801

L<Regexp::Common::comment> 2016060801

L<Regexp::Common::debian> v0.2.14

L<Regexp::Common::delimited> 2016060801

L<Regexp::Common::lingua> 2016060801

L<Regexp::Common::list> 2016060801

L<Regexp::Common::microsyntax> 0.02

L<Regexp::Common::net> 2016060801

L<Regexp::Common::net::CIDR> 0.03

L<Regexp::Common::number> 2016060801

L<Regexp::Common::profanity> 2016060801

L<Regexp::Common::profanity_us> 4.112150

L<Regexp::Common::time> 0.07

L<Regexp::Common::whitespace> 2016060801

L<Regexp::Common::zip> 2016060801

=head1 BENCHMARK PARTICIPANTS

=over

=item * Regexp::Common (perl_code)

L<Regexp::Common>



=item * Regexp::Common::ANSIescape (perl_code)

L<Regexp::Common::ANSIescape>



=item * Regexp::Common::CC (perl_code)

L<Regexp::Common::CC>



=item * Regexp::Common::Chess (perl_code)

L<Regexp::Common::Chess>



=item * Regexp::Common::Emacs (perl_code)

L<Regexp::Common::Emacs>



=item * Regexp::Common::Email::Address (perl_code)

L<Regexp::Common::Email::Address>



=item * Regexp::Common::IRC (perl_code)

L<Regexp::Common::IRC>



=item * Regexp::Common::Patch::DumpPatterns (perl_code)

L<Regexp::Common::Patch::DumpPatterns>



=item * Regexp::Common::RegexpPattern (perl_code)

L<Regexp::Common::RegexpPattern>



=item * Regexp::Common::SEN (perl_code)

L<Regexp::Common::SEN>



=item * Regexp::Common::URI (perl_code)

L<Regexp::Common::URI>



=item * Regexp::Common::URI::RFC1035 (perl_code)

L<Regexp::Common::URI::RFC1035>



=item * Regexp::Common::URI::RFC1738 (perl_code)

L<Regexp::Common::URI::RFC1738>



=item * Regexp::Common::URI::RFC1808 (perl_code)

L<Regexp::Common::URI::RFC1808>



=item * Regexp::Common::URI::RFC2384 (perl_code)

L<Regexp::Common::URI::RFC2384>



=item * Regexp::Common::URI::RFC2396 (perl_code)

L<Regexp::Common::URI::RFC2396>



=item * Regexp::Common::URI::RFC2806 (perl_code)

L<Regexp::Common::URI::RFC2806>



=item * Regexp::Common::URI::fax (perl_code)

L<Regexp::Common::URI::fax>



=item * Regexp::Common::URI::file (perl_code)

L<Regexp::Common::URI::file>



=item * Regexp::Common::URI::ftp (perl_code)

L<Regexp::Common::URI::ftp>



=item * Regexp::Common::URI::gopher (perl_code)

L<Regexp::Common::URI::gopher>



=item * Regexp::Common::URI::http (perl_code)

L<Regexp::Common::URI::http>



=item * Regexp::Common::URI::news (perl_code)

L<Regexp::Common::URI::news>



=item * Regexp::Common::URI::pop (perl_code)

L<Regexp::Common::URI::pop>



=item * Regexp::Common::URI::prospero (perl_code)

L<Regexp::Common::URI::prospero>



=item * Regexp::Common::URI::tel (perl_code)

L<Regexp::Common::URI::tel>



=item * Regexp::Common::URI::telnet (perl_code)

L<Regexp::Common::URI::telnet>



=item * Regexp::Common::URI::tv (perl_code)

L<Regexp::Common::URI::tv>



=item * Regexp::Common::URI::wais (perl_code)

L<Regexp::Common::URI::wais>



=item * Regexp::Common::VATIN (perl_code)

L<Regexp::Common::VATIN>



=item * Regexp::Common::balanced (perl_code)

L<Regexp::Common::balanced>



=item * Regexp::Common::comment (perl_code)

L<Regexp::Common::comment>



=item * Regexp::Common::debian (perl_code)

L<Regexp::Common::debian>



=item * Regexp::Common::delimited (perl_code)

L<Regexp::Common::delimited>



=item * Regexp::Common::lingua (perl_code)

L<Regexp::Common::lingua>



=item * Regexp::Common::list (perl_code)

L<Regexp::Common::list>



=item * Regexp::Common::microsyntax (perl_code)

L<Regexp::Common::microsyntax>



=item * Regexp::Common::net (perl_code)

L<Regexp::Common::net>



=item * Regexp::Common::net::CIDR (perl_code)

L<Regexp::Common::net::CIDR>



=item * Regexp::Common::number (perl_code)

L<Regexp::Common::number>



=item * Regexp::Common::profanity (perl_code)

L<Regexp::Common::profanity>



=item * Regexp::Common::profanity_us (perl_code)

L<Regexp::Common::profanity_us>



=item * Regexp::Common::time (perl_code)

L<Regexp::Common::time>



=item * Regexp::Common::whitespace (perl_code)

L<Regexp::Common::whitespace>



=item * Regexp::Common::zip (perl_code)

L<Regexp::Common::zip>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RegexpCommon::Startup >>):

 #table1#
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Regexp::Common::microsyntax         | 1.3                          | 4.7                | 16             |     120   |                  114.8 |        1   |   0.00013 |      21 |
 | Regexp::Common::time                | 1.2                          | 4.7                | 16             |      90   |                   84.8 |        1.3 |   0.00016 |      20 |
 | Regexp::Common::Email::Address      | 1.3                          | 4.7                | 16             |      87   |                   81.8 |        1.4 |   0.00027 |      20 |
 | Regexp::Common::RegexpPattern       | 1.2                          | 4.5                | 16             |      82   |                   76.8 |        1.5 |   0.00016 |      20 |
 | Regexp::Common                      | 1.7                          | 5.2                | 17             |      82   |                   76.8 |        1.5 |   0.00011 |      20 |
 | Regexp::Common::delimited           | 1.4                          | 4.9                | 19             |      60   |                   54.8 |        2   | 9.2e-05   |      20 |
 | Regexp::Common::Patch::DumpPatterns | 6.1                          | 9.8                | 24             |      31   |                   25.8 |        3.8 |   0.00011 |      20 |
 | Regexp::Common::URI::pop            | 1.8                          | 5.1                | 17             |      22   |                   16.8 |        5.5 |   0.00019 |      20 |
 | Regexp::Common::URI::prospero       | 1.8                          | 5.1                | 17             |      21   |                   15.8 |        5.6 |   0.00011 |      20 |
 | Regexp::Common::URI::http           | 1.8                          | 5.2                | 17             |      21   |                   15.8 |        5.6 |   0.00011 |      20 |
 | Regexp::Common::URI::fax            | 1.8                          | 5.1                | 17             |      21   |                   15.8 |        5.6 |   0.0001  |      20 |
 | Regexp::Common::URI::tel            | 1.8                          | 5.3                | 17             |      21   |                   15.8 |        5.6 | 9.2e-05   |      20 |
 | Regexp::Common::URI                 | 1.3                          | 4.7                | 16             |      21   |                   15.8 |        5.7 |   0.0001  |      20 |
 | Regexp::Common::URI::ftp            | 1.8                          | 5.1                | 17             |      21   |                   15.8 |        5.7 |   8e-05   |      20 |
 | Regexp::Common::URI::gopher         | 1.8                          | 5.2                | 17             |      21   |                   15.8 |        5.7 | 5.7e-05   |      20 |
 | Regexp::Common::URI::file           | 1.8                          | 5.1                | 17             |      21   |                   15.8 |        5.7 | 8.1e-05   |      20 |
 | Regexp::Common::URI::news           | 1.8                          | 5.2                | 17             |      21   |                   15.8 |        5.7 | 5.9e-05   |      20 |
 | Regexp::Common::URI::telnet         | 1.8                          | 5.2                | 17             |      21   |                   15.8 |        5.7 |   0.00011 |      20 |
 | Regexp::Common::URI::wais           | 1.3                          | 4.6                | 16             |      21   |                   15.8 |        5.8 | 6.1e-05   |      20 |
 | Regexp::Common::URI::tv             | 1.8                          | 5.2                | 17             |      21   |                   15.8 |        5.8 |   8e-05   |      20 |
 | Regexp::Common::profanity_us        | 7.4                          | 11                 | 31             |      20   |                   14.8 |        6.1 |   0.0001  |      20 |
 | Regexp::Common::zip                 | 0.83                         | 4.1                | 16             |      16   |                   10.8 |        7.5 | 6.9e-05   |      21 |
 | Regexp::Common::ANSIescape          | 1.4                          | 5                  | 19             |      15   |                    9.8 |        7.7 | 6.8e-05   |      20 |
 | Regexp::Common::Emacs               | 7                            | 11                 | 25             |      15   |                    9.8 |        7.9 |   0.00012 |      20 |
 | Regexp::Common::URI::RFC2806        | 1.9                          | 5.2                | 17             |      15   |                    9.8 |        8.1 | 6.8e-05   |      20 |
 | Regexp::Common::comment             | 1.4                          | 4.9                | 17             |      14   |                    8.8 |        8.4 | 6.4e-05   |      20 |
 | Regexp::Common::URI::RFC2384        | 1.4                          | 4.7                | 17             |      14   |                    8.8 |        8.5 | 7.9e-05   |      20 |
 | Regexp::Common::URI::RFC1738        | 1.1                          | 4.3                | 16             |      14   |                    8.8 |        8.8 | 4.1e-05   |      20 |
 | Regexp::Common::number              | 1.2                          | 4.5                | 16             |      13   |                    7.8 |        8.9 | 4.3e-05   |      20 |
 | Regexp::Common::URI::RFC1035        | 1.4                          | 4.7                | 17             |      13   |                    7.8 |        9.2 | 5.7e-05   |      20 |
 | Regexp::Common::debian              | 5                            | 8.5                | 23             |      13   |                    7.8 |        9.3 | 7.5e-05   |      20 |
 | Regexp::Common::CC                  | 1.3                          | 4.6                | 16             |      13   |                    7.8 |        9.3 | 2.6e-05   |      20 |
 | Regexp::Common::lingua              | 1.2                          | 4.5                | 16             |      12   |                    6.8 |        9.6 | 6.5e-05   |      20 |
 | Regexp::Common::URI::RFC2396        | 1.6                          | 5                  | 17             |      12   |                    6.8 |        9.6 | 9.6e-05   |      21 |
 | Regexp::Common::net                 | 1.2                          | 4.5                | 16             |      11   |                    5.8 |       10   |   5e-05   |      20 |
 | Regexp::Common::IRC                 | 2.9                          | 6.4                | 24             |      11   |                    5.8 |       11   |   7e-05   |      23 |
 | Regexp::Common::VATIN               | 1.2                          | 4.7                | 16             |      11   |                    5.8 |       11   | 6.4e-05   |      21 |
 | Regexp::Common::balanced            | 1.8                          | 5.4                | 19             |      11   |                    5.8 |       11   | 6.7e-05   |      20 |
 | Regexp::Common::Chess               | 1.7                          | 5                  | 17             |      11   |                    5.8 |       11   | 5.3e-05   |      20 |
 | Regexp::Common::URI::RFC1808        | 1.5                          | 4.8                | 17             |      11   |                    5.8 |       11   | 4.2e-05   |      20 |
 | Regexp::Common::profanity           | 2.5                          | 5.8                | 20             |      11   |                    5.8 |       11   | 7.4e-05   |      20 |
 | Regexp::Common::SEN                 | 1.8                          | 5.2                | 17             |      11   |                    5.8 |       11   | 3.6e-05   |      20 |
 | Regexp::Common::net::CIDR           | 1.6                          | 5.2                | 19             |      11   |                    5.8 |       11   | 7.2e-05   |      20 |
 | Regexp::Common::list                | 20                           | 24                 | 38             |      11   |                    5.8 |       11   | 2.2e-05   |      20 |
 | Regexp::Common::whitespace          | 1.6                          | 4.8                | 17             |      10   |                    4.8 |       11   | 3.7e-05   |      20 |
 | perl -e1 (baseline)                 | 1.2                          | 4.5                | 16             |       5.2 |                    0   |       23   | 1.3e-05   |      21 |
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-RegexpCommon>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-RegexpCommon>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-RegexpCommon>

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

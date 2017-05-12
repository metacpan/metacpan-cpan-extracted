package Bencher::Scenario::TextANSIUtil::Wrap;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.02'; # VERSION

use utf8;

our $scenario = {
    summary => 'Benchmark text wrapping',
    modules => {
        'Text::ANSI::Util' => {version => 0.22},
    },
    participants => [
        {fcall_template => 'Text::ANSI::Util::ta_wrap(<text>, <width>)'},
        {fcall_template => 'Text::ANSI::WideUtil::ta_mbwrap(<text>, <width>)'},
        {code_template  => 'local $Text::Wrap::columns = <width>; Text::Wrap::wrap("", "", <text>)', module=>'Text::Wrap'},
    ],
    datasets => [
        {name=>'ascii-100c-nocolor', tags=>['ascii'], args=>{text=>'foobar bz ' x 10, width=>77}},
    ],
};

1;
# ABSTRACT: Benchmark text wrapping

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TextANSIUtil::Wrap - Benchmark text wrapping

=head1 VERSION

This document describes version 0.02 of Bencher::Scenario::TextANSIUtil::Wrap (from Perl distribution Bencher-Scenarios-TextANSIUtil), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TextANSIUtil::Wrap

To run module startup overhead benchmark:

 % bencher --module-startup -m TextANSIUtil::Wrap

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::ANSI::Util> 0.22

L<Text::ANSI::WideUtil> 0.22

L<Text::Wrap> 2013.0523

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::ANSI::Util::ta_wrap (perl_code)

Function call template:

 Text::ANSI::Util::ta_wrap(<text>, <width>)



=item * Text::ANSI::WideUtil::ta_mbwrap (perl_code)

Function call template:

 Text::ANSI::WideUtil::ta_mbwrap(<text>, <width>)



=item * Text::Wrap (perl_code)

Code template:

 local $Text::Wrap::columns = <width>; Text::Wrap::wrap("", "", <text>)



=back

=head1 BENCHMARK DATASETS

=over

=item * ascii-100c-nocolor [ascii]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m TextANSIUtil::Wrap >>):

 #table1#
 +---------------------------------+-----------+-----------+------------+---------+---------+
 | participant                     | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+-----------+-----------+------------+---------+---------+
 | Text::ANSI::WideUtil::ta_mbwrap |      3500 |       290 |        1   | 2.7e-06 |      21 |
 | Text::ANSI::Util::ta_wrap       |      5400 |       180 |        1.6 | 1.8e-06 |      20 |
 | Text::Wrap                      |     23000 |        43 |        6.7 | 3.3e-07 |      20 |
 +---------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m TextANSIUtil::Wrap --module-startup >>):

 #table2#
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant          | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Text::ANSI::WideUtil | 1.3                          | 4.9                | 19             |      38   |                   33.6 |        1   |   0.00012 |      20 |
 | Text::Wrap           | 0.83                         | 4.2                | 16             |      11   |                    6.6 |        3.5 | 7.1e-05   |      20 |
 | Text::ANSI::Util     | 5.4                          | 9.2                | 29             |      11   |                    6.6 |        3.6 | 2.6e-05   |      20 |
 | perl -e1 (baseline)  | 1.4                          | 4.9                | 19             |       4.4 |                    0   |        8.7 | 1.4e-05   |      20 |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-TextANSIUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-TextANSIUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-TextANSIUtil>

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

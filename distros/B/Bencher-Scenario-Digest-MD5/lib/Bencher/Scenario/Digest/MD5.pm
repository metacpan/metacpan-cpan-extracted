package Bencher::Scenario::Digest::MD5;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-19'; # DATE
our $DIST = 'Bencher-Scenario-Digest-MD5'; # DIST
our $VERSION = '0.005'; # VERSION

sub _create_file {
    my ($size) = @_;

    require File::Temp;
    my ($fh, $filename) = File::Temp::tempfile();
    my $d1k = substr("1234567890" x 103, 0, 1024);
    for (1..int($size/1024)) {
        print $fh $d1k;
    }
    $filename;
}

our $scenario = {
    summary => 'Benchmark Digest::MD5 against md5sum utility',
    participants => [
        {
            name   => 'md5sum',
            helper_modules => ['String::ShellQuote'],
            code_template => 'my $cmd = "md5sum ".String::ShellQuote::shell_quote(<filename>); my $res = `$cmd`; $res =~ s/\s.+//s; $res',
        },
        {
            name   => 'Digest::MD5',
            module => 'Digest::MD5',
            code_template => 'my $ctx = Digest::MD5->new; open my $fh, "<", <filename>; $ctx->addfile($fh); $ctx->hexdigest',
        },
    ],
    precision => 6,

    datasets => [
        {name=>'30M_file', _size=>30*1024*1024, args=>{filename=>undef}, result=>'e4cdad1fa001d0de95bfc154c4c70424'},
    ],

    before_gen_items => sub {
        my %args = @_;
        my $sc    = $args{scenario};

        my $dss = $sc->{datasets};
        for my $ds (@$dss) {
            log_info("Creating temporary file with size of %.1fMB ...", $ds->{_size}/1024/1024);
            my $filename = _create_file($ds->{_size});
            log_info("Created file %s", $filename);
            $ds->{args}{filename} = $filename;
        }
    },

    before_return => sub {
        my %args = @_;
        my $sc    = $args{scenario};

        my $dss = $sc->{datasets};
        for my $ds (@$dss) {
            my $filename = $ds->{args}{filename};
            next unless $filename;
            log_info("Unlinking %s", $filename);
            unlink $filename;
        }
    },
};

1;
# ABSTRACT: Benchmark Digest::MD5 against md5sum utility

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Digest::MD5 - Benchmark Digest::MD5 against md5sum utility

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::Digest::MD5 (from Perl distribution Bencher-Scenario-Digest-MD5), released on 2022-03-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Digest::MD5

To run module startup overhead benchmark:

 % bencher --module-startup -m Digest::MD5

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Digest::MD5> 2.58

=head1 BENCHMARK PARTICIPANTS

=over

=item * md5sum (perl_code)

Code template:

 my $cmd = "md5sum ".String::ShellQuote::shell_quote(<filename>); my $res = `$cmd`; $res =~ s/\s.+//s; $res



=item * Digest::MD5 (perl_code)

Code template:

 my $ctx = Digest::MD5->new; open my $fh, "<", <filename>; $ctx->addfile($fh); $ctx->hexdigest



=back

=head1 BENCHMARK DATASETS

=over

=item * 30M_file

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Digest::MD5 >>):

 #table1#
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | md5sum      |      15.7 |      63.5 |                 0.00% |                 4.39% | 4.3e-05 |       7 |
 | Digest::MD5 |      16.4 |      60.9 |                 4.39% |                 0.00% | 4.8e-05 |       7 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                 Rate  md5sum  Digest::MD5 
  md5sum       15.7/s      --          -4% 
  Digest::MD5  16.4/s      4%           -- 
 
 Legends:
   Digest::MD5: participant=Digest::MD5
   md5sum: participant=md5sum

Benchmark module startup overhead (C<< bencher -m Digest::MD5 --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Digest::MD5         |       9.5 |               3.4 |                 0.00% |                55.21% | 1.3e-05 |       6 |
 | perl -e1 (baseline) |       6.1 |               0   |                55.21% |                 0.00% | 1.3e-05 |       7 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  D:M  perl -e1 (baseline) 
  D:M                  105.3/s   --                 -35% 
  perl -e1 (baseline)  163.9/s  55%                   -- 
 
 Legends:
   D:M: mod_overhead_time=3.4 participant=Digest::MD5
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Since they are both implemented in C, the speeds of both are roughly the same.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Digest-MD5>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DigestMD5>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Digest-MD5>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

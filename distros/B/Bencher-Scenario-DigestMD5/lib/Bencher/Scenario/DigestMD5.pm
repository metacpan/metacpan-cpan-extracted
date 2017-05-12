package Bencher::Scenario::DigestMD5;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

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
            $log->infof("Creating temporary file with size of %.1fMB ...", $ds->{_size}/1024/1024);
            my $filename = _create_file($ds->{_size});
            $log->infof("Created file %s", $filename);
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
            $log->infof("Unlinking %s", $filename);
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

Bencher::Scenario::DigestMD5 - Benchmark Digest::MD5 against md5sum utility

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::DigestMD5 (from Perl distribution Bencher-Scenario-DigestMD5), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DigestMD5

To run module startup overhead benchmark:

 % bencher --module-startup -m DigestMD5

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Digest::MD5> 2.54

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DigestMD5 >>):

 #table1#
 +-------------+-----------+-----------+------------+-----------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------+-----------+-----------+------------+-----------+---------+
 | Digest::MD5 |        14 |        70 |        1   |   0.00013 |       6 |
 | md5sum      |        15 |        66 |        1.1 | 8.2e-05   |       6 |
 +-------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m DigestMD5 --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Digest::MD5         | 1112                         | 4.55               | 18.3           |      8.95 |                   4.35 |        1   | 3.3e-06 |       8 |
 | perl -e1 (baseline) | 1052                         | 4.3                | 16             |      4.6  |                   0    |        1.9 | 6.9e-06 |       6 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Since they are both implemented in C, the speeds of both are roughly the same.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-DigestMD5>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DigestMD5>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-DigestMD5>

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

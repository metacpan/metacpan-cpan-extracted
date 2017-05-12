package Bencher::Scenario::IOFilterModules::Writing;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;
use File::Temp qw(tempfile);

our $scenario = {
    summary => 'Benchmark writing with filter that does nothing',

    description => <<'_',

Each participant will write `chunk_size` bytes (0, 1, and 1024) for 1000 times.

_

    modules => {
    },

    participants => [
        {
            module => 'Text::OutputFilter',
            code_template => <<'_',
open *FH0, ">", <tempfile> or die "Can't open: $!";
tie  *FH , "Text::OutputFilter", 0, *FH0, sub { $_[0] };
my $chunk = "a" x <chunk_size>;
for (1..1000) { print FH $chunk }
close FH;
die "Incorrect file size" unless (-s <tempfile>) == <chunk_size> * 1000;
_
        },
        {
            module => 'Tie::Handle::Filter',
            code_template => <<'_',
open *FH0, ">", <tempfile> or die "Can't open: $!";
tie  *FH , "Tie::Handle::Filter", *FH0, sub { @_ };
my $chunk = "a" x <chunk_size>;
for (1..1000) { print FH $chunk }
close FH;
die "Incorrect file size" unless (-s <tempfile>) == <chunk_size> * 1000;
_
        },
        {
            name => 'PerlIO::via',
            module => 'PerlIO::via::as_is',
            code_template => <<'_',
open my($fh), ">:via(as_is)", <tempfile>;
my $chunk = "a" x <chunk_size>;
for (1..1000) { print $fh $chunk }
close $fh;
die "Incorrect file size" unless (-s <tempfile>) == <chunk_size> * 1000;
_
        },
        {
            name => 'raw',
            code_template => <<'_',
open my($fh), ">", <tempfile>;
my $chunk = "a" x <chunk_size>;
for (1..1000) { print $fh $chunk }
close $fh;
die "Incorrect file size" unless (-s <tempfile>) == <chunk_size> * 1000;
_
        },
    ],

    # generate datasets
    before_parse_datasets => sub {
        my %args = @_;
        my $scenario = $args{scenario};
        for my $chunk_size (0, 1, 1024) {
            my ($fh, $filename) = tempfile();
            push @{ $scenario->{datasets} }, {
                name => "chunk_size=$chunk_size",
                args => {chunk_size => $chunk_size, tempfile => $filename},
            };
        }
    },

    # generated dynamically
    datasets => undef,
};

1;
# ABSTRACT: Benchmark writing with filter that does nothing

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::IOFilterModules::Writing - Benchmark writing with filter that does nothing

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::IOFilterModules::Writing (from Perl distribution Bencher-Scenarios-IOFilterModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m IOFilterModules::Writing

To run module startup overhead benchmark:

 % bencher --module-startup -m IOFilterModules::Writing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Each participant will write C<chunk_size> bytes (0, 1, and 1024) for 1000 times.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PerlIO::via::as_is> 0.001

L<Text::OutputFilter> 0.20

L<Tie::Handle::Filter> 0.011

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::OutputFilter (perl_code)

Code template:

 open *FH0, ">", <tempfile> or die "Can't open: $!";
 tie  *FH , "Text::OutputFilter", 0, *FH0, sub { $_[0] };
 my $chunk = "a" x <chunk_size>;
 for (1..1000) { print FH $chunk }
 close FH;
 die "Incorrect file size" unless (-s <tempfile>) == <chunk_size> * 1000;




=item * Tie::Handle::Filter (perl_code)

Code template:

 open *FH0, ">", <tempfile> or die "Can't open: $!";
 tie  *FH , "Tie::Handle::Filter", *FH0, sub { @_ };
 my $chunk = "a" x <chunk_size>;
 for (1..1000) { print FH $chunk }
 close FH;
 die "Incorrect file size" unless (-s <tempfile>) == <chunk_size> * 1000;




=item * PerlIO::via (perl_code)

Code template:

 open my($fh), ">:via(as_is)", <tempfile>;
 my $chunk = "a" x <chunk_size>;
 for (1..1000) { print $fh $chunk }
 close $fh;
 die "Incorrect file size" unless (-s <tempfile>) == <chunk_size> * 1000;




=item * raw (perl_code)

Code template:

 open my($fh), ">", <tempfile>;
 my $chunk = "a" x <chunk_size>;
 for (1..1000) { print $fh $chunk }
 close $fh;
 die "Incorrect file size" unless (-s <tempfile>) == <chunk_size> * 1000;




=back

=head1 BENCHMARK DATASETS

=over

=item * chunk_size=0

=item * chunk_size=1

=item * chunk_size=1024

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m IOFilterModules::Writing >>):

 #table1#
 +---------------------+-----------------+-----------+-----------+------------+-----------+---------+
 | participant         | dataset         | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------------------+-----------------+-----------+-----------+------------+-----------+---------+
 | Text::OutputFilter  | chunk_size=1024 |       2.7 |   370     |          1 |   0.00078 |      20 |
 | Text::OutputFilter  | chunk_size=0    |      70   |    10     |         30 |   0.0007  |      20 |
 | Tie::Handle::Filter | chunk_size=1024 |     290   |     3.5   |        110 | 4.9e-06   |      20 |
 | PerlIO::via         | chunk_size=1024 |     302   |     3.32  |        111 | 2.2e-06   |      20 |
 | raw                 | chunk_size=1024 |     360   |     2.8   |        130 | 6.7e-06   |      20 |
 | Text::OutputFilter  | chunk_size=1    |     560   |     1.8   |        210 | 5.5e-06   |      21 |
 | Tie::Handle::Filter | chunk_size=1    |    1300   |     0.76  |        480 | 3.1e-06   |      20 |
 | Tie::Handle::Filter | chunk_size=0    |    1500   |     0.67  |        550 |   1e-06   |      23 |
 | PerlIO::via         | chunk_size=1    |    1700   |     0.59  |        630 |   4e-06   |      26 |
 | raw                 | chunk_size=1    |    9100   |     0.11  |       3400 | 2.7e-07   |      20 |
 | PerlIO::via         | chunk_size=0    |   13000   |     0.078 |       4800 | 1.1e-07   |      20 |
 | raw                 | chunk_size=0    |   16000   |     0.062 |       5900 |   2e-07   |      22 |
 +---------------------+-----------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m IOFilterModules::Writing --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Tie::Handle::Filter | 0.83                         | 4.2                | 16             |      20   |                   14.1 |        1   | 6.4e-05 |      20 |
 | Text::OutputFilter  | 2.2                          | 5.5                | 23             |      12   |                    6.1 |        1.6 |   7e-05 |      20 |
 | PerlIO::via::as_is  | 0.83                         | 4                  | 16             |       6.4 |                    0.5 |        3   | 2.6e-05 |      20 |
 | perl -e1 (baseline) | 1.3                          | 4.6                | 16             |       5.9 |                    0   |        3.3 | 1.6e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-IOFilterModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-IOFilterModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-IOFilterModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

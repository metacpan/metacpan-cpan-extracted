package Bencher::Scenario::CBlocks::IO;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use File::Temp qw(tempfile);

our $infile_path;
our $outfile_path;

our $scenario = {
    summary => 'Benchmark I/O performance of C::Blocks',
    description => <<'_',

Each code reads a 100k-line file, line by line. Some lines (10% of them)
contains `Fred` which will be substituted with `Barney`. The lines are written
back to another file.

_
    precision => 6,
    before_bench => sub {
        (my $fh, $infile_path) = tempfile();
        $log->debugf("Input temp file is %s", $infile_path);
        for my $i (1..100*1024) {
            if ($i % 10 == 0) {
                print $fh "Fred Fred\n";
            } else {
                print $fh "Elmo Elmo\n";
            }
        }
        close $fh;
        (my $out_fh, $outfile_path) = tempfile();
        $log->debugf("Output temp file is %s", $outfile_path);
    },
    after_bench => sub {
        if ($log->is_debug) {
            $log->debugf("Keeping input and output temp files");
        } else {
            unlink $infile_path;
            unlink $outfile_path;
        }
    },
    participants => [
        {
            name => 'perl',
            code => sub {
                open my $in_fh, "<", $infile_path or die $!;
                open my $out_fh, ">", $outfile_path or die $!;
                while (<$in_fh>) {
                    s/Fred/Barney/g;
                    print $out_fh $_;
                }
            },
        },
        {
            name => 'C::Blocks',
            module => 'C::Blocks',
            code => sub {
                use C::Blocks;
                use C::Blocks::Types qw(char_array);
                my char_array $in_path  = $infile_path;
                my char_array $out_path = $outfile_path;

                cblock {
                    FILE * in_fh = fopen($in_path, "r");
                    FILE * out_fh = fopen($out_path, "w");
                    char * original = "Fre";

                    int match_length = 0;
                    int curr_char = fgetc(in_fh);
                    while (curr_char != EOF) {
                        if (curr_char == original[match_length]) {
                            /* found character in sequence */
                            match_length++;
                        }
                        else if (match_length == 3 && curr_char == 'd') {
                            /* found full name! print and reset */
                            fprintf(out_fh, "Barney");
                            match_length = 0;
                        }
                        else {
                            /* incomplete match, print what we've skipped */
                            if (match_length) fprintf(out_fh, "%.*s", match_length, original);

                            /* just in case we have FFred or FreFred */
                            if (curr_char == 'F') match_length = 1;
                            else {
                                match_length = 0;
                                fputc(curr_char, out_fh);
                            }
                        }

                        curr_char = fgetc(in_fh);
                    }

                    fclose(in_fh);
                    fclose(out_fh);
                }
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark I/O performance of C::Blocks

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CBlocks::IO - Benchmark I/O performance of C::Blocks

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::CBlocks::IO (from Perl distribution Bencher-Scenarios-CBlocks), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CBlocks::IO

To run module startup overhead benchmark:

 % bencher --module-startup -m CBlocks::IO

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Each code reads a 100k-line file, line by line. Some lines (10% of them)
contains C<Fred> which will be substituted with C<Barney>. The lines are written
back to another file.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<C::Blocks> 0.41

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (perl_code)



=item * C::Blocks (perl_code)

L<C::Blocks>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m CBlocks::IO >>):

 #table1#
 +-------------+-----------+-----------+------------+--------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest | errors | samples |
 +-------------+-----------+-----------+------------+--------+---------+
 | perl        |        30 |        30 |        1   | 0.0003 |       7 |
 | C::Blocks   |        49 |        20 |        1.4 | 0.0001 |       6 |
 +-------------+-----------+-----------+------------+--------+---------+


Benchmark module startup overhead (C<< bencher -m CBlocks::IO --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | C::Blocks           | 2.4                          | 5.9                | 22             |      23   |                   17.1 |        1   |   0.00021 |       6 |
 | perl -e1 (baseline) | 0.82                         | 4.1                | 16             |       5.9 |                    0   |        3.9 | 1.5e-05   |       7 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-CBlocks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-CBlocks>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-CBlocks>

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

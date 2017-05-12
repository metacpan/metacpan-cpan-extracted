package Bencher::Scenario::PerinciCmdLine::ResultStream;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use Perinci::CmdLine::Gen qw(gen_pericmd_script);

my $tempdir;

our $scenario = {
    summary => 'Benchmark result stream vs raw Perl I/O',
    description => <<'_',

Conclusion: about 2.5 times slower on my PC (1.2mil lines/sec vs 3mil).

_
    modules => {
    },
    precision => 2,
    participants => [
    ],
    before_list_participants => sub {
        my %args = @_;

        return if $tempdir;
        my $keep = $ENV{DEBUG_KEEP_TEMPDIR} ? 1:0;
        $tempdir = tempdir(CLEANUP => !$keep);

        my $sc = $args{scenario};
        my $pp = $sc->{participants};

        splice @$pp, 0;

        for my $cmdline (qw/rawperl Inline Lite Classic/) {
            my $progname = "produce-ints-$cmdline";
            my $progpath = "$tempdir/$progname";
            if ($cmdline eq 'rawperl') {
                write_text($progpath, "#!$^X\n" . <<'_');
for (1..$ARGV[1]) { print ++$i, "\n" }
_
                chmod 0755, $progpath;
            } else {
                my $res = gen_pericmd_script(
                    url => "/Perinci/Examples/Stream/produce_ints",
                    cmdline => "Perinci::CmdLine::Lite",
                    output_file => $progpath,
                );
                die "Can't create $progpath: $res->[0] - $res->[1]"
                    unless $res->[0] == 200;
            }

            push @$pp, {
                type => 'command',
                name => $progname,
                cmdline => "$progpath --num 1000000 > /dev/null",
            };
        }

        my $i = 0; for (@$pp) { $_->{seq} = $i++ }
    },
};

1;
# ABSTRACT: Benchmark result stream vs raw Perl I/O

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciCmdLine::ResultStream - Benchmark result stream vs raw Perl I/O

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::PerinciCmdLine::ResultStream (from Perl distribution Bencher-Scenarios-PerinciCmdLine), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciCmdLine::ResultStream

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Conclusion: about 2.5 times slower on my PC (1.2mil lines/sec vs 3mil).


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PerinciCmdLine::ResultStream >>):

 #table1#
 +----------------------+-----------+----------+------------+--------+---------+
 | participant          | rate (/s) |     time | vs_slowest | errors | samples |
 +----------------------+-----------+----------+------------+--------+---------+
 | produce-ints-Inline  |   0.3     | 3        |      1     | 0.039  |       3 |
 | produce-ints-Classic |   0.3     | 3        |      1     | 0.039  |       3 |
 | produce-ints-Lite    |   0.32    | 3.2      |      1     | 0.0075 |       3 |
 | produce-ints-rawperl |   3.00949 | 0.332282 |     10.026 | 0      |       2 |
 +----------------------+-----------+----------+------------+--------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciCmdLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciCmdLine>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciCmdLine>

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

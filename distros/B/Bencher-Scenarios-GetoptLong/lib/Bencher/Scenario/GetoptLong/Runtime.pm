package Bencher::Scenario::GetoptLong::Runtime;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Slurper qw(write_text);
use File::Temp qw(tempdir);

my $tempdir;

our $scenario = {
    summary => 'Benchmark runtime of simple Getopt::Long-based CLI script',
    modules => {
    },
    participants => [
    ],
    before_list_participants => sub {
        my %args = @_;

        my $sc = $args{scenario};
        my $pp = $sc->{participants};

        return if $tempdir;
        my $keep = $ENV{DEBUG_KEEP_TEMPDIR} ? 1:0;
        $tempdir = tempdir(CLEANUP => !$keep);

        my @script_content;
        push @script_content, "#!$^X\n";
        push @script_content, <<'_';
use 5.010;
use strict;
use warnings;
use Getopt::Long;

GetOptions(
    'help|h'    => sub { },
    'version|v' => sub { },
    'value=s'   => sub { },
    'file=s'    => sub { },
);
_
        write_text("$tempdir/cli1", join("", @script_content));
        chmod 0755, "$tempdir/cli1";

        push @$pp, {
            type => 'command',
            name => "default",
            cmdline => ["$tempdir/cli1"],
        };

        my $i = 0; for (@$pp) { $_->{seq} = $i++ }
    },
    #datasets => [
    #],
};

1;
# ABSTRACT: Benchmark runtime of simple Getopt::Long-based CLI script

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::GetoptLong::Runtime - Benchmark runtime of simple Getopt::Long-based CLI script

=head1 VERSION

This document describes version 0.02 of Bencher::Scenario::GetoptLong::Runtime (from Perl distribution Bencher-Scenarios-GetoptLong), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m GetoptLong::Runtime

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m GetoptLong::Runtime >>):

 #table1#
 +-------------+------+-----------+-----------+------------+---------+---------+
 | participant | perl | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------+------+-----------+-----------+------------+---------+---------+
 | default     | perl |        58 |        17 |          1 | 7.2e-05 |      21 |
 +-------------+------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-GetoptLong>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-GetoptLong>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-GetoptLong>

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

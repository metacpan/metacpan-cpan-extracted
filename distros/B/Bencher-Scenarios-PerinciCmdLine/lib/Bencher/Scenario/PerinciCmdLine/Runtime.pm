package Bencher::Scenario::PerinciCmdLine::Runtime;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::GenPericmdCompleterScript qw(gen_pericmd_completer_script);
use File::Temp qw(tempdir);
use Perinci::CmdLine::Gen qw(gen_pericmd_script);

my $tempdir;

our $scenario = {
    summary => 'Benchmark completion response time, to monitor regression',
    modules => {
    },
    participants => [
    ],
    before_list_participants => sub {
        my %args = @_;

        return if $tempdir;
        my $keep = $ENV{DEBUG_KEEP_TEMPDIR} ? 1:0;
        $tempdir = tempdir(CLEANUP => !$keep);

        my $res;

        my @cmds;

        push @cmds, "hello-inline";
        $res = gen_pericmd_script(
            url => "/Perinci/Examples/Tiny/hello_naked",
            cmdline => "Perinci::CmdLine::Inline",
            output_file => "$tempdir/hello-inline",
        );
        die "Can't create hello-inline: $res->[0] - $res->[1]"
            unless $res->[0] == 200;

        push @cmds, "hello-lite";
        $res = gen_pericmd_script(
            url => "/Perinci/Examples/Tiny/hello_naked",
            cmdline => "Perinci::CmdLine::Lite",
            output_file => "$tempdir/hello-lite",
        );
        die "Can't create hello-lite: $res->[0] - $res->[1]"
            unless $res->[0] == 200;

        # XXX hello-lite-packed

        push @cmds, "hello-classic";
        $res = gen_pericmd_script(
            url => "/Perinci/Examples/Tiny/hello_naked",
            cmdline => "Perinci::CmdLine::Classic",
            output_file => "$tempdir/hello-classic",
        );
        die "Can't create hello-classic: $res->[0] - $res->[1]"
            unless $res->[0] == 200;

        my $sc = $args{scenario};
        my $pp = $sc->{participants};

        splice @$pp, 0;

        for my $cmd (@cmds) {
            push @$pp, {
                type => 'perl_code',
                name => "$cmd help",
                summary => 'Run command --help',
                code => sub {
                    my $out = `$tempdir/$cmd --help`;
                    die "Backtick failed: $?" if $?;
                    $out;
                }
            };
            push @$pp, {
                type => 'perl_code',
                name => "$cmd version",
                summary => 'Run command --version',
                code => sub {
                    my $out = `$tempdir/$cmd --version`;
                    die "Backtick failed: $?" if $?;
                    $out;
                }
            };
            push @$pp, {
                type => 'perl_code',
                name => "$cmd",
                summary => 'Run command',
                code => sub {
                    my $out = `$tempdir/$cmd`;
                    die "Backtick failed: $?" if $?;
                    $out;
                }
            };
        }

        my $i = 0; for (@$pp) { $_->{seq} = $i++ }
    },
    #datasets => [
    #],
};

1;
# ABSTRACT: Benchmark completion response time, to monitor regression

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciCmdLine::Runtime - Benchmark completion response time, to monitor regression

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::PerinciCmdLine::Runtime (from Perl distribution Bencher-Scenarios-PerinciCmdLine), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciCmdLine::Runtime

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PerinciCmdLine::Runtime >>):

 #table1#
 +-----------------------+-----------+-----------+------------+-----------+---------+
 | participant           | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-----------------------+-----------+-----------+------------+-----------+---------+
 | hello-classic help    |      4.3  |       230 |       1    |   0.0006  |      20 |
 | hello-classic         |      4.31 |       232 |       1.01 |   0.00016 |      20 |
 | hello-classic version |      5.8  |       170 |       1.4  |   0.00029 |      20 |
 | hello-lite            |     18    |        55 |       4.2  |   0.00012 |      20 |
 | hello-lite help       |     20    |        51 |       4.6  |   0.00013 |      21 |
 | hello-lite version    |     23    |        43 |       5.5  |   0.00015 |      20 |
 | hello-inline          |     41    |        24 |       9.6  | 7.3e-05   |      20 |
 | hello-inline version  |     81    |        12 |      19    | 5.4e-05   |      20 |
 | hello-inline help     |     84    |        12 |      20    | 6.6e-05   |      20 |
 +-----------------------+-----------+-----------+------------+-----------+---------+


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

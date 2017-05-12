package Bencher::Scenario::PerinciCmdLine::Completion;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::GenPericmdCompleterScript qw(gen_pericmd_completer_script);
use Bencher::ScenarioUtil::Completion qw(make_completion_participant);
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

        # XXX _oddeven

        push @cmds, "oddeven-lite";
        $res = gen_pericmd_script(
            url => "/Perinci/Examples/Tiny/odd_even",
            cmdline => "Perinci::CmdLine::Lite",
            output_file => "$tempdir/oddeven-lite",
        );
        die "Can't create oddeven-lite: $res->[0] - $res->[1]"
            unless $res->[0] == 200;

        # XXX oddeven-lite-packed

        push @cmds, "oddeven-classic";
        $res = gen_pericmd_script(
            url => "/Perinci/Examples/Tiny/odd_even",
            cmdline => "Perinci::CmdLine::Classic",
            output_file => "$tempdir/oddeven-classic",
        );
        die "Can't create oddeven-classic: $res->[0] - $res->[1]"
            unless $res->[0] == 200;

        my $sc = $args{scenario};
        my $pp = $sc->{participants};

        splice @$pp, 0;

        for my $cmd (@cmds) {
            push @$pp, make_completion_participant(
                type => 'perl_code',
                name=>"$cmd optname_common_help",
                cmdline=>"$tempdir/$cmd --hel^",
            );
            push @$pp, make_completion_participant(
                type => 'perl_code',
                name=>"$cmd optname_common_version",
                cmdline=>"$tempdir/$cmd --vers^",
            );
            push @$pp, make_completion_participant(
                type => 'perl_code',
                name=>"$cmd optname_number",
                cmdline=>"$tempdir/$cmd --num^",
            );
            push @$pp, make_completion_participant(
                type => 'perl_code',
                name=>"$cmd optval_number",
                cmdline=>"$tempdir/$cmd --number ^",
            );
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

Bencher::Scenario::PerinciCmdLine::Completion - Benchmark completion response time, to monitor regression

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::PerinciCmdLine::Completion (from Perl distribution Bencher-Scenarios-PerinciCmdLine), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciCmdLine::Completion

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PerinciCmdLine::Completion >>):

 #table1#
 +----------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                            | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +----------------------------------------+-----------+-----------+------------+---------+---------+
 | oddeven-classic optval_number          |       9.7 |       100 |        1   | 0.00013 |      20 |
 | oddeven-classic optname_common_help    |       9.8 |       100 |        1   | 0.00026 |      20 |
 | oddeven-classic optname_common_version |       9.8 |       100 |        1   | 0.00023 |      20 |
 | oddeven-classic optname_number         |       9.8 |       100 |        1   | 0.00017 |      23 |
 | oddeven-lite optname_common_version    |      17   |        57 |        1.8 | 0.00022 |      21 |
 | oddeven-lite optname_common_help       |      17   |        57 |        1.8 | 0.00013 |      20 |
 | oddeven-lite optval_number             |      18   |        57 |        1.8 | 0.00014 |      20 |
 | oddeven-lite optname_number            |      18   |        57 |        1.8 | 0.00013 |      20 |
 +----------------------------------------+-----------+-----------+------------+---------+---------+


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

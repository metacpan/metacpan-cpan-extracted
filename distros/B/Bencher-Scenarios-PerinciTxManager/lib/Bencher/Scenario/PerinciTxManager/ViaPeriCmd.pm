package Bencher::Scenario::PerinciTxManager::ViaPeriCmd;

our $DATE = '2018-11-11'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempdir);

my $dir = tempdir();

our $scenario = {
    summary => 'Benchmark using transaction via Perinci::CmdLine::Classic',
    modules => {
        'Perinci::CmdLine::Classic' => 0,
        'Setup::File' => 0,
        'Perinci::Tx::Util' => 0,
    },
    participants => [
        {name=>'mkdir'         , perl_cmdline => ['-MPerinci::CmdLine::Classic', '-e', 'Perinci::CmdLine::Classic->new(url=>"/Setup/File/mkdir",     undo=>1)->run', '--', '--path', "$dir/1"]},
        {name=>'setup_dir'     , perl_cmdline => ['-MPerinci::CmdLine::Classic', '-e', 'Perinci::CmdLine::Classic->new(url=>"/Setup/File/setup_dir", undo=>1)->run', '--', '--path', "$dir/2"]},
        {name=>'setup_dir x10' , perl_cmdline => ['-MPerinci::CmdLine::Classic', '-MSetup::File', '-MPerinci::Tx::Util=use_other_actions', '-e',
                                                  join('',
                                                       '$SPEC{app} = {v=>1.1, args=>{}, features=>{tx=>{v=>2}, idempotent=>1}}; ',
                                                       'sub app { use_other_actions(actions=>[map {["Setup::File::setup_dir",{path=>"'.$dir.'/3$_"}]} 1..10]) } ',
                                                       'Perinci::CmdLine::Classic->new(url=>"/main/app", undo=>1)->run',
                                                   )]},
        {name=>'setup_dir x100', perl_cmdline => ['-MPerinci::CmdLine::Classic', '-MSetup::File', '-MPerinci::Tx::Util=use_other_actions', '-e',
                                                  join('',
                                                       '$SPEC{app} = {v=>1.1, args=>{}, features=>{tx=>{v=>2}, idempotent=>1}}; ',
                                                       'sub app { use_other_actions(actions=>[map {["Setup::File::setup_dir",{path=>"'.$dir.'/4$_"}]} 1..100]) } ',
                                                       'Perinci::CmdLine::Classic->new(url=>"/main/app", undo=>1)->run',
                                                   )]},
    ],
};

1;
# ABSTRACT: Benchmark using transaction via Perinci::CmdLine::Classic

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciTxManager::ViaPeriCmd - Benchmark using transaction via Perinci::CmdLine::Classic

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PerinciTxManager::ViaPeriCmd (from Perl distribution Bencher-Scenarios-PerinciTxManager), released on 2018-11-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciTxManager::ViaPeriCmd

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::CmdLine::Classic> 1.812

L<Perinci::Tx::Util> 0.39

L<Setup::File> 0.23

=head1 BENCHMARK PARTICIPANTS

=over

=item * mkdir (command)



=item * setup_dir (command)



=item * setup_dir x10 (command)



=item * setup_dir x100 (command)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m PerinciTxManager::ViaPeriCmd >>):

 #table1#
 +----------------+-----------+-----------+------------+---------+---------+
 | participant    | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +----------------+-----------+-----------+------------+---------+---------+
 | setup_dir      |       4.6 |       220 |        1   | 0.0006  |      20 |
 | mkdir          |       4.7 |       210 |        1   | 0.0003  |      20 |
 | setup_dir x100 |       5.6 |       180 |        1.2 | 0.00046 |      21 |
 | setup_dir x10  |       5.7 |       180 |        1.2 | 0.00025 |      20 |
 +----------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Startup/setup by L<Perinci::CmdLine::Classic> dominates.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciTxManager>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciTxManager>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciTxManager>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

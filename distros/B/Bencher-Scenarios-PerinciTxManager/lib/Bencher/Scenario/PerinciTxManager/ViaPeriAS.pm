package Bencher::Scenario::PerinciTxManager::ViaPeriAS;

our $DATE = '2018-11-11'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $scenario = {
    summary => 'Benchmark using transaction via Perinci::Access::Schemeless',
    modules => {
        'Perinci::Access::Schemeless' => 0,
        'Setup::File' => 0,
        'UUID::Random' => 0,
        'File::Temp' => 0,
    },
    participants => [
        {name => 'perias',
         code_template => q{

use 5.010;
use Perinci::Access::Schemeless;
use Perinci::Tx::Manager;
use UUID::Random;

if (!$main::tempdir) {
    require File::Temp;
    $main::tempdir = File::Temp::tempdir();
    mkdir "$main::tempdir/tm"    or die "Can't mkdir $main::tempdir/tm: $!";
    mkdir "$main::tempdir/setup" or die "Can't mkdir $main::tempdir/setup: $!";
}

state $pa = Perinci::Access::Schemeless->new(
    wrap => 0,
    use_tx => 1,
    custom_tx_manager => sub {
        my $pa = shift;
        Perinci::Tx::Manager->new(pa => $pa, data_dir=>"$main::tempdir/tm");
    },
);

for my $i (1..<num_txs>) {
    my $txid = UUID::Random::generate(); $txid =~ s/-.+//;
    my $res;
    $res = $pa->request(begin_tx => "/", {tx_id=>$txid, summary=>""});
    $res->[0] == 200 or die "Can't begin_tx: $res->[0] - $res->[1]";
    for my $j (1..<num_actions_per_tx>) {
        $res = $pa->request(call => "/Setup/File/setup_dir", {args=>{path=>"$main::tempdir/setup/$j", should_exist=>1}, tx_id=>$txid});
        $res->[0] =~ /\A(200|304)\z/ or die "Can't call #$j: $res->[0] - $res->[1]";
    } # action
    $res = $pa->request(commit_tx => "/", {tx_id=>$txid});
    $res->[0] == 200 or die "Can't commit_tx: $res->[0] - $res->[1]";
} # tx

}
     }],
    datasets => [
        {name=>"tx=1 actions=1"  , args=>{num_txs=>1, num_actions_per_tx=>1}},
        {name=>"tx=1 actions=10" , args=>{num_txs=>1, num_actions_per_tx=>10}},
        {name=>"tx=1 actions=100", args=>{num_txs=>1, num_actions_per_tx=>100}},
    ],
};

1;
# ABSTRACT: Benchmark using transaction via Perinci::Access::Schemeless

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciTxManager::ViaPeriAS - Benchmark using transaction via Perinci::Access::Schemeless

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PerinciTxManager::ViaPeriAS (from Perl distribution Bencher-Scenarios-PerinciTxManager), released on 2018-11-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciTxManager::ViaPeriAS

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::Temp> 0.2304

L<Perinci::Access::Schemeless> 0.88

L<Setup::File> 0.23

L<UUID::Random> 0.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * perias (perl_code)

Code template:

 
 
 use 5.010;
 use Perinci::Access::Schemeless;
 use Perinci::Tx::Manager;
 use UUID::Random;
 
 if (!$main::tempdir) {
     require File::Temp;
     $main::tempdir = File::Temp::tempdir();
     mkdir "$main::tempdir/tm"    or die "Can't mkdir $main::tempdir/tm: $!";
     mkdir "$main::tempdir/setup" or die "Can't mkdir $main::tempdir/setup: $!";
 }
 
 state $pa = Perinci::Access::Schemeless->new(
     wrap => 0,
     use_tx => 1,
     custom_tx_manager => sub {
         my $pa = shift;
         Perinci::Tx::Manager->new(pa => $pa, data_dir=>"$main::tempdir/tm");
     },
 );
 
 for my $i (1..<num_txs>) {
     my $txid = UUID::Random::generate(); $txid =~ s/-.+//;
     my $res;
     $res = $pa->request(begin_tx => "/", {tx_id=>$txid, summary=>""});
     $res->[0] == 200 or die "Can't begin_tx: $res->[0] - $res->[1]";
     for my $j (1..<num_actions_per_tx>) {
         $res = $pa->request(call => "/Setup/File/setup_dir", {args=>{path=>"$main::tempdir/setup/$j", should_exist=>1}, tx_id=>$txid});
         $res->[0] =~ /\A(200|304)\z/ or die "Can't call #$j: $res->[0] - $res->[1]";
     } # action
     $res = $pa->request(commit_tx => "/", {tx_id=>$txid});
     $res->[0] == 200 or die "Can't commit_tx: $res->[0] - $res->[1]";
 } # tx
 




=back

=head1 BENCHMARK DATASETS

=over

=item * tx=1 actions=1

=item * tx=1 actions=10

=item * tx=1 actions=100

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m PerinciTxManager::ViaPeriAS >>):

 #table1#
 +------------------+-----------+------+------------+---------+---------+
 | dataset          | rate (/s) | time | vs_slowest |  errors | samples |
 +------------------+-----------+------+------------+---------+---------+
 | tx=1 actions=100 |      0.47 | 2.1  |        1   | 0.011   |      20 |
 | tx=1 actions=10  |      4.4  | 0.23 |        9.4 | 0.00088 |      20 |
 | tx=1 actions=1   |     30    | 0.04 |       60   | 0.00043 |      21 |
 +------------------+-----------+------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

actions=100 is (2/s) indeed much slower than actions=10 (18/s, 9.7x) and
actions=1 (90/s, 50x).

=head1 PROFILE NOTES

For "tx=1 actions=100" (100 actions in a single transaction, ~1.2s), 1314 SQL
execute() (~0.6s, 0.46ms per execute()) and 1413 do() are performed. The bulk of
the exclusive time is inside execute() (~0.6s, >50%). That means ~13 SQL query
per function action. Or about 6ms SQL execute() overhead per function action.

This makes L<Perinci::Tx::Manager> generally quite slow when we involve a large
number of function actions. To speed things up, we need: 1) a much faster
database; 2) group multiple actions inside a single function action (which is
not always easy to do).

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

package Bencher::Scenario::FileWriteRotate::Writing;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use File::Temp;

our $scenario = {
    summary => 'Benchmark writing using File::Write::Rotate',
    modules => {
        'File::Write::Rotate' => {version=>'0.28'},
    },
    precision => 6,
    participants => [
        {
            name => 'fwr',
            module => 'File::Write::Rotate',
            function => 'write',
            code_template => <<'_',
state $tempdir = File::Temp::tempdir(CLEANUP => 1);
state $fwr = File::Write::Rotate->new(dir => $tempdir, prefix=>'fwr');
$fwr->write(<str>) for 1..1000;
_
        },
        {
            name => 'fwr(lock_mode=none)',
            module => 'File::Write::Rotate',
            function => 'write',
            code_template => <<'_',
state $tempdir = File::Temp::tempdir(CLEANUP => 1);
state $fwr = File::Write::Rotate->new(dir => $tempdir, prefix=>'fwr', lock_mode=>'none');
$fwr->write(<str>) for 1..1000;
_
        },
        {
            name => 'fwr(lock_mode=exclusive)',
            module => 'File::Write::Rotate',
            function => 'write',
            code_template => <<'_',
state $tempdir = File::Temp::tempdir(CLEANUP => 1);
state $fwr = File::Write::Rotate->new(dir => $tempdir, prefix=>'fwr', lock_mode=>'exclusive');
$fwr->write(<str>) for 1..1000;
_
        },
        {
            name => 'fwr(rotate_probability=0.1)',
            module => 'File::Write::Rotate',
            function => 'write',
            code_template => <<'_',
state $tempdir = File::Temp::tempdir(CLEANUP => 1);
state $fwr = File::Write::Rotate->new(dir => $tempdir, prefix=>'fwr', rotate_probability=>0.1);
$fwr->write(<str>) for 1..1000;
_
        },
        {
            name => 'normal',
            code_template => <<'_',
state $tempdir = File::Temp::tempdir(CLEANUP => 1);
state $fh = do { open my $fh, ">", "$tempdir/nf"; $fh };
print { $fh } <str> for 1..1000;
_
        },
    ],
    datasets => [
        {name => "1k x 100b", args => {str => "a" x 100}},
    ],
};

1;
# ABSTRACT: Benchmark writing using File::Write::Rotate

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::FileWriteRotate::Writing - Benchmark writing using File::Write::Rotate

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::FileWriteRotate::Writing (from Perl distribution Bencher-Scenarios-FileWriteRotate), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m FileWriteRotate::Writing

To run module startup overhead benchmark:

 % bencher --module-startup -m FileWriteRotate::Writing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::Write::Rotate> 0.31

=head1 BENCHMARK PARTICIPANTS

=over

=item * fwr (perl_code)

Code template:

 state $tempdir = File::Temp::tempdir(CLEANUP => 1);
 state $fwr = File::Write::Rotate->new(dir => $tempdir, prefix=>'fwr');
 $fwr->write(<str>) for 1..1000;




=item * fwr(lock_mode=none) (perl_code)

Code template:

 state $tempdir = File::Temp::tempdir(CLEANUP => 1);
 state $fwr = File::Write::Rotate->new(dir => $tempdir, prefix=>'fwr', lock_mode=>'none');
 $fwr->write(<str>) for 1..1000;




=item * fwr(lock_mode=exclusive) (perl_code)

Code template:

 state $tempdir = File::Temp::tempdir(CLEANUP => 1);
 state $fwr = File::Write::Rotate->new(dir => $tempdir, prefix=>'fwr', lock_mode=>'exclusive');
 $fwr->write(<str>) for 1..1000;




=item * fwr(rotate_probability=0.1) (perl_code)

Code template:

 state $tempdir = File::Temp::tempdir(CLEANUP => 1);
 state $fwr = File::Write::Rotate->new(dir => $tempdir, prefix=>'fwr', rotate_probability=>0.1);
 $fwr->write(<str>) for 1..1000;




=item * normal (perl_code)

Code template:

 state $tempdir = File::Temp::tempdir(CLEANUP => 1);
 state $fh = do { open my $fh, ">", "$tempdir/nf"; $fh };
 print { $fh } <str> for 1..1000;




=back

=head1 BENCHMARK DATASETS

=over

=item * 1k x 100b

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m FileWriteRotate::Writing >>):

 #table1#
 +-----------------------------+-----------+-----------+------------+-----------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------+-----------+-----------+------------+-----------+---------+
 | fwr                         |        19 |     53    |        1   | 8.4e-05   |       6 |
 | fwr(rotate_probability=0.1) |        24 |     42    |        1.3 | 6.8e-05   |       6 |
 | fwr(lock_mode=exclusive)    |        80 |     10    |        4   |   0.00014 |       7 |
 | fwr(lock_mode=none)         |        79 |     13    |        4.2 | 6.2e-05   |       6 |
 | normal                      |      7900 |      0.13 |      420   | 3.9e-07   |       6 |
 +-----------------------------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-FileWriteRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-FileWriteRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-FileWriteRotate>

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

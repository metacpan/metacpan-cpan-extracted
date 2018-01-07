package Bencher::Scenario::BIP39::GenMnemonic;

our $DATE = '2018-01-03'; # DATE
our $VERSION = '0.001'; # VERSION

use Nodejs::Util qw(get_nodejs_path nodejs_module_path);

our $scenario = {
    summary => 'Benchmark generating 20k 128bit mnemonic phrase',
    participants => [
        {
            module => 'Bitcoin::BIP39',
            code_template => 'for (1..20_000) { Bitcoin::BIP39::gen_bip39_mnemonic() }',
        },
    ],
    precision => 6,
};

{
    unless (get_nodejs_path()) {
        warn "nodejs not available, skipped benchmarking bip39js";
        last;
    }
    unless (nodejs_module_path("bip39")) {
        warn "nodejs module 'bip39' not available, skipped benchmarking bip39js";
        last;
    }
    push @{ $scenario->{participants} }, +{
        name => 'bip39js',
        helper_modules => ["Nodejs::Util"],
        code_template => q|Nodejs::Util::system_nodejs('-e', 'bip39 = require("bip39"); for (i=0; i<20000; i++) { bip39.generateMnemonic() }')|,
    };
}

$scenario;

1;
# ABSTRACT: Benchmark generating 20k 128bit mnemonic phrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::BIP39::GenMnemonic - Benchmark generating 20k 128bit mnemonic phrase

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::BIP39::GenMnemonic (from Perl distribution Bencher-Scenarios-BIP39), released on 2018-01-03.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m BIP39::GenMnemonic

To run module startup overhead benchmark:

 % bencher --module-startup -m BIP39::GenMnemonic

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Bitcoin::BIP39> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * Bitcoin::BIP39 (perl_code)

Code template:

 for (1..20_000) { Bitcoin::BIP39::gen_bip39_mnemonic() }



=item * bip39js (perl_code)

Code template:

 Nodejs::Util::system_nodejs('-e', 'bip39 = require("bip39"); for (i=0; i<20000; i++) { bip39.generateMnemonic() }')



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m BIP39::GenMnemonic >>):

 #table1#
 +----------------+-----------+-----------+------------+---------+---------+
 | participant    | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +----------------+-----------+-----------+------------+---------+---------+
 | bip39js        |      1.1  |       920 |       1    | 0.005   |       6 |
 | Bitcoin::BIP39 |      2.11 |       474 |       1.94 | 0.00015 |       6 |
 +----------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m BIP39::GenMnemonic --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Bitcoin::BIP39      | 1060                         | 4.4                | 16             |       9.9 |                    3.4 |        1   | 1.1e-05 |       6 |
 | perl -e1 (baseline) | 1076                         | 4.4                | 16             |       6.5 |                    0   |        1.5 | 5.3e-05 |       7 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-BIP39>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-BIP39>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-BIP39>

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

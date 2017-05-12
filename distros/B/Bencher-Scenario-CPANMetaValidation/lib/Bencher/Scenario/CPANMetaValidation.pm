package Bencher::Scenario::CPANMetaValidation;

our $DATE = '2017-03-06'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use CPAN::Meta::Validator;
use Data::Sah;
use Sah::Schema::cpan::meta20;

our $scenario = {
    summary => 'Benchmark CPAN Meta validation',
    participants => [
        {
            name => 'sah',
            summary => 'Data::Sah + Sah::Schema::cpan::meta20',
            code_template => 'state $v = Data::Sah::gen_validator("cpan::meta20*", {return_type=>"bool"}); $v->(<meta>) ? 1:0',
        },
        {
            name=>'cmv',
            summary => 'CPAN::Meta::Validator',
            code_template => 'my $cmv = CPAN::Meta::Validator->new(<meta>);
                              if ($cmv->is_valid) { return 1 } else { return 0 }',
        },
    ],
    datasets => [
        {name=>'invalid', result=>0, args=>{meta=>{
            "meta-spec"=>{url=>"http://search.cpan.org/perldoc?CPAN::Meta::Spec", version=>2},
        }}},
        {name=>'min_valid', result=>1, args=>{meta=>{
            name=>"a",
            version=>"1.0",
            "meta-spec"=>{url=>"http://search.cpan.org/perldoc?CPAN::Meta::Spec", version=>2},
            abstract=>"a",
            author=>["foo <foo\@example.com>"],
            dynamic_config=>0,
            generated_by=>"a",
            license=>["perl_5"],
            release_status=>"stable",
        }}},
    ],
};

1;
# ABSTRACT: Benchmark CPAN Meta validation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CPANMetaValidation - Benchmark CPAN Meta validation

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::CPANMetaValidation (from Perl distribution Bencher-Scenario-CPANMetaValidation), released on 2017-03-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CPANMetaValidation

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * sah (perl_code)

Data::Sah + Sah::Schema::cpan::meta20.

Code template:

 state $v = Data::Sah::gen_validator("cpan::meta20*", {return_type=>"bool"}); $v->(<meta>) ? 1:0



=item * cmv (perl_code)

CPAN::Meta::Validator.

Code template:

 my $cmv = CPAN::Meta::Validator->new(<meta>);
                               if ($cmv->is_valid) { return 1 } else { return 0 }



=back

=head1 BENCHMARK DATASETS

=over

=item * invalid

=item * min_valid

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m CPANMetaValidation >>):

 #table1#
 +-------------+-----------+-----------+-----------+------------+---------+---------+
 | participant | dataset   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+-----------+------------+---------+---------+
 | sah         | min_valid |      4400 |     230   |        1   | 4.8e-07 |      20 |
 | cmv         | min_valid |     36000 |      27   |        8.3 | 4.3e-08 |      31 |
 | cmv         | invalid   |     39000 |      25   |        8.9 |   4e-08 |      20 |
 | sah         | invalid   |    430000 |       2.3 |       97   | 3.3e-09 |      20 |
 +-------------+-----------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-CPANMetaValidation>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-CPANMetaValidation>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-CPANMetaValidation>

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

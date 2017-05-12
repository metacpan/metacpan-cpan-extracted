package Bencher::Scenario::PERLANCAR::method_call_using_variable;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark calling a method with the name of the method in a variable',
    description => <<'_',


_
    participants => [
        {
            name=>'class, literal',
            code_template=>'Foo->meth',
        },
        {
            name=>'class, variable',
            code_template=>'state $meth = "meth"; Foo->$meth',
        },
        {
            name=>'object, literal',
            code_template=>'state $obj = Foo->new; $obj->meth',
        },
        {
            name=>'object, variable',
            code_template=>'state $obj = Foo->new; state $meth = "meth"; $obj->$meth',
        },
    ],
};

package
    Foo;

sub new { my $class = shift; bless {}, $class }

sub meth {}

1;
# ABSTRACT: Benchmark calling a method with the name of the method in a variable

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCAR::method_call_using_variable - Benchmark calling a method with the name of the method in a variable

=head1 VERSION

This document describes version 0.06 of Bencher::Scenario::PERLANCAR::method_call_using_variable (from Perl distribution Bencher-Scenarios-PERLANCAR), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCAR::method_call_using_variable

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

=head1 BENCHMARK PARTICIPANTS

=over

=item * class, literal (perl_code)

Code template:

 Foo->meth



=item * class, variable (perl_code)

Code template:

 state $meth = "meth"; Foo->$meth



=item * object, literal (perl_code)

Code template:

 state $obj = Foo->new; $obj->meth



=item * object, variable (perl_code)

Code template:

 state $obj = Foo->new; state $meth = "meth"; $obj->$meth



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCAR::method_call_using_variable >>):

 #table1#
 +------------------+-----------+-----------+------------+---------+---------+
 | participant      | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------+-----------+-----------+------------+---------+---------+
 | class, variable  |   6500000 |     150   |       1    | 6.2e-10 |      23 |
 | object, variable |   6600000 |     150   |       1    | 2.1e-10 |      22 |
 | object, literal  |  10400000 |      96   |       1.6  |   5e-11 |      22 |
 | class, literal   |  10900000 |      91.9 |       1.67 | 7.1e-11 |      27 |
 +------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Using variable as method name is an extra indirection which has a cost.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PERLANCAR>

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

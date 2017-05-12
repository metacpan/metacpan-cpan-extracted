package Bencher::Scenario::PERLANCAR::require;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark require() in a tight loop/subroutine',
    description => <<'_',

`require()` can be put inside a block (like a subroutine) to delay loading a
module:

    sub foo {
        require Some::Module;
        ...
    }

After a module is loaded, the next `require()` should be cheap enough: it just
checks against `%INC` to see if an entry for the module is there. So it should
just be the cost of a single hash lookup.

However, for very tight loops/subroutines, you can avoid (reduce) this cost by
putting the `require()` inside a state variable, which will cause the
`require()` to be evaluated just once:

    sub foo {
        state $dummy = do { require Some::Module };
        ...
    }

There is a per-sub-invocation cost too of setting up the state variable
`$dummy`. But this cost is several times smaller.

Or, alternatively, you might also want to decide to put the `require()`
statement outside of the block/subroutine.

_
    participants => [
        {
            name=>'baseline_empty_sub',
            code_template=>' ',
        },
        {
            name=>'require_in_sub',
            code_template=>'require File::Find',
        },
        {
            name=>'require_in_sub_pm',
            code_template=>'require "File/Find.pm"',
            summary => 'There is no effect of using the path form',
        },
        {
            name=>'require_in_state',
            code_template=>'state $dummy = do { require File::Find }',
        },
    ],
};

1;
# ABSTRACT: Benchmark require() in a tight loop/subroutine

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCAR::require - Benchmark require() in a tight loop/subroutine

=head1 VERSION

This document describes version 0.06 of Bencher::Scenario::PERLANCAR::require (from Perl distribution Bencher-Scenarios-PERLANCAR), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCAR::require

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

C<require()> can be put inside a block (like a subroutine) to delay loading a
module:

 sub foo {
     require Some::Module;
     ...
 }

After a module is loaded, the next C<require()> should be cheap enough: it just
checks against C<%INC> to see if an entry for the module is there. So it should
just be the cost of a single hash lookup.

However, for very tight loops/subroutines, you can avoid (reduce) this cost by
putting the C<require()> inside a state variable, which will cause the
C<require()> to be evaluated just once:

 sub foo {
     state $dummy = do { require Some::Module };
     ...
 }

There is a per-sub-invocation cost too of setting up the state variable
C<$dummy>. But this cost is several times smaller.

Or, alternatively, you might also want to decide to put the C<require()>
statement outside of the block/subroutine.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline_empty_sub (perl_code)

Code template:

  



=item * require_in_sub (perl_code)

Code template:

 require File::Find



=item * require_in_sub_pm (perl_code)

There is no effect of using the path form.

Code template:

 require "File/Find.pm"



=item * require_in_state (perl_code)

Code template:

 state $dummy = do { require File::Find }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCAR::require >>):

 #table1#
 +--------------------+------------+-----------+------------+---------+---------+
 | participant        |  rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +--------------------+------------+-----------+------------+---------+---------+
 | require_in_sub_pm  |   17000000 |      57   |       1    | 2.1e-10 |      20 |
 | require_in_sub     |   17700000 |      56.6 |       1.01 | 5.2e-11 |      20 |
 | require_in_state   |  140000000 |       7.2 |       7.9  | 2.6e-11 |      20 |
 | baseline_empty_sub | -150000000 |      -6.5 |      -8.8  | 6.3e-11 |      20 |
 +--------------------+------------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

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

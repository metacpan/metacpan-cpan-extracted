package Bencher::Scenario::Accessors::GeneratorStartup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.14'; # VERSION

use Bencher::ScenarioUtil::Accessors;

my $classes = \%Bencher::ScenarioUtil::Accessors::classes;

our $scenario = {
    summary => 'Benchmark startup of various accessor generators',
    module_startup => 1,
    modules => {
    },
    participants => [
        map {
            my $spec = $classes->{$_};
            +{ (module=>$spec->{generator}) x !!$spec->{generator} };
        } keys %$classes,
    ],
};

1;
# ABSTRACT: Benchmark startup of various accessor generators

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Accessors::GeneratorStartup - Benchmark startup of various accessor generators

=head1 VERSION

This document describes version 0.14 of Bencher::Scenario::Accessors::GeneratorStartup (from Perl distribution Bencher-Scenarios-Accessors), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::GeneratorStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Class::Accessor> 0.34

L<Class::Accessor::Array> 0.02

L<Class::InsideOut> 1.13

L<Class::Struct> 0.65

L<Class::Tiny> 1.004

L<Class::XSAccessor> 1.19

L<Class::XSAccessor::Array> 1.19

L<Evo::Class>

L<Mo> 0.40

L<Mojo::Base>

L<Mojo::Base::XS> 0.07

L<Moo> 2.002004

L<Moops> 0.034

L<Moos> 0.30

L<Moose> 2.1805

L<Mouse> v2.4.5

L<Object::Simple> 3.17

L<Object::Tiny> 1.08

L<Object::Tiny::RW> 1.07

L<Object::Tiny::RW::XS> 0.03

L<Object::Tiny::XS> 1.01

L<Simple::Accessor> 1.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Tiny (perl_code)

L<Class::Tiny>



=item * Moo (perl_code)

L<Moo>



=item * Object::Tiny::XS (perl_code)

L<Object::Tiny::XS>



=item *  (perl_code)



=item * Object::Tiny (perl_code)

L<Object::Tiny>



=item * Class::XSAccessor (perl_code)

L<Class::XSAccessor>



=item * Class::InsideOut (perl_code)

L<Class::InsideOut>



=item *  (perl_code)



=item * Object::Tiny::RW::XS (perl_code)

L<Object::Tiny::RW::XS>



=item * Mouse (perl_code)

L<Mouse>



=item * Object::Simple (perl_code)

L<Object::Simple>



=item * Moos (perl_code)

L<Moos>



=item * Mo (perl_code)

L<Mo>



=item * Mojo::Base (perl_code)

L<Mojo::Base>



=item *  (perl_code)



=item * Simple::Accessor (perl_code)

L<Simple::Accessor>



=item * Class::Struct (perl_code)

L<Class::Struct>



=item * Object::Tiny::RW (perl_code)

L<Object::Tiny::RW>



=item * Class::Accessor::Array (perl_code)

L<Class::Accessor::Array>



=item * Class::Accessor (perl_code)

L<Class::Accessor>



=item * Moops (perl_code)

L<Moops>



=item * Mojo::Base::XS (perl_code)

L<Mojo::Base::XS>



=item * Moose (perl_code)

L<Moose>



=item * Class::XSAccessor::Array (perl_code)

L<Class::XSAccessor::Array>



=item * Evo::Class (perl_code)

L<Evo::Class>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Accessors::GeneratorStartup >>):

 #table1#
 +--------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant              | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +--------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Moose                    | 5                            | 8.8                | 43             |     150   |                  145.2 |        1   |   0.00038 |      20 |
 | Moops                    | 0.85                         | 4.2                | 16             |      67   |                   62.2 |        2.2 |   0.00017 |      20 |
 | Evo::Class               | 14                           | 18                 | 50             |      36   |                   31.2 |        4.2 |   0.00015 |      20 |
 | Mouse                    | 1.4                          | 4.9                | 19             |      24   |                   19.2 |        6.3 |   0.0001  |      21 |
 | Moos                     | 1.4                          | 4.9                | 19             |      20   |                   15.2 |        7.7 |   0.00012 |      20 |
 | Moo                      | 1.4                          | 4.8                | 19             |      19   |                   14.2 |        8.1 | 5.8e-05   |      20 |
 | Class::InsideOut         | 1.8                          | 5.3                | 19             |      15   |                   10.2 |        9.8 | 5.7e-05   |      20 |
 | Mojo::Base               | 0.86                         | 4.1                | 16             |      15   |                   10.2 |        9.9 | 7.6e-05   |      20 |
 | Class::Tiny              | 2.1                          | 5.5                | 21             |      14   |                    9.2 |       11   |   2e-05   |      20 |
 | Class::Struct            | 0.82                         | 4.1                | 16             |      12   |                    7.2 |       12   | 5.8e-05   |      20 |
 | Class::XSAccessor::Array | 0.91                         | 4.3                | 18             |      12   |                    7.2 |       13   | 7.1e-05   |      20 |
 | Object::Tiny::RW::XS     | 0.82                         | 4.1                | 16             |      12   |                    7.2 |       13   | 7.5e-05   |      20 |
 | Object::Simple           | 3.1                          | 6.6                | 24             |      12   |                    7.2 |       13   | 7.9e-05   |      20 |
 | Object::Tiny::XS         | 0.82                         | 4.1                | 16             |      12   |                    7.2 |       13   | 5.2e-05   |      20 |
 | Class::Accessor          | 0.86                         | 4.2                | 16             |      11   |                    6.2 |       13   | 8.8e-05   |      20 |
 | Class::XSAccessor        | 1.4                          | 4.8                | 19             |      11   |                    6.2 |       13   |   0.0001  |      20 |
 | Mojo::Base::XS           | 1.4                          | 4.8                | 19             |       8.4 |                    3.6 |       18   |   3e-05   |      20 |
 | Simple::Accessor         | 1.8                          | 5.2                | 21             |       7.5 |                    2.7 |       20   | 3.1e-05   |      20 |
 | Mo                       | 2.3                          | 5.8                | 26             |       6.9 |                    2.1 |       22   | 3.4e-05   |      20 |
 | Class::Accessor::Array   | 1.4                          | 4.7                | 17             |       6.9 |                    2.1 |       22   | 2.9e-05   |      20 |
 | Object::Tiny             | 0.86                         | 4.3                | 16             |       5.9 |                    1.1 |       26   |   2e-05   |      21 |
 | Object::Tiny::RW         | 0.88                         | 4.2                | 16             |       5.8 |                    1   |       26   | 2.4e-05   |      21 |
 | perl -e1 (baseline)      | 1.7                          | 5.1                | 19             |       4.8 |                    0   |       32   | 1.3e-05   |      20 |
 +--------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Accessors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Accessors>

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

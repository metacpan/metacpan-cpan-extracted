package Bencher::Scenario::Accessors::ClassStartup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.14'; # VERSION

use Bencher::ScenarioUtil::Accessors;

my $classes = \%Bencher::ScenarioUtil::Accessors::classes;

our $scenario = {
    summary => 'Benchmark startup of classes using various accessor generators',
    module_startup => 1,
    modules => {
        # include the generator modules here so we can show their versions in
        # sample benchmark results produced by PWP:Bencher::Scenario
        (map { $_=>0 } grep {defined} map { $classes->{$_}{generator} }
             keys %$classes),
    },
    participants => [
        map {
            #my $spec = $classes->{$_};
            +{ module=>$_ };
        } keys %$classes,
    ],
};

1;
# ABSTRACT: Benchmark startup of classes using various accessor generators

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Accessors::ClassStartup - Benchmark startup of classes using various accessor generators

=head1 VERSION

This document describes version 0.14 of Bencher::Scenario::Accessors::ClassStartup (from Perl distribution Bencher-Scenarios-Accessors), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::ClassStartup

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

L<Perl::Examples::Accessors::Array> 0.12

L<Perl::Examples::Accessors::ClassAccessor> 0.12

L<Perl::Examples::Accessors::ClassAccessorArray> 0.12

L<Perl::Examples::Accessors::ClassInsideOut> 0.12

L<Perl::Examples::Accessors::ClassStruct> 0.12

L<Perl::Examples::Accessors::ClassTiny> 0.12

L<Perl::Examples::Accessors::ClassXSAccessor> 0.12

L<Perl::Examples::Accessors::ClassXSAccessorArray> 0.12

L<Perl::Examples::Accessors::EvoClass> 0.12

L<Perl::Examples::Accessors::Hash> 0.12

L<Perl::Examples::Accessors::Mo> 0.12

L<Perl::Examples::Accessors::MojoBase> 0.12

L<Perl::Examples::Accessors::MojoBaseXS> 0.12

L<Perl::Examples::Accessors::Moo> 0.12

L<Perl::Examples::Accessors::Moops> 0.12

L<Perl::Examples::Accessors::Moos> 0.12

L<Perl::Examples::Accessors::Moose> 0.12

L<Perl::Examples::Accessors::Mouse> 0.12

L<Perl::Examples::Accessors::ObjectSimple> 0.12

L<Perl::Examples::Accessors::ObjectTiny> 0.12

L<Perl::Examples::Accessors::ObjectTinyRW> 0.12

L<Perl::Examples::Accessors::ObjectTinyRWXS> 0.12

L<Perl::Examples::Accessors::ObjectTinyXS> 0.12

L<Perl::Examples::Accessors::Scalar> 0.12

L<Perl::Examples::Accessors::SimpleAccessor> 0.12

L<Simple::Accessor> 1.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Perl::Examples::Accessors::ClassTiny (perl_code)

L<Perl::Examples::Accessors::ClassTiny>



=item * Perl::Examples::Accessors::Moo (perl_code)

L<Perl::Examples::Accessors::Moo>



=item * Perl::Examples::Accessors::ObjectTinyXS (perl_code)

L<Perl::Examples::Accessors::ObjectTinyXS>



=item * Perl::Examples::Accessors::Scalar (perl_code)

L<Perl::Examples::Accessors::Scalar>



=item * Perl::Examples::Accessors::ObjectTiny (perl_code)

L<Perl::Examples::Accessors::ObjectTiny>



=item * Perl::Examples::Accessors::ClassXSAccessor (perl_code)

L<Perl::Examples::Accessors::ClassXSAccessor>



=item * Perl::Examples::Accessors::ClassInsideOut (perl_code)

L<Perl::Examples::Accessors::ClassInsideOut>



=item * Perl::Examples::Accessors::Hash (perl_code)

L<Perl::Examples::Accessors::Hash>



=item * Perl::Examples::Accessors::ObjectTinyRWXS (perl_code)

L<Perl::Examples::Accessors::ObjectTinyRWXS>



=item * Perl::Examples::Accessors::Mouse (perl_code)

L<Perl::Examples::Accessors::Mouse>



=item * Perl::Examples::Accessors::ObjectSimple (perl_code)

L<Perl::Examples::Accessors::ObjectSimple>



=item * Perl::Examples::Accessors::Moos (perl_code)

L<Perl::Examples::Accessors::Moos>



=item * Perl::Examples::Accessors::Mo (perl_code)

L<Perl::Examples::Accessors::Mo>



=item * Perl::Examples::Accessors::MojoBase (perl_code)

L<Perl::Examples::Accessors::MojoBase>



=item * Perl::Examples::Accessors::Array (perl_code)

L<Perl::Examples::Accessors::Array>



=item * Perl::Examples::Accessors::SimpleAccessor (perl_code)

L<Perl::Examples::Accessors::SimpleAccessor>



=item * Perl::Examples::Accessors::ClassStruct (perl_code)

L<Perl::Examples::Accessors::ClassStruct>



=item * Perl::Examples::Accessors::ObjectTinyRW (perl_code)

L<Perl::Examples::Accessors::ObjectTinyRW>



=item * Perl::Examples::Accessors::ClassAccessorArray (perl_code)

L<Perl::Examples::Accessors::ClassAccessorArray>



=item * Perl::Examples::Accessors::ClassAccessor (perl_code)

L<Perl::Examples::Accessors::ClassAccessor>



=item * Perl::Examples::Accessors::Moops (perl_code)

L<Perl::Examples::Accessors::Moops>



=item * Perl::Examples::Accessors::MojoBaseXS (perl_code)

L<Perl::Examples::Accessors::MojoBaseXS>



=item * Perl::Examples::Accessors::Moose (perl_code)

L<Perl::Examples::Accessors::Moose>



=item * Perl::Examples::Accessors::ClassXSAccessorArray (perl_code)

L<Perl::Examples::Accessors::ClassXSAccessorArray>



=item * Perl::Examples::Accessors::EvoClass (perl_code)

L<Perl::Examples::Accessors::EvoClass>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Accessors::ClassStartup >>):

 #table1#
 +-------------------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                                     | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Perl::Examples::Accessors::Moops                | 0.92                         | 4.3                | 18             |     170   |                  165.4 |        1   |   0.00021 |      21 |
 | Perl::Examples::Accessors::Moose                | 1.5                          | 4.9                | 19             |     160   |                  155.4 |        1.1 |   0.00037 |      20 |
 | Perl::Examples::Accessors::EvoClass             | 0.82                         | 4.1                | 16             |      36   |                   31.4 |        4.7 |   7e-05   |      20 |
 | Perl::Examples::Accessors::Moo                  | 1.4                          | 4.8                | 19             |      30   |                   25.4 |        5.6 | 4.4e-05   |      20 |
 | Perl::Examples::Accessors::Mouse                | 1.4                          | 4.8                | 19             |      24   |                   19.4 |        6.9 |   7e-05   |      20 |
 | Perl::Examples::Accessors::Moos                 | 0.88                         | 4.1                | 16             |      19   |                   14.4 |        8.6 | 4.5e-05   |      22 |
 | Perl::Examples::Accessors::ClassInsideOut       | 0.84                         | 4.2                | 16             |      16   |                   11.4 |       10   | 8.1e-05   |      21 |
 | Perl::Examples::Accessors::MojoBase             | 0.84                         | 4.1                | 16             |      15   |                   10.4 |       11   | 7.7e-05   |      21 |
 | Perl::Examples::Accessors::ClassTiny            | 3.8                          | 7.3                | 27             |      14   |                    9.4 |       12   | 4.8e-05   |      20 |
 | Perl::Examples::Accessors::ClassStruct          | 0.88                         | 4.3                | 16             |      12   |                    7.4 |       13   |   5e-05   |      22 |
 | Perl::Examples::Accessors::ObjectSimple         | 2.3                          | 5.8                | 26             |      12   |                    7.4 |       14   | 4.5e-05   |      22 |
 | Perl::Examples::Accessors::ClassXSAccessorArray | 4.1                          | 7.6                | 27             |      12   |                    7.4 |       14   | 3.3e-05   |      20 |
 | Perl::Examples::Accessors::ObjectTinyXS         | 0.83                         | 4.1                | 16             |      12   |                    7.4 |       14   | 4.9e-05   |      20 |
 | Perl::Examples::Accessors::ClassAccessor        | 16                           | 20                 | 76             |      12   |                    7.4 |       14   | 6.6e-05   |      20 |
 | Perl::Examples::Accessors::ClassXSAccessor      | 1.9                          | 5.2                | 19             |      11   |                    6.4 |       15   | 6.7e-05   |      20 |
 | Perl::Examples::Accessors::ObjectTinyRWXS       | 3.2                          | 6.6                | 24             |      11   |                    6.4 |       15   | 1.7e-05   |      20 |
 | Perl::Examples::Accessors::MojoBaseXS           | 15                           | 18                 | 50             |       8.3 |                    3.7 |       20   | 1.7e-05   |      20 |
 | Perl::Examples::Accessors::SimpleAccessor       | 1.5                          | 5                  | 17             |       7.4 |                    2.8 |       23   | 2.8e-05   |      20 |
 | Perl::Examples::Accessors::Mo                   | 1.8                          | 5.2                | 21             |       7   |                    2.4 |       24   | 1.2e-05   |      20 |
 | Perl::Examples::Accessors::ClassAccessorArray   | 1.4                          | 4.8                | 19             |       7   |                    2.4 |       24   |   3e-05   |      20 |
 | Perl::Examples::Accessors::ObjectTinyRW         | 0.88                         | 4.3                | 16             |       5.8 |                    1.2 |       29   | 2.5e-05   |      20 |
 | Perl::Examples::Accessors::ObjectTiny           | 1.4                          | 4.8                | 19             |       5.7 |                    1.1 |       29   | 2.1e-05   |      20 |
 | Perl::Examples::Accessors::Scalar               | 0.88                         | 4.2                | 16             |       5.1 |                    0.5 |       33   | 2.3e-05   |      20 |
 | Perl::Examples::Accessors::Hash                 | 1.4                          | 4.9                | 19             |       5   |                    0.4 |       33   | 1.4e-05   |      20 |
 | Perl::Examples::Accessors::Array                | 0.89                         | 4.2                | 16             |       5   |                    0.4 |       33   | 8.7e-06   |      20 |
 | perl -e1 (baseline)                             | 1.7                          | 5.2                | 19             |       4.6 |                    0   |       36   | 5.3e-06   |      20 |
 +-------------------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


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

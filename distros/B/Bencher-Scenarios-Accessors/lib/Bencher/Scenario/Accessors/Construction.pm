package Bencher::Scenario::Accessors::Construction;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.14'; # VERSION

use Bencher::ScenarioUtil::Accessors;

my $classes = \%Bencher::ScenarioUtil::Accessors::classes;

our $scenario = {
    summary => 'Benchmark object construction',
    modules => {
        # force minimum version
        'Perl::Examples::Accessors' => {version=>0.05},

        # include the generator modules here so we can show their versions in
        # sample benchmark results produced by PWP:Bencher::Scenario
        (map { $_=>0 } grep {defined} map { $classes->{$_}{generator} }
             keys %$classes),
    },
    participants => [
        map {
            my $spec = $classes->{$_};
            +{
                name => $spec->{generator} || $spec->{name},
                module => $_,
                code_template => "${_}->new",
            };
        } keys %$classes,
    ],
    include_result_size => 1,
};

1;
# ABSTRACT: Benchmark object construction

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Accessors::Construction - Benchmark object construction

=head1 VERSION

This document describes version 0.14 of Bencher::Scenario::Accessors::Construction (from Perl distribution Bencher-Scenarios-Accessors), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::Construction

To run module startup overhead benchmark:

 % bencher --module-startup -m Accessors::Construction

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

L<Perl::Examples::Accessors> 0.12

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

=item * Class::Tiny (perl_code)

Code template:

 Perl::Examples::Accessors::ClassTiny->new



=item * Moo (perl_code)

Code template:

 Perl::Examples::Accessors::Moo->new



=item * Object::Tiny::XS (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTinyXS->new



=item * no generator (scalar-based) (perl_code)

Code template:

 Perl::Examples::Accessors::Scalar->new



=item * Object::Tiny (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTiny->new



=item * Class::XSAccessor (perl_code)

Code template:

 Perl::Examples::Accessors::ClassXSAccessor->new



=item * Class::InsideOut (perl_code)

Code template:

 Perl::Examples::Accessors::ClassInsideOut->new



=item * no generator (hash-based) (perl_code)

Code template:

 Perl::Examples::Accessors::Hash->new



=item * Object::Tiny::RW::XS (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTinyRWXS->new



=item * Mouse (perl_code)

Code template:

 Perl::Examples::Accessors::Mouse->new



=item * Object::Simple (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectSimple->new



=item * Moos (perl_code)

Code template:

 Perl::Examples::Accessors::Moos->new



=item * Mo (perl_code)

Code template:

 Perl::Examples::Accessors::Mo->new



=item * Mojo::Base (perl_code)

Code template:

 Perl::Examples::Accessors::MojoBase->new



=item * no generator (array-based) (perl_code)

Code template:

 Perl::Examples::Accessors::Array->new



=item * Simple::Accessor (perl_code)

Code template:

 Perl::Examples::Accessors::SimpleAccessor->new



=item * Class::Struct (perl_code)

Code template:

 Perl::Examples::Accessors::ClassStruct->new



=item * Object::Tiny::RW (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTinyRW->new



=item * Class::Accessor::Array (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessorArray->new



=item * Class::Accessor (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessor->new



=item * Moops (perl_code)

Code template:

 Perl::Examples::Accessors::Moops->new



=item * Mojo::Base::XS (perl_code)

Code template:

 Perl::Examples::Accessors::MojoBaseXS->new



=item * Moose (perl_code)

Code template:

 Perl::Examples::Accessors::Moose->new



=item * Class::XSAccessor::Array (perl_code)

Code template:

 Perl::Examples::Accessors::ClassXSAccessorArray->new



=item * Evo::Class (perl_code)

Code template:

 Perl::Examples::Accessors::EvoClass->new



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Accessors::Construction >>):

 #table1#
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Moos                        |    142190 |    7.033  |      1     | 3.5e-11 |      23 |
 | Class::InsideOut            |    340000 |    3      |      2.4   | 3.3e-09 |      20 |
 | Simple::Accessor            |    460000 |    2.2    |      3.2   |   3e-09 |      25 |
 | Class::Tiny                 |    650000 |    1.5    |      4.6   | 3.4e-09 |      20 |
 | Moose                       |    820000 |    1.2    |      5.8   | 1.2e-09 |      20 |
 | Evo::Class                  |    830000 |    1.2    |      5.9   | 1.2e-09 |      21 |
 | Mo                          |   1080000 |    0.928  |      7.58  | 4.2e-10 |      20 |
 | Class::Struct               |   1217000 |    0.8217 |      8.559 | 3.4e-11 |      20 |
 | Moops                       |   1310000 |    0.763  |      9.22  |   4e-10 |      22 |
 | Moo                         |   1345000 |    0.7435 |      9.46  | 1.2e-11 |      20 |
 | Class::Accessor             |   1539000 |    0.6496 |     10.83  | 1.1e-11 |      20 |
 | Mouse                       |   1700000 |    0.58   |     12     | 6.2e-10 |      20 |
 | no generator (array-based)  |   2129000 |    0.4698 |     14.97  | 3.5e-11 |      20 |
 | no generator (hash-based)   |   2585000 |    0.3868 |     18.18  | 1.1e-11 |      20 |
 | Object::Simple              |   2686000 |    0.3723 |     18.89  | 1.1e-11 |      20 |
 | Mojo::Base                  |   2746000 |    0.3642 |     19.31  | 1.2e-11 |      20 |
 | Object::Tiny::RW            |   2800000 |    0.35   |     20     | 8.3e-10 |      20 |
 | Object::Tiny                |   2833000 |    0.353  |     19.92  | 1.1e-11 |      20 |
 | Class::Accessor::Array      |   2966000 |    0.3372 |     20.86  | 1.1e-11 |      22 |
 | no generator (scalar-based) |   3000000 |    0.334  |     21.1   | 2.1e-10 |      20 |
 | Class::XSAccessor           |   4240000 |    0.236  |     29.8   | 1.4e-10 |      21 |
 | Object::Tiny::RW::XS        |   4270000 |    0.234  |     30.1   |   1e-10 |      20 |
 | Object::Tiny::XS            |   4340000 |    0.231  |     30.5   | 4.5e-11 |      20 |
 | Class::XSAccessor::Array    |   4400000 |    0.23   |     31     | 3.1e-10 |      20 |
 | Mojo::Base::XS              |   4559000 |    0.2194 |     32.06  | 1.1e-11 |      30 |
 +-----------------------------+-----------+-----------+------------+---------+---------+


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

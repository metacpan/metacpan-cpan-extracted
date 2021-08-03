package Bencher::Scenario::Accessors::ClassStartup;

our $DATE = '2021-08-03'; # DATE
our $VERSION = '0.150'; # VERSION

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

This document describes version 0.150 of Bencher::Scenario::Accessors::ClassStartup (from Perl distribution Bencher-Scenarios-Accessors), released on 2021-08-03.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::ClassStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Class::Accessor> 0.51

L<Class::Accessor::Array> 0.032

L<Class::Accessor::PackedString> 0.001

L<Class::Accessor::PackedString::Set> 0.001

L<Class::InsideOut> 1.14

L<Class::Struct> 0.66

L<Class::Tiny> 1.008

L<Class::XSAccessor> 1.19

L<Class::XSAccessor::Array> 1.19

L<Mo> 0.40

L<Mojo::Base>

L<Mojo::Base::XS> 0.07

L<Moo> 2.004004

L<Moops> 0.038

L<Moos> 0.30

L<Moose> 2.2015

L<Mouse> v2.5.10

L<Object::Pad> 0.46

L<Object::Simple> 3.19

L<Object::Tiny> 1.09

L<Object::Tiny::RW> 1.07

L<Object::Tiny::RW::XS> 0.04

L<Object::Tiny::XS> 1.01

L<Perl::Examples::Accessors::Array> 0.132

L<Perl::Examples::Accessors::ClassAccessor> 0.132

L<Perl::Examples::Accessors::ClassAccessorArray> 0.132

L<Perl::Examples::Accessors::ClassAccessorPackedString> 0.132

L<Perl::Examples::Accessors::ClassAccessorPackedStringSet> 0.132

L<Perl::Examples::Accessors::ClassInsideOut> 0.132

L<Perl::Examples::Accessors::ClassStruct> 0.132

L<Perl::Examples::Accessors::ClassTiny> 0.132

L<Perl::Examples::Accessors::ClassXSAccessor> 0.132

L<Perl::Examples::Accessors::ClassXSAccessorArray> 0.132

L<Perl::Examples::Accessors::Hash> 0.132

L<Perl::Examples::Accessors::Mo> 0.132

L<Perl::Examples::Accessors::MojoBase> 0.132

L<Perl::Examples::Accessors::MojoBaseXS> 0.132

L<Perl::Examples::Accessors::Moo> 0.132

L<Perl::Examples::Accessors::Moops> 0.132

L<Perl::Examples::Accessors::Moos> 0.132

L<Perl::Examples::Accessors::Moose> 0.132

L<Perl::Examples::Accessors::Mouse> 0.132

L<Perl::Examples::Accessors::ObjectPad> 0.132

L<Perl::Examples::Accessors::ObjectSimple> 0.132

L<Perl::Examples::Accessors::ObjectTiny> 0.132

L<Perl::Examples::Accessors::ObjectTinyRW> 0.132

L<Perl::Examples::Accessors::ObjectTinyRWXS> 0.132

L<Perl::Examples::Accessors::ObjectTinyXS> 0.132

L<Perl::Examples::Accessors::Scalar> 0.132

L<Perl::Examples::Accessors::SimpleAccessor> 0.132

L<Simple::Accessor> 1.13

=head1 BENCHMARK PARTICIPANTS

=over

=item * Perl::Examples::Accessors::ClassAccessorPackedString (perl_code)

L<Perl::Examples::Accessors::ClassAccessorPackedString>



=item * Perl::Examples::Accessors::ClassAccessorArray (perl_code)

L<Perl::Examples::Accessors::ClassAccessorArray>



=item * Perl::Examples::Accessors::MojoBase (perl_code)

L<Perl::Examples::Accessors::MojoBase>



=item * Perl::Examples::Accessors::ObjectTiny (perl_code)

L<Perl::Examples::Accessors::ObjectTiny>



=item * Perl::Examples::Accessors::SimpleAccessor (perl_code)

L<Perl::Examples::Accessors::SimpleAccessor>



=item * Perl::Examples::Accessors::ObjectTinyRW (perl_code)

L<Perl::Examples::Accessors::ObjectTinyRW>



=item * Perl::Examples::Accessors::Moose (perl_code)

L<Perl::Examples::Accessors::Moose>



=item * Perl::Examples::Accessors::Scalar (perl_code)

L<Perl::Examples::Accessors::Scalar>



=item * Perl::Examples::Accessors::Moos (perl_code)

L<Perl::Examples::Accessors::Moos>



=item * Perl::Examples::Accessors::ObjectPad (perl_code)

L<Perl::Examples::Accessors::ObjectPad>



=item * Perl::Examples::Accessors::ObjectTinyXS (perl_code)

L<Perl::Examples::Accessors::ObjectTinyXS>



=item * Perl::Examples::Accessors::Mouse (perl_code)

L<Perl::Examples::Accessors::Mouse>



=item * Perl::Examples::Accessors::Mo (perl_code)

L<Perl::Examples::Accessors::Mo>



=item * Perl::Examples::Accessors::ObjectSimple (perl_code)

L<Perl::Examples::Accessors::ObjectSimple>



=item * Perl::Examples::Accessors::Moops (perl_code)

L<Perl::Examples::Accessors::Moops>



=item * Perl::Examples::Accessors::ClassStruct (perl_code)

L<Perl::Examples::Accessors::ClassStruct>



=item * Perl::Examples::Accessors::ClassXSAccessor (perl_code)

L<Perl::Examples::Accessors::ClassXSAccessor>



=item * Perl::Examples::Accessors::ObjectTinyRWXS (perl_code)

L<Perl::Examples::Accessors::ObjectTinyRWXS>



=item * Perl::Examples::Accessors::Array (perl_code)

L<Perl::Examples::Accessors::Array>



=item * Perl::Examples::Accessors::Moo (perl_code)

L<Perl::Examples::Accessors::Moo>



=item * Perl::Examples::Accessors::ClassInsideOut (perl_code)

L<Perl::Examples::Accessors::ClassInsideOut>



=item * Perl::Examples::Accessors::MojoBaseXS (perl_code)

L<Perl::Examples::Accessors::MojoBaseXS>



=item * Perl::Examples::Accessors::ClassAccessor (perl_code)

L<Perl::Examples::Accessors::ClassAccessor>



=item * Perl::Examples::Accessors::ClassTiny (perl_code)

L<Perl::Examples::Accessors::ClassTiny>



=item * Perl::Examples::Accessors::Hash (perl_code)

L<Perl::Examples::Accessors::Hash>



=item * Perl::Examples::Accessors::ClassAccessorPackedStringSet (perl_code)

L<Perl::Examples::Accessors::ClassAccessorPackedStringSet>



=item * Perl::Examples::Accessors::ClassXSAccessorArray (perl_code)

L<Perl::Examples::Accessors::ClassXSAccessorArray>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::ClassStartup

Result formatted as table:

 #table1#
 +---------------------------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                                             | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Perl::Examples::Accessors::Moops                        |     140   |             135   |                 0.00% |              2751.06% |   0.0011  |      20 |
 | Perl::Examples::Accessors::Moose                        |     120   |             115   |                24.45% |              2190.99% |   0.00054 |      20 |
 | Perl::Examples::Accessors::MojoBase                     |      90   |              85   |                60.80% |              1673.02% |   0.001   |      21 |
 | Perl::Examples::Accessors::Moo                          |      30   |              25   |               405.55% |               463.95% |   0.00056 |      20 |
 | Perl::Examples::Accessors::Mouse                        |      20   |              15   |               579.46% |               319.60% |   0.00022 |      21 |
 | Perl::Examples::Accessors::ClassInsideOut               |      20   |              15   |               770.63% |               227.47% |   0.00025 |      20 |
 | Perl::Examples::Accessors::Moos                         |      16   |              11   |               809.64% |               213.43% |   0.00015 |      20 |
 | Perl::Examples::Accessors::ObjectPad                    |      20   |              15   |               830.32% |               206.46% |   0.00017 |      20 |
 | Perl::Examples::Accessors::ClassTiny                    |      10   |               5   |               976.04% |               164.96% |   0.0002  |      20 |
 | Perl::Examples::Accessors::ClassXSAccessorArray         |      10   |               5   |              1005.80% |               157.83% |   0.00019 |      20 |
 | Perl::Examples::Accessors::ObjectTinyRWXS               |      10   |               5   |              1021.40% |               154.24% |   0.00019 |      20 |
 | Perl::Examples::Accessors::ObjectTinyXS                 |      10   |               5   |              1088.28% |               139.93% |   0.00016 |      20 |
 | Perl::Examples::Accessors::ClassXSAccessor              |      10   |               5   |              1088.63% |               139.86% |   0.00026 |      20 |
 | Perl::Examples::Accessors::ClassStruct                  |      10   |               5   |              1118.95% |               133.89% |   0.00022 |      20 |
 | Perl::Examples::Accessors::ClassAccessor                |      10   |               5   |              1123.35% |               133.05% |   0.00013 |      20 |
 | Perl::Examples::Accessors::ObjectSimple                 |      10   |               5   |              1166.35% |               125.14% |   0.00014 |      20 |
 | Perl::Examples::Accessors::MojoBaseXS                   |      10   |               5   |              1348.32% |                96.85% |   0.00028 |      20 |
 | Perl::Examples::Accessors::SimpleAccessor               |       8   |               3   |              1632.60% |                64.55% |   0.0002  |      22 |
 | Perl::Examples::Accessors::ClassAccessorPackedString    |       8.2 |               3.2 |              1660.36% |                61.96% | 8.1e-05   |      22 |
 | Perl::Examples::Accessors::ClassAccessorPackedStringSet |       7   |               2   |              1982.56% |                36.90% |   0.00013 |      20 |
 | Perl::Examples::Accessors::ObjectTinyRW                 |       7   |               2   |              2107.67% |                29.14% | 9.3e-05   |      20 |
 | Perl::Examples::Accessors::ObjectTiny                   |       7   |               2   |              2120.42% |                28.40% |   0.00014 |      20 |
 | Perl::Examples::Accessors::Mo                           |       6   |               1   |              2149.49% |                26.74% |   0.00013 |      20 |
 | Perl::Examples::Accessors::ClassAccessorArray           |       6   |               1   |              2213.42% |                23.24% |   0.00015 |      20 |
 | Perl::Examples::Accessors::Array                        |       6   |               1   |              2243.23% |                21.67% |   0.00013 |      21 |
 | Perl::Examples::Accessors::Scalar                       |       5   |               0   |              2548.51% |                 7.65% |   0.00015 |      21 |
 | Perl::Examples::Accessors::Hash                         |       5   |               0   |              2564.36% |                 7.01% |   0.00015 |      20 |
 | perl -e1 (baseline)                                     |       5   |               0   |              2751.06% |                 0.00% |   0.00018 |      20 |
 +---------------------------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                              Rate  Perl::Examples::Accessors::Moops  Perl::Examples::Accessors::Moose  Perl::Examples::Accessors::MojoBase  Perl::Examples::Accessors::Moo  Perl::Examples::Accessors::Mouse  Perl::Examples::Accessors::ClassInsideOut  Perl::Examples::Accessors::ObjectPad  Perl::Examples::Accessors::Moos  Perl::Examples::Accessors::ClassTiny  Perl::Examples::Accessors::ClassXSAccessorArray  Perl::Examples::Accessors::ObjectTinyRWXS  Perl::Examples::Accessors::ObjectTinyXS  Perl::Examples::Accessors::ClassXSAccessor  Perl::Examples::Accessors::ClassStruct  Perl::Examples::Accessors::ClassAccessor  Perl::Examples::Accessors::ObjectSimple  Perl::Examples::Accessors::MojoBaseXS  Perl::Examples::Accessors::ClassAccessorPackedString  Perl::Examples::Accessors::SimpleAccessor  Perl::Examples::Accessors::ClassAccessorPackedStringSet  Perl::Examples::Accessors::ObjectTinyRW  Perl::Examples::Accessors::ObjectTiny  Perl::Examples::Accessors::Mo  Perl::Examples::Accessors::ClassAccessorArray  Perl::Examples::Accessors::Array  Perl::Examples::Accessors::Scalar  Perl::Examples::Accessors::Hash  perl -e1 (baseline) 
  Perl::Examples::Accessors::Moops                           7.1/s                                --                              -14%                                 -35%                            -78%                              -85%                                       -85%                                  -85%                             -88%                                  -92%                                             -92%                                       -92%                                     -92%                                        -92%                                    -92%                                      -92%                                     -92%                                   -92%                                                  -94%                                       -94%                                                     -95%                                     -95%                                   -95%                           -95%                                           -95%                              -95%                               -96%                             -96%                 -96% 
  Perl::Examples::Accessors::Moose                           8.3/s                               16%                                --                                 -25%                            -75%                              -83%                                       -83%                                  -83%                             -86%                                  -91%                                             -91%                                       -91%                                     -91%                                        -91%                                    -91%                                      -91%                                     -91%                                   -91%                                                  -93%                                       -93%                                                     -94%                                     -94%                                   -94%                           -95%                                           -95%                              -95%                               -95%                             -95%                 -95% 
  Perl::Examples::Accessors::MojoBase                       11.1/s                               55%                               33%                                   --                            -66%                              -77%                                       -77%                                  -77%                             -82%                                  -88%                                             -88%                                       -88%                                     -88%                                        -88%                                    -88%                                      -88%                                     -88%                                   -88%                                                  -90%                                       -91%                                                     -92%                                     -92%                                   -92%                           -93%                                           -93%                              -93%                               -94%                             -94%                 -94% 
  Perl::Examples::Accessors::Moo                            33.3/s                              366%                              300%                                 200%                              --                              -33%                                       -33%                                  -33%                             -46%                                  -66%                                             -66%                                       -66%                                     -66%                                        -66%                                    -66%                                      -66%                                     -66%                                   -66%                                                  -72%                                       -73%                                                     -76%                                     -76%                                   -76%                           -80%                                           -80%                              -80%                               -83%                             -83%                 -83% 
  Perl::Examples::Accessors::Mouse                          50.0/s                              600%                              500%                                 350%                             50%                                --                                         0%                                    0%                             -19%                                  -50%                                             -50%                                       -50%                                     -50%                                        -50%                                    -50%                                      -50%                                     -50%                                   -50%                                                  -59%                                       -60%                                                     -65%                                     -65%                                   -65%                           -70%                                           -70%                              -70%                               -75%                             -75%                 -75% 
  Perl::Examples::Accessors::ClassInsideOut                 50.0/s                              600%                              500%                                 350%                             50%                                0%                                         --                                    0%                             -19%                                  -50%                                             -50%                                       -50%                                     -50%                                        -50%                                    -50%                                      -50%                                     -50%                                   -50%                                                  -59%                                       -60%                                                     -65%                                     -65%                                   -65%                           -70%                                           -70%                              -70%                               -75%                             -75%                 -75% 
  Perl::Examples::Accessors::ObjectPad                      50.0/s                              600%                              500%                                 350%                             50%                                0%                                         0%                                    --                             -19%                                  -50%                                             -50%                                       -50%                                     -50%                                        -50%                                    -50%                                      -50%                                     -50%                                   -50%                                                  -59%                                       -60%                                                     -65%                                     -65%                                   -65%                           -70%                                           -70%                              -70%                               -75%                             -75%                 -75% 
  Perl::Examples::Accessors::Moos                           62.5/s                              775%                              650%                                 462%                             87%                               25%                                        25%                                   25%                               --                                  -37%                                             -37%                                       -37%                                     -37%                                        -37%                                    -37%                                      -37%                                     -37%                                   -37%                                                  -48%                                       -50%                                                     -56%                                     -56%                                   -56%                           -62%                                           -62%                              -62%                               -68%                             -68%                 -68% 
  Perl::Examples::Accessors::ClassTiny                     100.0/s                             1300%                             1100%                                 800%                            200%                              100%                                       100%                                  100%                              60%                                    --                                               0%                                         0%                                       0%                                          0%                                      0%                                        0%                                       0%                                     0%                                                  -18%                                       -19%                                                     -30%                                     -30%                                   -30%                           -40%                                           -40%                              -40%                               -50%                             -50%                 -50% 
  Perl::Examples::Accessors::ClassXSAccessorArray          100.0/s                             1300%                             1100%                                 800%                            200%                              100%                                       100%                                  100%                              60%                                    0%                                               --                                         0%                                       0%                                          0%                                      0%                                        0%                                       0%                                     0%                                                  -18%                                       -19%                                                     -30%                                     -30%                                   -30%                           -40%                                           -40%                              -40%                               -50%                             -50%                 -50% 
  Perl::Examples::Accessors::ObjectTinyRWXS                100.0/s                             1300%                             1100%                                 800%                            200%                              100%                                       100%                                  100%                              60%                                    0%                                               0%                                         --                                       0%                                          0%                                      0%                                        0%                                       0%                                     0%                                                  -18%                                       -19%                                                     -30%                                     -30%                                   -30%                           -40%                                           -40%                              -40%                               -50%                             -50%                 -50% 
  Perl::Examples::Accessors::ObjectTinyXS                  100.0/s                             1300%                             1100%                                 800%                            200%                              100%                                       100%                                  100%                              60%                                    0%                                               0%                                         0%                                       --                                          0%                                      0%                                        0%                                       0%                                     0%                                                  -18%                                       -19%                                                     -30%                                     -30%                                   -30%                           -40%                                           -40%                              -40%                               -50%                             -50%                 -50% 
  Perl::Examples::Accessors::ClassXSAccessor               100.0/s                             1300%                             1100%                                 800%                            200%                              100%                                       100%                                  100%                              60%                                    0%                                               0%                                         0%                                       0%                                          --                                      0%                                        0%                                       0%                                     0%                                                  -18%                                       -19%                                                     -30%                                     -30%                                   -30%                           -40%                                           -40%                              -40%                               -50%                             -50%                 -50% 
  Perl::Examples::Accessors::ClassStruct                   100.0/s                             1300%                             1100%                                 800%                            200%                              100%                                       100%                                  100%                              60%                                    0%                                               0%                                         0%                                       0%                                          0%                                      --                                        0%                                       0%                                     0%                                                  -18%                                       -19%                                                     -30%                                     -30%                                   -30%                           -40%                                           -40%                              -40%                               -50%                             -50%                 -50% 
  Perl::Examples::Accessors::ClassAccessor                 100.0/s                             1300%                             1100%                                 800%                            200%                              100%                                       100%                                  100%                              60%                                    0%                                               0%                                         0%                                       0%                                          0%                                      0%                                        --                                       0%                                     0%                                                  -18%                                       -19%                                                     -30%                                     -30%                                   -30%                           -40%                                           -40%                              -40%                               -50%                             -50%                 -50% 
  Perl::Examples::Accessors::ObjectSimple                  100.0/s                             1300%                             1100%                                 800%                            200%                              100%                                       100%                                  100%                              60%                                    0%                                               0%                                         0%                                       0%                                          0%                                      0%                                        0%                                       --                                     0%                                                  -18%                                       -19%                                                     -30%                                     -30%                                   -30%                           -40%                                           -40%                              -40%                               -50%                             -50%                 -50% 
  Perl::Examples::Accessors::MojoBaseXS                    100.0/s                             1300%                             1100%                                 800%                            200%                              100%                                       100%                                  100%                              60%                                    0%                                               0%                                         0%                                       0%                                          0%                                      0%                                        0%                                       0%                                     --                                                  -18%                                       -19%                                                     -30%                                     -30%                                   -30%                           -40%                                           -40%                              -40%                               -50%                             -50%                 -50% 
  Perl::Examples::Accessors::ClassAccessorPackedString     122.0/s                             1607%                             1363%                                 997%                            265%                              143%                                       143%                                  143%                              95%                                   21%                                              21%                                        21%                                      21%                                         21%                                     21%                                       21%                                      21%                                    21%                                                    --                                        -2%                                                     -14%                                     -14%                                   -14%                           -26%                                           -26%                              -26%                               -39%                             -39%                 -39% 
  Perl::Examples::Accessors::SimpleAccessor                125.0/s                             1650%                             1400%                                1025%                            275%                              150%                                       150%                                  150%                             100%                                   25%                                              25%                                        25%                                      25%                                         25%                                     25%                                       25%                                      25%                                    25%                                                    2%                                         --                                                     -12%                                     -12%                                   -12%                           -25%                                           -25%                              -25%                               -37%                             -37%                 -37% 
  Perl::Examples::Accessors::ClassAccessorPackedStringSet  142.9/s                             1900%                             1614%                                1185%                            328%                              185%                                       185%                                  185%                             128%                                   42%                                              42%                                        42%                                      42%                                         42%                                     42%                                       42%                                      42%                                    42%                                                   17%                                        14%                                                       --                                       0%                                     0%                           -14%                                           -14%                              -14%                               -28%                             -28%                 -28% 
  Perl::Examples::Accessors::ObjectTinyRW                  142.9/s                             1900%                             1614%                                1185%                            328%                              185%                                       185%                                  185%                             128%                                   42%                                              42%                                        42%                                      42%                                         42%                                     42%                                       42%                                      42%                                    42%                                                   17%                                        14%                                                       0%                                       --                                     0%                           -14%                                           -14%                              -14%                               -28%                             -28%                 -28% 
  Perl::Examples::Accessors::ObjectTiny                    142.9/s                             1900%                             1614%                                1185%                            328%                              185%                                       185%                                  185%                             128%                                   42%                                              42%                                        42%                                      42%                                         42%                                     42%                                       42%                                      42%                                    42%                                                   17%                                        14%                                                       0%                                       0%                                     --                           -14%                                           -14%                              -14%                               -28%                             -28%                 -28% 
  Perl::Examples::Accessors::Mo                            166.7/s                             2233%                             1900%                                1400%                            400%                              233%                                       233%                                  233%                             166%                                   66%                                              66%                                        66%                                      66%                                         66%                                     66%                                       66%                                      66%                                    66%                                                   36%                                        33%                                                      16%                                      16%                                    16%                             --                                             0%                                0%                               -16%                             -16%                 -16% 
  Perl::Examples::Accessors::ClassAccessorArray            166.7/s                             2233%                             1900%                                1400%                            400%                              233%                                       233%                                  233%                             166%                                   66%                                              66%                                        66%                                      66%                                         66%                                     66%                                       66%                                      66%                                    66%                                                   36%                                        33%                                                      16%                                      16%                                    16%                             0%                                             --                                0%                               -16%                             -16%                 -16% 
  Perl::Examples::Accessors::Array                         166.7/s                             2233%                             1900%                                1400%                            400%                              233%                                       233%                                  233%                             166%                                   66%                                              66%                                        66%                                      66%                                         66%                                     66%                                       66%                                      66%                                    66%                                                   36%                                        33%                                                      16%                                      16%                                    16%                             0%                                             0%                                --                               -16%                             -16%                 -16% 
  Perl::Examples::Accessors::Scalar                        200.0/s                             2700%                             2300%                                1700%                            500%                              300%                                       300%                                  300%                             220%                                  100%                                             100%                                       100%                                     100%                                        100%                                    100%                                      100%                                     100%                                   100%                                                   63%                                        60%                                                      39%                                      39%                                    39%                            19%                                            19%                               19%                                 --                               0%                   0% 
  Perl::Examples::Accessors::Hash                          200.0/s                             2700%                             2300%                                1700%                            500%                              300%                                       300%                                  300%                             220%                                  100%                                             100%                                       100%                                     100%                                        100%                                    100%                                      100%                                     100%                                   100%                                                   63%                                        60%                                                      39%                                      39%                                    39%                            19%                                            19%                               19%                                 0%                               --                   0% 
  perl -e1 (baseline)                                      200.0/s                             2700%                             2300%                                1700%                            500%                              300%                                       300%                                  300%                             220%                                  100%                                             100%                                       100%                                     100%                                        100%                                    100%                                      100%                                     100%                                   100%                                                   63%                                        60%                                                      39%                                      39%                                    39%                            19%                                            19%                               19%                                 0%                               0%                   -- 
 
 Legends:
   Perl::Examples::Accessors::Array: mod_overhead_time=1 participant=Perl::Examples::Accessors::Array
   Perl::Examples::Accessors::ClassAccessor: mod_overhead_time=5 participant=Perl::Examples::Accessors::ClassAccessor
   Perl::Examples::Accessors::ClassAccessorArray: mod_overhead_time=1 participant=Perl::Examples::Accessors::ClassAccessorArray
   Perl::Examples::Accessors::ClassAccessorPackedString: mod_overhead_time=3.2 participant=Perl::Examples::Accessors::ClassAccessorPackedString
   Perl::Examples::Accessors::ClassAccessorPackedStringSet: mod_overhead_time=2 participant=Perl::Examples::Accessors::ClassAccessorPackedStringSet
   Perl::Examples::Accessors::ClassInsideOut: mod_overhead_time=15 participant=Perl::Examples::Accessors::ClassInsideOut
   Perl::Examples::Accessors::ClassStruct: mod_overhead_time=5 participant=Perl::Examples::Accessors::ClassStruct
   Perl::Examples::Accessors::ClassTiny: mod_overhead_time=5 participant=Perl::Examples::Accessors::ClassTiny
   Perl::Examples::Accessors::ClassXSAccessor: mod_overhead_time=5 participant=Perl::Examples::Accessors::ClassXSAccessor
   Perl::Examples::Accessors::ClassXSAccessorArray: mod_overhead_time=5 participant=Perl::Examples::Accessors::ClassXSAccessorArray
   Perl::Examples::Accessors::Hash: mod_overhead_time=0 participant=Perl::Examples::Accessors::Hash
   Perl::Examples::Accessors::Mo: mod_overhead_time=1 participant=Perl::Examples::Accessors::Mo
   Perl::Examples::Accessors::MojoBase: mod_overhead_time=85 participant=Perl::Examples::Accessors::MojoBase
   Perl::Examples::Accessors::MojoBaseXS: mod_overhead_time=5 participant=Perl::Examples::Accessors::MojoBaseXS
   Perl::Examples::Accessors::Moo: mod_overhead_time=25 participant=Perl::Examples::Accessors::Moo
   Perl::Examples::Accessors::Moops: mod_overhead_time=135 participant=Perl::Examples::Accessors::Moops
   Perl::Examples::Accessors::Moos: mod_overhead_time=11 participant=Perl::Examples::Accessors::Moos
   Perl::Examples::Accessors::Moose: mod_overhead_time=115 participant=Perl::Examples::Accessors::Moose
   Perl::Examples::Accessors::Mouse: mod_overhead_time=15 participant=Perl::Examples::Accessors::Mouse
   Perl::Examples::Accessors::ObjectPad: mod_overhead_time=15 participant=Perl::Examples::Accessors::ObjectPad
   Perl::Examples::Accessors::ObjectSimple: mod_overhead_time=5 participant=Perl::Examples::Accessors::ObjectSimple
   Perl::Examples::Accessors::ObjectTiny: mod_overhead_time=2 participant=Perl::Examples::Accessors::ObjectTiny
   Perl::Examples::Accessors::ObjectTinyRW: mod_overhead_time=2 participant=Perl::Examples::Accessors::ObjectTinyRW
   Perl::Examples::Accessors::ObjectTinyRWXS: mod_overhead_time=5 participant=Perl::Examples::Accessors::ObjectTinyRWXS
   Perl::Examples::Accessors::ObjectTinyXS: mod_overhead_time=5 participant=Perl::Examples::Accessors::ObjectTinyXS
   Perl::Examples::Accessors::Scalar: mod_overhead_time=0 participant=Perl::Examples::Accessors::Scalar
   Perl::Examples::Accessors::SimpleAccessor: mod_overhead_time=3 participant=Perl::Examples::Accessors::SimpleAccessor
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAc5QTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABgAIFgAfEQAYAAAAAAAAAAAAAAAAAAAACwAQIwAyAAAAAAAAAAAAAAAAAAAAVgB7lADUbQCdlADUAAAAlADUlADUAAAAlQDVlQDWAAAAlADUlQDVlADUlQDVlADUlADUlADUlADUlADUlADVlADUlADVlQDVlADVlQDWlADUlADUlADUfgC0iwDIkgDRhQC/kADPdACnjQDKZQCRhgDAAAAAFQAePgBZLwBEJAA0QgBeQgBfJwA3OQBSPwBaPQBYQQBeMQBHBgAIGwAmGwAmFAAcDQATGgAmCAALGQAkGQAkCwAQDwAWGAAjFAAcBgAIFQAfDQATAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJwA5lADURQBj////sgh2+gAAAJV0Uk5TABFEZiK7Vcwzd4jdme6qcM7Vx8rV0tI/+vbs9fzx+fR1XHXfXEROIhG+p3WJ1uxmjojHM+/6es239U5co/H3ULLwl+XV+cf24eD49eD++/Ly/f366/D5+PXz+fD5+PPz+Pfv9vJbQCBrYN+vn43WgNHjv/3P81CX2c3IaXow77ePxuqbwNrEpLXwptetgqfo+/Ln4OZqBtaXAAAAAWJLR0QAiAUdSAAAAAlwSFlzAAAASAAAAEgARslrPgAAAAd0SU1FB+UIAwk5IJKjUkMAAER1SURBVHja7X0J2y3LVVZ3795T7yESMVfQmFxibhATRFAERxSU6zyL88w9d8LAJSainpCoIAQFUbf6c+2a16p6V+/e39ffHvqs93ngntTpU9179epVb62pqkqhUCgUCoVCoVAoFAqFQqFQKBQKhUKhUCgUCoVCoVAoFAqFQqFQvCzqxv+hqelw84SpFIpbYdGGPzUn/4cT1eH2dNl8CsVNsYzaixS6Xa1VoRUPhM1621aLrmuMQrf2v1ahm67b9H9cLFWhFY+ExW7fLHddd1j0Cn3Y70+dVejtodufFuaCRhVa8UjoKceyp9HdsVfdbVVtT22v0O2pN8+Lg/l7VWjFQ8Fy6M1qvfSq25vnU7PYNT2MVqtCKx4LvUJ3p+V+GRT6YBS6OywNVKEVD4dlszoYymEUuq6q2lro1a4KfmlVaMVDYbla9NpbW8qx7xV7Z1hH3e8R7R9VoRUPhuPuU+vdcrc/LJr1erc7bCyNXhzWa/NHVWjFg6Fu2qpp6qoxEcMmRr3rhgfAFQqFQqFQKBQKhUKhUCgUCoVCoVAoFIp7QqwVslHajca2FA+NWMDZLfv/sT6Z7BqF4kGRCjibU6/Qy2Pd7rpbP5RC8VTEAs76cFxWtmpou771QykUT4dPbTx2na+30FxHxSPD6e9ibTj0wil03Bf+ju+y+DTD7/xuh9/1aYViMnzGqtpn3ppGodtdaxR66xQ69gE6/e7vMfheht/zfxx+Lxv9ns9+L8DvQ4MXXPrZ7xl96UPd69mPNb97fc6q2unz0yh0t+4Zx657O6MccPrv+78OX2CjHWzftkSDF1zadKMvfah7Pfux5nqvqRS66axCv2WM82I3PL0qtCr0i91rKoW2D2Pcdp37v6HpVaFVoV/sXlMr9Oaw3q1TrFAVWhX64RSao27oI6lCq0I/uEKPmP73Q4VuWjTBAv6U8Ze2zehLH+pez36sud7rFgr9RajQCsUEUIVWzAqq0IpZQRVaMSuoQitmBVVoxaygCq2YFVShFbOCKrRiVlCFVswKqtCKWUEVWjErqEIrZgVVaMWsoAqtmBVUoRWzgiq0YlZQhVbMClMotC+F2bjqGdZOVxVacV1MoNCune5mdzrtNnk7XVVoxXXxbIUO7XQP+6re7/J2uqrQiuvi2Qrt2+naBo3t6Z2sna4qtOK6mKrRTN3YP43qbacKrXgxTNk5qV3v83a6p31jwP8BVugvfdHh+28tEsVjYmNVbTqFrrtTV7bT/QOdAf8HWKF/wI/+wVsLRvGYWFhVm0yhN+vlpio6+F9AOVShFRNgMoXeWWddO6adriq04sUwlUKvTo4sj2mnqwqteDFM1sH/ZDGqna4qtOLFcIt2uqrQihfD/SQnqUIrJoAqtGJWUIVWzAqq0IpZQRVaMSuoQitmBVVoxaygCq2YFVShFbOCKrRiVlCFVswKqtCKWUEVWjErqEIrZgVVaMWsoAqtmBVUoRWzgiq0YlZQhVbMClO2063pfwamV4VWvBgma6fr++g+vZ2uKrRiAkzWTtf30X16O11VaMUEmKqdbuv66LZPb6erCq2YAFM1mvH/T3vbKW6LqRTa99H91NPb6apCK56Fadvp+j66X9Z2uoobYdp2uko5FHeBqRTa99HVdrqK22Ky/tC+j66201XcFNN18Hd9dLWdruKmmC6Xw/fR1Xa6iltCk5MUs4IqtGJWUIVWzAqq0IpZQRVaMSuoQitmBVVoxaygCq2YFVShFbPCvSv0V75g8ZXbSknxMLh3hf5BN/iDt5WS4mGgCq2YFVShFbOCKrRiVlCFVswKqtCKWUEVWjErqEIrZgVVaMWsMKFCb1x7mWnb6apCKy7CZAq92Z1Oy3rydrqq0IqLMJlC77qqXu8nb6erCq24CJMp9Kmpqm45eTtdVWjFRZhMoQ/bqjruJ+9tpwqtuAiTKXRz2B129WLqdrqq0IqRmKydrkW9Pjar9X47dTtdVWjFSEzWTtfNZjqObk5vK+VQ3BQjFXqzOXNBZzaCda/QE7fTVYVWXIRRCr04nJbNblCnN8a90R0mb6erCq24CGMUenNaNMu6O9RDFy1O691hM3k7XVVoxUUYo9DdvmqWVbVuBq9qX6Sdriq04iKMUuhujEKPn14VWvFiGKPQzWHTK/RimHJcML0qtOLFMGpTuD3tDrvDYqrpVaEVL4Zxbrt20a2eYJ9VoRXXhib4K2aFUQrdLS2mml4VWvFiGKPQ20MHMjKePr0qtOLFMNJtN+n0qtCKF8MYhV7sz19zyfSq0IoXwygOvdwr5VA8BkYFVk5r3RQqHgMjczkmnV4VWvFiGOXl0E2h4lEwRqHr5QJUBj59elVoxYthHId2mGp6VWjFi0FD34pZQRVaMSucVejm1CjlUDwM1EIrZoUxCt06/8aiHb6sdmXh2k5XcUOcV+i22dp+XqvdoN+uPp5O61bb6Spui/MKvViudzbyfRysWdmv6/p41Ha6ittiVF+OEdWEtWk003baTldxW0y1KWxO1aapK22nq7gtplLo1Wm52x022k5XcStM2063O3Wmt52201XcCtO207U0oz59XimH4qaYSqE3TqHf0Xa6iptiulOwtlW132k7XcVtMd05hQdtp6u4PabL5ai1na7i9tDkJMWsoAqtmBVUoRWzgiq0YlZQhVbMCqrQillBFVoxK6hCK2YFVWjFrKAKrZgVVKEVs4IqtGJWUIVWzAqq0IpZQRVaMSuoQitmBVVoxaygCq2YFVShFbPCpApt++lqO13FDTGlQnfLStvpKm6LCRW6OfUKre10FTfFhG0MDsdlpe10FbfFdAp97HrKoe10FbfFZAq9WBsOre10FbfCtO10211rFFrb6SpuhWnb6XbrnnHsureVcihuisn6Q3dWod/SdrqKm2JqP7S201XcFFMrtLbTVdwUk+dyaDtdxS2hyUmKWUEVWjErqEIrZgVVaMWsoAqtmBVUoRWzgiq0YlZQhVbMCqrQilnhIRX6D33B4YeuLy/FneMhFfoP+0t/+AYCU9w3VKEVs4IqtGJWUIVWzAqq0IpZQRVaMSuoQitmBVVoxaygCq2YFSZU6I1rL3OFdrqq0AoJkyn0Znc67TbXaaerCq2QMJlCH/ZVvd9dp52uKrRCwmSdk0yDxvb0zlXa6apCKyRMpdC16cbRnK7T204VWiFhSi9Hu95fp50uVugverDB7/eDP8JGf8SPfv81RKy4DqZtp9vb6O7UXamdLlboP+JHR9zrC36UK7/ioTFtO91qs15uqit18McK/QVVaMV0lGNnnXXtVdrpqkIrJEyl0KuTI8tXaaerCq2QMFkH/5PFddrpqkIrJDxkO11VaIWEGSUnPVuh/yi6l+KxoAp95l6Kx4Iq9Jl7KR4LqtBn7qV4LKhCn7mX4rGgCn3mXorHgir0mXspHguq0GfupXgsqEKfuZfisaAKfeZeP+pb9/4oG/1jfpQN/ogf/AH+u/woz8j+ihv8sRH38pd+hQ3ijsL4Xm8UVKHP3Cs81g/c7F5PEMEbHNJXhT5zL1Xox4Iq9Jl7Pb5Cf/HHf9CCc5ZAb/74BW/zEaAKfeZeM1DoC8QN6zK/5Ae/xEbvtC5TFfrMvd4shf5xN/jjT73X7aEKfeZeb5ZCP/deX/phhx9il/4JP8pN/I+5wT9ZTQpV6DP3UoWe7l5cBH8K3evZUIU+cy9V6JdS6AtE8KfHi/sWCv1n4JP8BJTwn0W/+s9BCf8k+tX4Xj8JJQzv9RNQwte81xNEwO71wuK+4F7XEPf0Cn2+ne73wSf5KSjhP49+9V+AEv5p9KvxvX4aShje66eghK95ryeIgN3rhcV9wb2uIe6pFXpMO11VaFXoFxP31Ao9pp2uKrQq9IuJe2KFbse001WFVoV+MXFPrNCjetupQqtCv5i4J1boop3uu99l8GmGv/j/HP4SG/3LfvSvsNG/6gb/Ghv86/7Sv8FG/6YfHXGvv+VHvxvd62/Dx/o7N7vXBSKA93ohcT/hXi8r7s9YVZtYofN2up/9HovvZfi7f+9nLP4+G/0H/9CN/iM2+o/d4D9hg//UX/rP2Og/d4M/M+Je/8Jf+i/Rvf4VfKx/fbN7XSACeK8XEvcT7vWy4v6cVbXP/eykCp1TDoXioZG301UoHhtZO907RPv8Kd4k1PXz53hkZO10bwuou7vm0mlu+LC3f4DD6tbPdWPUzd0ozHaJRrvpCVG7Pxy6kaOXPezznuAiCA+w3l84zxWwuRsVuy7qwxK9jd0Fb37RjhjdHPbNqrBkeNRPUL4R4WHRpSUG7rWC/37UA7SbSvz+F+MXlFEyhI9V781aDx71eLwXElAtlvvyWRbr0wWju64ed2lzOJRSWxyXByAN+FwSP+Gj9WFr/n92DR51f9WeSt2DD4svLX6tfK9Ft1yPnLV8gN2h1+iNif2OEgx8MyNlKDzWuqtWhxOgsIsDfKrrY7/uloUsu92qWa9Hjq5Xq2IUXrpq6nZdGOP9btEdSlMIn6uS9rd0tIZeynrId7lfg1nRw+aXtlaP8187cK9uvd2fFk99gOPa/Nvd9pwINuttJbyZcTIUH6s5NbumRUvqnWj0aoc+YbNWLgqbgUdPjTFI3YhLuzUL8ThYt+LmlFsH9Fztrn+b3f7MaNf1cy6qplufDoszo+kh8je0WPafU/Gw5aX2jWe/duheZsZtuSCBBzBGnzzAprODi37iLufWhWBWJ3ML9GbGyVB+rOpoLm3Q2tXdhethdWhW+/U6+7hOm81yucm/OGHU/Lbc0V1canxNtTEtxyO/0tmyff6OyufaGKVZVKvC5GSjxtDsT6fTult1aXHGo1VYlnNe2q0XXf9J8YdFl9pXm/1a6V7mjzYHgRk44QGc0U8PsDC61Z7q/teSRAZBMO3J7BzhmzkvQ7fqbHfmhiVfby2ZygVjGdfNncOL3WnZLk+7/Yo8n6Wu6/VuZd7T8Kh7FeaLpUtsfmm7MLuNo/n8V73daA9NnMAIrbaWrSHLsJs2PldrDYcjbs1h39LF3Emdjx6Msd809p2nFROPxmW5zpZxbxnpwwqXmkfMBIPv5X6BlVZHLH82a3COeKPvHqBerJzOVf19+v/azaaTSyEYp+uHbf80+ZtB0kKj5pn3/WP1v4P/WPtqrY63dEkNjKs5TKKWT0XdHFbN0a1+i2ggHXVdOB5QCaOMonVmitVBuLQ+ntZGbd1OxnzD3SmwCSe0vVmpFsv4SVHmZ5+rN9N12xM3I+fNYU8+My91P1q/d+z8QhtgXukGjgaEZXmRaMCqqdy7rRvysPBS/2qTYNC9rOaFX2Cl1e2OwgNE50gw+v0DvOoOp9PSafS+M/91Ww6zfOWCqZeOyS4X/ZpXvBkqrYHRftWxRHC3q9iPda/W6Tg9XDsyrtsGFNZr816X+8YIM/C/QF37ndo2sa98lFO05W6xiFwxu7ReL1sjoaUjfgsjs6Z/QbuNZ8+7Xb1erxaHJIowrX2u948rQ1f2u86v7vU6cNVFE6XuRg8fdL11q506debtHs23UsPRytubuCwnD5mh+vb3mM+pGbjUrnD28iAYfC+jefEXmF+727i5ilmTcyQa/Wa1Wzf917KwGr3aWSmuq7YXTE/jCsEsT3at67q2/wnkzRTSGhjtV516V9frvVHdJJfwas06Gx04lkYFxtXdlHOs/Fr/Xq9ecT8TqWu3JD6GfDSjaPHa3rZll3oOtulfs5Hswnh9dmu3QgWh1fvDmmwfw7Sbw+nDjw5HS1da+3FZYlS7Rdw4lJLU7Wj/TPV2d3B2Zn/Y7w9LJ3Y86uxNXJY3lgUEqm8IdFq38KV+hbMWK4oA3qs2TMv/grpb95canQezJn4Qjf7R6rjjp71GW+lseqPdC6ancYVg2pP9spql/QnhsYC0xNHKrTrmg1gc2noT2VF8tb2OM74TP77VrUI+nqXa25tnJ6M5pXYMK40OUDRn2/gEa0/BukO/t1+tdq1/Qc6tEYTGHitN+/7OrWG9fB1xs3bc7fGdQylM0G66pf94utNpbz+JY+eta4tGg71hy/KiCVTfLRsr+dK0wmUUpLyXmzX9gl69zT9BsxLnSDD6W+tQqJ3NWRyswV05wRi9KwTT7Tbmyz6xrSeXFpahG/V7wX47areEPYsvtcDoOOU7iXE9K7b6dHiWapUqOYYId10s687+hMiw3OgQRYtuDH+pQ1jFTCHY/mReQ+e4orViQWiQk7fLntW5W3dLQtyM2M1S2ZEJdoePl37OZtcsT3viW7DvvhiN9sYvy60zWJHq9ywnLlHZpfb31HGFq/PdPbmXn9VoXvoFx93aMC4wK3OOBOu625sp+2H3sRyJYHpRMMHU/YfUs5ae59X9HVbhQ8ulhWVoR9NesFfcZle3Vj8yLbB+EMp3IkHNPFjXQmCp3anrElH2o5a6/txu7V5zYFiBaEsUjbgxGCePq5hXzda9oM3aarwXGubke7OIuA+jpyv27bza1j0TWdn4lTVNYYLjvzGF7fbdmgSIXqHSvs+qGx+15DXYG6s45u+twUpUX7rUPM/ydNikFc6vyiFcmO7FZk3Us2ngrDYmXjpimtPi2EvFkYtqURPBGBoXpzWCMXZ8268v/YeyreqvOr7DpfXqy4IMzSjZC77nNjrmToUWmMdjfCcK5kYK7VlqfVh2TT5qqOvPW1pgv3/PsDaeaGOKZhBt24Zy8uDHbJ2KmDe8OjX7k4vIbrzQJE5ul2D7Gg+1UZ/jaW2usTpiTVM/wS98XLGAg1tNvdctxgvoKA1ChqXEpE1YgxWpvnipGe3a/bJY4UK4MN2Lz5q2V3BWFhOPjpieMB3dd7JINiEKxlCXMK01z1XlvW79XZG0dhs86u9G9oJd7QYbwrPjq7V+EMZ3boSMpW4djctGexGu3WurCcNqw2sDFM1OkGzbW36wfxG1D2rvd1Fvesu0DEpQbwY5eeU2Z5WRrzGD3Xp92IT4laWu9SYPOKQwGg040OBa2K07e+McvzZtwr4fT/XBpe+7n9Lz2INTUb7CRedVtwzu5DSredgNnDV8+yEmzhwxljCFr3of7X8SjDEgbVBGP1Vj3sEGS0sarXxslO4F/TdnXl2uBZVdWIAH72rAnuPN5z4Boy4aVHeng/nMI8PyNoBSNDernyDZNstavcFanfrteP96/edu3nCb+IDMyX1qUojcurfWy39v7uLsvjdNWcAhxBx5wIFGIgN5tfbGO35t2oR7P47qg0vdRmizXm1tEVC/socVzvnfgvPKGO9iVsqz+aweISZOHTH+33V01+lT8Lxgkg+CrPdH92OhtIrREMkJsdH0vp0RapeZFlj09pnxnasDe45Xp198Bf3J3WF7WPY6e9pEhlV5GxApWlX7WcME0bZZWQWDZfYzp+XGvvblBzYI0KVghcTJ46K8oOkUm94E709bryOb1kbQsoBD9xaNY4R4QUdpbgpCEsev4Q7UX1FcWlVuI7TyytHP7lc497DRedW1YNZNK86axcSjIyYSJpaPEVLwmGBSZmLdL6ttC6UFZfhOjOS4vyfv29y2tqtQTbXA/YRuzfjO1YFZanv6DOau9c4thesuMqyCosVZ4wTRtpn3kvIb/D7HmQDzhskLEjg5SU1a051z/+n0H4j3lNU+gpYHHFgcg8YLWFacI6+E4RgFI9EVdqk3Y3YjtPCB36Z/Bsu1/cMG51V7wazux8KYOCVMi5C8EW0CFwzh5DQmzaQlyDB8eiE2Shm1N2v9Np6M+p9gvgfCd64JzFJF7uoI9erkNjWLwLByikb+PWHf9g25/OYiHSSZgGqbsmsgJ6epSU1yPpkF+HjYLg5rs0VMEbQ84EDjGDRekFaNSF6J49ekTaT3wy7dejMWN0KWkrf+4cLDeueVZ73nZ10xZ26IicPUlbCBiTaBCGbRxM/fmGdBWvavrXucjaZPL8RG/fu213qz1vT8YpP/hP57uIU2CywVjtpqhOCNNn6hBUtTphSN/XtCfp1xtPnNeTpIMAE23SbsY/Zt6TZlLq10d5tq7twjm8N209IIWhZw4HEM74kzxj+sGoS8Usevz9soLv0gMgi7EbJeC/fPt+/SgEMKjo6Z1cxAnbkmlPPu8tTKqSvUJlC5xM8/mudCWm7U3pONpk+Px0bdtY2fb7lNbyauvLfKrcMsFY6a5SUQ6s2pW0Yfc0nR2L8n5LeuY35zSgdxrCuYAJLvY6RGObnVMOgo81Gt7S5+WyyCxgMOPI5hFdrZtrRqtPFnEcevj+IUlyYzFjdCG/9QPODgYDR0xKxVVTFnbt197cN/ezSPXmPCxG0ClUv8/Gs6SqVFKCMbTZ/eeyQ2Gq9lxTXZVuEm9rmSWKoU8k+EOviKK0jR+L9P5Pe4T/nN/eAH1ug71hVNQBOF5tJwEievoEvLkiDnZqKZwCyCxgMOLI6xSVsevmqwmpiUgZdf2lIG4TZCPo5aBhyqrKBMntX+r4Y5c1cfftiY+VHqimgTUgq+/6IEaVHKGEfNO4ifHomNxmuJQyrfKtwI/SOXLNX8DhzyPyY+XIcMD0DR4KxeAl9n+c3G6HvWxdIjgNvUi61waQWvojUsccuzaHkEjQUcsjhGsm00iTD8rMzxm19qo32JQZiN0Ps+jloGHFJB2ZlZ2xDBi87cbywPu9O/c1mIJHWl/pr1rCKbQCoD0heFpWVvHv6QRutd+UHbZSttcVKKc7ZVuBH6Ry5ZqvkdIORvRZhl4AgUDc3q07+XPL/ZGH3PupIJ4EI7LmmNRO7SCiTIO4nDaE+WeQSNBRxoHMOS12jblkWGBnH8okut3zcxiE3b7x98HBUEHBLhGpw1xsSTM9esL7/0S+430NSVD/99hW0CrQxIXxSUFqeMbjSukPzTI8uWtV8gN4klYl5Vmf0jc5Ya+FHGXePnzhI0EEXzE+TcN6R/Hz7F8pt7o1/4O+ha30ut5+SkRsK/gfQzAgnizqdll0XQeMBh2dVbb4AteeVbHveCw89afPTJ18VLWem1M2MkjloEHBLhEmZ1DsAYE4/OXBrQDqkrjjB9QGq8aMoUrwyInz+QFvTqRevMIjm0lDNeK72ZayM+MmOp+SiLIdpUYPoBFhQtTcC5bxTF4vBqf1hvY2rtocmJI6t/bU+fb3mNBGXPRvEiCQocIgYcWASNBxw2rc9Z8OSV2Tb6QZmfJV+aYkHEjNE4ah5wIAVlcFYfQkwxce/M5QFtn7rin7as8RLqDaC0sFevIhQkpdT214bVmFwLtwo3QXhkzlKzUR5DJPwDUjQyAZ11Q9O/XZJtYws6NmYCwroYhemFVht62rEaibR8OsVLgfrW3yoEHFgErc4CDjFnwf5lQ2xbfMHhZ4mXJr8vM2MpjloGHBLhQrOGOAaJiftqAba+mNSVd4hJgLvZrN4ASwtTRtLypE6NOyypD8tWe/oP4QHQVuHq4I/sg/sZl3KjWQwxWgZI0dgE/b/fkyhAEMU7/9Gk1Hc7UtCRjD6jMP0Ocn1sq2bZshqJsHwGxXMkCAUcaAQtNh3wAYeQsxCLqSLiCw4/S7yU+H2TGaNx1Kr+WfvaVxnNbdCsLISYRdqzgHavjcwkVGA3m+12uLTCKPTq0RWKRBZTEw5DjT6VHqDcKlwd2SO3bT5qFei1/SOPFsa2PIii8Qlak8hMogBWFJ/4oth6t/MFHasDYxiUwtQpCY7USLi/3ddZNRcKOLAIGq+tDzkLnry6fafb3qSoTYsuJQ9r/r/3+7omWHkc1YVYtkdKc31BWTErDyHymDhfX2yhPDMJaDebVBdIC8rb/pdTELKD8r4+t2z1/4kPUG4Vrgv4yCWXEjLdesomUDRExpbLFOoyovjmLhTFhoKOlBUHKMwyFsmnGgnzv9yXQxRPrpU1oE0HYpNEn7MQKPE6K8BhlphfWkG/73ID46gmTnHcVuXWt5iVhxBJTDxbX3yh/CtkEmBlQC6tSpS3QEGor88vW42hROEB6Fbh6pBjofkojBbWxyMuCYXTmlyKGAUwovgoFsWSgg77liGFCQq93ZIaCb7XNukFnVgraxWPNh14LzZJDDkLr/bv/tL77jsI25t8d5Mu3X1iiTL0+xoPJIij9h+Z+UbKgAOZ1RdTsRBijI5k60sslC9MghBGzaRVMSXNvHo4sMh8fW7ZapapjJrVAFwdA7HQbBRHC7sPIEXD09p9eYoCtLQo1hd01G6fjr1MR/+mjJ8r1kikRdUp3grVyrKAQ2o6QJokhpyFr8Z9Z9zepBfsNgUxvaFyoSAcC+p/Boqj9uuy7fhFaK6z73TWCoQQg1HImtqkQvnMJAiVAZm0wij26gGvVQV9fbV5cfEB6pups/TIcHQ4043vLsAELjwSPmxXt0CLYruDK+iore0pt531vg1JvYZL+xx+mjBsFO99oVaWBhyCJa15nyD7n1d035nKxN013uLxpAfB72s0Lo+jWrJwNL9zZyrAlu/T3o1Z0gQOISamHkx2sgmZSUBhVCsuIq20dS8pI/Ra5b6+lLa7qIhNuhFcKVT+yPCH4AJhSNEE/11QhlNL6hZoUWx9OHb22l/+hAotJrUYh7YrliW+lSxjuUW1skXAwVtS3iTRvwi278y2N9Hi0XcG/L5RBNmy5ciCuWftG6jS3o1sVh5C/OTjOqpj3tSG2ARiEnBlABGX96NUkldPpCDM1/eNaNlsT7zwADeCL4Xij4x/SFl9QnQ0yKcamiAyt92xSvm2rCh2BR2k4VJ7081haSu0gpIXGcs0giYHHJwlzZok+p0C3XeS7Q3zDJhLNyEnhPp987ATX7bC+mJUyn8atHcjTaUgIUTjAFxuqpKpOxCbEE1C962iNIGKCzW/yr49TEEKX1+XwqIuMu8f4Dbwz5zFQsEPQdUnlUTRygmsHY/K0G/PU75tVhQLheYvdX/YLE2FVpRinjDMI2hnAg5Zk0SXs8D2nXXc3nDPgLk0+l2p37cIO4Vly/j/YsyENMujvRv3OIToBNBCpp7ZhJX4oTNxbVDzK+7Vw4HF3NdXr0/RTbIx4lzdzPNsf55/ZlboBZq3jc90gxN4O54tf/4j4UWxsoM0rcabhvDRPGE4i6BJAYeBhox83xm2N9wz4BqkBr/rK+L3lcJOzv8XyEKTXjvr3WhRhBDdBEfI1IFNwKUJrkY7iotmIWGvHg4sZr6+fdckITa382xk3H7TgsFYpplluvlLIUWDE7BUjKzEoapIUazoIIWBV8dHc+cXj6CJAQepISPcd9ofQTwD3/x2FgtyOwpUpLY5fZb2mcxSnorejW4GFkKkxCZj6oGGcZuAKwO8qy8T15BXTwgs8mvtHPGPG3xUwDWAaOrQYNQmH0PsIEWDExCuwZe/KCC/6EtCEwKvXu+oLmQloUMBB6lNI9h3slxI01anjAX118Kw02r3n75N+0x+lZKF7DPbhpg4DyFSYpOpY1o3iU2AlQFRWvzTGfbqcfqPfX2Vj3+GP9+qnSikqWCQZ7oRbYIUDUzAIse5N9eJgJhvIDQceO2tbHJeRWKSlYS+Ggg4uOuzJomeBMV9p4t+F33aujIWZPy+IOx0PHzV/GzSZ/L1x44stHXRuzHGxDM7TIkNqVJj62ayCaA0gUmL8Tjg1cNeq8wzSkYreGDGNcE3aPGZEXfNM92SNiGKxid4P1eGha97riqcbwsdpFLg1ShumUSUlYTKAQf/PeUNGYPFi/vONSybQrGg/RGFnXpD3UuN95m0NzKt7orejSEmHo2rY+qM2HCa6x872gRYmoClhSkj9loVntFs9JJD9iZHvkGjozl3zTLdhoo3ywmoMjA7jvNtoYM0Cze+8in4TnHzzKCiJFQMOITXVrRpJCSobfuNm/GplbmQIBZkQ0Eg7AT6TNqfZVvd5b0bQ0zc2+FwlAEjNh5Zhvh/RqUJ9ZC0MGXEFAQ7TMi5R7c8WQJv0ATCn2W6VUQ+GUXLfACNS8EHkWMpxQM6SPMn8BnwXnG/TvPqUUkoDjiQhyUNGfN9p0+7dolOWS4kigV1r0CDhf7TLftMplZ3rHejMa4hJm6NazrKgBEbPy9dN6uPYL2BLK1KUlLBa1X2ciCjdvaXV1wJeINWclcxWR9Vj2Y+gGVMhSgix3KKR+EgBU/gM+CD4hrn1Qc0dJyVicOAQ82OFyBPxfadtQ9/2y+OBQuFWBBosODT31OfyXesP5G0uiO9G51xDTFxO5KYOiU2RVp9I9UbAGkl/11JGQWvFfCMOpTJglcHZakpVx0SfhzsgxQtn+DDHU2FAE37QIoHlVrMWC6fILUNTMunlBokBBzYpsc3ZKQ7X0+Coqrb6DfNhUSxINxgYe9IFzlvyHXVWcVWd6Q78SkGOGNMPDF1Rmx4Wn1VE7lwnoykVYlePUhBMs9omxI3VqsbdyeoCpZateiH+NfGgn31l+Xq0XKCLBWC1dBBq4/9ySheGdsG0uVTSA3CQUi+6bENGRkHiomywZ9ae/Kc2l0Vfl8p7OQ+3Y5yPNtyjLS624a/DMaVxMQpU4/Epo7zUgniegMoLcmrhylI7hkNn9JmuW6q23YnqASWKkVIaaRroHoUTMBTIWgNHU7xKP3JReA1T8FnOW0gNQgHHCq86eEcKJQhxPC3+aDqXHOJ31cKO4WkLxeyTL0beas7c2/r2Qy8IMXE2VEGq8Ik8M66Rb2BJC3Bq4cDi4VnNJwH27imyLfqThB+HwjjA8JfBvvk6lE0AU+FIImxKMVjuaoKqRWB102Rgm+z51BqENc7HnCo8KYH5smS8DfryFbEgsoGC/ZVp6Qv22dyQ3o3slZ3vZV2ns1gXJuYFpAdZZCmrWhavft4i8oACyot/wNFrx4OLGa+vkWTn+p7K0CWigk/CPZJJaF4giwVwl+Jkl18NDabNgu81hVIwTcDMDUo17te8V6T2sB80wOzZ42KkPA3TQDws6dYUOY+ixn4POmrpr0bQ6s7d/Ziy85eTHXykDChgzztx5tVBmRVCF8daDiSU5ABX184zOgOAFkqpq4ohCiUhKIJcCpEZnPf+zIVWj4tD7x2HUjBfy2mBiHFy2sD071g9qxTkTz8DcPvufssqlmW9MV7N9pRcPZiMK6QMEGTEDejvDIgr0IYpIwZBRnw9bnDjIpDv28BkPWABsVMN4GigVlRKkSR7MKF1tBK0yLwuixT8OsjTA1Civd2cIjj1icgezbkybK0a+AGqZD7LP6ELOkr6924GTx7ERImnP+G2ilWVVGFIFJGQEEkX1/luVl9u/SjIF/A7XEqBIwWYoqGJ8hTIaKAs2SXTGhp0wICr8aq8hT8FHAoImh5DPLjojYweQCpxUN5sintGrpBKuQ+q6T0LN67sarg2YtVlW8xI1MXUvBBO8WiCqGSKSPseYZ9fdY3Gw8zuiEgt8fBfRwthBRNyKUoUiEqZHNFoWU+CJKxzFLwhdSgMgZZw9rAinQ9yAxpoU2RMJVukAq5zzBjYy1ow71wTBxnaMD8N06t9mwHRKsQqpIycp7M113s63O+2fIwo+uDcfvB4D6IFhYUTZ7AiZemQlAB+0vi32IHaeaDoBnLDs6lJaQGlTHIgdpAaPGyPNkIFApC7jOJsYEWtDAmXvTwa+K0ZR9PnFIrpDBklDGnfNxrhXx93jdLDzO6ERi3Fwk/jhaWFE2cQLQsMNkFCY1FMQOfjRnLNAVfSg0qFE+qDaxwxi/Mk4VuEOg+E/K7AidnRQR5TLxYX8gWE59PgBoDVaJRyihjTvnos5a+Pitz75u92RFWEYzbS4RfiBaWFE2aQHBeIb+vILQ8ihnHXcYyTcFHqUG//DUQgxRqA7HFw200sRsEus8E4xiMAv0FZUy8EjIbRZNAqRXolZ0Zpbzfh0D54LW2qCb4Zm9rnZ2ikGeWfgiKFkKKhicgukCUASe7YE4u5dqljGWSgg9Sg3AMEtcGQouHHRbIDYI96hXM72I0jPRuBDFxmNloRPgBMQkuxTxbzOoK9spuK9mrhygfvjYU1dw+byO+KUpTJe6KjnqCFA1KguoCycFHyS6xdToVGo28FiUtecbymIBD628FawOxxQMOC+wGge4zzNiEFPwsJp4NMmJjRUhNwrqr0GIm9MoWD0lBlA97AGNRzc3zNiIYty9/iJAeKFA0JAmuC/FamCMSUyGI0LLIa7aZpEfIjw84VIJDvAIkqGyjSR4gLyKGm0nE2IQNXhETzwcpsSEZ9Elzs8XMZp7jXtlVBbx67hVklI97d+g2PBXV3DpvIyDSVMxdcbSQUzTy79GOodQFuUSL9foLfxysF+iAV3BEwAE6xCEJAm00yQNI5b6sFLP8drnnmrbBH2qEwgfjwklFezyylJwPfBM+0CsbUsawQnLKly0le8qTY1HNveCQ0iARd2XBvlagaESb8h1DXCqJLgyVaJVCQ8lfxPsVjpC/LOCAHOJCxi9oo2knFhy/6BickrFxB6I3ClIoB3VHoQvnz7JEKtLKoI2O9rxXtkQZg1wY5RN39FaCtKjmHuDcRIjwg2CfQNFI3yS+u6DrZ9KFsyVaycFqbponf3HvV1d8DucCDvQBiUN8MOOXt9E86/glATTM2DIHYp3+/WAjlEj087x6e2Xo4ZEk25Hw15a7JQXK6P/EeLKQjhIe5XTTXnUYiPCjYF9J0QYmqLKlMmC4RKuX2qvtK/IERWoS8n5dEHCADRIGSFBxZM4Zxy+TC2JseIMnrCU4UA6yZGgPjzicHO2sV3aFKCOnIEGEjITBTDpSVHMfyAn/YLQwo2grNAGZtlgqz5do9VL7Lyz3K3e54M4cowMOsEHCEAnKjsxBmmt/ACwfBelZwgYPryVloBxniFe8h0cYJo520yv7nQHKmFGQ/VvkwN4oQ5iksd3B4VuhIPyDpcCcouUTpCMYs/XzPVyi1dL61SS1LPcreUxwaEBwESOLuWgq1CBhmATlbKXQXP8D8kxq3OoGbvBw8xYUKMcZ4m1dFT08DA2kjvZNO0AZqzJZ0FwrVCtlWN8V4SjWarEUuKRoXBIgZSBYNynflrY+TlIrc7+EBkX+baGcNhiDNJqPGiSc2XcStgJjQcR7RjOpcasbtOuDawnfKvB1M8urN01pyh4ePQ2kjnYDkTJWZbKguRa3J8jR3Da9LkOxVuNgH6RoTBLsCMZs/ZTybVnr4yg1UC6AGxQ5gJw2lPcRND9bayEJwlkXghsk/gD7CB8MMDa8wcPsO9sqyBnioSkNczeEXX7uaOeU8d0loCDxJR6PQnuCAvfj4qhAcgCOFiKKJuwYwPopntp3ZPWrxO1Kcr/kBkWCW1DK+0iuhWrxyVDRkdRGs1yBmRPDPsJwQQfa4OHmLdlWQcwQj01pmLshuiWzzPOMMsoUxF17PwHtC8HW6jLYV1C0dmDHgNZP6dS+svVxkfv1wUCDIsEtiBbVpPlOHb89VHSE9p3QDZI7MdpqoKADcXLIYVCgXMiyoU1pmLshZmVERzuijBIFidfeT0B7NNgPgdFCRNHkHYPYsj8v0cKtj/PwjtygyE/L3YLOc11Wr1PNt8MSCRLyZLEbBPbrxelZmJNDDgNTG4UsG9qUJrgbsppJ52gXKCPyWrFr7yWgPR5soYPRQkDR8I4Beq94RDyWaNXoSFOQmiQ2KIJuQe8DyPM+cs1vRRIk5cmWbhDJiQE1T+Dk2CYI8R2UVs+b0oRiXxQChF496LWqii6+j4X4Q3B6IKZocMeAvVcoIg5aH5NrWXRGaFAkhNVCW0NKYrBDXCBBgp+qdIOITgykeYiTYw7j3kg2iLNsnA+TNaVpDp+CJ/5Cr57gtYLXPhJA7xWSSogompUE2DEA7xWMiOPWx+nvK5rrIjQowmG1aDHJooo1X6xTLzWMu0E++ZUP3IWSEwOlZwFOjjkMDpTjddP5MFlTmvoteOIv8uoJFETwAD4SQLP3pE6AogVJlDsG5r0SSrTspLD1MQtIp9QkoUEROpaJ6F1aVIHmCyQoU6bX2A1y1omRaZ7AyXEoR+hjAtbN5MP0TWnCE6ATfwFllCgIvPbxIKYHAooWJMF2DKX3KswWZoo+Pdj6GAekhxoUhdf2rV/5hPgbCi8KCijDtMBCmYRY0HknBtM8iZPjfBapj4kBNQnNLvkwaYAGFesiyijQColePhxgZg+kaK+JJAj5Bd6rPAfIfSRC6+MKB6TPNihKAQfofkMBZSEtsFQmwQ0iFakRXkHTs3DtGspnEfaYjIa1+4X93419Id6HGWpi4Nm+iDJKgUXJA/h4wJk9gKL9KpPEctCyIJMrtT6W6gXMo2Shgaj5POCACu5xbSAgQbjVDnaDYPcZ+3RoShrh5B/+14FQjnDKCadh3eHYy2S9W1iFZj5MoW8r8upJtAJe+4CgYc+YdylQNC4J+2lLlgWaXE5hvvxZmyWaxRZ4vUDFQgOkJLTKAg6lv0Gohi53CliZpFgQ7NfLPp093uDBtWQwtZHbhNVu7d/O7mBIDEtvhocUI8oIaYVdjQG9fEiwsKdXAUTRMMESvVelybVSYxTmc5+ucGwBNyjKSkJ5wEGmANJJcfvXwwcMlW4QqSvFuExouJYMpTZym3AkFfD7025BfZjoXFpIGV9BWuFX4+zahzXRpJ5Spmg5wfo6VAaXFIdNrpMaozCf/8XXkGUKDYrKklD7BMD9dvZAMhd3lJRJcINIDRaqcZnQcC0R9pgsROWTIJ3ttW7Mrlvsdps6HRVd1ExCyti/H0QrwmqcXXtrtXwqUthzgKIVBEtQBttOFaakBalRClP92hF5foWDPMuSUKmT9/CBZJEEiQ4L6AbJ3GeDPaUhDYNrSb7HZBnizCYYdTMbafv3XTj1CGc8CZQReq0WaTXm1z4qQthzkKIVkhCUwUTE4cY+SY0Wf7LAa9AG1KAIl4RKFnP4QLK0U8B5soIbJHefDfWUFg79BGtJscdkGeJs2tVpe/BHDRCPPMp4gpQRUpDaXJtW49v38ZoAnuPJFA2HWAXvldnkJ5P72X2UcJTae15vceAVV5+gklAYcCgCyp+1cT1MgrDDQqiOpO6zFveU/mCYk+NTIfI9JssQ54vR0qt4W3XhM8+P5hUpY0FBLL187a8Nq/EjBgYLeI4nUjRMxqQWS70ORpPb/fqxrZKE2cG/UrkArj4ZG3AoA8p5wi/a9mX5PqUbhKevffwdoaf0wKGf7PwHwmHAHpNmiMcv0v7ajZVdTzuE3o8yZSwpSHYtW40fHCHgIFA0gYyhFkve5npDGigMlBouF0ANikYFHNJT5QFlmvCbn5KCjswpY0F5+trXxZ7SIifPzn8Izw8DllmGuPkiY9aYMfqL3dL/3izjaYAyFhQkv5Y5TOYCSNEWgIxhy0JsrjWkv5FeUS41HHjFDYpGBRziOAgoH+G+U8r3AbGgvHxU7il9tks7WUsgU0cZ4v0XGUlQfdgvU7Uuz3hClPHd/4YpSHEtOYhsJsgo2uu9ExvbMZDay6pUBmpzjSGlFIZJTcrn4g2KXo8POPhBGFCG+06p5SaIBbFQjruZ3FMa0TB0/kMSYkW1HGaIO2YT/tX21KXnqlnGE6CMH0sUpLz21vo3OThFswQLcl/BBwBsLqUwTGpSPhdvUDQ64PBqoDbQWrxi3ylu+8qOynkox4wJPaXtTyhoGDz/QUhthBniiyblAnSx9CyrAmwrQBkHKIhEL2eCnKL9dycJvGOASdPQ5hIKk6SGw42gQdHAUUvc/yYnJ9XpSLfsCFqiTLRbX5V3VIahHNhTWtjgwWJb2McE0zDr8wnHpBEWhBoRZJRxMLCIPYAzQU7RkiTgjgElTeMq+kRhgtSEfC7UoAgHHIDiyclJweLRhN8yT1Zyg1D3GfOewZ7SwgYPJPbDsJFEw6zPx1CQvGdxUQVYePVErxX2AM4IOUWjkuA7BugDkKvoiZfJSw3nc8EGRTjgABRPSE6iFi8ZIZAnK7lBqPuMh3KKntKQhgnnP+A+JhINcz6f/idmW4W4KXjLv5HSq1fSila8dl7IKRqXBNkxwBT8zOa+bY9YCKfgMC9TBXO/pIM8ccABKB4MKHOLRzq6gDxZwQ3C3Wc0lFMcsshp2ECTJ9zHRKBh9lrXd8EwG3+vPOVpwKtX0Ar52lmhoGhEEnTHAPNBC5vr1khvzqiXqcy1s6eySwd54oADUjwUUAYWT2yjCdwguMGCfMgip2GgyZPQw89OmpmE33QEz1/r+y4kO5qHmASvHqQVsgdwVuAUjUvCf9og98ujsLnWkIYXHL1MMNfOpI+gBkUDAQeueFJtYGbxBpriQDeI4D6rCIlFhywaGX7nbR8Tz5s84R5+dgZmEn7rQ3++d7iWNaVGISbo1YO0YtHga2cHRtG4JL7xsZT7JVbRR0tLvEwLnGuH9kzDAYcs7wMmxZUbT6kpDnSDSO4z0FM63+B9fR9j4nmTJ9zDr6oyk3D8H59Urid+uDZRdRhiyr16rUj5jMMEeQDniN4Ovw6CyCQh535JVfRRaOkjoZHXWC4gFEOfCTgkxZOS4sDGU2qjidwgQvkojiFyTv6KxcSzJk+wh19Bw7rf/mbtzveO14ZGxCjEBLx6IuWzDhPgAZwjQuNgQLCE3K+hKnorNPOCXbgxi7y+x3rSWLCDPM8FHOJSK0VHUCERaqMJ3SDQfYZ7SpecPIuJ83yfoodfBWnY7jv+fO94bfCzC30TcsooUT7nMAEewLmCCYJIIsv9clo0WEVvqWf//ny4EdcLQDqJ3IJyH59S84WMX9RGU3CDII963lNa3ODxmDjx3gemzlvgQRqWzvcO14YIEwoxlV69BaJ8xGHC6OWcQQTBCRZ3Xn1noIqeCq2qPgiBV1wvgBgAWNaFgIOUFAfyXP8jbqOJHL/YfVb2lJY2eDwmHr33hKmTLSaiYXaSdCTXkrVNyJs0Ia8e48n5AafOYUI8gDMGEwTp85xZlqEq+kxoNPCaRV6FY6GgWxAHHBChxSQIt9GEmit1paA9pcsYIv0is5i4+9c1Y+ourV6gYf52mS8t+Nl9iOmjIa8ep3x1565lDpNZpPCfBRcEP8Q5Whac7PINLDSWa8cir/hYKOQWlPr4IM0XSBByWEjxd9SXNuspXcYQ4xcJY+K8id/SmwSJhjl0eUOMEGEyIaaf/y3Zq1dllK9/X+7a0mEyezBBhEFmWYRkl60ktCzXjiR0gYM8oVtQ7uPDCa1cdCQ5LHA/FbCZLHpKR3GVGzwYE+dN/DbvD9MwPxHpwJVXIbh3AL16OeWr07Xx23szrLNtNEME4QZLHwBKdhkQGs21i/1bhYM8sVuQ6d27H8PcpAESJLbRLDVX2kwWPaUrYYMHY+JFE78BGkaxJWmMWRWCewfMq/fxr5cUxMo7Xfuwx0o8EUYSRBBWkMAHgHJoJaFluXYdzVgGB3mCrqWF3v1PkJs0WKeO6DfWXFw0WaHjqvAGD8XEQRM/mYZxhERdUAS823OvXqQVgCfHax/xWInnoZcE3zDAvRjKoc2E9g2Yz3X2IM/CLQjyPn77m0Vu0kDGr+SwKDV30UKPOjquKt/gkStBTLxs4ifTMAhUBJx59X5DpiD02gc8VuI5cJIgp6JDHwDOoc2FZh39eeD17EGeWddSnPdR5iaJGb+4Szt0gwibSdC8pdjg0SvdFTQ5gi0wnqkjGobBvhLqN+ZePUBBCE9O175Z8NYR9lT91a993Q8LObSZ0FxeThZ4FYtPEB9dCD2WUG6SVEiEtn2Z5g5tJnGGdrbBy3uhVoN9iH3iZknDMPhXspe9ejkFYbMUHsA3BFk4livD17pqMIc2FxptHxrCjdKBZIiPmqrcMuAg1AYCElS00Xy9/19dqbnfkDeTMENb6NIOmzxlxMY6chrjCh+dVi+1Qquq3KtXBhbla98YcElke7HfJCYX5tAyoeGKTqEnTRlwCHqXBRxgUpzzaOUkqGij2Wvu24dXmeb+3MBmEmVoC13acZOngthYGvad9oK0enw2b3gHTGuLwOLAtW8KoiSgD+AjYnJRDi0RmlTRiQ/yrIqAQ7SYWcABJcW5ryy3eHkbTecGaTPN/bWB8lFc1Yq7tKMmT6CPCaRhEsQyhIgty8UaphXb0xtpoj2gD+BtkimNc2iT0GLuF7EsAwd5goCD1ztqMnOHOEv45RavaKMpuEHk8lFc1Qo3eBU7Yvz9oT4miIYVGKhpya9k/2uYVryRm0IL6ANgJlfMoSV5TD73q+L1AsJBnhUKOLiq3GgygUNcyHOtQBtNQXOFzSTM0MYbPHqgibnyI7mPiUDDSsg1LYN4Q2nFOWDvFTe5Q1laWe5XquYaOsizAgEHX5Vby01pijzX15R+szaakhsEdqWAGdpo1WrMiXbpQJOqen+gj4lIw8pXINa0DOPNphUQovcKmVyObij369xBnhUIOFC9gw7xLOG3aofaaCLNlbpSIOOIG1W2/ECTwT4miIYJgDUtI/Dm0goBgvcqpngkk5sDB17dPx9zkGdVBhySxcQHkuUJv3IbzdwN8lruSiEcUowaVfJzlu2w1MfESvC8TXAP747mfePSLl4I1AfwLZrsUhTRMwzkfo08yLMMOCSLiQ8k4wm/qI3mO0RxmebCKKZB1lPaVjFUwgaPn7NsRSP0MfGr1hmbYJ80Hc375qVdvBCCD+C3foHbXJ5um0EOvMKDPEGGxlDAAR4ylue5ojaaVHGp5oruM95TeqBRpXDCeNbH5DdZhviwTbCgR/O+YWkXLwLiA1gWNncwJ1wMvKIGRXmGhvO/wYADTopbgDxXRL8bKRYkuM9YT+mPhhpVgnOWM2Kz7Iq0+kGbwN2SZy5VjANRhtLmDpoWFHgVIgOgJHSg4J66FnzNUUtJEGlWB+j3EcaCoPss7yn97YENHjpnOSc23UdlhviQTciStufXCfRWCJIcTHYB/4wGXt+XGxTBklBccJ85xFeBAzEStEEtTrHiVkPus6KntNyoMjssVorvgAzxIZuAjuZVPBtpLzac7FL+QxZ4BQ2KUFJbOAUL9ljKHOJp30lJkNEmq0wl/Zb8vtx99oplaNOjYqVGlcVhsVJ854K0eqlmUvE8sL3YYLJLCRZ4LRsUyRVSuf9NSOdMBo+RIOMcMf+rpN/A7wvcZzxDm/aURo0qWQlv8OpJfUxGp9XLNZOK54Elf12YQ8sDr1mDotVwUhsvuBc0Pxk8SoLsvi8+As33Kf2+yH2WZWiHmfINXkUn4IfFFvGdKISxafVCra7i2eAafGEOLQu88gZFg2ci5AX3kuYTg0c2nqQrDkm7zsLv35LdZ8IRstkGz/8yUMKLG7qE/znOJEC3pGJyXJrsElLdywZFUlKbUHDvUGg+MXjhQMWsjWb36yj8Pug+4xna78sJfAaghDeP7zCMMAmwV/ZNXvcbgKcku8AGRbmPGHXyJgX3OJ0TGLyoTXYvefrfMPx+HHaf8QxtMYGPNXkiCUOwj0kUxlmTAGsmr/+m3xQ8QbSwozL3EQ8U3A8fMlYYvKhNdnv3TRx+F91n6HgAaYOXN3myGRz5+lJK45xJwDWTinsBbFCUpwZ9NFxwP3DIGDV4mTbVA+F36D7rnwo0SRc3eOCE8XJ9QRIZEteigk0aFXeCLNb1zndwapCoeLg2kCIZPKRNUigIus/MU9khkqGNN3hFk6dnNj5s96AM4T3lGfeHPAVfSg3KFa+VkuJKtNWANomhIOg+C58GydCGG7y8ydNzGx+6jCcp5UlxLwCxLik1qFA8SfNLDGuTFArKd5Opp7QBPQSLbPCEJk/PbHwY3JJSypPiPoBjXUehTDxXvOZcg4SAM9ok+n35bhKdR1xu8IQmT89rfEjckvBsXsWdAHZUhqlBBoXiHc80SAg4p02S35e5z2hP6SyGSCm51OTpWY0PWZPGLOVJcR8oGhT5EzeHSkK54smaX+CMNol+X+o+Y93UvyVScqHJ0/MaH2ZNGmnKk+I+UDQo8rGuwZJQ1sl7dDF0dV6bJL9v+x3YU3qIkgtNnp7Z+JA2aTzfdVRxdeQNiszYiJLQbeZaGFcMXZ3XJukv4Xn3w5S8bPIUfvJTGx9mTRo1h//uUDQoMoOjSkIpoR5TDJ2ufpo2wfPuh5q0gxPGA57c+DBL2p7tecQPi6xBUXdpSeioBgkZnqpN8Lx7gZILJ4wHXNyhSD6kWHEXaFGDou27o0tCveaPapCQ46n9rsqe0hWm5NI5ywQXJ22JNZOKewBsUHQcXRIad2KjGiQUeEIKoNBTuoKUXDpnmeLSTaF4SLHi9hAaFI0uCcW1gRfgUm2CPaXDXJySS02englcM6m4C4AGRc4LNTbgINQGvhxgT+n4NJSSoxDi8zFU06K4OVCDIovRAQdcG/hCKA9Z5KCUfOj4h2dgsKZFcWvIKfhjAw6wNvCFHhYcspiBUPKh4x+egcGaFsXNIabgj3YRl7WBLwV84D2Hi3OfPf7hSRhR06K4KaT+oBZjXcRXOmNsVPOW8cc/PAGjaloUt0Ard1ROGO0ivsYZY2Obtzzx+IczP/B5NS2Kl4fv3jwc6xrrIr7GYSBjm7c89fiHATy3pkVxBfTvfUQK/lgjdIXDQEY3b3nq8Q/yhM+raVFcAzY0MCYFfyRe9AXjntLio0x9/MPzaloUV0DeoOi+Y13ouCrhidEJ48/Hs2paFFdACg1U9+9MxcdVIcATxifAs2paFFdADA2cO6Pw9oDHVQlgJ4xPiWfVtCheFDw0cLfWuR06jxj/izMx8Wc9zXUc7YrLkYcG7tQ6Dx5XhTAiJv48sd2poN5cPFJoYDV8XBXCmJj4M6Cnbt8ZHio0MHgeMcIVDjTRU7fvCo8VGhg4rgrhOgea3K+43kQ8VmhAPq4KQg80eQPxWKEBdFyVDD3Q5A3E44QGhOOqMC6LiStmhIcJDQjHVUFcEBNXzAx3Hxpoh4+rKrG4ICaumB/uPjQgHleFkZ2zfOunV1wbdx8akI6ryiCcs3zrp1dcHXceGpDPI2aQTxhXvGm4Zys2snfL0AnjCsX9YFzvlsFzlhWK+8G43i2D5ywrFPeB1FP6XO+W4XOWFYp7AO0pfS4xf/CcZYXilghN0mlP6SH32/lzlhWKmyE1ST/XU/qCc5YVihuBNEk/21N6/DnLCsWNQJqkn83QHn3OskJxM6QE7XMZ2i6EOGGTJ4ViepAE7cEM7aLH010HPBVvLkYmaD9UjyfFG4yRCdophKjnmSjuGucTtHkIUc2z4q5xNkE7DyGqeVbcNaQE7UtDiArFfQAq6fgQokJx/7gkhKhQ3D0uCSEqFPeP8SFEheIBMDaEqFA8Bh6mx5NCMQZ33+NJobgId9/jSaG4BHff40mhuAh33uNJobgQuilUKBQKhUKhUCgUCoVCoVAoFAqFQqFQKBQKhUKhUCgUCoVCoVAoFAqFQqFQKBQKhUKhUCgUCoVCoVAoFAqFQqFQKBQKhUKhUCgUCoVCoVAoFAqFQqFQKBQKhUKhUCgUCoVCoVAoFAqFQqFQKBQKhUKhUCgUiivj/wMgLnl5eTLLMwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMS0wOC0wM1QwOTo1NzozMiswNzowMKsEOOUAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjEtMDgtMDNUMDk6NTc6MzIrMDc6MDDaWYBZAAAAIXRFWHRwczpIaVJlc0JvdW5kaW5nQm94ADUwNHg3MjArNTArNTDW4iLDAAAAE3RFWHRwczpMZXZlbABBZG9iZS0yLjAKOZN0DQAAAABJRU5ErkJggg==" />

=end html


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

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

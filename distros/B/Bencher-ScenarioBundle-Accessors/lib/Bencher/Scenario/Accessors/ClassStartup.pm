package Bencher::Scenario::Accessors::ClassStartup;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Accessors'; # DIST
our $VERSION = '0.151'; # VERSION

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

This document describes version 0.151 of Bencher::Scenario::Accessors::ClassStartup (from Perl distribution Bencher-ScenarioBundle-Accessors), released on 2024-05-06.

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

L<Class::Struct> 0.68

L<Class::Tiny> 1.008

L<Class::XSAccessor> 1.19

L<Class::XSAccessor::Array> 1.19

L<Mo> 0.40

L<Mojo::Base>

L<Mojo::Base::XS> 0.07

L<Moo> 2.005005

L<Moops> 0.038

L<Moos> 0.30

L<Moose> 2.2206

L<Mouse> v2.5.10

L<Object::Pad> 0.806

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

=item * Perl::Examples::Accessors::ClassTiny (perl_code)

L<Perl::Examples::Accessors::ClassTiny>



=item * Perl::Examples::Accessors::ClassAccessorArray (perl_code)

L<Perl::Examples::Accessors::ClassAccessorArray>



=item * Perl::Examples::Accessors::Scalar (perl_code)

L<Perl::Examples::Accessors::Scalar>



=item * Perl::Examples::Accessors::MojoBase (perl_code)

L<Perl::Examples::Accessors::MojoBase>



=item * Perl::Examples::Accessors::ObjectTinyRWXS (perl_code)

L<Perl::Examples::Accessors::ObjectTinyRWXS>



=item * Perl::Examples::Accessors::ClassXSAccessor (perl_code)

L<Perl::Examples::Accessors::ClassXSAccessor>



=item * Perl::Examples::Accessors::Moops (perl_code)

L<Perl::Examples::Accessors::Moops>



=item * Perl::Examples::Accessors::ClassInsideOut (perl_code)

L<Perl::Examples::Accessors::ClassInsideOut>



=item * Perl::Examples::Accessors::Moos (perl_code)

L<Perl::Examples::Accessors::Moos>



=item * Perl::Examples::Accessors::Hash (perl_code)

L<Perl::Examples::Accessors::Hash>



=item * Perl::Examples::Accessors::ClassAccessorPackedString (perl_code)

L<Perl::Examples::Accessors::ClassAccessorPackedString>



=item * Perl::Examples::Accessors::ObjectTinyRW (perl_code)

L<Perl::Examples::Accessors::ObjectTinyRW>



=item * Perl::Examples::Accessors::SimpleAccessor (perl_code)

L<Perl::Examples::Accessors::SimpleAccessor>



=item * Perl::Examples::Accessors::ObjectTinyXS (perl_code)

L<Perl::Examples::Accessors::ObjectTinyXS>



=item * Perl::Examples::Accessors::ObjectSimple (perl_code)

L<Perl::Examples::Accessors::ObjectSimple>



=item * Perl::Examples::Accessors::Mouse (perl_code)

L<Perl::Examples::Accessors::Mouse>



=item * Perl::Examples::Accessors::MojoBaseXS (perl_code)

L<Perl::Examples::Accessors::MojoBaseXS>



=item * Perl::Examples::Accessors::ClassStruct (perl_code)

L<Perl::Examples::Accessors::ClassStruct>



=item * Perl::Examples::Accessors::Array (perl_code)

L<Perl::Examples::Accessors::Array>



=item * Perl::Examples::Accessors::ClassAccessor (perl_code)

L<Perl::Examples::Accessors::ClassAccessor>



=item * Perl::Examples::Accessors::Moo (perl_code)

L<Perl::Examples::Accessors::Moo>



=item * Perl::Examples::Accessors::ClassAccessorPackedStringSet (perl_code)

L<Perl::Examples::Accessors::ClassAccessorPackedStringSet>



=item * Perl::Examples::Accessors::ClassXSAccessorArray (perl_code)

L<Perl::Examples::Accessors::ClassXSAccessorArray>



=item * Perl::Examples::Accessors::Moose (perl_code)

L<Perl::Examples::Accessors::Moose>



=item * Perl::Examples::Accessors::Mo (perl_code)

L<Perl::Examples::Accessors::Mo>



=item * Perl::Examples::Accessors::ObjectTiny (perl_code)

L<Perl::Examples::Accessors::ObjectTiny>



=item * Perl::Examples::Accessors::ObjectPad (perl_code)

L<Perl::Examples::Accessors::ObjectPad>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::ClassStartup

Result formatted as table:

 #table1#
 +---------------------------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                                             | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Perl::Examples::Accessors::Moops                        |    190    |            183.22 |                 0.00% |              2630.85% |   0.00019 |      20 |
 | Perl::Examples::Accessors::Moose                        |    140    |            133.22 |                32.49% |              1961.14% | 9.8e-05   |      20 |
 | Perl::Examples::Accessors::MojoBase                     |    113    |            106.22 |                63.34% |              1571.86% | 5.4e-05   |      20 |
 | Perl::Examples::Accessors::Moo                          |     27    |             20.22 |               594.64% |               293.13% | 3.1e-05   |      20 |
 | Perl::Examples::Accessors::Mouse                        |     26.3  |             19.52 |               604.02% |               287.90% | 9.7e-06   |      21 |
 | Perl::Examples::Accessors::ObjectPad                    |     19.8  |             13.02 |               836.44% |               191.62% | 1.2e-05   |      20 |
 | Perl::Examples::Accessors::Moos                         |     19.5  |             12.72 |               847.95% |               188.08% | 1.6e-05   |      20 |
 | Perl::Examples::Accessors::ClassInsideOut               |     17.6  |             10.82 |               954.08% |               159.07% | 1.4e-05   |      22 |
 | Perl::Examples::Accessors::ClassStruct                  |     14.7  |              7.92 |              1163.69% |               116.10% | 1.2e-05   |      20 |
 | Perl::Examples::Accessors::ClassXSAccessor              |     14    |              7.22 |              1193.45% |               111.13% | 5.7e-05   |      20 |
 | Perl::Examples::Accessors::ObjectSimple                 |     14.2  |              7.42 |              1199.96% |               110.07% | 1.3e-05   |      20 |
 | Perl::Examples::Accessors::ClassXSAccessorArray         |     14.2  |              7.42 |              1200.15% |               110.04% | 1.2e-05   |      20 |
 | Perl::Examples::Accessors::ClassTiny                    |     14.2  |              7.42 |              1206.46% |               109.03% | 1.1e-05   |      20 |
 | Perl::Examples::Accessors::ObjectTinyXS                 |     14.1  |              7.32 |              1210.62% |               108.36% | 1.2e-05   |      20 |
 | Perl::Examples::Accessors::ObjectTinyRWXS               |     14.1  |              7.32 |              1211.54% |               108.22% | 1.2e-05   |      20 |
 | Perl::Examples::Accessors::ClassAccessor                |     14    |              7.22 |              1219.06% |               107.03% | 1.9e-05   |      24 |
 | Perl::Examples::Accessors::MojoBaseXS                   |     11    |              4.22 |              1618.77% |                58.88% | 1.2e-05   |      20 |
 | Perl::Examples::Accessors::SimpleAccessor               |      9.63 |              2.85 |              1824.14% |                41.93% | 7.8e-06   |      20 |
 | Perl::Examples::Accessors::ClassAccessorPackedString    |      9.3  |              2.52 |              1883.66% |                37.67% | 1.4e-05   |      20 |
 | Perl::Examples::Accessors::Mo                           |      9.1  |              2.32 |              1934.31% |                34.24% | 9.4e-06   |      20 |
 | Perl::Examples::Accessors::ObjectTinyRW                 |      7.63 |              0.85 |              2327.99% |                12.47% | 5.5e-06   |      20 |
 | Perl::Examples::Accessors::ObjectTiny                   |      7.57 |              0.79 |              2346.32% |                11.63% | 3.4e-06   |      20 |
 | Perl::Examples::Accessors::ClassAccessorPackedStringSet |      7.5  |              0.72 |              2374.96% |                10.34% | 7.8e-06   |      20 |
 | Perl::Examples::Accessors::ClassAccessorArray           |      7.3  |              0.52 |              2423.40% |                 8.22% | 1.1e-05   |      20 |
 | Perl::Examples::Accessors::Hash                         |      7    |              0.22 |              2539.45% |                 3.46% | 1.4e-05   |      20 |
 | Perl::Examples::Accessors::Array                        |      6.98 |              0.2  |              2554.45% |                 2.88% | 5.1e-06   |      20 |
 | Perl::Examples::Accessors::Scalar                       |      6.91 |              0.13 |              2581.65% |                 1.83% | 4.2e-06   |      20 |
 | perl -e1 (baseline)                                     |      6.78 |              0    |              2630.85% |                 0.00% | 4.9e-06   |      20 |
 +---------------------------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                              Rate  Perl::Examples::Accessors::Moops  Perl::Examples::Accessors::Moose  Perl::Examples::Accessors::MojoBase  Perl::Examples::Accessors::Moo  Perl::Examples::Accessors::Mouse  Perl::Examples::Accessors::ObjectPad  Perl::Examples::Accessors::Moos  Perl::Examples::Accessors::ClassInsideOut  Perl::Examples::Accessors::ClassStruct  Perl::Examples::Accessors::ObjectSimple  Perl::Examples::Accessors::ClassXSAccessorArray  Perl::Examples::Accessors::ClassTiny  Perl::Examples::Accessors::ObjectTinyXS  Perl::Examples::Accessors::ObjectTinyRWXS  Perl::Examples::Accessors::ClassXSAccessor  Perl::Examples::Accessors::ClassAccessor  Perl::Examples::Accessors::MojoBaseXS  Perl::Examples::Accessors::SimpleAccessor  Perl::Examples::Accessors::ClassAccessorPackedString  Perl::Examples::Accessors::Mo  Perl::Examples::Accessors::ObjectTinyRW  Perl::Examples::Accessors::ObjectTiny  Perl::Examples::Accessors::ClassAccessorPackedStringSet  Perl::Examples::Accessors::ClassAccessorArray  Perl::Examples::Accessors::Hash  Perl::Examples::Accessors::Array  Perl::Examples::Accessors::Scalar  perl -e1 (baseline) 
  Perl::Examples::Accessors::Moops                           5.3/s                                --                              -26%                                 -40%                            -85%                              -86%                                  -89%                             -89%                                       -90%                                    -92%                                     -92%                                             -92%                                  -92%                                     -92%                                       -92%                                        -92%                                      -92%                                   -94%                                       -94%                                                  -95%                           -95%                                     -95%                                   -96%                                                     -96%                                           -96%                             -96%                              -96%                               -96%                 -96% 
  Perl::Examples::Accessors::Moose                           7.1/s                               35%                                --                                 -19%                            -80%                              -81%                                  -85%                             -86%                                       -87%                                    -89%                                     -89%                                             -89%                                  -89%                                     -89%                                       -89%                                        -90%                                      -90%                                   -92%                                       -93%                                                  -93%                           -93%                                     -94%                                   -94%                                                     -94%                                           -94%                             -95%                              -95%                               -95%                 -95% 
  Perl::Examples::Accessors::MojoBase                        8.8/s                               68%                               23%                                   --                            -76%                              -76%                                  -82%                             -82%                                       -84%                                    -86%                                     -87%                                             -87%                                  -87%                                     -87%                                       -87%                                        -87%                                      -87%                                   -90%                                       -91%                                                  -91%                           -91%                                     -93%                                   -93%                                                     -93%                                           -93%                             -93%                              -93%                               -93%                 -94% 
  Perl::Examples::Accessors::Moo                            37.0/s                              603%                              418%                                 318%                              --                               -2%                                  -26%                             -27%                                       -34%                                    -45%                                     -47%                                             -47%                                  -47%                                     -47%                                       -47%                                        -48%                                      -48%                                   -59%                                       -64%                                                  -65%                           -66%                                     -71%                                   -71%                                                     -72%                                           -72%                             -74%                              -74%                               -74%                 -74% 
  Perl::Examples::Accessors::Mouse                          38.0/s                              622%                              432%                                 329%                              2%                                --                                  -24%                             -25%                                       -33%                                    -44%                                     -46%                                             -46%                                  -46%                                     -46%                                       -46%                                        -46%                                      -46%                                   -58%                                       -63%                                                  -64%                           -65%                                     -70%                                   -71%                                                     -71%                                           -72%                             -73%                              -73%                               -73%                 -74% 
  Perl::Examples::Accessors::ObjectPad                      50.5/s                              859%                              607%                                 470%                             36%                               32%                                    --                              -1%                                       -11%                                    -25%                                     -28%                                             -28%                                  -28%                                     -28%                                       -28%                                        -29%                                      -29%                                   -44%                                       -51%                                                  -53%                           -54%                                     -61%                                   -61%                                                     -62%                                           -63%                             -64%                              -64%                               -65%                 -65% 
  Perl::Examples::Accessors::Moos                           51.3/s                              874%                              617%                                 479%                             38%                               34%                                    1%                               --                                        -9%                                    -24%                                     -27%                                             -27%                                  -27%                                     -27%                                       -27%                                        -28%                                      -28%                                   -43%                                       -50%                                                  -52%                           -53%                                     -60%                                   -61%                                                     -61%                                           -62%                             -64%                              -64%                               -64%                 -65% 
  Perl::Examples::Accessors::ClassInsideOut                 56.8/s                              979%                              695%                                 542%                             53%                               49%                                   12%                              10%                                         --                                    -16%                                     -19%                                             -19%                                  -19%                                     -19%                                       -19%                                        -20%                                      -20%                                   -37%                                       -45%                                                  -47%                           -48%                                     -56%                                   -56%                                                     -57%                                           -58%                             -60%                              -60%                               -60%                 -61% 
  Perl::Examples::Accessors::ClassStruct                    68.0/s                             1192%                              852%                                 668%                             83%                               78%                                   34%                              32%                                        19%                                      --                                      -3%                                              -3%                                   -3%                                      -4%                                        -4%                                         -4%                                       -4%                                   -25%                                       -34%                                                  -36%                           -38%                                     -48%                                   -48%                                                     -48%                                           -50%                             -52%                              -52%                               -52%                 -53% 
  Perl::Examples::Accessors::ObjectSimple                   70.4/s                             1238%                              885%                                 695%                             90%                               85%                                   39%                              37%                                        23%                                      3%                                       --                                               0%                                    0%                                       0%                                         0%                                         -1%                                       -1%                                   -22%                                       -32%                                                  -34%                           -35%                                     -46%                                   -46%                                                     -47%                                           -48%                             -50%                              -50%                               -51%                 -52% 
  Perl::Examples::Accessors::ClassXSAccessorArray           70.4/s                             1238%                              885%                                 695%                             90%                               85%                                   39%                              37%                                        23%                                      3%                                       0%                                               --                                    0%                                       0%                                         0%                                         -1%                                       -1%                                   -22%                                       -32%                                                  -34%                           -35%                                     -46%                                   -46%                                                     -47%                                           -48%                             -50%                              -50%                               -51%                 -52% 
  Perl::Examples::Accessors::ClassTiny                      70.4/s                             1238%                              885%                                 695%                             90%                               85%                                   39%                              37%                                        23%                                      3%                                       0%                                               0%                                    --                                       0%                                         0%                                         -1%                                       -1%                                   -22%                                       -32%                                                  -34%                           -35%                                     -46%                                   -46%                                                     -47%                                           -48%                             -50%                              -50%                               -51%                 -52% 
  Perl::Examples::Accessors::ObjectTinyXS                   70.9/s                             1247%                              892%                                 701%                             91%                               86%                                   40%                              38%                                        24%                                      4%                                       0%                                               0%                                    0%                                       --                                         0%                                          0%                                        0%                                   -21%                                       -31%                                                  -34%                           -35%                                     -45%                                   -46%                                                     -46%                                           -48%                             -50%                              -50%                               -50%                 -51% 
  Perl::Examples::Accessors::ObjectTinyRWXS                 70.9/s                             1247%                              892%                                 701%                             91%                               86%                                   40%                              38%                                        24%                                      4%                                       0%                                               0%                                    0%                                       0%                                         --                                          0%                                        0%                                   -21%                                       -31%                                                  -34%                           -35%                                     -45%                                   -46%                                                     -46%                                           -48%                             -50%                              -50%                               -50%                 -51% 
  Perl::Examples::Accessors::ClassXSAccessor                71.4/s                             1257%                              900%                                 707%                             92%                               87%                                   41%                              39%                                        25%                                      5%                                       1%                                               1%                                    1%                                       0%                                         0%                                          --                                        0%                                   -21%                                       -31%                                                  -33%                           -35%                                     -45%                                   -45%                                                     -46%                                           -47%                             -50%                              -50%                               -50%                 -51% 
  Perl::Examples::Accessors::ClassAccessor                  71.4/s                             1257%                              900%                                 707%                             92%                               87%                                   41%                              39%                                        25%                                      5%                                       1%                                               1%                                    1%                                       0%                                         0%                                          0%                                        --                                   -21%                                       -31%                                                  -33%                           -35%                                     -45%                                   -45%                                                     -46%                                           -47%                             -50%                              -50%                               -50%                 -51% 
  Perl::Examples::Accessors::MojoBaseXS                     90.9/s                             1627%                             1172%                                 927%                            145%                              139%                                   80%                              77%                                        60%                                     33%                                      29%                                              29%                                   29%                                      28%                                        28%                                         27%                                       27%                                     --                                       -12%                                                  -15%                           -17%                                     -30%                                   -31%                                                     -31%                                           -33%                             -36%                              -36%                               -37%                 -38% 
  Perl::Examples::Accessors::SimpleAccessor                103.8/s                             1873%                             1353%                                1073%                            180%                              173%                                  105%                             102%                                        82%                                     52%                                      47%                                              47%                                   47%                                      46%                                        46%                                         45%                                       45%                                    14%                                         --                                                   -3%                            -5%                                     -20%                                   -21%                                                     -22%                                           -24%                             -27%                              -27%                               -28%                 -29% 
  Perl::Examples::Accessors::ClassAccessorPackedString     107.5/s                             1943%                             1405%                                1115%                            190%                              182%                                  112%                             109%                                        89%                                     58%                                      52%                                              52%                                   52%                                      51%                                        51%                                         50%                                       50%                                    18%                                         3%                                                    --                            -2%                                     -17%                                   -18%                                                     -19%                                           -21%                             -24%                              -24%                               -25%                 -27% 
  Perl::Examples::Accessors::Mo                            109.9/s                             1987%                             1438%                                1141%                            196%                              189%                                  117%                             114%                                        93%                                     61%                                      56%                                              56%                                   56%                                      54%                                        54%                                         53%                                       53%                                    20%                                         5%                                                    2%                             --                                     -16%                                   -16%                                                     -17%                                           -19%                             -23%                              -23%                               -24%                 -25% 
  Perl::Examples::Accessors::ObjectTinyRW                  131.1/s                             2390%                             1734%                                1380%                            253%                              244%                                  159%                             155%                                       130%                                     92%                                      86%                                              86%                                   86%                                      84%                                        84%                                         83%                                       83%                                    44%                                        26%                                                   21%                            19%                                       --                                     0%                                                      -1%                                            -4%                              -8%                               -8%                                -9%                 -11% 
  Perl::Examples::Accessors::ObjectTiny                    132.1/s                             2409%                             1749%                                1392%                            256%                              247%                                  161%                             157%                                       132%                                     94%                                      87%                                              87%                                   87%                                      86%                                        86%                                         84%                                       84%                                    45%                                        27%                                                   22%                            20%                                       0%                                     --                                                       0%                                            -3%                              -7%                               -7%                                -8%                 -10% 
  Perl::Examples::Accessors::ClassAccessorPackedStringSet  133.3/s                             2433%                             1766%                                1406%                            260%                              250%                                  164%                             160%                                       134%                                     96%                                      89%                                              89%                                   89%                                      87%                                        87%                                         86%                                       86%                                    46%                                        28%                                                   24%                            21%                                       1%                                     0%                                                       --                                            -2%                              -6%                               -6%                                -7%                  -9% 
  Perl::Examples::Accessors::ClassAccessorArray            137.0/s                             2502%                             1817%                                1447%                            269%                              260%                                  171%                             167%                                       141%                                    101%                                      94%                                              94%                                   94%                                      93%                                        93%                                         91%                                       91%                                    50%                                        31%                                                   27%                            24%                                       4%                                     3%                                                       2%                                             --                              -4%                               -4%                                -5%                  -7% 
  Perl::Examples::Accessors::Hash                          142.9/s                             2614%                             1900%                                1514%                            285%                              275%                                  182%                             178%                                       151%                                    110%                                     102%                                             102%                                  102%                                     101%                                       101%                                        100%                                      100%                                    57%                                        37%                                                   32%                            30%                                       9%                                     8%                                                       7%                                             4%                               --                                0%                                -1%                  -3% 
  Perl::Examples::Accessors::Array                         143.3/s                             2622%                             1905%                                1518%                            286%                              276%                                  183%                             179%                                       152%                                    110%                                     103%                                             103%                                  103%                                     102%                                       102%                                        100%                                      100%                                    57%                                        37%                                                   33%                            30%                                       9%                                     8%                                                       7%                                             4%                               0%                                --                                -1%                  -2% 
  Perl::Examples::Accessors::Scalar                        144.7/s                             2649%                             1926%                                1535%                            290%                              280%                                  186%                             182%                                       154%                                    112%                                     105%                                             105%                                  105%                                     104%                                       104%                                        102%                                      102%                                    59%                                        39%                                                   34%                            31%                                      10%                                     9%                                                       8%                                             5%                               1%                                1%                                 --                  -1% 
  perl -e1 (baseline)                                      147.5/s                             2702%                             1964%                                1566%                            298%                              287%                                  192%                             187%                                       159%                                    116%                                     109%                                             109%                                  109%                                     107%                                       107%                                        106%                                      106%                                    62%                                        42%                                                   37%                            34%                                      12%                                    11%                                                      10%                                             7%                               3%                                2%                                 1%                   -- 
 
 Legends:
   Perl::Examples::Accessors::Array: mod_overhead_time=0.2 participant=Perl::Examples::Accessors::Array
   Perl::Examples::Accessors::ClassAccessor: mod_overhead_time=7.22 participant=Perl::Examples::Accessors::ClassAccessor
   Perl::Examples::Accessors::ClassAccessorArray: mod_overhead_time=0.52 participant=Perl::Examples::Accessors::ClassAccessorArray
   Perl::Examples::Accessors::ClassAccessorPackedString: mod_overhead_time=2.52 participant=Perl::Examples::Accessors::ClassAccessorPackedString
   Perl::Examples::Accessors::ClassAccessorPackedStringSet: mod_overhead_time=0.72 participant=Perl::Examples::Accessors::ClassAccessorPackedStringSet
   Perl::Examples::Accessors::ClassInsideOut: mod_overhead_time=10.82 participant=Perl::Examples::Accessors::ClassInsideOut
   Perl::Examples::Accessors::ClassStruct: mod_overhead_time=7.92 participant=Perl::Examples::Accessors::ClassStruct
   Perl::Examples::Accessors::ClassTiny: mod_overhead_time=7.42 participant=Perl::Examples::Accessors::ClassTiny
   Perl::Examples::Accessors::ClassXSAccessor: mod_overhead_time=7.22 participant=Perl::Examples::Accessors::ClassXSAccessor
   Perl::Examples::Accessors::ClassXSAccessorArray: mod_overhead_time=7.42 participant=Perl::Examples::Accessors::ClassXSAccessorArray
   Perl::Examples::Accessors::Hash: mod_overhead_time=0.22 participant=Perl::Examples::Accessors::Hash
   Perl::Examples::Accessors::Mo: mod_overhead_time=2.32 participant=Perl::Examples::Accessors::Mo
   Perl::Examples::Accessors::MojoBase: mod_overhead_time=106.22 participant=Perl::Examples::Accessors::MojoBase
   Perl::Examples::Accessors::MojoBaseXS: mod_overhead_time=4.22 participant=Perl::Examples::Accessors::MojoBaseXS
   Perl::Examples::Accessors::Moo: mod_overhead_time=20.22 participant=Perl::Examples::Accessors::Moo
   Perl::Examples::Accessors::Moops: mod_overhead_time=183.22 participant=Perl::Examples::Accessors::Moops
   Perl::Examples::Accessors::Moos: mod_overhead_time=12.72 participant=Perl::Examples::Accessors::Moos
   Perl::Examples::Accessors::Moose: mod_overhead_time=133.22 participant=Perl::Examples::Accessors::Moose
   Perl::Examples::Accessors::Mouse: mod_overhead_time=19.52 participant=Perl::Examples::Accessors::Mouse
   Perl::Examples::Accessors::ObjectPad: mod_overhead_time=13.02 participant=Perl::Examples::Accessors::ObjectPad
   Perl::Examples::Accessors::ObjectSimple: mod_overhead_time=7.42 participant=Perl::Examples::Accessors::ObjectSimple
   Perl::Examples::Accessors::ObjectTiny: mod_overhead_time=0.79 participant=Perl::Examples::Accessors::ObjectTiny
   Perl::Examples::Accessors::ObjectTinyRW: mod_overhead_time=0.85 participant=Perl::Examples::Accessors::ObjectTinyRW
   Perl::Examples::Accessors::ObjectTinyRWXS: mod_overhead_time=7.32 participant=Perl::Examples::Accessors::ObjectTinyRWXS
   Perl::Examples::Accessors::ObjectTinyXS: mod_overhead_time=7.32 participant=Perl::Examples::Accessors::ObjectTinyXS
   Perl::Examples::Accessors::Scalar: mod_overhead_time=0.13 participant=Perl::Examples::Accessors::Scalar
   Perl::Examples::Accessors::SimpleAccessor: mod_overhead_time=2.85 participant=Perl::Examples::Accessors::SimpleAccessor
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Accessors>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Accessors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package Bencher::Scenario::Accessors::Get;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-03'; # DATE
our $DIST = 'Bencher-Scenarios-Accessors'; # DIST
our $VERSION = '0.150'; # VERSION

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::Accessors;

my $classes = \%Bencher::ScenarioUtil::Accessors::classes;

our $scenario = {
    summary => 'Benchmark attribute read/get',
    modules => {
        # include the generator modules here so we can show their versions in
        # sample benchmark results produced by PWP:Bencher::Scenario
        (map { $_=>0 } grep {defined} map { $classes->{$_}{generator} }
             keys %$classes),
    },
    participants => [
        (map {
            my $spec = $classes->{$_};
            my $supports_setters = $spec->{supports_setters} // 1;
            +{
                name => $spec->{generator} || $spec->{name},
                module => $_,
                code_template => $supports_setters ?
                    "state \$o = do { my \$o = ${_}->new; \$o->".($spec->{setter_name} // "attr1")."(42); \$o }; \$o->attr1" :
                    "state \$o = do { my \$o = ${_}->new(attr1 => 42); \$o }; \$o->attr1",
            };
        } grep { !$classes->{$_}{immutable} } keys %$classes),

        # also compare with raw hash & array access
        {
            name => 'raw hash access',
            module => 'Perl::Examples::Accessors::Hash',
            code_template => "state \$o = do { my \$o = Perl::Examples::Accessors::Hash->new; \$o->attr1(42); \$o }; \$o->{attr1}",
        },
        {
            name => 'raw array access',
            module => 'Perl::Examples::Accessors::Array',
            code_template => "state \$o = do { my \$o = Perl::Examples::Accessors::Array->new; \$o->attr1(42); \$o }; \$o->[0]",
        },
    ],
    result => 42,
};

1;
# ABSTRACT: Benchmark attribute read/get

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Accessors::Get - Benchmark attribute read/get

=head1 VERSION

This document describes version 0.150 of Bencher::Scenario::Accessors::Get (from Perl distribution Bencher-Scenarios-Accessors), released on 2021-08-03.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::Get

To run module startup overhead benchmark:

 % bencher --module-startup -m Accessors::Get

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

L<Perl::Examples::Accessors::SimpleAccessor> 0.132

L<Simple::Accessor> 1.13

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Accessor::PackedString (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorPackedString->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Accessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorArray->new; $o->attr1(42); $o }; $o->attr1



=item * Mojo::Base (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBase->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTiny->new(attr1 => 42); $o }; $o->attr1



=item * Simple::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::SimpleAccessor->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny::RW (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRW->new; $o->attr1(42); $o }; $o->attr1



=item * Moose (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moose->new; $o->attr1(42); $o }; $o->attr1



=item * Moos (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moos->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Pad (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectPad->new; $o->set_attr1(42); $o }; $o->attr1



=item * Object::Tiny::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyXS->new(attr1 => 42); $o }; $o->attr1



=item * Mouse (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mouse->new; $o->attr1(42); $o }; $o->attr1



=item * Mo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mo->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Simple (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectSimple->new; $o->attr1(42); $o }; $o->attr1



=item * Moops (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moops->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Struct (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassStruct->new; $o->attr1(42); $o }; $o->attr1



=item * Class::XSAccessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessor->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny::RW::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRWXS->new; $o->attr1(42); $o }; $o->attr1



=item * no generator (array-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o->attr1(42); $o }; $o->attr1



=item * Moo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moo->new; $o->attr1(42); $o }; $o->attr1



=item * Class::InsideOut (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassInsideOut->new; $o->attr1(42); $o }; $o->attr1



=item * Mojo::Base::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBaseXS->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessor->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Tiny (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassTiny->new; $o->attr1(42); $o }; $o->attr1



=item * no generator (hash-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Accessor::PackedString::Set (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorPackedStringSet->new; $o->attr1(42); $o }; $o->attr1



=item * Class::XSAccessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessorArray->new; $o->attr1(42); $o }; $o->attr1



=item * raw hash access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o->attr1(42); $o }; $o->{attr1}



=item * raw array access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o->attr1(42); $o }; $o->[0]



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::Get

Result formatted as table:

 #table1#
 +------------------------------------+------------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        |  rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+------------+-----------+-----------------------+-----------------------+---------+---------+
 | Class::Accessor::PackedString::Set |    2000000 |       600 |                 0.00% |            -10483.94% | 1.6e-08 |      21 |
 | Class::Accessor::Array             |    2200000 |       460 |                23.99% |             -8475.01% | 2.3e-09 |      20 |
 | Object::Pad                        |    2000000 |       400 |                37.22% |             -7667.54% | 5.2e-09 |      20 |
 | Class::Accessor::PackedString      |    2000000 |       400 |                38.66% |             -7588.70% | 1.7e-08 |      20 |
 | Class::Accessor                    |    3000000 |       400 |                44.98% |             -7262.48% | 2.1e-08 |      20 |
 | Class::InsideOut                   |    3000000 |       400 |                61.32% |             -6536.79% | 6.9e-09 |      21 |
 | Mo                                 |    3000000 |       300 |                80.30% |             -5859.41% | 1.3e-08 |      20 |
 | Mojo::Base                         |    4000000 |       200 |               137.49% |             -4472.46% | 1.2e-08 |      20 |
 | Simple::Accessor                   |    4000000 |       200 |               139.63% |             -4433.24% | 5.7e-09 |      20 |
 | Class::Tiny                        |    5000000 |       200 |               166.06% |             -4002.89% | 1.2e-08 |      21 |
 | no generator (hash-based)          |    5000000 |       200 |               203.33% |             -3523.27% | 3.6e-09 |      21 |
 | no generator (array-based)         |    6000000 |       200 |               231.72% |             -3230.31% | 4.1e-09 |      20 |
 | Class::Struct                      |    6000000 |       170 |               242.10% |             -3135.35% |   1e-09 |      20 |
 | Object::Simple                     |    6000000 |       200 |               264.60% |             -2948.05% | 3.7e-09 |      20 |
 | Object::Tiny::RW                   |    7000000 |       100 |               322.42% |             -2558.21% | 3.6e-09 |      20 |
 | Moose                              |    8000000 |       100 |               327.94% |             -2526.49% | 4.3e-09 |      20 |
 | Object::Tiny::XS                   |    8000000 |       100 |               335.23% |             -2485.84% | 1.7e-09 |      20 |
 | Mojo::Base::XS                     |    9000000 |       100 |               391.55% |             -2212.50% | 5.9e-09 |      28 |
 | Moops                              |    9000000 |       100 |               403.91% |             -2160.65% | 7.9e-09 |      20 |
 | Moos                               |   10000000 |       100 |               475.19% |             -1905.31% | 6.7e-09 |      35 |
 | raw hash access                    |   10000000 |        90 |               501.10% |             -1827.49% | 2.2e-09 |      22 |
 | Object::Tiny                       |   11000000 |        94 |               505.39% |             -1815.25% | 8.7e-10 |      20 |
 | Mouse                              |   12000000 |        81 |               600.65% |             -1582.04% | 4.8e-10 |      20 |
 | Moo                                |   16000000 |        63 |               807.87% |             -1243.77% |   3e-10 |      20 |
 | Object::Tiny::RW::XS               |   20000000 |        60 |               848.65% |             -1194.60% | 1.3e-09 |      20 |
 | Class::XSAccessor                  |   20000000 |        40 |              1277.21% |              -853.98% | 1.9e-09 |      22 |
 | Class::XSAccessor::Array           |   40000000 |        20 |              2411.56% |              -513.45% | 1.5e-09 |      20 |
 | raw array access                   | -200000000 |        -5 |            -10483.94% |                 0.00% | 2.2e-10 |      20 |
 +------------------------------------+------------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                              Rate  Class::Accessor::PackedString::Set  Class::Accessor::Array  Object::Pad  Class::Accessor::PackedString  Class::Accessor  Class::InsideOut      Mo  Mojo::Base  Simple::Accessor  Class::Tiny  no generator (hash-based)  no generator (array-based)  Object::Simple  Class::Struct  Object::Tiny::RW   Moose  Object::Tiny::XS  Mojo::Base::XS   Moops    Moos  Object::Tiny  raw hash access   Mouse     Moo  Object::Tiny::RW::XS  Class::XSAccessor  Class::XSAccessor::Array  raw array access 
  Class::Accessor::PackedString::Set     2000000/s                                  --                    -23%         -33%                           -33%             -33%              -33%    -50%        -66%              -66%         -66%                       -66%                        -66%            -66%           -71%              -83%    -83%              -83%            -83%    -83%    -83%          -84%             -85%    -86%    -89%                  -90%               -93%                      -96%             -100% 
  Class::Accessor::Array                 2200000/s                                 30%                      --         -13%                           -13%             -13%              -13%    -34%        -56%              -56%         -56%                       -56%                        -56%            -56%           -63%              -78%    -78%              -78%            -78%    -78%    -78%          -79%             -80%    -82%    -86%                  -86%               -91%                      -95%             -101% 
  Object::Pad                            2000000/s                                 50%                     14%           --                             0%               0%                0%    -25%        -50%              -50%         -50%                       -50%                        -50%            -50%           -57%              -75%    -75%              -75%            -75%    -75%    -75%          -76%             -77%    -79%    -84%                  -85%               -90%                      -95%             -101% 
  Class::Accessor::PackedString          2000000/s                                 50%                     14%           0%                             --               0%                0%    -25%        -50%              -50%         -50%                       -50%                        -50%            -50%           -57%              -75%    -75%              -75%            -75%    -75%    -75%          -76%             -77%    -79%    -84%                  -85%               -90%                      -95%             -101% 
  Class::Accessor                        3000000/s                                 50%                     14%           0%                             0%               --                0%    -25%        -50%              -50%         -50%                       -50%                        -50%            -50%           -57%              -75%    -75%              -75%            -75%    -75%    -75%          -76%             -77%    -79%    -84%                  -85%               -90%                      -95%             -101% 
  Class::InsideOut                       3000000/s                                 50%                     14%           0%                             0%               0%                --    -25%        -50%              -50%         -50%                       -50%                        -50%            -50%           -57%              -75%    -75%              -75%            -75%    -75%    -75%          -76%             -77%    -79%    -84%                  -85%               -90%                      -95%             -101% 
  Mo                                     3000000/s                                100%                     53%          33%                            33%              33%               33%      --        -33%              -33%         -33%                       -33%                        -33%            -33%           -43%              -66%    -66%              -66%            -66%    -66%    -66%          -68%             -70%    -73%    -79%                  -80%               -86%                      -93%             -101% 
  Mojo::Base                             4000000/s                                200%                    129%         100%                           100%             100%              100%     50%          --                0%           0%                         0%                          0%              0%           -15%              -50%    -50%              -50%            -50%    -50%    -50%          -53%             -55%    -59%    -68%                  -70%               -80%                      -90%             -102% 
  Simple::Accessor                       4000000/s                                200%                    129%         100%                           100%             100%              100%     50%          0%                --           0%                         0%                          0%              0%           -15%              -50%    -50%              -50%            -50%    -50%    -50%          -53%             -55%    -59%    -68%                  -70%               -80%                      -90%             -102% 
  Class::Tiny                            5000000/s                                200%                    129%         100%                           100%             100%              100%     50%          0%                0%           --                         0%                          0%              0%           -15%              -50%    -50%              -50%            -50%    -50%    -50%          -53%             -55%    -59%    -68%                  -70%               -80%                      -90%             -102% 
  no generator (hash-based)              5000000/s                                200%                    129%         100%                           100%             100%              100%     50%          0%                0%           0%                         --                          0%              0%           -15%              -50%    -50%              -50%            -50%    -50%    -50%          -53%             -55%    -59%    -68%                  -70%               -80%                      -90%             -102% 
  no generator (array-based)             6000000/s                                200%                    129%         100%                           100%             100%              100%     50%          0%                0%           0%                         0%                          --              0%           -15%              -50%    -50%              -50%            -50%    -50%    -50%          -53%             -55%    -59%    -68%                  -70%               -80%                      -90%             -102% 
  Object::Simple                         6000000/s                                200%                    129%         100%                           100%             100%              100%     50%          0%                0%           0%                         0%                          0%              --           -15%              -50%    -50%              -50%            -50%    -50%    -50%          -53%             -55%    -59%    -68%                  -70%               -80%                      -90%             -102% 
  Class::Struct                          6000000/s                                252%                    170%         135%                           135%             135%              135%     76%         17%               17%          17%                        17%                         17%             17%             --              -41%    -41%              -41%            -41%    -41%    -41%          -44%             -47%    -52%    -62%                  -64%               -76%                      -88%             -102% 
  Object::Tiny::RW                       7000000/s                                500%                    359%         300%                           300%             300%              300%    200%        100%              100%         100%                       100%                        100%            100%            70%                --      0%                0%              0%      0%      0%           -6%              -9%    -18%    -37%                  -40%               -60%                      -80%             -105% 
  Moose                                  8000000/s                                500%                    359%         300%                           300%             300%              300%    200%        100%              100%         100%                       100%                        100%            100%            70%                0%      --                0%              0%      0%      0%           -6%              -9%    -18%    -37%                  -40%               -60%                      -80%             -105% 
  Object::Tiny::XS                       8000000/s                                500%                    359%         300%                           300%             300%              300%    200%        100%              100%         100%                       100%                        100%            100%            70%                0%      0%                --              0%      0%      0%           -6%              -9%    -18%    -37%                  -40%               -60%                      -80%             -105% 
  Mojo::Base::XS                         9000000/s                                500%                    359%         300%                           300%             300%              300%    200%        100%              100%         100%                       100%                        100%            100%            70%                0%      0%                0%              --      0%      0%           -6%              -9%    -18%    -37%                  -40%               -60%                      -80%             -105% 
  Moops                                  9000000/s                                500%                    359%         300%                           300%             300%              300%    200%        100%              100%         100%                       100%                        100%            100%            70%                0%      0%                0%              0%      --      0%           -6%              -9%    -18%    -37%                  -40%               -60%                      -80%             -105% 
  Moos                                  10000000/s                                500%                    359%         300%                           300%             300%              300%    200%        100%              100%         100%                       100%                        100%            100%            70%                0%      0%                0%              0%      0%      --           -6%              -9%    -18%    -37%                  -40%               -60%                      -80%             -105% 
  Object::Tiny                          11000000/s                                538%                    389%         325%                           325%             325%              325%    219%        112%              112%         112%                       112%                        112%            112%            80%                6%      6%                6%              6%      6%      6%            --              -4%    -13%    -32%                  -36%               -57%                      -78%             -105% 
  raw hash access                       10000000/s                                566%                    411%         344%                           344%             344%              344%    233%        122%              122%         122%                       122%                        122%            122%            88%               11%     11%               11%             11%     11%     11%            4%               --     -9%    -30%                  -33%               -55%                      -77%             -105% 
  Mouse                                 12000000/s                                640%                    467%         393%                           393%             393%              393%    270%        146%              146%         146%                       146%                        146%            146%           109%               23%     23%               23%             23%     23%     23%           16%              11%      --    -22%                  -25%               -50%                      -75%             -106% 
  Moo                                   16000000/s                                852%                    630%         534%                           534%             534%              534%    376%        217%              217%         217%                       217%                        217%            217%           169%               58%     58%               58%             58%     58%     58%           49%              42%     28%      --                   -4%               -36%                      -68%             -107% 
  Object::Tiny::RW::XS                  20000000/s                                900%                    666%         566%                           566%             566%              566%    400%        233%              233%         233%                       233%                        233%            233%           183%               66%     66%               66%             66%     66%     66%           56%              50%     35%      5%                    --               -33%                      -66%             -108% 
  Class::XSAccessor                     20000000/s                               1400%                   1050%         900%                           900%             900%              900%    650%        400%              400%         400%                       400%                        400%            400%           325%              150%    150%              150%            150%    150%    150%          135%             125%    102%     57%                   50%                 --                      -50%             -112% 
  Class::XSAccessor::Array              40000000/s                               2900%                   2200%        1900%                          1900%            1900%             1900%   1400%        900%              900%         900%                       900%                        900%            900%           750%              400%    400%              400%            400%    400%    400%          370%             350%    305%    215%                  200%               100%                        --             -125% 
  raw array access                    -200000000/s                             -12100%                  -9300%       -8100%                         -8100%           -8100%            -8100%  -6100%      -4100%            -4100%       -4100%                     -4100%                      -4100%          -4100%         -3500%            -2100%  -2100%            -2100%          -2100%  -2100%  -2100%        -1980%           -1900%  -1720%  -1360%                -1300%              -900%                     -500%                -- 
 
 Legends:
   Class::Accessor: participant=Class::Accessor
   Class::Accessor::Array: participant=Class::Accessor::Array
   Class::Accessor::PackedString: participant=Class::Accessor::PackedString
   Class::Accessor::PackedString::Set: participant=Class::Accessor::PackedString::Set
   Class::InsideOut: participant=Class::InsideOut
   Class::Struct: participant=Class::Struct
   Class::Tiny: participant=Class::Tiny
   Class::XSAccessor: participant=Class::XSAccessor
   Class::XSAccessor::Array: participant=Class::XSAccessor::Array
   Mo: participant=Mo
   Mojo::Base: participant=Mojo::Base
   Mojo::Base::XS: participant=Mojo::Base::XS
   Moo: participant=Moo
   Moops: participant=Moops
   Moos: participant=Moos
   Moose: participant=Moose
   Mouse: participant=Mouse
   Object::Pad: participant=Object::Pad
   Object::Simple: participant=Object::Simple
   Object::Tiny: participant=Object::Tiny
   Object::Tiny::RW: participant=Object::Tiny::RW
   Object::Tiny::RW::XS: participant=Object::Tiny::RW::XS
   Object::Tiny::XS: participant=Object::Tiny::XS
   Simple::Accessor: participant=Simple::Accessor
   no generator (array-based): participant=no generator (array-based)
   no generator (hash-based): participant=no generator (hash-based)
   raw array access: participant=raw array access
   raw hash access: participant=raw hash access

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

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

package Bencher::Scenario::Accessors::Get;

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::Accessors;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Accessors'; # DIST
our $VERSION = '0.151'; # VERSION

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

This document describes version 0.151 of Bencher::Scenario::Accessors::Get (from Perl distribution Bencher-ScenarioBundle-Accessors), released on 2024-05-06.

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

L<Perl::Examples::Accessors::SimpleAccessor> 0.132

L<Simple::Accessor> 1.13

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Tiny (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassTiny->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Accessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorArray->new; $o->attr1(42); $o }; $o->attr1



=item * Mojo::Base (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBase->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny::RW::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRWXS->new; $o->attr1(42); $o }; $o->attr1



=item * Class::XSAccessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessor->new; $o->attr1(42); $o }; $o->attr1



=item * Moops (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moops->new; $o->attr1(42); $o }; $o->attr1



=item * Class::InsideOut (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassInsideOut->new; $o->attr1(42); $o }; $o->attr1



=item * Moos (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moos->new; $o->attr1(42); $o }; $o->attr1



=item * no generator (hash-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Accessor::PackedString (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorPackedString->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny::RW (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRW->new; $o->attr1(42); $o }; $o->attr1



=item * Simple::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::SimpleAccessor->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyXS->new(attr1 => 42); $o }; $o->attr1



=item * Object::Simple (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectSimple->new; $o->attr1(42); $o }; $o->attr1



=item * Mouse (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mouse->new; $o->attr1(42); $o }; $o->attr1



=item * Mojo::Base::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBaseXS->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Struct (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassStruct->new; $o->attr1(42); $o }; $o->attr1



=item * no generator (array-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessor->new; $o->attr1(42); $o }; $o->attr1



=item * Moo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moo->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Accessor::PackedString::Set (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorPackedStringSet->new; $o->attr1(42); $o }; $o->attr1



=item * Class::XSAccessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessorArray->new; $o->attr1(42); $o }; $o->attr1



=item * Moose (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moose->new; $o->attr1(42); $o }; $o->attr1



=item * Mo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mo->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTiny->new(attr1 => 42); $o }; $o->attr1



=item * Object::Pad (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectPad->new; $o->set_attr1(42); $o }; $o->attr1



=item * raw hash access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o->attr1(42); $o }; $o->{attr1}



=item * raw array access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o->attr1(42); $o }; $o->[0]



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::Get

Result formatted as table:

 #table1#
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Class::Accessor::PackedString::Set |   1740000 |     575   |                 0.00% |              1678.82% | 2.6e-10 |      20 |
 | Object::Tiny::RW                   |   2390000 |     418   |                37.66% |              1192.22% | 3.8e-10 |      20 |
 | Class::Accessor                    |   2650000 |     377   |                52.51% |              1066.39% | 1.2e-10 |      20 |
 | Simple::Accessor                   |   3300000 |     310   |                87.01% |               851.20% | 5.3e-10 |      20 |
 | Class::InsideOut                   |   3400000 |     294   |                95.44% |               810.15% | 8.5e-11 |      20 |
 | Class::Accessor::PackedString      |   3440000 |     291   |                97.50% |               800.69% | 1.1e-10 |      21 |
 | Object::Pad                        |   4210000 |     237   |               142.11% |               634.70% | 1.9e-10 |      20 |
 | Class::XSAccessor::Array           |   4000000 |     200   |               153.25% |               602.40% | 5.4e-09 |      21 |
 | Class::Struct                      |   5100000 |     200   |               192.35% |               508.45% | 3.5e-10 |      20 |
 | no generator (hash-based)          |   5300000 |     190   |               204.11% |               484.93% | 3.3e-10 |      20 |
 | Mojo::Base                         |   5500000 |     180   |               213.68% |               467.07% | 2.8e-10 |      20 |
 | Object::Simple                     |   5700000 |     180   |               226.24% |               445.24% | 6.6e-10 |      20 |
 | Moose                              |   6050000 |     165   |               247.56% |               411.81% | 1.5e-10 |      20 |
 | no generator (array-based)         |   6000000 |     170   |               247.69% |               411.61% | 2.9e-10 |      20 |
 | Mo                                 |   6100000 |     170   |               248.00% |               411.16% | 2.7e-10 |      21 |
 | Class::Tiny                        |   6200000 |     161   |               256.49% |               398.99% | 7.6e-11 |      21 |
 | Class::Accessor::Array             |   6770000 |     148   |               289.48% |               356.72% | 6.6e-11 |      21 |
 | Object::Tiny                       |   7200000 |     140   |               311.51% |               332.27% | 1.9e-10 |      20 |
 | Mouse                              |  13000000 |      80   |               620.95% |               146.73% | 1.2e-10 |      20 |
 | Moops                              |  14200000 |      70.4 |               717.18% |               117.68% | 6.2e-11 |      20 |
 | Moo                                |  14000000 |      70   |               722.77% |               116.20% |   1e-10 |      20 |
 | Moos                               |  15000000 |      69   |               734.24% |               113.23% |   7e-11 |      20 |
 | Mojo::Base::XS                     |  14800000 |      67.7 |               748.89% |               109.55% | 4.9e-11 |      22 |
 | Object::Tiny::RW::XS               |  15000000 |      68   |               749.72% |               109.34% | 1.2e-10 |      21 |
 | Object::Tiny::XS                   |  16000000 |      64   |               796.98% |                98.31% | 7.1e-11 |      20 |
 | Class::XSAccessor                  |  16400000 |      60.8 |               845.17% |                88.20% | 2.1e-11 |      21 |
 | raw hash access                    |  23500000 |      42.6 |              1248.39% |                31.92% | 3.7e-11 |      20 |
 | raw array access                   |  31000000 |      32   |              1678.82% |                 0.00% | 3.3e-11 |      20 |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                            Rate  Class::Accessor::PackedString::Set  Object::Tiny::RW  Class::Accessor  Simple::Accessor  Class::InsideOut  Class::Accessor::PackedString  Object::Pad  Class::XSAccessor::Array  Class::Struct  no generator (hash-based)  Mojo::Base  Object::Simple  no generator (array-based)    Mo  Moose  Class::Tiny  Class::Accessor::Array  Object::Tiny  Mouse  Moops   Moo  Moos  Object::Tiny::RW::XS  Mojo::Base::XS  Object::Tiny::XS  Class::XSAccessor  raw hash access  raw array access 
  Class::Accessor::PackedString::Set   1740000/s                                  --              -27%             -34%              -46%              -48%                           -49%         -58%                      -65%           -65%                       -66%        -68%            -68%                        -70%  -70%   -71%         -72%                    -74%          -75%   -86%   -87%  -87%  -88%                  -88%            -88%              -88%               -89%             -92%              -94% 
  Object::Tiny::RW                     2390000/s                                 37%                --              -9%              -25%              -29%                           -30%         -43%                      -52%           -52%                       -54%        -56%            -56%                        -59%  -59%   -60%         -61%                    -64%          -66%   -80%   -83%  -83%  -83%                  -83%            -83%              -84%               -85%             -89%              -92% 
  Class::Accessor                      2650000/s                                 52%               10%               --              -17%              -22%                           -22%         -37%                      -46%           -46%                       -49%        -52%            -52%                        -54%  -54%   -56%         -57%                    -60%          -62%   -78%   -81%  -81%  -81%                  -81%            -82%              -83%               -83%             -88%              -91% 
  Simple::Accessor                     3300000/s                                 85%               34%              21%                --               -5%                            -6%         -23%                      -35%           -35%                       -38%        -41%            -41%                        -45%  -45%   -46%         -48%                    -52%          -54%   -74%   -77%  -77%  -77%                  -78%            -78%              -79%               -80%             -86%              -89% 
  Class::InsideOut                     3400000/s                                 95%               42%              28%                5%                --                            -1%         -19%                      -31%           -31%                       -35%        -38%            -38%                        -42%  -42%   -43%         -45%                    -49%          -52%   -72%   -76%  -76%  -76%                  -76%            -76%              -78%               -79%             -85%              -89% 
  Class::Accessor::PackedString        3440000/s                                 97%               43%              29%                6%                1%                             --         -18%                      -31%           -31%                       -34%        -38%            -38%                        -41%  -41%   -43%         -44%                    -49%          -51%   -72%   -75%  -75%  -76%                  -76%            -76%              -78%               -79%             -85%              -89% 
  Object::Pad                          4210000/s                                142%               76%              59%               30%               24%                            22%           --                      -15%           -15%                       -19%        -24%            -24%                        -28%  -28%   -30%         -32%                    -37%          -40%   -66%   -70%  -70%  -70%                  -71%            -71%              -72%               -74%             -82%              -86% 
  Class::XSAccessor::Array             4000000/s                                187%              108%              88%               55%               47%                            45%          18%                        --             0%                        -5%         -9%             -9%                        -15%  -15%   -17%         -19%                    -26%          -30%   -60%   -64%  -65%  -65%                  -65%            -66%              -68%               -69%             -78%              -84% 
  Class::Struct                        5100000/s                                187%              108%              88%               55%               47%                            45%          18%                        0%             --                        -5%         -9%             -9%                        -15%  -15%   -17%         -19%                    -26%          -30%   -60%   -64%  -65%  -65%                  -65%            -66%              -68%               -69%             -78%              -84% 
  no generator (hash-based)            5300000/s                                202%              120%              98%               63%               54%                            53%          24%                        5%             5%                         --         -5%             -5%                        -10%  -10%   -13%         -15%                    -22%          -26%   -57%   -62%  -63%  -63%                  -64%            -64%              -66%               -68%             -77%              -83% 
  Mojo::Base                           5500000/s                                219%              132%             109%               72%               63%                            61%          31%                       11%            11%                         5%          --              0%                         -5%   -5%    -8%         -10%                    -17%          -22%   -55%   -60%  -61%  -61%                  -62%            -62%              -64%               -66%             -76%              -82% 
  Object::Simple                       5700000/s                                219%              132%             109%               72%               63%                            61%          31%                       11%            11%                         5%          0%              --                         -5%   -5%    -8%         -10%                    -17%          -22%   -55%   -60%  -61%  -61%                  -62%            -62%              -64%               -66%             -76%              -82% 
  no generator (array-based)           6000000/s                                238%              145%             121%               82%               72%                            71%          39%                       17%            17%                        11%          5%              5%                          --    0%    -2%          -5%                    -12%          -17%   -52%   -58%  -58%  -59%                  -60%            -60%              -62%               -64%             -74%              -81% 
  Mo                                   6100000/s                                238%              145%             121%               82%               72%                            71%          39%                       17%            17%                        11%          5%              5%                          0%    --    -2%          -5%                    -12%          -17%   -52%   -58%  -58%  -59%                  -60%            -60%              -62%               -64%             -74%              -81% 
  Moose                                6050000/s                                248%              153%             128%               87%               78%                            76%          43%                       21%            21%                        15%          9%              9%                          3%    3%     --          -2%                    -10%          -15%   -51%   -57%  -57%  -58%                  -58%            -58%              -61%               -63%             -74%              -80% 
  Class::Tiny                          6200000/s                                257%              159%             134%               92%               82%                            80%          47%                       24%            24%                        18%         11%             11%                          5%    5%     2%           --                     -8%          -13%   -50%   -56%  -56%  -57%                  -57%            -57%              -60%               -62%             -73%              -80% 
  Class::Accessor::Array               6770000/s                                288%              182%             154%              109%               98%                            96%          60%                       35%            35%                        28%         21%             21%                         14%   14%    11%           8%                      --           -5%   -45%   -52%  -52%  -53%                  -54%            -54%              -56%               -58%             -71%              -78% 
  Object::Tiny                         7200000/s                                310%              198%             169%              121%              110%                           107%          69%                       42%            42%                        35%         28%             28%                         21%   21%    17%          14%                      5%            --   -42%   -49%  -50%  -50%                  -51%            -51%              -54%               -56%             -69%              -77% 
  Mouse                               13000000/s                                618%              422%             371%              287%              267%                           263%         196%                      150%           150%                       137%        125%            125%                        112%  112%   106%         101%                     85%           75%     --   -11%  -12%  -13%                  -15%            -15%              -19%               -24%             -46%              -60% 
  Moops                               14200000/s                                716%              493%             435%              340%              317%                           313%         236%                      184%           184%                       169%        155%            155%                        141%  141%   134%         128%                    110%           98%    13%     --    0%   -1%                   -3%             -3%               -9%               -13%             -39%              -54% 
  Moo                                 14000000/s                                721%              497%             438%              342%              320%                           315%         238%                      185%           185%                       171%        157%            157%                        142%  142%   135%         129%                    111%          100%    14%     0%    --   -1%                   -2%             -3%               -8%               -13%             -39%              -54% 
  Moos                                15000000/s                                733%              505%             446%              349%              326%                           321%         243%                      189%           189%                       175%        160%            160%                        146%  146%   139%         133%                    114%          102%    15%     2%    1%    --                   -1%             -1%               -7%               -11%             -38%              -53% 
  Object::Tiny::RW::XS                15000000/s                                745%              514%             454%              355%              332%                           327%         248%                      194%           194%                       179%        164%            164%                        150%  150%   142%         136%                    117%          105%    17%     3%    2%    1%                    --              0%               -5%               -10%             -37%              -52% 
  Mojo::Base::XS                      14800000/s                                749%              517%             456%              357%              334%                           329%         250%                      195%           195%                       180%        165%            165%                        151%  151%   143%         137%                    118%          106%    18%     3%    3%    1%                    0%              --               -5%               -10%             -37%              -52% 
  Object::Tiny::XS                    16000000/s                                798%              553%             489%              384%              359%                           354%         270%                      212%           212%                       196%        181%            181%                        165%  165%   157%         151%                    131%          118%    25%    10%    9%    7%                    6%              5%                --                -5%             -33%              -50% 
  Class::XSAccessor                   16400000/s                                845%              587%             520%              409%              383%                           378%         289%                      228%           228%                       212%        196%            196%                        179%  179%   171%         164%                    143%          130%    31%    15%   15%   13%                   11%             11%                5%                 --             -29%              -47% 
  raw hash access                     23500000/s                               1249%              881%             784%              627%              590%                           583%         456%                      369%           369%                       346%        322%            322%                        299%  299%   287%         277%                    247%          228%    87%    65%   64%   61%                   59%             58%               50%                42%               --              -24% 
  raw array access                    31000000/s                               1696%             1206%            1078%              868%              818%                           809%         640%                      525%           525%                       493%        462%            462%                        431%  431%   415%         403%                    362%          337%   150%   120%  118%  115%                  112%            111%              100%                89%              33%                -- 
 
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

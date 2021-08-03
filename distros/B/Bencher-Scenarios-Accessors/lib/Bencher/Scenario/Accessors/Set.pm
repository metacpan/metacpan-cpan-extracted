package Bencher::Scenario::Accessors::Set;

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
    summary => 'Benchmark attribute write/set',
    modules => {
        # include the generator modules here so we can show their versions in
        # sample benchmark results produced by PWP:Bencher::Scenario
        (map { $_=>0 } grep {defined} map { $classes->{$_}{generator} }
             keys %$classes),
    },
    participants => [
        (map {
            my $spec = $classes->{$_};
            +{
                name => $spec->{generator} || $spec->{name},
                module => $_,
                code_template => "state \$o = do { my \$o = ${_}->new; \$o }; \$o->".($spec->{setter_name} // "attr1")."(42)",
            };
        } grep { !$classes->{$_}{immutable} && ($classes->{$_}{supports_setters} // 1) } keys %$classes),

        # also compare with raw hash & array access
        {
            name => 'raw hash access',
            module => 'Perl::Examples::Accessors::Hash',
            code_template => "state \$o = do { my \$o = Perl::Examples::Accessors::Hash->new; \$o }; \$o->{attr1} = 42",
        },
        {
            name => 'raw array access',
            module => 'Perl::Examples::Accessors::Array',
            code_template => "state \$o = do { my \$o = Perl::Examples::Accessors::Array->new; \$o }; \$o->[0] = 42",
        },
    ],
};

1;
# ABSTRACT: Benchmark attribute write/set

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Accessors::Set - Benchmark attribute write/set

=head1 VERSION

This document describes version 0.150 of Bencher::Scenario::Accessors::Set (from Perl distribution Bencher-Scenarios-Accessors), released on 2021-08-03.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::Set

To run module startup overhead benchmark:

 % bencher --module-startup -m Accessors::Set

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

L<Perl::Examples::Accessors::ObjectTinyRW> 0.132

L<Perl::Examples::Accessors::ObjectTinyRWXS> 0.132

L<Perl::Examples::Accessors::SimpleAccessor> 0.132

L<Simple::Accessor> 1.13

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Accessor::PackedString (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorPackedString->new; $o }; $o->attr1(42)



=item * Class::Accessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorArray->new; $o }; $o->attr1(42)



=item * Mojo::Base (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBase->new; $o }; $o->attr1(42)



=item * Simple::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::SimpleAccessor->new; $o }; $o->attr1(42)



=item * Object::Tiny::RW (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRW->new; $o }; $o->attr1(42)



=item * Moose (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moose->new; $o }; $o->attr1(42)



=item * Moos (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moos->new; $o }; $o->attr1(42)



=item * Object::Pad (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectPad->new; $o }; $o->set_attr1(42)



=item * Mouse (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mouse->new; $o }; $o->attr1(42)



=item * Mo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mo->new; $o }; $o->attr1(42)



=item * Object::Simple (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectSimple->new; $o }; $o->attr1(42)



=item * Moops (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moops->new; $o }; $o->attr1(42)



=item * Class::Struct (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassStruct->new; $o }; $o->attr1(42)



=item * Class::XSAccessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessor->new; $o }; $o->attr1(42)



=item * Object::Tiny::RW::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRWXS->new; $o }; $o->attr1(42)



=item * no generator (array-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o }; $o->attr1(42)



=item * Moo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moo->new; $o }; $o->attr1(42)



=item * Class::InsideOut (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassInsideOut->new; $o }; $o->attr1(42)



=item * Mojo::Base::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBaseXS->new; $o }; $o->attr1(42)



=item * Class::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessor->new; $o }; $o->attr1(42)



=item * Class::Tiny (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassTiny->new; $o }; $o->attr1(42)



=item * no generator (hash-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o }; $o->attr1(42)



=item * Class::Accessor::PackedString::Set (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorPackedStringSet->new; $o }; $o->attr1(42)



=item * Class::XSAccessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessorArray->new; $o }; $o->attr1(42)



=item * raw hash access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o }; $o->{attr1} = 42



=item * raw array access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o }; $o->[0] = 42



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::Set

Result formatted as table:

 #table1#
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Simple::Accessor                   |    922000 |   1090    |                 0.00% |              2929.69% | 4.1e-10 |      20 |
 | Class::Accessor::PackedString::Set |   1730000 |    579    |                87.44% |              1516.37% | 2.5e-10 |      20 |
 | Class::Accessor::PackedString      |   2380000 |    419    |               158.70% |              1071.14% | 1.5e-10 |      31 |
 | Class::Accessor                    |   2590000 |    386    |               181.28% |               977.11% | 9.8e-11 |      20 |
 | Class::InsideOut                   |   3400000 |    290    |               269.54% |               719.86% | 3.1e-10 |      20 |
 | Object::Pad                        |   4640000 |    216    |               403.39% |               501.86% | 2.9e-11 |      24 |
 | Moose                              |   5120000 |    195    |               455.28% |               445.61% | 5.2e-11 |      20 |
 | Object::Tiny::RW                   |   5270000 |    190    |               472.33% |               429.36% |   7e-11 |      20 |
 | Class::Struct                      |   5390000 |    186    |               484.42% |               418.41% | 1.5e-10 |      20 |
 | Class::Accessor::Array             |   5800000 |    170    |               526.56% |               383.54% | 1.7e-10 |      20 |
 | Mojo::Base                         |   5900000 |    170    |               537.32% |               375.38% | 3.1e-10 |      20 |
 | Mo                                 |   6400000 |    160    |               599.49% |               333.13% | 4.1e-10 |      21 |
 | Object::Simple                     |   6600000 |    150    |               611.69% |               325.70% | 2.4e-10 |      20 |
 | Class::Tiny                        |   6700000 |    150    |               625.50% |               317.60% | 2.1e-10 |      20 |
 | no generator (hash-based)          |   7000000 |    140    |               655.64% |               300.94% | 2.1e-10 |      24 |
 | no generator (array-based)         |   7480000 |    134    |               711.82% |               273.20% | 9.8e-11 |      20 |
 | Mouse                              |  11200000 |     89.28 |              1115.36% |               149.28% | 5.5e-12 |      25 |
 | Moops                              |  11000000 |     88    |              1134.75% |               145.37% | 2.2e-10 |      20 |
 | Moos                               |  12000000 |     81    |              1237.15% |               126.58% | 2.2e-10 |      20 |
 | Object::Tiny::RW::XS               |  13000000 |     77    |              1310.03% |               114.87% | 2.4e-10 |      21 |
 | Mojo::Base::XS                     |  13500000 |     74.3  |              1360.26% |               107.48% |   7e-11 |      20 |
 | Moo                                |  13500000 |     74    |              1366.84% |               106.54% | 5.7e-11 |      20 |
 | Class::XSAccessor                  |  15000000 |     68    |              1497.85% |                89.61% | 1.6e-10 |      20 |
 | Class::XSAccessor::Array           |  17000000 |     58    |              1771.16% |                61.91% | 2.1e-10 |      20 |
 | raw hash access                    |  25000000 |     41    |              2579.11% |                13.09% | 2.4e-10 |      20 |
 | raw array access                   |  28000000 |     36    |              2929.69% |                 0.00% |   2e-10 |      26 |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                            Rate  Simple::Accessor  Class::Accessor::PackedString::Set  Class::Accessor::PackedString  Class::Accessor  Class::InsideOut  Object::Pad  Moose  Object::Tiny::RW  Class::Struct  Class::Accessor::Array  Mojo::Base    Mo  Object::Simple  Class::Tiny  no generator (hash-based)  no generator (array-based)  Mouse  Moops  Moos  Object::Tiny::RW::XS  Mojo::Base::XS   Moo  Class::XSAccessor  Class::XSAccessor::Array  raw hash access  raw array access 
  Simple::Accessor                      922000/s                --                                -46%                           -61%             -64%              -73%         -80%   -82%              -82%           -82%                    -84%        -84%  -85%            -86%         -86%                       -87%                        -87%   -91%   -91%  -92%                  -92%            -93%  -93%               -93%                      -94%             -96%              -96% 
  Class::Accessor::PackedString::Set   1730000/s               88%                                  --                           -27%             -33%              -49%         -62%   -66%              -67%           -67%                    -70%        -70%  -72%            -74%         -74%                       -75%                        -76%   -84%   -84%  -86%                  -86%            -87%  -87%               -88%                      -89%             -92%              -93% 
  Class::Accessor::PackedString        2380000/s              160%                                 38%                             --              -7%              -30%         -48%   -53%              -54%           -55%                    -59%        -59%  -61%            -64%         -64%                       -66%                        -68%   -78%   -78%  -80%                  -81%            -82%  -82%               -83%                      -86%             -90%              -91% 
  Class::Accessor                      2590000/s              182%                                 50%                             8%               --              -24%         -44%   -49%              -50%           -51%                    -55%        -55%  -58%            -61%         -61%                       -63%                        -65%   -76%   -77%  -79%                  -80%            -80%  -80%               -82%                      -84%             -89%              -90% 
  Class::InsideOut                     3400000/s              275%                                 99%                            44%              33%                --         -25%   -32%              -34%           -35%                    -41%        -41%  -44%            -48%         -48%                       -51%                        -53%   -69%   -69%  -72%                  -73%            -74%  -74%               -76%                      -80%             -85%              -87% 
  Object::Pad                          4640000/s              404%                                168%                            93%              78%               34%           --    -9%              -12%           -13%                    -21%        -21%  -25%            -30%         -30%                       -35%                        -37%   -58%   -59%  -62%                  -64%            -65%  -65%               -68%                      -73%             -81%              -83% 
  Moose                                5120000/s              458%                                196%                           114%              97%               48%          10%     --               -2%            -4%                    -12%        -12%  -17%            -23%         -23%                       -28%                        -31%   -54%   -54%  -58%                  -60%            -61%  -62%               -65%                      -70%             -78%              -81% 
  Object::Tiny::RW                     5270000/s              473%                                204%                           120%             103%               52%          13%     2%                --            -2%                    -10%        -10%  -15%            -21%         -21%                       -26%                        -29%   -53%   -53%  -57%                  -59%            -60%  -61%               -64%                      -69%             -78%              -81% 
  Class::Struct                        5390000/s              486%                                211%                           125%             107%               55%          16%     4%                2%             --                     -8%         -8%  -13%            -19%         -19%                       -24%                        -27%   -52%   -52%  -56%                  -58%            -60%  -60%               -63%                      -68%             -77%              -80% 
  Class::Accessor::Array               5800000/s              541%                                240%                           146%             127%               70%          27%    14%               11%             9%                      --          0%   -5%            -11%         -11%                       -17%                        -21%   -47%   -48%  -52%                  -54%            -56%  -56%               -60%                      -65%             -75%              -78% 
  Mojo::Base                           5900000/s              541%                                240%                           146%             127%               70%          27%    14%               11%             9%                      0%          --   -5%            -11%         -11%                       -17%                        -21%   -47%   -48%  -52%                  -54%            -56%  -56%               -60%                      -65%             -75%              -78% 
  Mo                                   6400000/s              581%                                261%                           161%             141%               81%          35%    21%               18%            16%                      6%          6%    --             -6%          -6%                       -12%                        -16%   -44%   -44%  -49%                  -51%            -53%  -53%               -57%                      -63%             -74%              -77% 
  Object::Simple                       6600000/s              626%                                286%                           179%             157%               93%          43%    30%               26%            24%                     13%         13%    6%              --           0%                        -6%                        -10%   -40%   -41%  -46%                  -48%            -50%  -50%               -54%                      -61%             -72%              -76% 
  Class::Tiny                          6700000/s              626%                                286%                           179%             157%               93%          43%    30%               26%            24%                     13%         13%    6%              0%           --                        -6%                        -10%   -40%   -41%  -46%                  -48%            -50%  -50%               -54%                      -61%             -72%              -76% 
  no generator (hash-based)            7000000/s              678%                                313%                           199%             175%              107%          54%    39%               35%            32%                     21%         21%   14%              7%           7%                         --                         -4%   -36%   -37%  -42%                  -44%            -46%  -47%               -51%                      -58%             -70%              -74% 
  no generator (array-based)           7480000/s              713%                                332%                           212%             188%              116%          61%    45%               41%            38%                     26%         26%   19%             11%          11%                         4%                          --   -33%   -34%  -39%                  -42%            -44%  -44%               -49%                      -56%             -69%              -73% 
  Mouse                               11200000/s             1120%                                548%                           369%             332%              224%         141%   118%              112%           108%                     90%         90%   79%             68%          68%                        56%                         50%     --    -1%   -9%                  -13%            -16%  -17%               -23%                      -35%             -54%              -59% 
  Moops                               11000000/s             1138%                                557%                           376%             338%              229%         145%   121%              115%           111%                     93%         93%   81%             70%          70%                        59%                         52%     1%     --   -7%                  -12%            -15%  -15%               -22%                      -34%             -53%              -59% 
  Moos                                12000000/s             1245%                                614%                           417%             376%              258%         166%   140%              134%           129%                    109%        109%   97%             85%          85%                        72%                         65%    10%     8%    --                   -4%             -8%   -8%               -16%                      -28%             -49%              -55% 
  Object::Tiny::RW::XS                13000000/s             1315%                                651%                           444%             401%              276%         180%   153%              146%           141%                    120%        120%  107%             94%          94%                        81%                         74%    15%    14%    5%                    --             -3%   -3%               -11%                      -24%             -46%              -53% 
  Mojo::Base::XS                      13500000/s             1367%                                679%                           463%             419%              290%         190%   162%              155%           150%                    128%        128%  115%            101%         101%                        88%                         80%    20%    18%    9%                    3%              --    0%                -8%                      -21%             -44%              -51% 
  Moo                                 13500000/s             1372%                                682%                           466%             421%              291%         191%   163%              156%           151%                    129%        129%  116%            102%         102%                        89%                         81%    20%    18%    9%                    4%              0%    --                -8%                      -21%             -44%              -51% 
  Class::XSAccessor                   15000000/s             1502%                                751%                           516%             467%              326%         217%   186%              179%           173%                    150%        150%  135%            120%         120%                       105%                         97%    31%    29%   19%                   13%              9%    8%                 --                      -14%             -39%              -47% 
  Class::XSAccessor::Array            17000000/s             1779%                                898%                           622%             565%              400%         272%   236%              227%           220%                    193%        193%  175%            158%         158%                       141%                        131%    53%    51%   39%                   32%             28%   27%                17%                        --             -29%              -37% 
  raw hash access                     25000000/s             2558%                               1312%                           921%             841%              607%         426%   375%              363%           353%                    314%        314%  290%            265%         265%                       241%                        226%   117%   114%   97%                   87%             81%   80%                65%                       41%               --              -12% 
  raw array access                    28000000/s             2927%                               1508%                          1063%             972%              705%         500%   441%              427%           416%                    372%        372%  344%            316%         316%                       288%                        272%   148%   144%  125%                  113%            106%  105%                88%                       61%              13%                -- 
 
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
   Object::Tiny::RW: participant=Object::Tiny::RW
   Object::Tiny::RW::XS: participant=Object::Tiny::RW::XS
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

#!perl

use Data::Frame::Setup;

use PDL::Core qw(pdl);
use PDL::Primitive qw(which);
use Path::Tiny;

use Test2::V0;
use Test2::Tools::Warnings qw(no_warnings);
use Test2::Tools::DataFrame;
use Test2::Tools::PDL;

use Test::File::ShareDir -share =>
  { -dist => { 'Data-Frame' => 'data-raw' } };

use Data::Frame::Examples qw(:datasets dataset_names);

subtest simple => sub {    # just test if the data is loadable
    for my $name (dataset_names()) {
        my $df;
        no strict 'refs';
        ok( no_warnings { $df = $name->(); }, "no warnings from $name()" );
        ok( defined($df), $name );
        ok( no_warnings { $df->string; }, "no warnings from $name()->string" );
    }
};

subtest airquality => sub {
    my $airquality = airquality();
    is($airquality->at('Ozone')->nbad, 37, 'airquality');

    my $tempfile = Path::Tiny->tempfile( SUFFIX => '.csv' );
    $airquality->to_csv($tempfile, row_names => false, na => 'MYNA');
    my $df = Data::Frame->from_csv($tempfile, na => 'MYNA');
    dataframe_is($df, $airquality, '$df->to_csv() handles NA');
};

subtest diamonds => sub {
    my $diamonds = diamonds();
    is( $diamonds->names, [qw(carat cut color clarity depth table price x y z)],
        '$diamonds->names' );
    is( $diamonds->nrow, 53940, '$diamonds->nrow' );

    is(
        $diamonds->at('clarity')->levels,
        [qw(I1 SI2 SI1 VS2 VS1 VVS2 VVS1 IF)],
        'factor for clarity'
    );

    my $cut = $diamonds->at('cut');
    isa_ok( $cut, ['PDL::Factor::Ordered'], 'cut is ordered factor' );
    is(
        $cut->levels,
        [ qw(Fair Good), 'Very Good', qw(Premium Ideal) ],
        'factor for cut'
    );
    my %cut_count =
      map { $_ => which( $cut == $_ )->length } $cut->levels->flatten;
    is(
        \%cut_count,
        {
            Fair        => 1610,
            Good        => 4906,
            'Very Good' => 12082,
            Premium     => 13791,
            Ideal       => 21551
        },
        'numbers of each kind of cut. This test if factor reordering is good.'
    );
};

subtest economics => sub {
    my $economics = economics()->head(3);

    my $expected = <<'END_OF_TEXT';
----------------------------------------------------------
    date        pce    pop     psavert  uempmed  unemploy 
----------------------------------------------------------
 0  1967-07-01  507.4  198712  12.5     4.5      2944     
 1  1967-08-01  510.5  198911  12.5     4.7      2945     
 2  1967-09-01  516.3  199113  11.7     4.6      2958     
----------------------------------------------------------
END_OF_TEXT

    diag($economics->string);   
    #diag($expected);   

    is($economics->string, $expected, 'stringification of datetime column');

    my $tempfile = Path::Tiny->tempfile( SUFFIX => '.csv' );
    $economics->to_csv($tempfile, row_names => false);
    my $df =
      Data::Frame->from_csv( $tempfile, dtype => { date => 'datetime' } );
    dataframe_is($df, $economics, '$df->to_csv() handles datetime');
};

subtest iris => sub {
    my $iris = iris();

    is(
        $iris->at('Species')->levels,
        [qw(setosa versicolor virginica)],
        'iris Species'
    );
};

done_testing;

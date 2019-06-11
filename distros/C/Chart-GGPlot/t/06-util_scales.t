#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

use Chart::GGPlot::Util qw(:scales);
use Chart::GGPlot::Util::_Labeling qw(:all);

use Test2::V0 '!number';
use Test2::Tools::PDL;

ok( zero_range( pdl( [ 1, 1 ] ) ), 'zero_range()' );

subtest censor => sub {
    pdl_is(
        censor( pdl( [ -0.5, 0, 0.5, 1, 1.5, 2 ] ) ),
        pdl( [ 'nan', 0, 0.5, 1, 'nan', 'nan' ] )->setnantobad,
        'censor() with default options'
    );

    pdl_is( censor( pdl( [ -0.5, 0, 0.5, 1, 1.5, 2 ] ), pdl( [ 1, 2 ] ) ),
        pdl( [ 'nan', 'nan', 'nan', 1, 1.5, 2 ] )->setnantobad, 'censor()' );
};

subtest rescale => sub {
    pdl_is(
        rescale( pdl( [ 1 .. 5 ] ) ),
        pdl( [ 0, 0.25, 0.5, 0.75, 1.0 ] ),
        'rescale() to default "to"'
    );
    pdl_is( rescale( pdl( [ 1 .. 5 ] ), pdl( [ 1, 3 ] ) ),
        pdl( [ 1, 1.5, 2, 2.5, 3 ] ), 'rescale()' );
    pdl_is( rescale( pdl( [qw(2 2.5 3 3.5 4 4.5 5 5.5 6)] ) ),
        pdl( [ 0 .. 8 ] ) / 8, 'rescale()' );
};

subtest regular_minor_breaks => sub {
    my $func_minor_breaks_non_reverse = regular_minor_breaks();
    for my $case (
        {
            breaks   => pdl( [ 1, 3, 4 ] ),
            limits   => pdl( [ 1, 4 ] ),
            n        => 2,
            expected => pdl( [ 1, 2, 3, 3.5, 4 ] )
        },
        {
            breaks   => pdl( [ 1, 3, 4 ] ),
            limits   => pdl( [ 0, 4.5 ] ),
            n        => 2,
            expected => pdl( [ 0, 1, 2, 3, 3.5, 4 ] )
        },
      )
    {
        pdl_is(
            $func_minor_breaks_non_reverse->(
                $case->{breaks}, $case->{limits}, $case->{n}
            ),
            $case->{expected},
            "regular_minor_breaks(false)"
        );
    }

    my $func_minor_breaks_reverse = regular_minor_breaks(true);
    for my $case (
        {
            breaks   => pdl( [ 4, 3, 1 ] ),
            limits   => pdl( [ 1, 4 ] ),
            n        => 2,
            expected => pdl( [ 4, 3.5, 3, 2, 1 ] )
        },
        {
            breaks   => pdl( [ 4,   3, 1 ] ),
            limits   => pdl( [ 0,   4.5 ] ),
            n        => 2,
            expected => pdl( [ 4.5, 4, 3.5, 3, 2, 1, 0.5, 0 ] )
        },
      )
    {
        pdl_is(
            $func_minor_breaks_reverse->(
                $case->{breaks}, $case->{limits}, $case->{n}
            ),
            $case->{expected},
            "regular_minor_breaks(true)"
        );
    }
};

subtest squish => sub {
    pdl_is(
        squish( pdl( [ -0.5, 0, 0.5, 1, 1.5, 2 ] ) ),
        pdl( [ 0, 0, 0.5, 1, 1, 1 ] ),
        'squish() with default options'
    );
    pdl_is(
        squish( pdl( [ -0.5, 0, 0.5, 1, 1.5, 2 ] ), pdl( [ 1, 2 ] ) ),
        pdl( [ 1, 1, 1, 1, 1.5, 2 ] ),
        'squish() with default options'
    );
};

subtest discard => sub {
    pdl_is(
        discard( pdl( [ -0.5, 0, 0.5, 1, 1.5, 2 ] ) ),
        pdl( [ 0, 0.5, 1 ] ),
        'discard() with default options'
    );
    pdl_is(
        discard( pdl( [ -0.5, 0, 0.5, 1, 1.5, 2 ] ), pdl( [ 1, 2 ] ) ),
        pdl( [ 1, 1.5, 2 ] ),
        'discard() with non-default options'
    );
};

pdl_is(
    expand_range( pdl( [ 0, 1 ] ), 1, 2 ),
    pdl( [ 0 - 3, 1 + 3 ] ),
    'expand_range()'
);

subtest hue_pal => sub {
    no warnings 'qw';

    pdl_is( hue_pal()->(4),
        PDL::SV->new( [qw(#f7766c #7bae00 #00bfc4 #c77cff)] ), 'hue_pal()' );
    pdl_is(
        hue_pal( l => 90 )->(9),
        PDL::SV->new(
            [
                qw(#ffbbb3 #ffd64c #d6ef16 #54ff8a #00ffe4
                  #00fdff #b0e0ff #ffbcff #ffadff)
            ]
        ),
        'hue_pal()'
    );
    pdl_is(
        hue_pal( h => [ 0, 90 ] )->(9),
        PDL::SV->new(
            [
                qw(#ff6c90 #fa7376 #f27b57 #e9832d #de8b00
                  #d19300 #c29a00 #b1a000 #9da600)
            ]
        ),
        'hue_pal()'
    );
};

subtest gradient_n_pal => sub {
    no warnings 'qw';

    # NOTE: R's gradient_n_pal gives #777777 for 0.5, but we get #7f7f7f,
    #  This is because R's interpolation is in the CIELab space.
    pdl_is(
        gradient_n_pal( PDL::SV->new( [qw(black white)] ) )
          ->( pdl( 0, 0.5, 1 ) ),
        PDL::SV->new( [qw(#000000 #7f7f7f #ffffff)] ),
        "gradient_n_pal()"
    );
};

subtest 'pretty' => sub {
    pdl_is(
        pretty( pdl( 1 .. 15 ) ),
        pdl( [ 0 .. 8 ] ) * 2,
        'pretty(pdl(1..15))'
    );
    pdl_is(
        pretty( pdl( 1 .. 15 ), high_u_bias => 2 ),
        pdl( [ 0, 5, 10, 15 ] ),
        'pretty(pdl(1..15),h=>2)'
    );
    pdl_is(
        pretty( pdl( 1 .. 15 ), n => 4 ),
        pdl( [ 0, 5, 10, 15 ] ),
        'pretty(pdl(1..15),n=>4)'
    );
    pdl_is(
        pretty( pdl( 2 .. 30 ) ),
        pdl( [ 0, 5, 10, 15, 20, 25, 30 ] ),
        'pretty(pdl(2..30))'
    );
    pdl_is(
        pretty( pdl( 1 .. 20 ) ),
        pdl( [ 0, 5, 10, 15, 20 ] ),
        'pretty(pdl(1..20))'
    );
    pdl_is(
        pretty( pdl( 1 .. 20 ), n => 2 ),
        pdl( [ 0, 10, 20 ] ),
        'pretty(pdl(1..20),n=>2)'
    );
    pdl_is(
        pretty( pdl( 1 .. 20 ), n => 10 ),
        pdl( [ 0 .. 10 ] ) * 2,
        'pretty(pdl(1..20),n=>10)'
    );
};

subtest log_breaks => sub {
    pdl_is(
        Chart::GGPlot::Util::Scales::log_sub_breaks( 10, 5, pdl( 1, 3 ) ),
        pdl( 10, 30, 100, 300, 1000, 3000 ),
        'log_sub_breaks()'
    );
    pdl_is(
        log_breaks()->( pdl( 1, 1e6 ) ),
        pdl( 1, 1e2, 1e4, 1e6 ),
        'log_breaks()'
    );
};

subtest pretty_dt => sub {
    pdl_is(
        Chart::GGPlot::Util::Scales::seq_dt(
            beg => PDL::DateTime->new_from_datetime('2018-01-01'),
            end => PDL::DateTime->new_from_datetime('2019-01-01'),
            by  => '1 month'
        ),
        PDL::DateTime->new_sequence( '2018-01-01', 13, 'month' ),
        'Util::Scales::seq_dt'
    );

    pdl_is(
        Chart::GGPlot::Util::Scales::seq_dt(
            beg => PDL::DateTime->new_from_datetime('2018-01-01'),
            end => PDL::DateTime->new_from_datetime('2019-01-25'),
            by  => '1 month'
        ),
        PDL::DateTime->new_sequence( '2018-01-01', 13, 'month' ),
        'Util::Scales::seq_dt'
    );

    pdl_is(
        Chart::GGPlot::Util::Scales::seq_dt(
            beg => PDL::DateTime->new_from_datetime('2018-01-01'),
            end => PDL::DateTime->new_from_datetime('2019-01-05'),
            by  => 'halfmonth'
        ),
        PDL::DateTime->new_from_datetime(
            [
                (
                    map {
                        (
                            sprintf( "2018-%02s-01", $_ ),
                            sprintf( "2018-%02s-15", $_ )
                        )
                    } ( 1 .. 12 )
                ),
                '2019-01-01',
                '2019-01-15'
            ]
        ),
        'Util::Scales::seq_dt'
    );

    my $pretty_dt_rslt = Chart::GGPlot::Util::Scales::pretty_dt(
        PDL::DateTime->new_from_datetime( [qw(2008-01-01 2009-01-01)] ) );
    DOES_ok($pretty_dt_rslt, [qw(PDL::DateTime PDL::Role::HasNames)]);
    pdl_is(
        PDL::DateTime->new($pretty_dt_rslt->unpdl),
        PDL::DateTime->new_sequence( '2008-01-01', 5, 'quarter' ),
        'pretty_dt'
    );
};

subtest pretty_breaks => sub {
    my $f_default = pretty_breaks();

    pdl_is(
        $f_default->( pdl( 1 .. 10 ) ),
        pdl( 0 .. 5 ) * 2,
        'pretty_breaks()->(pdl(1..10))'
    );
    pdl_is(
        $f_default->( pdl( 1 .. 100 ) ),
        pdl( 0 .. 5 ) * 20,
        'pretty_breaks()->(pdl(1..100))'
    );

    my $pretty_dt_rslt1 = $f_default->(
            PDL::DateTime->new_from_datetime( [qw(2008-01-01 2009-01-01)] )
        );
    DOES_ok($pretty_dt_rslt1, [qw(PDL::DateTime PDL::Role::HasNames)]);
    pdl_is(
        PDL::DateTime->new($pretty_dt_rslt1->unpdl),
        PDL::DateTime->new_sequence( '2008-01-01', 5, 'quarter' ),
'pretty_breaks()->(PDL::DateTime->new_from_datetime( [qw(2008-01-01 2009-01-01)] )'
    );
    my $pretty_dt_rslt2 = $f_default->(
            PDL::DateTime->new_from_datetime( [qw(2008-01-01 2090-01-01)] )
        );
    pdl_is(
        PDL::DateTime->new($pretty_dt_rslt2->unpdl),
        PDL::DateTime->new_sequence( '2000-01-01', 6, 'year', 20 ),
'pretty_breaks()->(PDL::DateTime->new_from_datetime( [qw(2008-01-01 2090-01-01)] )'
    );
};

subtest format => sub {
    no warnings 'qw';

    pdl_is( number( pdl( 1000, 2000 )),
        PDL::SV->new( ['1 000', '2 000'] ), "number()" );

    pdl_is( comma( pdl( 1000, 2000 )),
        PDL::SV->new( [qw(1,000 2,000)] ), "comma()" );

    pdl_is( percent( pdl( 0 .. 5 ) / 5 ),
        PDL::SV->new( [qw(0% 20% 40% 60% 80% 100%)] ), "percent()" );

    pdl_is( dollar( pdl( 0, 1 )),
        PDL::SV->new( [qw($0 $1)] ), "dollar()" );
    pdl_is( dollar( pdl( 1000, 2000 )),
        PDL::SV->new( [qw($1,000 $2,000)] ), "dollar()" );
    pdl_is( dollar( pdl( 0, 1.01, -2.1), negative_parens => true),
        PDL::SV->new( [qw($0.00 $1.01 ($2.10))] ), "dollar()" );
};

# Util::_Labeling

# this is from in R `labeling` package's doc
pdl_is(
    labeling_extended( 8.1, 14.1, 4 ),
    pdl( [ 8, 10, 12, 14 ] ),
    'labeling_extended()'
);

done_testing();

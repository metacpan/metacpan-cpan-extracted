#!perl

use Chart::GGPlot::Setup;

use Test2::V0;

use Chart::GGPlot::Theme::Rel;
use Chart::GGPlot::Theme;
use Chart::GGPlot::Theme::Defaults qw(:all);

subtest rel => sub {
    my $r1 = Chart::GGPlot::Theme::Rel->new(2);
    my $r2 = Chart::GGPlot::Theme::Rel->new(3);
    is( $r1 * $r2, 6, 'rel(2) * rel(3)' );
    is( $r1 * 3,   6, 'rel(2) * 3' );
    is( 2 * $r2,   6, '2 * rel(3)' );
};

for my $name (
    qw(
    theme_grey theme_bw
    theme_linedraw theme_light theme_dark
    theme_minimal theme_classic theme_void
    )
  )
{
    my $f     = \&{$name};
    my $theme = $f->();
    ok( $theme, $name );
}

my $theme_grey  = theme_grey();
my $axis_text_x = $theme_grey->calc_element('axis_text_x');

is(
    $axis_text_x->as_hashref,
    {
        family        => '',
        face          => 'plain',
        color         => 'grey30',
        size          => 8.8,   # 11 * 0.8
        hjust         => 0.5,
        vjust         => 1,
        angle         => 0,
        lineheight    => 0.9,
        #margin        => unit( [ 2.2, 0, 0, 0 ], 'pt' )->as_hashref,
        inherit_blank => 1,
    },
    '$theme->calc_element()'
);

ok( $axis_text_x->at('color') eq $axis_text_x->at('colour'),
    'alias "colour" to "color"' );

#is(
#    $theme_grey->legend_position,
#    $theme_grey->at('legend_position'),
#    'AUTOLOAD for theme properties'
#);

done_testing();

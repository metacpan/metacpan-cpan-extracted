#!perl

use Chart::GGPlot::Setup;

use Data::Frame;
use Data::Frame::Examples qw(mtcars);

use Test2::V0;

my $mtcars = mtcars();

use Chart::GGPlot::Labeller;

#diag($mtcars->select_columns([qw(am)])->uniq->string);

my $mtcars_vs    = $mtcars->select_columns( [qw(vs)] )->uniq;
my $mtcars_vs_am = $mtcars->select_columns( [qw(vs am)] )->uniq;

{
    my $label_value_multiline  = Chart::GGPlot::Labeller->label_value;
    my $labels_value_multiline = $label_value_multiline->($mtcars_vs_am);
    is( $labels_value_multiline, [ [ 0, 1 ], [ 1, 1 ], [ 1, 0 ], [ 0, 0 ] ],
        'label_value()' );

    my $label_value_singleline  = Chart::GGPlot::Labeller->label_value(false);
    my $labels_value_singleline = $label_value_singleline->($mtcars_vs_am);
    is( $labels_value_singleline, [ '0, 1', '1, 1', '1, 0', '0, 0' ],
        'label_value(false)' );

    my $label_both_multiline  = Chart::GGPlot::Labeller->label_both;
    my $labels_both_multiline = $label_both_multiline->($mtcars_vs_am);
    is(
        $labels_both_multiline,
        [
            [ 'vs: 0', 'am: 1' ],
            [ 'vs: 1', 'am: 1' ],
            [ 'vs: 1', 'am: 0' ],
            [ 'vs: 0', 'am: 0' ]
        ],
        'label_both()'
    );

    my $label_both_singleline  = Chart::GGPlot::Labeller->label_both(false);
    my $labels_both_singleline = $label_both_singleline->($mtcars_vs_am);
    is( $labels_both_singleline,
        [ 'vs: 0, am: 1', 'vs: 1, am: 1', 'vs: 1, am: 0', 'vs: 0, am: 0' ],
        'label_both(false)' );

    my $label_context_multiline = Chart::GGPlot::Labeller->label_context();
    my $label_context_singleline =
      Chart::GGPlot::Labeller->label_context(false);

    my $labels_context_multiline1 = $label_context_multiline->($mtcars_vs);
    is( $labels_context_multiline1, [ ['0'], ['1'] ], 'label_context()' );

    my $labels_context_singleline1 = $label_context_singleline->($mtcars_vs);
    is( $labels_context_singleline1, [ '0', '1' ], 'label_context(false)' );

    my $labels_context_multiline2 = $label_context_multiline->($mtcars_vs_am);
    is(
        $labels_context_multiline2,
        [
            [ 'vs: 0', 'am: 1' ],
            [ 'vs: 1', 'am: 1' ],
            [ 'vs: 1', 'am: 0' ],
            [ 'vs: 0', 'am: 0' ]
        ],
        'label_context()'
    );

    my $labels_context_singleline2 = $label_context_singleline->($mtcars_vs_am);
    is( $labels_context_singleline2,
        [ 'vs: 0, am: 1', 'vs: 1, am: 1', 'vs: 1, am: 0', 'vs: 0, am: 0' ],
        'label_context(false)' );
}

{
    my $labeller_multiline =
      Chart::GGPlot::Labeller->labeller( vs => 'both', am => 'value' );
    my $labels_multiline = $labeller_multiline->($mtcars_vs_am);
    is(
        $labels_multiline,
        [
            [ 'vs: 0', '1' ],
            [ 'vs: 1', '1' ],
            [ 'vs: 1', '0' ],
            [ 'vs: 0', '0' ]
        ],
        'labeller()'
    );

    my $labeller_singleline = Chart::GGPlot::Labeller->labeller(
        vs          => 'both',
        am          => 'value',
        _multi_line => false
    );
    my $labels_singleline = $labeller_singleline->($mtcars_vs_am);
    is( $labels_singleline, [ 'vs: 0, 1', 'vs: 1, 1', 'vs: 1, 0', 'vs: 0, 0' ],
        'labeller(_multiline=>false)' );
}

done_testing();

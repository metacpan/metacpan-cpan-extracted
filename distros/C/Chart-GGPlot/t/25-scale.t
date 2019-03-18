#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

use List::AllUtils qw(pairmap);

use Test2::V0;
use Test2::Tools::PDL;

use Chart::GGPlot::Aes::Functions qw(aes);
use Chart::GGPlot::Scale::Functions qw(:all);

subtest scale_x_continuous => sub {
    my $s = scale_x_continuous( limits => [ 2, 6 ] );
    isa_ok( $s, [qw(Chart::GGPlot::Scale::ContinuousPosition)],
        'scale_x_continuous()' );

    pdl_is( $s->break_positions, pdl([qw(2 3 4 5 6)]), '$s->break_positions()' );
    pdl_is( $s->dimension,  pdl([ 2, 6 ]), '$s->dimension()' );
    pdl_is( $s->get_limits, pdl([ 2, 6 ]), '$s->get_limits()' );
    pdl_is( $s->get_breaks, pdl([qw(2 3 4 5 6)]), '$s->get_breaks()' );
    pdl_is(
        $s->get_breaks_minor,
        pdl([qw(2 2.5 3 3.5 4 4.5 5 5.5 6)]),
        '$s->get_breaks_minor()'
    );
    pdl_is( $s->get_labels, pdl([qw(2 3 4 5 6)]), '$s->get_labels()' );

    my $break_info = $s->break_info;
    # TODO: see how to do this with Test2::Tools::PDL
    is(
        { pairmap { $a => $b->unpdl } $break_info->flatten },
        {
            range        => [ 2, 6 ],
            labels       => [qw(2 3 4 5 6)],
            major        => [qw(0 0.25 0.5 0.75 1)],
            minor        => [qw(0 0.125 0.25 0.375 0.5 0.625 0.75 0.875 1)],
            major_source => [qw(2 3 4 5 6)],
            minor_source => [qw(2 2.5 3 3.5 4 4.5 5 5.5 6)],
        },
        '$s->break_info()'
    );
};

subtest scale_x_discrete => sub {
    my $s = scale_x_discrete( limits => [qw(Fair Ideal)] );
    isa_ok( $s, [qw(Chart::GGPlot::Scale::DiscretePosition)],
        'scale_x_discrete()' );

    is($s->breaks, undef, '$s->breaks');
    pdl_is($s->get_breaks, PDL::SV->new([qw(Fair Ideal)]), '$s->get_breaks()');
    pdl_is($s->get_labels, PDL::SV->new([qw(Fair Ideal)]), '$s->get_labels()');
    pdl_is($s->get_limits, PDL::SV->new([qw(Fair Ideal)]), '$s->get_limits()');

    pdl_is( $s->break_positions, pdl([0, 1]), '$s->break_positions()' );
    ok( $s->dimension->isempty, '$s->dimension()' );
    pdl_is( $s->get_breaks, PDL::SV->new([qw(Fair Ideal)]), '$s->get_breaks()' );
    ok( $s->get_breaks_minor->isempty, '$s->get_breaks_minor()' );
    pdl_is( $s->break_positions, pdl( [ 0, 1 ] ), '$s->break_positions()');

};

subtest scale_color_hue => sub {
    no warnings 'qw';

    my $s = scale_color_hue( l => 40, c => 30 );
    isa_ok( $s, [qw(Chart::GGPlot::Scale::Discrete)], 'scale_color_hue()' );

    pdl_is( $s->get_limits, pdl([ 0, 1 ]), '$s->get_limits()' );
    ok( $s->get_labels->isempty, '$s->get_labels()' );

    pdl_is(
        $s->palette->(2),
        PDL::SV->new([qw(#7e5250 #13686a)]),
        '$s->palette->(2)'
    );
    pdl_is(
        $s->palette->(4),
        PDL::SV->new([qw(#7e5250 #536436 #13686a #6a567d)]),
        '$s->palette->(4)'
    );
};

subtest scale_color_brewer => sub {
    no warnings 'qw';

    my $s = scale_color_brewer();
    isa_ok( $s, [qw(Chart::GGPlot::Scale::Discrete)], 'scale_color_brewer()' );
    
    pdl_is( $s->get_limits, pdl([ 0, 1 ]), '$s->get_limits()' );
    ok( $s->get_labels->isempty, '$s->get_labels()' );

    pdl_is(
        $s->palette->(2),
        PDL::SV->new([qw(#deebf7 #9ecae1)]),
        '$s->palette->(2)'
    );
    pdl_is(
        $s->palette->(3),
        PDL::SV->new([qw(#deebf7 #9ecae1 #3182bd)]),
        '$s->palette->(3)'
    );
    pdl_is(
        $s->palette->(4),
        PDL::SV->new([qw(#eff3ff #bdd7e7 #6baed6 #2171b5)]),
        '$s->palette->(4)'
    );
};

done_testing();

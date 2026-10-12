use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";

use Object::Pad;
use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Layout::HasScroll;
use Clay::UI::Test::Box;

# A scroll container: 100 wide, 50 high, holding five rows 20 high.
class Clay::UI::Test::ScrollBox :strict(params)
	:does(Clay::UI::Role::Layout::HasScroll)
	:does(Clay::UI::Role::Layout::HasLayout)
{}

sub fixed_box ($width, $height) {
	return Clay::UI::Test::Box->new(layout => { sizing => { width => sizing_fixed($width), height => sizing_fixed($height) } });
}

sub scrolling_ui () {
	my $root   = Clay::UI::Test::Box->new(id => 'root', layout => { layout_direction => CLAY_TOP_TO_BOTTOM, padding => { top => 10 } });
	my $scroll = Clay::UI::Test::ScrollBox->new(
		id     => 'scroll',
		layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(100), height => sizing_fixed(50) } },
	);
	my @rows = map { fixed_box(100, 20) } 1 .. 5;
	$scroll->add_child(@rows);
	$root->add_child($scroll);
	my $ui = Clay::UI->new(root => $root, width => 200, height => 200, measure_text => sub { { width => 0, height => 0 } });
	return ($ui, $scroll, \@rows);
}

subtest 'bounding_box' => sub {
	my ($ui, $scroll, $rows) = scrolling_ui();
	is( $ui->bounding_box($rows->[1]), undef, 'nothing before the first frame' );
	$ui->render;
	is( $ui->bounding_box($rows->[1]), { x => 0, y => 30, width => 100, height => 20 }, 'where the last frame put the widget' );
	is( $ui->bounding_box(fixed_box(1, 1)), undef, 'undef for a widget the frame did not lay out' );
	like( dies { $ui->bounding_box('row') }, qr/expected a widget, got 'row'/, 'a non-widget dies' );
};

subtest 'scroll_state and scroll_to' => sub {
	my ($ui, $scroll, $rows) = scrolling_ui();
	is( $ui->scroll_state($scroll), undef, 'no state before the first frame' );
	is( $ui->scroll_to($scroll, { y => -10 }), undef, 'and scroll_to moves nothing' );
	$ui->render;
	is(
		$ui->scroll_state($scroll),
		{ position => { x => 0, y => 0 }, viewport => { width => 100, height => 50 }, content => { width => 100, height => 100 } },
		'the scroll data of the last frame',
	);

	is( $ui->scroll_to($scroll, { y => -30 }), { x => 0, y => -30 }, 'scroll_to returns the position' );
	$ui->render;
	is( $ui->scroll_state($scroll)->{position}, { x => 0, y => -30 }, 'the next frame shows it' );
	is( $ui->bounding_box($rows->[0])->{y}, 10 - 30, 'the content moved' );

	is( $ui->scroll_to($scroll, { y => -500 }), { x => 0, y => -50 }, 'kept within the content at the bottom' );
	is( $ui->scroll_to($scroll, { y => 7 }), { x => 0, y => 0 }, 'and at the top' );
	is( $ui->scroll_to($scroll, { x => -5 }), { x => 0, y => 0 }, 'an axis without overflow stays at 0' );

	like( dies { $ui->scroll_state($rows->[0]) },           qr/is not a scroll container/,               'a plain widget dies' );
	like( dies { $ui->scroll_to($scroll, { z => 1 }) },     qr/unknown position key\(s\): z/,            'an unknown key dies' );
	like( dies { $ui->scroll_to($scroll, { y => 'up' }) },  qr/position 'y' must be a finite number/,    'a non-number dies' );
	like( dies { $ui->scroll_to($scroll, [ 0, 1 ]) },       qr/needs a position/,                         'a non-hash dies' );
};

done_testing;

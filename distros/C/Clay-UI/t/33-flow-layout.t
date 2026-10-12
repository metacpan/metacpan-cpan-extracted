use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;
use Scalar::Util qw(refaddr);

use lib 't/lib';

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Test::Box;

# -----------------------------------------------------------------------------
# Flow layout (patches/0002-clay-flow-layout.patch): a CLAY_LEFT_TO_RIGHT_WRAP
# container breaks its children into lines that fit its inner width, grows
# GROW children per line, shares leftover height between lines
# (CLAY_LINE_SIZING_GROW, the default) or aligns the block of lines
# (CLAY_LINE_SIZING_FIT), and draws betweenChildren borders within and
# between lines.
# -----------------------------------------------------------------------------

my @errors;
my $ctx = Clay_Initialize(Clay_MinMemorySize(), { width => 1000, height => 1000 },
	sub ($error, $userdata) { push @errors, $error });
# Every character is 10 wide and 20 high.
Clay_SetMeasureTextFunction(sub ($text, @) { return { width => 10 * length($text), height => 20 } });

sub el ($name, $decl, @children) {
	Clay__OpenElementWithId(Clay_GetElementId($name));
	Clay__ConfigureOpenElement($decl);
	$_->() for @children;
	Clay__CloseElement();
}

sub fixed ($name, $width, $height) {
	return sub { el($name, { layout => { sizing => { width => sizing_fixed($width), height => sizing_fixed($height) } } }) };
}

sub flow ($name, $layout, @children) {
	return sub { el($name, { layout => { layoutDirection => CLAY_LEFT_TO_RIGHT_WRAP, %$layout } }, @children) };
}

sub frame (@content) {
	Clay_BeginLayout();
	$_->() for @content;
	return Clay_EndLayout(0.016);
}

# [x, y, width, height], rounded to two decimals.
sub box_of ($name) {
	my $box = Clay_GetElementData(Clay_GetElementId($name))->{boundingBox};
	return [ map { 0 + sprintf('%.2f', $box->{$_}) } qw(x y width height) ];
}

subtest 'children break into lines that fit the inner width' => sub {
	frame(flow('flow', { sizing => { width => sizing_fixed(200) }, padding => padding_all(10), childGap => 10, lineGap => 5 },
		map { fixed("c$_", 50, 20) } 0 .. 6));
	is( box_of('c2'), [130, 10, 50, 20], 'three children fill the first line' );
	is( box_of('c3'), [10, 35, 50, 20], 'the fourth starts the second line, lineGap below' );
	is( box_of('c6'), [10, 60, 50, 20], 'the seventh is alone on the third line' );
	is( box_of('flow'), [0, 0, 200, 90], 'a FIT height spans the lines, gaps and padding' );
};

subtest 'GROW children share the free width of their own line' => sub {
	frame(flow('flow', { sizing => { width => sizing_fixed(200) }, padding => padding_all(10), childGap => 10 },
		map { my $name = "g$_"; sub { el($name, { layout => { sizing => { width => sizing_grow(50), height => sizing_fixed(20) } } }) } } 0 .. 3));
	is( box_of('g0')->[2], 53.33, 'three children split the first line' );
	is( box_of('g3'), [10, 30, 180, 20], 'the last child takes its whole line' );
};

subtest 'childAlignment.x aligns every line, childAlignment.y within its line' => sub {
	frame(flow('flow', { sizing => { width => sizing_fixed(200) },
	                     childAlignment => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_BOTTOM } },
		fixed('a', 100, 40), fixed('b', 80, 20), fixed('c', 60, 20)));
	is( box_of('a'), [10, 0, 100, 40], 'the first line is centered' );
	is( box_of('b'), [110, 20, 80, 20], 'a short child sits at the bottom of its line' );
	is( box_of('c'), [70, 40, 60, 20], 'the second line is centered on its own' );
};

my $tall_lines = sub ($layout) {
	return flow('flow', { sizing => { width => sizing_fixed(200), height => sizing_fixed(200) }, lineGap => 10, %$layout },
		fixed('a', 120, 40), fixed('b', 120, 20),
		sub { el('s', { layout => { sizing => { width => sizing_fixed(80), height => sizing_grow() } } }) });
};

subtest 'CLAY_LINE_SIZING_GROW (default) shares leftover height equally between lines' => sub {
	frame($tall_lines->({}));
	# Natural lines 40 and 20 plus a 10 gap leave 130: each line gains 65.
	is( box_of('b'), [0, 115, 120, 20], 'the second line starts below the grown first line' );
	is( box_of('s'), [120, 115, 80, 85], 'a GROW child grows with its line' );
};

subtest 'CLAY_LINE_SIZING_FIT keeps lines tight and aligns the block' => sub {
	frame($tall_lines->({ lineSizing => CLAY_LINE_SIZING_FIT, childAlignment => { y => CLAY_ALIGN_Y_CENTER } }));
	is( box_of('a'), [0, 65, 120, 40], 'the block of lines is centered' );
	is( box_of('s'), [120, 115, 80, 20], 'a GROW child stretches to its line only' );
};

subtest 'a FIT container prefers one line and wraps when compressed' => sub {
	my $flow = flow('flow', {}, map { fixed("f$_", 50, 10) } 0 .. 2);
	frame(sub { el('wide', { layout => { sizing => { width => sizing_fixed(400) } } }, $flow) });
	is( box_of('flow'), [0, 0, 150, 10], 'a roomy parent keeps one line' );

	frame(sub { el('narrow', { layout => { sizing => { width => sizing_fixed(70) }, layoutDirection => CLAY_TOP_TO_BOTTOM } },
		$flow, fixed('after', 10, 10)) });
	is( box_of('flow'), [0, 0, 70, 30], 'a narrow parent compresses it to one child per line' );
	is( box_of('after'), [0, 30, 10, 10], 'the wrapped height pushes later siblings down' );
};

subtest 'text children take part like elements' => sub {
	frame(flow('flow', { sizing => { width => sizing_fixed(100) }, childGap => 10 },
		map { my $text = $_; sub { Clay__OpenTextElement($text, { fontSize => 10 }) } } qw(abcd efgh ijklmn)));
	is( box_of('flow')->[3], 40, 'two words fit the first line, the third wraps' );
};

subtest 'a scroll container measures every line' => sub {
	my $scroll = sub {
		el('scroll', { layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(30) },
		                           layoutDirection => CLAY_LEFT_TO_RIGHT_WRAP },
		               clip => { vertical => 1, childOffset => Clay_GetScrollOffset() } },
			map { fixed("s$_", 50, 20) } 0 .. 5);
	};
	frame($scroll) for 1 .. 2;
	is( Clay_GetScrollContainerData(Clay_GetElementId('scroll'))->{contentDimensions},
		{ width => 100, height => 60 }, 'content size spans three lines' );
};

subtest 'sizing groups equalize members before lines break' => sub {
	my $member = sub ($name, $width) {
		return sub { el($name, { layout => { sizing => { height => sizing_fixed(10) } }, sizingGroup => { width => 1 } },
			fixed("$name.in", $width, 10)) };
	};
	frame(flow('flow', { sizing => { width => sizing_fixed(100) } }, $member->('p', 20), $member->('q', 40), $member->('r', 30)));
	is( box_of('p'), [0, 0, 40, 10], 'members are widened to the widest' );
	is( box_of('r'), [0, 10, 40, 10], 'three widened members do not fit one line' );
};

subtest 'betweenChildren borders separate neighbours and lines' => sub {
	my $commands = frame(sub {
		el('flow', { layout => { sizing => { width => sizing_fixed(100) }, childGap => 10, lineGap => 6,
		                         layoutDirection => CLAY_LEFT_TO_RIGHT_WRAP },
		             border => { color => [9, 9, 9, 255], width => { betweenChildren => 2 } } },
			map { fixed("b$_", 40, 20) } 0 .. 2);
	});
	my @bars = map { [ @{ $_->{boundingBox} }{qw(x y width height)} ] }
		grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @$commands;
	is( \@bars, [ [44, 0, 2, 23], [0, 22, 100, 2] ],
		'a vertical bar in the childGap down to mid lineGap, a horizontal bar across the lineGap' );
};

subtest 'exiting children take no space' => sub {
	Clay_SetTransitionHandlers(sub { 0 }, undef, sub ($initial, $properties, $userdata) { $initial });
	my $layout = sub ($with_b) {
		return flow('flow', { sizing => { width => sizing_fixed(100) } },
			fixed('a', 40, 10),
			($with_b
				? sub { el('b', { layout => { sizing => { width => sizing_fixed(40), height => sizing_fixed(10) } },
				                  transition => { duration => 1, properties => CLAY_TRANSITION_PROPERTY_X,
				                                  exit => { hasSetFinal => 1 } } }) }
				: ()),
			fixed('c', 40, 10));
	};
	frame($layout->(1)) for 1 .. 2;
	is( box_of('c'), [0, 10, 40, 10], 'c wraps while b is present' );
	frame($layout->(0));
	ok( Clay_GetElementData(Clay_GetElementId('b'))->{found}, 'b is still laid out while it exits' );
	is( box_of('c'), [40, 0, 40, 10], 'c moves up next to a while b exits' );

	my $bottom_aligned = sub ($with_b) {
		return flow('low', { sizing => { width => sizing_fixed(300), height => sizing_fixed(100) },
		                     childAlignment => { y => CLAY_ALIGN_Y_BOTTOM } },
			fixed('d', 40, 10),
			($with_b
				? sub { el('e', { layout => { sizing => { width => sizing_fixed(40), height => sizing_fixed(30) } },
				                  transition => { duration => 1, properties => CLAY_TRANSITION_PROPERTY_X,
				                                  exit => { hasSetFinal => 1 } } }) }
				: ()));
	};
	frame($bottom_aligned->(1)) for 1 .. 2;
	my $declared_y = box_of('e')->[1];
	frame($bottom_aligned->(0));
	is( box_of('e')->[1], $declared_y, 'an exiting child placed before the first line keeps its bottom alignment' );
	Clay_SetTransitionHandlers();
};

subtest 'Clay::UI widgets flow through their layout slice' => sub {
	my $flow = Clay::UI::Test::Box->new(layout => {
		sizing           => { width => sizing_fixed(100) },
		layout_direction => CLAY_LEFT_TO_RIGHT_WRAP,
		line_gap         => 4,
		line_sizing      => CLAY_LINE_SIZING_FIT,
	});
	my @items = map { Clay::UI::Test::Box->new(background_color => [1, 1, 1, 255],
		layout => { sizing => { width => sizing_fixed(60), height => sizing_fixed(10) } }) } 1 .. 2;
	$flow->add_child($_) for @items;
	my $ui = Clay::UI->new(width => 200, height => 200, root => $flow);
	my %box_of = map { ($_->{userData} => $_->{boundingBox}) } grep { $_->{userData} } @{ $ui->render };
	is( $box_of{ refaddr($items[1]) }{y}, 14, 'the second item wraps below line_gap' );
};

is( \@errors, [], 'Clay reported no errors' );

done_testing;

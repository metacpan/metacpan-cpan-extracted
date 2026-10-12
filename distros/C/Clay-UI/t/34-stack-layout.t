use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib 't/lib';

use Object::Pad 0.800;
use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Test::Box;
use Clay::UI::Role::Interaction::Pressable;

# -----------------------------------------------------------------------------
# Stack layout (patches/0003-clay-back-to-front.patch): a CLAY_BACK_TO_FRONT
# container places all children on top of each other, fits its largest
# child on both axes, grows GROW children to its inner size, aligns each
# child on its own and draws later children over earlier ones.
# -----------------------------------------------------------------------------

class StackButton :strict(params) :isa(Clay::UI::Test::Box) :does(Clay::UI::Role::Interaction::Pressable) {}

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

sub stack ($name, $decl, @children) {
	my %layout = %{ $decl->{layout} // {} };
	return sub { el($name, { %$decl, layout => { layoutDirection => CLAY_BACK_TO_FRONT, %layout } }, @children) };
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

subtest 'a FIT stack fits its largest child on each axis' => sub {
	frame(stack('stack', { layout => { padding => padding_all(10), childGap => 50 } },
		fixed('wide', 80, 20), fixed('tall', 30, 60)));
	is( box_of('stack'), [0, 0, 100, 80], 'width from the wide child, height from the tall one, plus padding' );
	is( box_of('wide'), [10, 10, 80, 20], 'the first child sits at the padding origin' );
	is( box_of('tall'), [10, 10, 30, 60], 'so does the second: childGap is unused' );
};

subtest 'childAlignment places every child on its own' => sub {
	frame(stack('stack', { layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) },
	                                   childAlignment => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_BOTTOM } } },
		fixed('a', 60, 20), fixed('b', 20, 40)));
	is( box_of('a'), [20, 80, 60, 20], 'a is centered and at the bottom' );
	is( box_of('b'), [40, 60, 20, 40], 'b is aligned by its own size' );
};

subtest 'GROW children fill the inner size' => sub {
	frame(stack('stack', { layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(60) }, padding => padding_all(5) } },
		sub { el('fill', { layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } }) },
		fixed('badge', 10, 10)));
	is( box_of('fill'), [5, 5, 90, 50], 'a GROW child covers the stack inside its padding' );
};

subtest 'later children are drawn over earlier ones' => sub {
	my $cmds = frame(stack('stack', {},
		sub { el('back',  { layout => { sizing => { width => sizing_fixed(40), height => sizing_fixed(40) } }, backgroundColor => [1, 0, 0, 255] }) },
		sub { el('front', { layout => { sizing => { width => sizing_fixed(20), height => sizing_fixed(20) } }, backgroundColor => [0, 1, 0, 255] }) }));
	my @order = map { $_->{id} } grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @$cmds;
	is( \@order, [ map { Clay_GetElementId($_)->{id} } qw(back front) ], 'back is drawn first, front after it' );
};

subtest 'betweenChildren borders draw nothing' => sub {
	my $cmds = frame(stack('stack', { border => { color => [0, 0, 0, 255], width => { betweenChildren => 2 } } },
		fixed('a', 40, 40), fixed('b', 20, 20)));
	my @rects = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @$cmds;
	is( \@rects, [], 'no bars between overlapping children' );
};

subtest 'wrapped text raises a FIT height' => sub {
	frame(stack('stack', { layout => { sizing => { width => sizing_fixed(100) }, padding => padding_all(5) } },
		sub { Clay__OpenTextElement('aaaa bbbb cccc', { fontSize => 10 }) }));
	is( box_of('stack')->[3], 50, 'two lines of text plus padding' );
};

subtest 'a scrolling stack reports its largest child as content size' => sub {
	my $layout = stack('scroller', { layout => { sizing => { width => sizing_fixed(50), height => sizing_fixed(50) } },
	                                 clip => { horizontal => 1, vertical => 1 } },
		fixed('a', 80, 30), fixed('b', 40, 90));
	frame($layout) for 1 .. 2;
	my $data = Clay_GetScrollContainerData(Clay_GetElementId('scroller'));
	is( $data->{contentDimensions}, { width => 80, height => 90 }, 'content is as wide and as tall as the largest children' );
};

subtest 'Clay::UI: the press goes to the child drawn on top' => sub {
	my $stack = Clay::UI::Test::Box->new(layout => { layout_direction => CLAY_BACK_TO_FRONT });
	my ($back, $front) = map { StackButton->new(id => $_,
		layout => { sizing => { width => sizing_fixed(40), height => sizing_fixed(40) } }) } qw(back front);
	$stack->add_child($back, $front);
	my $ui = Clay::UI->new(width => 200, height => 200, root => $stack);
	my @log;
	$_->on('OnPress', sub ($e) { push @log, $e->target->id; return }) for $back, $front;
	$ui->render(pointer_state => { x => 10, y => 10, down => 0 }) for 1 .. 2;
	$ui->render(pointer_state => { x => 10, y => 10, down => 1 });
	is( \@log, ['front'], 'the later sibling gets OnPress' );
	is( [ $back->is_hovered, $front->is_hovered ], [1, 1], 'both stay hovered' );
};

is( \@errors, [], 'Clay reported no errors' );

done_testing;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib 't/lib';
use Scalar::Util qw(refaddr);

use Object::Pad 0.800;
use Clay::UI::_FrameRegistry;
use Clay::UI::Test::Box;
use Clay::UI::Role::Layout::HasScroll;

# -----------------------------------------------------------------------------
# The frame registry records what one frame laid out. Filled by hand here:
# no Clay context, no walk.
# -----------------------------------------------------------------------------

class ScrollPanel :strict(params) :does(Clay::UI::Role::Layout::HasScroll) {}

my $next_id = 1;
sub element_id () { return { id => $next_id++, offset => 0, baseId => 0 } }

subtest 'back references map userData to the widget' => sub {
	my $frame = Clay::UI::_FrameRegistry->new;
	my $box = Clay::UI::Test::Box->new;
	my $user_data = $frame->add_back_reference($box);
	is( $user_data, refaddr($box), 'userData is the refaddr' );
	ref_is( $frame->widget_for($user_data), $box, 'widget_for finds it' );
	is( $frame->widget_for(1), undef, 'unknown userData' );
};

subtest 'elements are found by id and ranked in walk order' => sub {
	my $frame = Clay::UI::_FrameRegistry->new;
	my @boxes = map { Clay::UI::Test::Box->new } 1 .. 3;
	my @ids   = map { element_id() } @boxes;
	$frame->add_element($boxes[$_], $ids[$_]) for 0 .. 2;
	ref_is( $frame->widget_for_element($ids[1]{id}), $boxes[1], 'widget_for_element' );
	my $stranger = Clay::UI::Test::Box->new;
	is( [ map { refaddr $_ } $frame->in_tree_order($stranger, $boxes[2], $boxes[0], $boxes[1]) ],
		[ map { refaddr $_ } @boxes, $stranger ], 'walk order, unknown widgets last' );
};

subtest 'scroll containers keep the element id they were declared with' => sub {
	my $frame  = Clay::UI::_FrameRegistry->new;
	my $panel  = ScrollPanel->new(id => 'log');
	my $box    = Clay::UI::Test::Box->new;
	my $id     = element_id();
	$frame->add_element($box, element_id());
	$frame->add_element($panel, $id);
	my @containers = $frame->scroll_containers;
	is( scalar @containers, 1, 'only the scroll container is listed' );
	ref_is( $containers[0][0], $panel, 'the widget' );
	is( $containers[0][1], $id, 'its element id' );
};

subtest 'a scroll container is a widget composing HasScroll' => sub {
	my $frame = Clay::UI::_FrameRegistry->new;
	is( $frame->is_scroll_container(ScrollPanel->new(id => 'log')), 1, 'HasScroll' );
	is( $frame->is_scroll_container(Clay::UI::Test::Box->new), 0, 'a plain box' );
};

subtest 'widget references are weak' => sub {
	my $frame = Clay::UI::_FrameRegistry->new;
	my $id    = element_id();
	my $user_data;
	{
		my $panel = ScrollPanel->new(id => 'gone');
		$user_data = $frame->add_back_reference($panel);
		$frame->add_element($panel, $id);
	}
	is( $frame->widget_for($user_data), undef, 'freed widget is not found by userData' );
	is( $frame->widget_for_element($id->{id}), undef, 'nor by element id' );
	is( [ $frame->scroll_containers ], [], 'nor listed as a scroll container' );
};

done_testing;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib 't/lib';

use Object::Pad;
use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Test::Box;
use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Core::Stateful;
use Clay::UI::Role::Core::TextNode;
use Clay::UI::Role::Interaction::Hoverable;
use Clay::UI::Role::Layout::HasLayout;

# -----------------------------------------------------------------------------
# Minimal widget class consuming the Container role: exercises the walker
# without the mixin roles.
# -----------------------------------------------------------------------------

class TestWidget :does(Clay::UI::Role::Core::Container) {
	field $bg :param :reader = [40, 50, 60, 200];

	method contribute_test ($cfg) {
		$cfg->{background_color} = $bg;
		$cfg->{layout} = {
			sizing => {
				width  => Clay::XS::sizing_fixed(100),
				height => Clay::XS::sizing_fixed(50),
			},
		};
		return;
	}
}

class RawConfigWidget :does(Clay::UI::Role::Core::Container) {
	field $raw :param :accessor;
	method contribute_raw ($cfg) { %$cfg = (%$cfg, %$raw); return }
}

# Rots once rot is called: the UI walks the tree when it is built (to
# announce tree_changed), so the garbage appears only afterwards.
class RottenWidget :isa(TestWidget) {
	field $rotten = 0;

	method rot () { $rotten = 1; return $self }

	method layout_children { return $rotten ? [ { not => 'a widget' } ] : $self->SUPER::layout_children }
}

class HoverWidget
	:does(Clay::UI::Role::Core::Stateful)
	:does(Clay::UI::Role::Interaction::Hoverable)
	:does(Clay::UI::Role::Layout::HasLayout)
{}

# A text widget whose text_config returns one hash shared by every instance.
class SharedStyleLabel :does(Clay::UI::Role::Core::TextNode) {
	field $text  :param :reader;
	field $style :param;
	method text_config { $style }
}

my @errors;
my $error_handler = sub ($err, $userdata) { push @errors, $err };
my $measure_text  = sub { return { width => 0, height => 0 } };

sub make_ui ($root) {
	return Clay::UI->new(
		width         => 400,
		height        => 300,
		root          => $root,
		error_handler => $error_handler,
		measure_text  => $measure_text,
	);
}

# -----------------------------------------------------------------------------
# Walker emits a single rectangle for a single widget.
# -----------------------------------------------------------------------------

subtest 'single node' => sub {
	my $ui = make_ui( TestWidget->new(id => 'solo') );
	my $cmds = $ui->render;

	is( scalar(@errors), 0, 'no Clay errors' );

	my ($rect) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @$cmds;
	ok( defined $rect, 'rectangle command emitted' );
	is( $rect->{renderData}{backgroundColor}{r}, 40, 'snake_case background_color was camelized and marshalled' );
};

# -----------------------------------------------------------------------------
# Walker recurses into children and applies parent before child.
# -----------------------------------------------------------------------------

subtest 'parent with children' => sub {
	my $parent = TestWidget->new(
		id => 'parent',
		bg => [10, 20, 30, 255],
	);
	$parent->add_child(
		TestWidget->new( bg => [200, 100, 50, 255] ),
		TestWidget->new( bg => [50, 100, 200, 255] ),
	);
	my $ui = make_ui($parent);
	my $cmds = $ui->render;

	my @rects = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @$cmds;
	is( scalar(@rects), 3, 'three rectangles (parent + two children)' );
	is( $rects[0]{renderData}{backgroundColor}{r}, 10,  'parent first' );
	is( $rects[1]{renderData}{backgroundColor}{r}, 200, 'first child second' );
	is( $rects[2]{renderData}{backgroundColor}{r}, 50,  'second child third' );
};

# -----------------------------------------------------------------------------
# Non-Element values in a tree fail loud at construction.
# -----------------------------------------------------------------------------

subtest 'fail loud on bad root' => sub {
	like(
		dies {
			Clay::UI->new(
				width  => 400,
				height => 300,
				root   => { not => 'a widget' },
			)
		},
		qr/must be a widget/,
		'plain hashref rejected at construction',
	);
};

# -----------------------------------------------------------------------------
# Non-blessed values inside the tree fail loud at render time without
# leaving Clay's open-element stack unbalanced (no segfault on EndLayout).
# -----------------------------------------------------------------------------

subtest 'fail loud on bad child without segfault' => sub {
	# add_child rejects non-widgets, so a widget whose layout_children
	# method returns garbage stands in for a rotten tree only the walker
	# can catch.
	my $parent = RottenWidget->new(id => 'parent');
	my $ui = make_ui($parent);
	$parent->rot;
	like(
		dies { $ui->render },
		qr/not a blessed widget/,
		'plain hashref child rejected by walker',
	);

	# Survives a follow-up render with a healthy tree (proves Clay's
	# internal stack was restored).
	my $ui2 = make_ui( TestWidget->new(id => 'recover') );
	my $cmds = $ui2->render;
	ok( scalar(@$cmds) > 0, 'fresh render after a failed one still works' );
};

# -----------------------------------------------------------------------------
# Errors after the element is opened (marshalling, listeners) close it
# before propagating; the same Clay::UI renders again once fixed.
# -----------------------------------------------------------------------------

subtest 'a config Clay::XS rejects makes render die, not crash' => sub {
	# RawConfigWidget bypasses the attribute validation of the mixin roles,
	# so the bad values reach Clay__ConfigureOpenElement after the open.
	my $root = Clay::UI::Test::Box->new(id => 'root');
	my $bad  = RawConfigWidget->new(id => 'bad', raw => { layout => { padding => 8 } });
	$root->add_child($bad, Clay::UI::Test::Box->new(id => 'sibling', background_color => [1, 2, 3, 255]));
	my $ui = make_ui($root);
	like( dies { $ui->render }, qr/layout\.padding: expected a hash reference, got '8'/,
		'scalar padding reported by the marshaller' );

	$bad->raw({ layout => { padding => padding_all(8) } });
	ok( lives { $ui->render }, 'the next render of the repaired tree succeeds' );

	my $red = RawConfigWidget->new(id => 'red', raw => { background_color => 'red' });
	like( dies { make_ui($red)->render }, qr/backgroundColor: expected a hash or array reference, got 'red'/,
		'a string colour is reported' );
};

subtest 'render cannot be re-entered from a listener' => sub {
	my $root = HoverWidget->new(id => 'hover',
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) } });
	my $ui = make_ui($root);
	my $nested_error;
	$root->on('OnHoverStart', sub ($e) { $nested_error = dies { $ui->render }; return });
	$ui->render;
	$ui->render(pointer_state => { x => -10, y => -10, down => 0 });
	$ui->render(pointer_state => { x => 10, y => 10, down => 0 });
	like( $nested_error, qr/called while this Clay::UI is already rendering/, 'nested render dies' );
	ok( lives { $ui->render }, 'the outer UI keeps working' );
};

subtest 'a measure_text callback cannot render another Clay::UI' => sub {
	my $other = make_ui(TestWidget->new(id => 'other'));
	my $root  = TestWidget->new(id => 'root');
	$root->add_child(SharedStyleLabel->new(text => 'measured', style => { font_size => 10 }));
	my $ui = Clay::UI->new(width => 100, height => 100, root => $root,
		measure_text => sub ($text, $config, $userdata) { $other->render; return { width => 1, height => 1 } });
	like( dies { $ui->render }, qr/Clay_SetCurrentContext: cannot be called from inside a Clay callback/,
		'render dies instead of switching contexts mid-walk' );
	$ui->measure_text(sub ($text, $config, $userdata) { return { width => 1, height => 1 } });
	ok( lives { $ui->render },    'the UI renders again with a well-behaved measurer' );
	ok( lives { $other->render }, 'and so does the other UI' );
};

# -----------------------------------------------------------------------------
# Anonymous ids grow linearly with depth and cannot collide with user ids.
# -----------------------------------------------------------------------------

subtest 'anonymous ids are linear in depth' => sub {
	my $leaf = TestWidget->new;
	my $top  = $leaf;
	for (1 .. 30) {
		my $parent = TestWidget->new;
		$parent->add_child($top);
		$top = $parent;
	}
	my $root = TestWidget->new(id => 'root');
	$root->add_child($top);

	my $depth_indices = [ (0) x 31 ];
	my $leaf_id = $leaf->resolve_id('root', $depth_indices);
	ok( length($leaf_id) < 200, 'a 30-deep anonymous leaf has a short id (' . length($leaf_id) . ' chars)' );
	ok( lives { make_ui($root)->render }, 'and renders' );

	isnt( TestWidget->new->resolve_id('a/0', [1]), TestWidget->new->resolve_id('a', [0, 1]),
		'a user id containing "/" cannot collide with an anonymous path' );
};

# -----------------------------------------------------------------------------
# Walker works on copies of the configs widgets return.
# -----------------------------------------------------------------------------

subtest 'a shared text_config hash is not modified' => sub {
	my %style = (font_size => 14, text_color => [0, 0, 0, 255]);
	my $root = TestWidget->new(id => 'root');
	$root->add_child(SharedStyleLabel->new(text => 'one', style => \%style),
	                 SharedStyleLabel->new(text => 'two', style => \%style));
	my $ui = make_ui($root);
	ok( lives { $ui->render for 1 .. 2 }, 'two frames, two widgets sharing one hash' );
	is( [ sort keys %style ], [ 'font_size', 'text_color' ], 'the shared hash is untouched' );
};

# -----------------------------------------------------------------------------
# Construction validation.
# -----------------------------------------------------------------------------

subtest 'memory_size is validated' => sub {
	my $min = Clay_MinMemorySize();
	for my $bad (10, -1, 'abc', $min + 0.5) {
		like( dies { Clay::UI->new(width => 10, height => 10, root => TestWidget->new, memory_size => $bad) },
			qr/'memory_size' must be an integer >= Clay_MinMemorySize\(\) \($min\)/, "memory_size $bad" );
	}
};

subtest 'the default error handler makes Clay errors fatal' => sub {
	my $root = TestWidget->new(id => 'root');
	$root->add_child(TestWidget->new(id => 'dup'), TestWidget->new(id => 'dup'));
	my $ui = Clay::UI->new(width => 400, height => 300, root => $root, measure_text => $measure_text);
	like( dies { $ui->render }, qr/^Clay error: An element with this ID was already previously declared/,
		'duplicate ids make render die' );
};

done_testing;

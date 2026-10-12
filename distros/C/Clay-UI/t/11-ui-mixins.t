use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Object::Pad;
use Clay::UI::Role::Core::Element;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Style::HasBackground;
use Clay::UI::Role::Style::HasBorder;
use Clay::UI::Role::Style::HasCornerRadius;
use Clay::UI::Role::Layout::HasFloating;
use Clay::UI::Text;

# -----------------------------------------------------------------------------
# A widget composing every mixin. The Element role's to_config walks
# all composed roles and calls each contribute_* method, so the user
# does not have to wire them up by hand.
# -----------------------------------------------------------------------------

class TestKitchenSink :does(Clay::UI::Role::Core::Element)
                      :does(Clay::UI::Role::Layout::HasLayout)
                      :does(Clay::UI::Role::Style::HasBackground)
                      :does(Clay::UI::Role::Style::HasBorder)
                      :does(Clay::UI::Role::Style::HasCornerRadius)
                      :does(Clay::UI::Role::Layout::HasFloating)
{}

# -----------------------------------------------------------------------------
# Each mixin in isolation: only its slice appears.
# -----------------------------------------------------------------------------

subtest 'HasLayout alone' => sub {
	class TL :does(Clay::UI::Role::Core::Element) :does(Clay::UI::Role::Layout::HasLayout) {}
	my $cfg = TL->new( layout => { padding => { left => 8, right => 8, top => 0, bottom => 0 } } )->to_config;
	is( $cfg, { layout => { padding => { left => 8, right => 8, top => 0, bottom => 0 } } }, 'layout slice only' );
};

subtest 'HasBackground alone' => sub {
	class TB :does(Clay::UI::Role::Core::Element) :does(Clay::UI::Role::Style::HasBackground) {}
	my $cfg = TB->new( background_color => [10, 20, 30, 255] )->to_config;
	is( $cfg, { background_color => [10, 20, 30, 255] }, 'background slice only' );
};

subtest 'HasBorder scalar shorthand expands' => sub {
	class TBd :does(Clay::UI::Role::Core::Element) :does(Clay::UI::Role::Style::HasBorder) {}
	my $cfg = TBd->new( border_color => [100, 100, 100, 255], border_width => 2 )->to_config;
	is(
		$cfg,
		{
			border => {
				color => [100, 100, 100, 255],
				width => { left => 2, right => 2, top => 2, bottom => 2, between_children => 0 },
			},
		},
		'scalar width expanded to four sides',
	);
};

subtest 'HasBorder hashref width passes through' => sub {
	class TBd2 :does(Clay::UI::Role::Core::Element) :does(Clay::UI::Role::Style::HasBorder) {}
	my $cfg = TBd2->new(
		border_color => [50, 50, 50, 255],
		border_width => { left => 1, right => 0, top => 1, bottom => 0, between_children => 0 },
	)->to_config;
	is( $cfg->{border}{width}{left}, 1, 'hashref width unchanged' );
	is( $cfg->{border}{width}{right}, 0, 'hashref width unchanged' );
};

subtest 'HasCornerRadius scalar shorthand expands' => sub {
	class TC :does(Clay::UI::Role::Core::Element) :does(Clay::UI::Role::Style::HasCornerRadius) {}
	my $cfg = TC->new( corner_radius => 6 )->to_config;
	is(
		$cfg,
		{ corner_radius => { top_left => 6, top_right => 6, bottom_left => 6, bottom_right => 6 } },
		'scalar radius expanded to four corners',
	);
};

subtest 'HasFloating alone' => sub {
	class TF :does(Clay::UI::Role::Core::Element) :does(Clay::UI::Role::Layout::HasFloating) {}
	my $cfg = TF->new( floating => { attach_to => 1 } )->to_config;
	is( $cfg, { floating => { attach_to => 1 } }, 'floating slice only' );
};

# -----------------------------------------------------------------------------
# Composition: every mixin together produces the union of slices.
# -----------------------------------------------------------------------------

subtest 'kitchen sink composes all slices' => sub {
	my $cfg = TestKitchenSink->new(
		layout           => { padding => { left => 1, right => 1, top => 1, bottom => 1 } },
		background_color => [10, 20, 30, 255],
		border_color     => [50, 50, 50, 255],
		border_width     => 1,
		corner_radius    => 4,
		floating         => { attach_to => 0 },
	)->to_config;

	ok( exists $cfg->{layout},           'layout slice present' );
	ok( exists $cfg->{background_color}, 'background slice present' );
	ok( exists $cfg->{border},           'border slice present' );
	ok( exists $cfg->{corner_radius},    'corner_radius slice present' );
	ok( exists $cfg->{floating},         'floating slice present' );
};

# -----------------------------------------------------------------------------
# Undefined fields contribute nothing.
# -----------------------------------------------------------------------------

subtest 'unset mixins are silent' => sub {
	my $cfg = TestKitchenSink->new->to_config;
	is( $cfg, {}, 'no slices when no fields supplied' );
};

# -----------------------------------------------------------------------------
# Mixin attributes are mutable post-construction: a write through the
# same-named accessor is reflected on the next to_config (config is rebuilt
# fresh each call, so there is nothing to invalidate).
# -----------------------------------------------------------------------------

subtest 'mixin attributes are mutable' => sub {
	my $w = TestKitchenSink->new(
		layout           => { padding => { left => 1, right => 1, top => 1, bottom => 1 } },
		background_color => [10, 20, 30, 255],
		border_color     => [50, 50, 50, 255],
		border_width     => 1,
		corner_radius    => 4,
		floating         => { attach_to => 0 },
	);

	# Each accessor reads back the constructed value.
	is( $w->background_color, [10, 20, 30, 255], 'background_color reads initial value' );

	# Writing returns/stores the new value...
	$w->background_color([99, 0, 0, 255]);
	$w->border_color([1, 2, 3, 255]);
	$w->border_width(3);
	$w->corner_radius(8);
	$w->layout({ padding => { left => 5, right => 5, top => 5, bottom => 5 } });
	$w->floating({ attach_to => 2 });

	is( $w->background_color, [99, 0, 0, 255], 'background_color reflects write' );

	# ...and the rebuilt config carries every updated slice.
	my $cfg = $w->to_config;
	is( $cfg->{background_color}, [99, 0, 0, 255], 'to_config sees new background_color' );
	is( $cfg->{border}{color},   [1, 2, 3, 255],   'to_config sees new border_color' );
	is( $cfg->{border}{width},
		{ left => 3, right => 3, top => 3, bottom => 3, between_children => 0 },
		'to_config sees new border_width' );
	is( $cfg->{corner_radius},
		{ top_left => 8, top_right => 8, bottom_left => 8, bottom_right => 8 },
		'to_config sees new corner_radius' );
	is( $cfg->{layout}{padding}, { left => 5, right => 5, top => 5, bottom => 5 }, 'to_config sees new layout' );
	is( $cfg->{floating}, { attach_to => 2 }, 'to_config sees new floating' );
};

# -----------------------------------------------------------------------------
# Contributor discovery: every contribute_* method runs exactly once per
# to_config, whether it comes from a role, the class or a superclass.
# -----------------------------------------------------------------------------

my %calls;
role CountingRole { method contribute_counted ($cfg) { $calls{role}++; return } }
class CountingWidget :does(Clay::UI::Role::Core::Element) :does(CountingRole) {
	method contribute_own ($cfg) { $calls{class}++; return }
}

subtest 'each contributor runs once per to_config' => sub {
	%calls = ();
	CountingWidget->new->to_config;
	is( \%calls, { role => 1, class => 1 }, 'role and class contributors ran once each' );
};

class StyledBase :does(Clay::UI::Role::Core::Element) {
	method contribute_base_style ($cfg) { $cfg->{background_color} = [1, 2, 3, 255]; return }
}
class StyledSub :isa(StyledBase) {}

subtest 'a subclass keeps its superclass contributors' => sub {
	is( StyledSub->new->to_config, { background_color => [1, 2, 3, 255] },
		'contribute_* defined directly on the superclass is discovered' );
};

my @contributed;
role OrderRole { method contribute_middle ($cfg) { push @contributed, 'middle'; return } }
class OrderBase :does(Clay::UI::Role::Core::Element) {
	method contribute_zebra ($cfg) { push @contributed, 'zebra'; return }
}
class OrderWidget :isa(OrderBase) :does(OrderRole) {
	method contribute_alpha ($cfg) { push @contributed, 'alpha'; return }
}

subtest 'contributors run in the alphabetical order of their names' => sub {
	@contributed = ();
	OrderWidget->new->to_config;
	is( \@contributed, [qw(alpha middle zebra)],
		'whether they come from the class, a role or a superclass' );
};

subtest 'to_config and text_config hand out parts of their own' => sub {
	my $widget = TestKitchenSink->new(background_color => [10, 20, 30, 255], corner_radius => { top_left => 4 });
	my $config = $widget->to_config;
	$config->{background_color}[0] = 99;
	$config->{corner_radius}{top_left} = 99;
	is( [ $widget->background_color, $widget->corner_radius ], [ [10, 20, 30, 255], { top_left => 4 } ],
		'editing the to_config parts changes no reader' );
	is( [ @{ $widget->to_config }{qw(background_color corner_radius)} ], [ [10, 20, 30, 255], { top_left => 4 } ],
		'nor the next to_config' );

	class TestText :does(Clay::UI::Text) {}
	my $text = TestText->new(text => 'hi', text_color => [1, 2, 3, 255]);
	$text->text_config->{text_color}[0] = 99;
	is( $text->text_color, [1, 2, 3, 255], 'editing the text_config colour changes no reader' );
};

done_testing;

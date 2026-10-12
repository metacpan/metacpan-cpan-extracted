use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

ok( defined &Clay_MinMemorySize, 'Clay_MinMemorySize is loaded' );

my $size = Clay_MinMemorySize();
ok( $size > 0, "Clay_MinMemorySize() returned a positive value ($size)" );

# A representative set of constants - confirms BOOT installed them.
is( CLAY_LEFT_TO_RIGHT,           0, 'CLAY_LEFT_TO_RIGHT == 0' );
is( CLAY_TOP_TO_BOTTOM,           1, 'CLAY_TOP_TO_BOTTOM == 1' );
is( CLAY__SIZING_TYPE_FIT,        0, 'CLAY__SIZING_TYPE_FIT == 0' );
is( CLAY_RENDER_COMMAND_TYPE_RECTANGLE, 1, 'CLAY_RENDER_COMMAND_TYPE_RECTANGLE == 1' );

# Every enum field of the struct schemas accepts its group's last member and
# nothing past it; for the transition property flags, every flag OR-ed
# together.
my $all_properties = 0;
$all_properties |= Clay::XS->can($_)->() for grep { /^CLAY_TRANSITION_PROPERTY_/ } Clay::XS::_constant_names();

my @enum_fields = (
	[ Clay_LayoutConfig            => 'layoutDirection',      CLAY_BACK_TO_FRONT ],
	[ Clay_LayoutConfig            => 'lineSizing',           CLAY_LINE_SIZING_FIT ],
	[ Clay_ChildAlignment          => 'x',                    CLAY_ALIGN_X_CENTER ],
	[ Clay_ChildAlignment          => 'y',                    CLAY_ALIGN_Y_CENTER ],
	[ Clay_SizingAxis              => 'type',                 CLAY__SIZING_TYPE_FIXED ],
	[ Clay_TextElementConfig       => 'wrapMode',             CLAY_TEXT_WRAP_NONE ],
	[ Clay_TextElementConfig       => 'textAlignment',        CLAY_TEXT_ALIGN_RIGHT ],
	[ Clay_FloatingAttachPoints    => 'element',              CLAY_ATTACH_POINT_RIGHT_BOTTOM ],
	[ Clay_FloatingAttachPoints    => 'parent',               CLAY_ATTACH_POINT_RIGHT_BOTTOM ],
	[ Clay_FloatingElementConfig   => 'pointerCaptureMode',   CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH ],
	[ Clay_FloatingElementConfig   => 'attachTo',             CLAY_ATTACH_TO_ROOT ],
	[ Clay_FloatingElementConfig   => 'clipTo',               CLAY_CLIP_TO_ATTACHED_PARENT ],
	[ Clay_TransitionElementConfig => 'properties',           $all_properties ],
	[ Clay_TransitionElementConfig => 'interactionHandling',  CLAY_TRANSITION_ALLOW_INTERACTIONS_WHILE_TRANSITIONING_POSITION ],
	[ Clay_TransitionElementConfig => 'enter.trigger',        CLAY_TRANSITION_ENTER_TRIGGER_ON_FIRST_PARENT_FRAME ],
	[ Clay_TransitionElementConfig => 'exit.trigger',         CLAY_TRANSITION_EXIT_TRIGGER_WHEN_PARENT_EXITS ],
	[ Clay_TransitionElementConfig => 'exit.siblingOrdering', CLAY_EXIT_TRANSITION_ORDERING_ABOVE_SIBLINGS ],
	[ Clay_TransitionCallbackArguments => 'transitionState', CLAY_TRANSITION_STATE_EXITING ],
	[ Clay_TransitionCallbackArguments => 'properties',      $all_properties ],
);

# { a => { b => $value } } for the path 'a.b'.
sub nested ($path, $value) {
	my $hash = $value;
	$hash = { $_ => $hash } for reverse split /\./, $path;
	return $hash;
}

for my $case (@enum_fields) {
	my ($type, $path, $last) = @$case;
	ok( lives { check_struct($type, nested($path, $last)) }, "$type.$path accepts $last" ) or note $@;
	like( dies { check_struct($type, nested($path, $last + 1)) },
		qr/^\Q$type.$path\E: expected an integer in 0\.\.$last, got '${\($last + 1)}'/, "$type.$path ends at $last" );
}

done_testing;

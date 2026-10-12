package Clay::UI;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Scalar::Util qw(blessed refaddr);

use Clay::XS qw(
	Clay_Initialize
	Clay_MinMemorySize
	Clay_GetCurrentContext
	Clay_SetCurrentContext
	Clay_SetMaxElementCount
	Clay_SetMaxMeasureTextCacheWordCount
	Clay_SetLayoutDimensions
	Clay_SetMeasureTextFunction
	Clay_ResetMeasureTextCache
	Clay_SetPointerState
	Clay_GetPointerState
	Clay_GetPointerOverIds
	Clay_UpdateScrollContainers
	Clay_GetScrollOffset
	Clay_BeginLayout
	Clay_EndLayout
	Clay_GetElementId
	Clay_GetElementData
	Clay_GetScrollContainerData
	set_scroll_position
	Clay__OpenElementWithId
	Clay__ConfigureOpenElement
	Clay__CloseElement
	Clay__OpenTextElement
	CLAY_POINTER_DATA_PRESSED
	CLAY_POINTER_DATA_PRESSED_THIS_FRAME
	CLAY_ERROR_TYPE_TEXT_MEASUREMENT_CAPACITY_EXCEEDED
);
use Clay::UI::_keys qw(camelize_keys);
use Clay::UI::_validate qw(is_finite_number);
use Clay::UI::Interaction;
use Clay::UI::_FrameRegistry;
use Clay::UI::Role::Core::Preparable;
use Clay::UI::Revision qw(bump_revision current_revision);
use Clay::UI::_error qw(croak_ui);

our $VERSION = '0.06';

my %RENDER_ARGS  = map { $_ => 1 } qw(pointer_state delta_time scroll_delta enable_drag_scrolling);
my %POINTER_KEYS = map { $_ => 1 } qw(x y down);
my %VECTOR_KEYS  = map { $_ => 1 } qw(x y);

# Clay's default element count, and the fewest measure-cache words Clay::XS
# accepts.
my $DEFAULT_MAX_ELEMENT_COUNT = 8192;
my $MIN_MEASURE_CACHE_WORDS   = 32;

class Clay::UI :strict(params) {
	field $root   :param :reader;
	field $width  :param;
	field $height :param;

	field $memory_size                       :param = undef;
	field $max_element_count                 :param :reader = $DEFAULT_MAX_ELEMENT_COUNT;
	field $max_measure_text_cache_word_count :param :reader = undef;
	field $error_handler                     :param = undef;
	field $measure_text                      :param = undef;

	field $_ctx;
	field $_uses_default_error_handler;
	field $_rendering = 0;

	# What the last completed frame laid out (see Clay::UI::_FrameRegistry).
	field $_frame = Clay::UI::_FrameRegistry->new;

	# The last pointer state passed to render, and the tracker that owns
	# hover, armed, pressed and focus state.
	field $_last_pointer;
	field $interaction :reader;

	# The revision (Clay::UI::Revision) the last layout pass started at.
	field $_laid_out_revision :reader(laid_out_revision);

	ADJUST {
		unless (blessed $root
			&& ($root->DOES('Clay::UI::Role::Core::Element')
			 || $root->DOES('Clay::UI::Role::Core::TextNode'))) {
			croak_ui "Clay::UI: 'root' must be a widget consuming Clay::UI::Role::Core::Element or TextNode";
		}
		croak_ui "Clay::UI: 'root' must not have a parent; the root is the top of its widget tree"
			if defined $root->parent;
		croak_ui "Clay::UI: 'root' is already the root of another Clay::UI"
			if defined $root->_local_ui_controller;
		unless (_is_viewport_size($width) && _is_viewport_size($height)) {
			croak_ui "Clay::UI: 'width' and 'height' must be positive finite numbers";
		}
		unless (is_finite_number($max_element_count) && $max_element_count == int($max_element_count)
			&& $max_element_count >= 1) {
			croak_ui "Clay::UI: 'max_element_count' must be a positive integer";
		}
		$max_measure_text_cache_word_count //= _default_measure_cache_words($max_element_count);
		unless (is_finite_number($max_measure_text_cache_word_count)
			&& $max_measure_text_cache_word_count == int($max_measure_text_cache_word_count)
			&& $max_measure_text_cache_word_count >= $MIN_MEASURE_CACHE_WORDS) {
			croak_ui "Clay::UI: 'max_measure_text_cache_word_count' must be an integer >= $MIN_MEASURE_CACHE_WORDS";
		}

		# The handler closes over the count, not over $self: Clay's context
		# keeps the handler, and a cycle would keep the UI alive.
		$_uses_default_error_handler = !defined $error_handler;
		my $measure_cache_error = _measure_cache_error($max_measure_text_cache_word_count);
		$error_handler //= sub ($err, $userdata) {
			die $measure_cache_error if $err->{errorType} == CLAY_ERROR_TYPE_TEXT_MEASUREMENT_CAPACITY_EXCEEDED;
			die "Clay error: $err->{errorText}\n";
		};
		$measure_text //= sub ($text, $config, $userdata) {
			my $fs = $config->{fontSize} || 16;
			return { width => length($text) * $fs, height => $fs };
		};

		unless (ref $error_handler eq 'CODE') {
			croak_ui "Clay::UI: 'error_handler' must be a coderef";
		}
		unless (ref $measure_text eq 'CODE') {
			croak_ui "Clay::UI: 'measure_text' must be a coderef";
		}

		my $previous = Clay_GetCurrentContext();
		my $ok = eval {
			$_ctx = $self->_initialize_context;
			Clay_SetMeasureTextFunction($measure_text);
			1;
		};
		$self->_abandon_construction($previous, $@) unless $ok;

		# Events follow the tree order of the last completed frame.
		$interaction = Clay::UI::Interaction->new(
			ui         => $self,
			tree_order => sub (@widgets) { $_frame->in_tree_order(@widgets) },
		);
		$root->_set_ui_controller($self);
		my $hook_error = $root->_announce_tree_change;
		$self->_abandon_construction($previous, $hook_error) if defined $hook_error;
	}

	# A failed construction frees the new context at once, makes the
	# caller's context current again and dies with $error.
	method _abandon_construction ($previous, $error) {
		undef $_ctx;
		Clay_SetCurrentContext($previous) if defined $previous;
		die $error;
	}

	# Creates this UI's context, sized for max_element_count, and leaves it
	# current. Clay_MinMemorySize and Clay_Initialize use the counts of the
	# current context, so a throwaway seed context carries this UI's counts
	# to them: setting the counts on another UI's context would disable it
	# until it is initialised again, and setting them with no current
	# context would change Clay's process-wide defaults.
	method _initialize_context () {
		my $seed = Clay_Initialize(Clay_MinMemorySize(), { width => $width, height => $height });
		Clay_SetMaxElementCount($max_element_count);
		Clay_SetMaxMeasureTextCacheWordCount($max_measure_text_cache_word_count);

		my $min_memory = Clay_MinMemorySize();
		$memory_size //= $min_memory;
		unless (is_finite_number($memory_size) && $memory_size == int($memory_size)
			&& $memory_size >= $min_memory) {
			croak_ui "Clay::UI: 'memory_size' must be an integer >= Clay_MinMemorySize() ($min_memory)"
				. " for max_element_count $max_element_count and max_measure_text_cache_word_count $max_measure_text_cache_word_count";
		}
		# The new context copies the seed's counts and becomes current.
		return Clay_Initialize($memory_size, { width => $width, height => $height }, $error_handler);
	}

	# Clay keeps one element for its own root and never fills its last
	# slot, so this many widgets fit into one frame.
	method _widget_capacity () {
		return $max_element_count > 2 ? $max_element_count - 2 : 0;
	}

	# Clay's own default: twice as many cached words as elements, and at
	# least the 32 its hash buckets need.
	sub _default_measure_cache_words ($element_count) {
		my $words = 2 * $element_count;
		return $words > $MIN_MEASURE_CACHE_WORDS ? $words : $MIN_MEASURE_CACHE_WORDS;
	}

	# Clay measures every text laid out in a frame word by word and keeps
	# the words of the last few frames; past the capacity it reports an
	# error and lays the rest of the text out with no size at all.
	sub _measure_cache_error ($word_count) {
		return "Clay::UI: the texts laid out in one frame have more words than max_measure_text_cache_word_count ($word_count) allows;"
			. " pass a larger max_measure_text_cache_word_count to Clay::UI->new\n";
	}

	sub _is_viewport_size ($value) {
		return is_finite_number($value) && $value > 0;
	}

	sub _one_value ($name, @value) {
		croak_ui "Clay::UI: $name takes one value" unless @value == 1;
		return $value[0];
	}

	# Read with no args; write with one arg, propagating to Clay. Clay gets
	# the new size before the field does, so a size Clay refuses leaves
	# both unchanged.
	method width (@v) {
		return $width unless @v;
		my $new = _one_value(width => @v);
		croak_ui "Clay::UI: width must be a positive finite number" unless _is_viewport_size($new);
		Clay_SetCurrentContext($_ctx);
		Clay_SetLayoutDimensions({ width => $new, height => $height });
		$width = $new;
		bump_revision();
		return $width;
	}

	method height (@v) {
		return $height unless @v;
		my $new = _one_value(height => @v);
		croak_ui "Clay::UI: height must be a positive finite number" unless _is_viewport_size($new);
		Clay_SetCurrentContext($_ctx);
		Clay_SetLayoutDimensions({ width => $width, height => $new });
		$height = $new;
		bump_revision();
		return $height;
	}

	method measure_text (@v) {
		return $measure_text unless @v;
		my $new = _one_value(measure_text => @v);
		croak_ui "Clay::UI: measure_text must be a coderef" unless ref $new eq 'CODE';
		Clay_SetCurrentContext($_ctx);
		Clay_SetMeasureTextFunction($new);
		Clay_ResetMeasureTextCache();
		$measure_text = $new;
		bump_revision();
		return $measure_text;
	}

	# Parses render's named arguments into a frame description; dies on
	# anything it does not recognise.
	sub _parse_render_args (%args) {
		my @unknown = grep { !$RENDER_ARGS{$_} } keys %args;
		croak_ui "Clay::UI::render: unknown argument(s): @{[ sort @unknown ]}" if @unknown;

		my $pointer = $args{pointer_state};
		if (defined $pointer) {
			croak_ui "Clay::UI::render: 'pointer_state' must be a hashref { x => ..., y => ..., down => ... }"
				unless ref $pointer eq 'HASH';
			my @bad = grep { !$POINTER_KEYS{$_} } keys %$pointer;
			croak_ui "Clay::UI::render: unknown pointer_state key(s): @{[ sort @bad ]}" if @bad;
			for my $axis (qw(x y)) {
				croak_ui "Clay::UI::render: pointer_state '$axis' must be a finite number"
					unless is_finite_number($pointer->{$axis});
			}
			croak_ui "Clay::UI::render: pointer_state 'down' must be a plain boolean value"
				if ref $pointer->{down};
			$pointer = { x => $pointer->{x}, y => $pointer->{y}, down => $pointer->{down} ? 1 : 0 };
		}

		my $delta_time = $args{delta_time} // 0;
		croak_ui "Clay::UI::render: 'delta_time' must be a finite number >= 0"
			unless is_finite_number($delta_time) && $delta_time >= 0;

		my $scroll_delta = $args{scroll_delta} // [0, 0];
		if (ref $scroll_delta eq 'HASH') {
			my @bad = grep { !$VECTOR_KEYS{$_} } keys %$scroll_delta;
			croak_ui "Clay::UI::render: unknown scroll_delta key(s): @{[ sort @bad ]}" if @bad;
			$scroll_delta = [ @{$scroll_delta}{qw(x y)} ];
		}
		croak_ui "Clay::UI::render: 'scroll_delta' must be { x => ..., y => ... } or [x, y] of finite numbers"
			unless ref $scroll_delta eq 'ARRAY' && @$scroll_delta == 2
				&& !grep { !is_finite_number($_) } @$scroll_delta;

		my $drag = $args{enable_drag_scrolling} // 0;
		croak_ui "Clay::UI::render: 'enable_drag_scrolling' must be a plain boolean value"
			if ref $drag;

		return {
			pointer      => $pointer,
			delta_time   => $delta_time,
			scroll_delta => { x => $scroll_delta->[0], y => $scroll_delta->[1] },
			drag         => $drag ? 1 : 0,
		};
	}

	method render (%args) {
		my $frame = _parse_render_args(%args);
		croak_ui "Clay::UI::render: called while this Clay::UI is already rendering"
			if $_rendering;

		$_rendering = 1;
		my $commands;
		my $ok = eval { $commands = $self->_render_frame($frame); 1 };
		my $error = $@;
		$_rendering = 0;
		die $error unless $ok;
		return $commands;
	}

	# One frame: pointer and scroll input, event dispatch and the widgets
	# that asked to be prepared (plain Perl, with no element open, so they
	# may change the tree), then the layout pass. The layout pass runs even
	# when a listener died (documented behaviour): the frame then shows the
	# scroll input already applied and the changes made before the error;
	# its commands are discarded and the listener's error is rethrown.
	method _render_frame ($frame) {
		Clay_SetCurrentContext($_ctx);

		my $pointer = $frame->{pointer} // $_last_pointer;
		if (defined $pointer) {
			Clay_SetPointerState({ x => $pointer->{x}, y => $pointer->{y} }, $pointer->{down});
		}
		$_last_pointer = $pointer;
		my @under_pointer = $self->_widgets_under_pointer;
		my $pointer_data  = Clay_GetPointerState();

		my $scroll_before = $_frame->scroll_positions($self);
		Clay_UpdateScrollContainers($frame->{drag}, $frame->{scroll_delta}, $frame->{delta_time});

		my ($dispatch_error, $layout_error, $commands);
		{
			local $@;
			eval {
				# Wheel, drag and momentum scrolling move containers without
				# any setter: the frame changes all the same.
				my @scrolled = $_frame->scroll_changes($scroll_before);
				bump_revision() if @scrolled;

				my $state = $pointer_data->{state};
				$interaction->update(
					over     => \@under_pointer,
					down     => $state == CLAY_POINTER_DATA_PRESSED || $state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME,
					x        => $pointer_data->{position}{x},
					y        => $pointer_data->{position}{y},
					scrolled => \@scrolled,
				);
				1;
			} or $dispatch_error = $@ || 'unknown listener error';
		}
		{
			local $@;
			eval { Clay::UI::Role::Core::Preparable::_prepare_pending($self); 1 }
				or $dispatch_error //= $@ || 'unknown prepare_layout error';
		}
		{
			local $@;
			$_laid_out_revision = current_revision();    # nothing changes the tree from here on
			eval { $commands = $self->_layout_frame($frame->{delta_time}); 1 }
				or $layout_error = $@ || 'unknown layout error';
		}
		if (defined $dispatch_error) {
			$dispatch_error .= "(the layout pass also failed: $layout_error)"
				if defined $layout_error && !ref $dispatch_error;
			die $dispatch_error;
		}
		die $layout_error if defined $layout_error;
		return $commands;
	}

	method _layout_frame ($delta_time) {
		# The walk fills a new registry; it replaces the current one only
		# after a complete frame, so a failed frame leaves the last good one
		# in place.
		my $next_frame = Clay::UI::_FrameRegistry->new;

		# A listener may have used another Clay::UI, which switches Clay's
		# current context.
		Clay_SetCurrentContext($_ctx);
		my ($walk_error, $end_error, $commands);
		Clay_BeginLayout();
		{
			local $@;
			eval { $self->_walk($next_frame, $root, '', []); 1 } or $walk_error = $@ || 'unknown walker error';
		}
		{
			local $@;
			eval { $commands = Clay_EndLayout($delta_time); 1 }
				or $end_error = $@ || 'unknown Clay_EndLayout error';
		}
		$end_error = $self->_capacity_error($next_frame->element_count)
			if defined $end_error && $_uses_default_error_handler && $next_frame->element_count > $self->_widget_capacity;

		if (defined $walk_error) {
			$walk_error .= "(Clay_EndLayout also failed: $end_error)"
				if defined $end_error && !ref $walk_error;
			die $walk_error;
		}
		die $end_error if defined $end_error;

		$_frame = $next_frame;
		return $commands;
	}

	# Clay drops every element past its capacity without a word and then
	# reports the open elements it could not close; this says what
	# happened instead.
	method _capacity_error ($widget_count) {
		return "Clay::UI: the widget tree has more elements than max_element_count ($max_element_count) allows:"
			. " $widget_count widgets, at most " . $self->_widget_capacity . " fit;"
			. " pass a larger max_element_count to Clay::UI->new\n";
	}

	# ---------------------------------------------------------------------
	# Pointer and scroll events.
	# ---------------------------------------------------------------------

	method _belongs_here ($widget) {
		my $ui = $widget->ui;
		return defined $ui && refaddr($ui) == refaddr($self);
	}

	# The widgets of this UI under the pointer, in Clay's pointer-over order:
	# the topmost floating root first, pre-order within each root. Clay adds
	# an element to that list exactly when it would call its hover callback.
	method _widgets_under_pointer () {
		my @widgets;
		for my $id (@{ Clay_GetPointerOverIds() }) {
			my $widget = $_frame->widget_for_element($id->{id});
			push @widgets, $widget if defined $widget && $self->_belongs_here($widget);
		}
		return @widgets;
	}

	method widget_for ($user_data) {
		return undef unless defined $user_data && $user_data;
		return $_frame->widget_for($user_data);
	}

	# ---------------------------------------------------------------------
	# Geometry and scrolling of the last completed frame.
	# ---------------------------------------------------------------------

	# The element id the last frame declared the widget with, or undef when
	# the widget was not part of it.
	method _laid_out_element ($widget) {
		croak_ui "Clay::UI: expected a widget, got " . (ref($widget) || (defined $widget ? "'$widget'" : 'undef'))
			unless blessed $widget;
		return $_frame->element_id_of($widget);
	}

	method bounding_box ($widget) {
		my $element = $self->_laid_out_element($widget) // return undef;
		Clay_SetCurrentContext($_ctx);
		my $data = Clay_GetElementData($element);
		return undef unless $data->{found};
		return { map { $_ => $data->{boundingBox}{$_} + 0 } qw(x y width height) };
	}

	# ( element id, Clay's scroll data ) of a scroll container, or an empty
	# list when the last frame did not lay it out.
	method _scroll_data ($widget) {
		croak_ui "Clay::UI: " . (ref($widget) || (defined $widget ? "'$widget'" : 'undef'))
			. " is not a scroll container (it does not compose Clay::UI::Role::Layout::HasScroll)"
			unless blessed $widget && $_frame->is_scroll_container($widget);
		my $element = $self->_laid_out_element($widget) // return;
		Clay_SetCurrentContext($_ctx);
		my $data = Clay_GetScrollContainerData($element);
		return $data->{found} ? ($element, $data) : ();
	}

	method scroll_state ($widget) {
		my (undef, $data) = $self->_scroll_data($widget) or return undef;
		return {
			position => { map { $_ => $data->{scrollPosition}{$_} + 0 } qw(x y) },
			viewport => { map { $_ => $data->{scrollContainerDimensions}{$_} + 0 } qw(width height) },
			content  => { map { $_ => $data->{contentDimensions}{$_} + 0 } qw(width height) },
		};
	}

	# Moves a scroll container, kept within its content; an axis left out
	# keeps its position. Returns the position, or undef when the last frame
	# did not lay the container out. A container that prepares its subtree
	# for the position it shows (a Preparable) is prepared for the new one.
	method scroll_to ($widget, $position) {
		croak_ui "Clay::UI: scroll_to needs a position { x => ..., y => ... }"
			unless ref $position eq 'HASH';
		my @unknown = grep { !$VECTOR_KEYS{$_} } sort keys %$position;
		croak_ui "Clay::UI: scroll_to got unknown position key(s): @unknown" if @unknown;
		for my $axis (sort keys %$position) {
			croak_ui "Clay::UI: scroll_to position '$axis' must be a finite number"
				unless is_finite_number($position->{$axis});
		}
		my ($element, $data) = $self->_scroll_data($widget) or return undef;
		my %extent = (x => 'width', y => 'height');
		my %clamped;
		for my $axis (qw(x y)) {
			my $lowest = $data->{scrollContainerDimensions}{ $extent{$axis} } - $data->{contentDimensions}{ $extent{$axis} };
			$lowest = 0 if $lowest > 0;
			my $wanted = $position->{$axis} // $data->{scrollPosition}{$axis};
			$clamped{$axis} = $wanted > 0 ? 0 : $wanted < $lowest ? $lowest : $wanted + 0;
		}
		# Clay holds the position in single precision, so what it holds
		# after the move decides whether anything changed.
		set_scroll_position($element, \%clamped);
		my $moved = Clay_GetScrollContainerData($element)->{scrollPosition};
		my %held  = map { $_ => $moved->{$_} + 0 } qw(x y);
		return \%held if !grep { $held{$_} != $data->{scrollPosition}{$_} } qw(x y);
		$widget->request_prepare if $widget->DOES('Clay::UI::Role::Core::Preparable');
		return \%held;
	}

	# Injects the back-reference into a config hash the walker owns (a
	# copy of what the widget returned) and records it in $frame.
	sub _attach_back_reference ($frame, $config, $node) {
		if (exists $config->{user_data} || exists $config->{userData}) {
			croak_ui "Clay::UI: widget " . ref($node)
				. " set user_data in its config; Clay::UI auto-injects a refaddr"
				. " back-reference here. Use one mechanism or the other, not both.";
		}
		$config->{user_data} = $frame->add_back_reference($node);
		return;
	}

	# Declares $node and its subtree, recording it in $frame (the registry
	# of the frame being laid out). $base is the nearest ancestor-or-self
	# user id ('' if none) and $indices the child indices below it; they
	# name anonymous elements (see Element::resolve_id).
	#
	# Only the config is built before the element is opened; marshalling
	# (Clay__ConfigureOpenElement), the scroll offset lookup and the
	# children run after the open, inside one guard, so Clay__CloseElement
	# always runs and the first error is rethrown after it: Clay's
	# open-element stack stays balanced whatever fails. No listener runs
	# during the walk.
	method _walk ($frame, $node, $base, $indices) {
		unless (blessed $node) {
			croak_ui "Clay::UI: tree node is not a blessed widget (got " . (ref($node) || 'non-ref') . ")";
		}

		if ($node->DOES('Clay::UI::Role::Core::TextNode')) {
			my %text_config = %{ $node->text_config };
			_attach_back_reference($frame, \%text_config, $node);
			Clay__OpenTextElement($node->text, camelize_keys(\%text_config));
			return;
		}

		unless ($node->DOES('Clay::UI::Role::Core::Element')) {
			croak_ui "Clay::UI: tree node " . ref($node) . " does not consume Clay::UI::Role::Core::Element or TextNode";
		}

		my %config = %{ $node->to_config };
		_attach_back_reference($frame, \%config, $node);
		my $camelized = camelize_keys(\%config);

		my $element = Clay_GetElementId($node->resolve_id($base, $indices));
		$frame->add_element($node, $element);
		my ($child_base, $child_indices) = defined $node->id ? ($node->id, []) : ($base, $indices);

		Clay__OpenElementWithId($element);
		my $ok = eval {
			my $clip = $camelized->{clip};
			if ($frame->is_scroll_container($node) && $clip && !exists $clip->{childOffset}) {
				$clip->{childOffset} = Clay_GetScrollOffset();
			}
			Clay__ConfigureOpenElement($camelized);

			my @children = @{ $node->layout_children };
			for my $index (0 .. $#children) {
				$self->_walk($frame, $children[$index], $child_base, [ @$child_indices, $index ]);
			}
			1;
		};
		my $error = $@;
		Clay__CloseElement();
		die($error || 'unknown walker error') unless $ok;
		return;
	}
}

1;

__END__
=head1 NAME

Clay::UI - widget layer over Clay::XS: build a widget tree, lay it out, turn pointer input into events

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::XS qw(sizing_grow sizing_fixed);
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Text;
	use Clay::UI::Role::Interaction::Pressable;

	# Widget classes: Object::Pad classes composed from Clay::UI roles.
	class My::Panel  :strict(params) :does(Clay::UI::Box) {}
	class My::Label  :strict(params) :does(Clay::UI::Text) {}
	class My::Button :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Pressable)
	{}

	# The widget tree.
	my $root = My::Panel->new(
		id               => 'root',
		layout           => {
			sizing  => { width => sizing_grow(), height => sizing_grow() },
			padding => { left => 10, top => 10 },
		},
		background_color => [40, 50, 60, 255],
	);
	my $button = My::Button->new(
		id     => 'ok',
		layout => { sizing => { width => sizing_fixed(80), height => sizing_fixed(30) } },
	);
	$button->add_child(My::Label->new(text => 'OK', font_size => 16));
	$button->on('OnHoverStart', sub ($event) { say 'over the button'; return });
	$button->on('OnRelease',    sub ($event) { say 'clicked';         return });
	$root->add_child($button);

	# The UI that owns the tree and its Clay context.
	my $ui = Clay::UI->new(width => 800, height => 600, root => $root);

	# One call per frame: pointer input in, render commands out.
	for my $down (0, 1, 0) {
		my $commands = $ui->render(pointer_state => { x => 20, y => 20, down => $down });
		for my $command (@$commands) {
			my $widget = $ui->widget_for($command->{userData});
			# draw $command; $widget is the widget that produced it
		}
	}

=head1 DESCRIPTION

C<Clay::UI> is the widget layer of this distribution. You build a tree
of widgets (Perl objects that describe boxes and text), hand its root
widget to a C<Clay::UI> object, and call L</render> once per frame.
C<render> does three things:

=over 4

=item *

it turns the frame's pointer and scroll input into widget events
(L</EVENTS>) and calls your listeners,

=item *

it lays out the widget tree with Clay, and

=item *

it returns Clay's render commands: an arrayref of hashes, each one a
rectangle, text, border or clipping instruction with a bounding box
(see L<Clay::XS/RENDER COMMANDS>).

=back

Nothing is drawn. A renderer (your code) draws the render commands with
whatever graphics library you use, and finds the widget behind each
command with L</widget_for>.

A C<Clay::UI> object owns one Clay context (a L<Clay::XS> context: one
independent Clay instance), the measure-text callback and the
interaction tracker (L<Clay::UI::Interaction>), which holds which
widgets are hovered, pressed and focused. You never call C<Clay_*>
functions yourself, with one exception: to animate transitions, call
C<Clay_SetTransitionHandlers> right after C<< Clay::UI->new >>, while
the new UI's context is current (see L<Clay::Manual/TRANSITIONS>). The
low-level L<Clay::XS> API stays usable on its own.


For a guided introduction read L<Clay::Manual>; for ready-made
solutions see L<Clay::Cookbook>.

=head1 WIDGET CLASSES

A I<widget class> is an L<Object::Pad> class that composes roles from
this distribution. The roles provide the attributes, the children and
the behaviour; the class itself is often empty:

	class My::Button :strict(params)
		:does(Clay::UI::Box)                             # an element with layout and style
		:does(Clay::UI::Role::Interaction::Pressable)    # OnPress / OnRelease
	{}

There are two kinds of widget:

=over 4

=item element widgets

Compose L<Clay::UI::Role::Core::Element> (usually through
L<Clay::UI::Box>, which adds layout, background, border, corner radius,
floating and the public child methods). An element widget becomes one
Clay element and may have children.

=item text widgets

Compose L<Clay::UI::Role::Core::TextNode> (usually through
L<Clay::UI::Text>). A text widget becomes one Clay text element and has
no children.

=back

A grid is an element widget too: a class composing L<Clay::UI::Grid>
(a widget role like C<Clay::UI::Box> and C<Clay::UI::Text>) lays its
children out in rows and columns.

Further roles add behaviour: L<Clay::UI::Role::Interaction::Hoverable>,
L<Clay::UI::Role::Interaction::Pressable>,
L<Clay::UI::Role::Interaction::Focusable>,
L<Clay::UI::Role::Interaction::Disableable>,
L<Clay::UI::Role::Interaction::HasFocusOrder>,
L<Clay::UI::Role::Layout::HasScroll> (scroll containers)
and L<Clay::UI::Role::Core::Preparable> (widgets that rebuild their
children right before the layout).

Every widget can listen to events with C<on>
(L<Clay::UI::Role::Events::Listener>); widgets that compose
L<Clay::UI::Role::Events::Emitter> can also fire them. C<Clay::UI::Box>,
L<Clay::UI::Role::Interaction::Hoverable>,
L<Clay::UI::Role::Interaction::Pressable>,
L<Clay::UI::Role::Interaction::Focusable> and
L<Clay::UI::Role::Layout::HasScroll> compose it; C<Clay::UI::Text>,
C<Disableable> and C<HasFocusOrder> do not.

The C<class> keyword opens a new package, so C<use Clay::XS qw(...)>
imports made at file scope are not visible inside the class block.

=head1 KEYS AND VALIDATION

Clay::UI accepts the keys of Clay's structs in snake_case
(C<child_gap>, C<layout_direction>, C<background_color>) as well as in
the camelCase spelling Clay::XS uses (C<childGap>, C<layoutDirection>).
Widgets store every key in snake_case, so readers return snake_case
whatever spelling was set:

	my $box = My::Box->new(layout => { childGap => 4 });
	$box->layout;    # { child_gap => 4 }

Both spellings of the same key in one hash die where the value is set:

=for highlighter language=text

	Clay::UI: key 'childGap' in 'layout' is 'child_gap' in snake_case, which is already present in the same hash

The layout pass converts every key to camelCase before it passes a
widget's settings to Clay.

Widget attributes are validated where they are set: in the constructor
and in the accessor that writes them, not later in C<render>. The rules
are exactly the ones Clay::XS applies when the value reaches Clay
(see C<check_struct> in L<Clay::XS/CHECKING STRUCTS>). Errors name the attribute and the
snake_case path inside it:

	Clay::UI: 'layout.padding.left' expected an integer in 0..65535, got '-5'
	Clay::UI: 'layout' has unknown key 'chld_gap' (known keys: sizing, padding, child_gap, ...)

Attributes are copied when they are set and when they are read, so a
widget never shares a hash or array with your code: changing a hash
after passing it, or changing what a reader returned, does not change
the widget. Use the accessor to write a new value.

=head1 HOW A FRAME WORKS

One call to L</render> is one I<frame>. It runs these steps in order:

=over 4

=item 1. Pointer input

The pointer position and button state (the C<pointer_state> argument,
or the previous frame's when it is omitted) go to Clay. Clay tests the
position against the layout of the previous frame and lists the
elements under the pointer, topmost floating element first. Clay::UI
maps those elements back to widgets: these are the widgets I<under the
pointer>. A widget added to the tree can be hovered from the frame
after the one that first lays it out.

=item 2. Scrolling

The C<scroll_delta>, C<enable_drag_scrolling> and C<delta_time>
arguments go to Clay. Wheel input moves the scroll container under the
pointer at once. Drag scrolling moves it while the button is held and,
after the release, keeps it gliding (momentum) for some frames. Wheel
input has no momentum.

=item 3. Events

The widgets under the pointer, the button state and the scroll
containers that moved go to the interaction tracker
(L<Clay::UI::Interaction/update>). It updates the hovered, armed and
pressed widgets first, then fires the events in this order: every
C<OnHoverStopped>, every C<OnHoverStart>, C<OnPress>, C<OnRelease>,
every C<OnScroll>. Events of one kind fire in tree order (depth-first
pre-order of the last layout). See L</EVENTS>.

=item 4. Preparations

Every widget of this UI that called C<request_prepare> since its last
preparation gets its C<prepare_layout> method called
(L<Clay::UI::Role::Core::Preparable>), so it can rebuild its children
from its own state: parents before their descendants, widgets at the
same depth in the order they asked. A widget that an earlier
preparation detached is not prepared and stays queued. Preparations
may request more preparations; after 100 rounds C<render> gives up and
dies.

=item 5. Layout pass

C<render> records the current revision as L</laid_out_revision>, then
declares the widget tree to Clay: one Clay element per element widget,
one text element per text widget, in tree order. Nothing may change the
tree from here on. Clay computes the layout.

=item 6. Result

C<render> returns the render commands. The frame is now the I<last
completed frame>: L</widget_for>, L</bounding_box>, L</scroll_state>,
L</scroll_to> and the next frame's pointer test refer to it.

=back

Listeners and preparations run in steps 3 and 4, while no Clay element
is open. They may change the tree, widget attributes and focus, and use
other Clay::UI objects; the changes show in this frame's layout. They
must not call C<render> of the same Clay::UI.

If a listener dies, the remaining events still fire and the
preparations still run. If a C<prepare_layout> dies, the other widgets
due in that round are still prepared; then preparation stops: later
rounds do not run, and the requests made during that round stay queued
for the next C<render> (see L<Clay::UI::Role::Core::Preparable/prepare_layout>).
In both cases the layout pass still runs, so the frame shows the scroll
input already applied and the changes made before the error. Then
C<render> dies with the first error and the frame's render commands are
lost. The next
C<render> works normally.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $ui = Clay::UI->new(
		root   => $root_widget,
		width  => 800,
		height => 600,
		# optional: memory_size, max_element_count,
		#           max_measure_text_cache_word_count, error_handler, measure_text
	);

Creates a Clay::UI, its Clay context and its interaction tracker, and
makes C<root> the root widget of this UI. Then every widget of the
root's subtree gets its
L<tree_changed|Clay::UI::Role::Layout::HasParent/tree_changed> call;
C<new> dies with the first error of those hooks once all ran. The new
context is current when C<new> returns. If C<new> dies, it frees the
new context and makes the context that was current before current
again; the root is then free to become the root of another Clay::UI.

Unknown parameters die (C<Unrecognised parameters for Clay::UI constructor>).

=over 4

=item root

Required. The root widget: an object composing
L<Clay::UI::Role::Core::Element> or L<Clay::UI::Role::Core::TextNode>.
It must have no parent and must not be the root of another Clay::UI;
a widget that was removed from its parent may become a root. Read it
back with L</root>; it cannot be replaced, but the tree below it can
change at any time. Dies with:

=for highlighter language=text

	Clay::UI: 'root' must be a widget consuming Clay::UI::Role::Core::Element or TextNode
	Clay::UI: 'root' must not have a parent; the root is the top of its widget tree
	Clay::UI: 'root' is already the root of another Clay::UI

=item width

Required. The viewport width in layout units, a positive finite number.
Change it later with L</width>.

=item height

Required. The viewport height, like C<width>. Both die with
C<Clay::UI: 'width' and 'height' must be positive finite numbers>.


=item memory_size

Optional. Bytes of memory for the Clay context: an integer of at least
C<Clay_MinMemorySize()> for this UI's C<max_element_count> and
C<max_measure_text_cache_word_count>, which is also the default. Dies with
C<Clay::UI: 'memory_size' must be an integer E<gt>= Clay_MinMemorySize() (...)>.


=item max_element_count

Optional. How many Clay elements this UI's context holds: a positive
integer, default 8192 (Clay's default). Every element widget and every
text widget is one element. Clay keeps two slots for itself, so one
frame fits C<max_element_count - 2> widgets (none for a count below 3).
Clay also wraps at most this many text lines per frame, over all the
text widgets it lays out; past that it silently stops wrapping. Each
Clay::UI has its own count, whatever context is current when it is
constructed. A larger count needs more memory (see C<memory_size>).
Dies with C<Clay::UI: 'max_element_count' must be a positive integer>.
Read it back with L</max_element_count>.


=item max_measure_text_cache_word_count

Optional. How many measured words Clay's text cache holds: an integer
of at least 32, default twice C<max_element_count> (Clay's default).
Clay measures every text it lays out word by word and keeps the words
of the last few frames, visible or not, so a frame whose texts have
more words than this makes C<render> die with
C<Clay::UI: the texts laid out in one frame have more words than max_measure_text_cache_word_count (16384) allows; ...>
(default error handler). A larger count needs more memory (see
C<memory_size>). Dies with
C<Clay::UI: 'max_measure_text_cache_word_count' must be an integer E<gt>= 32>.
Read it back with L</max_measure_text_cache_word_count>.


=item error_handler

Optional. A coderef Clay calls as C<< $handler->($error, $userdata) >>
when it reports an error; C<$error> is a hashref with C<errorType> (a
C<CLAY_ERROR_TYPE_*> constant) and C<errorText>. The default handler
dies with C<Clay error: $error-E<gt>{errorText}>, which makes C<render>
die (see L<Clay::XS/ERRORS FROM CALLBACKS>); a handler that returns
lets the frame continue. Dies with C<Clay::UI: 'error_handler' must be a coderef>.

With the default handler, a tree with more widgets than
C<max_element_count> allows makes C<render> die with a message that
names C<max_element_count> (see L</render>) instead of the error Clay
reports for it (Clay drops the extra elements without a word and then
reports elements it could not close). A handler of your own receives
Clay's error unchanged.

The handler runs inside Clay and must not use any Clay::UI object (see
L<Clay::XS/What a callback may do>).

=item measure_text

Optional. A coderef Clay calls as C<< $measure->($text, $config,
$userdata) >> to measure a piece of text; it returns C<< { width =>
$w, height => $h } >>. C<$config> is the text element's configuration
with camelCase keys (C<fontSize>, C<fontId>, C<letterSpacing>, ...).
The default is a monospace estimate: C<width = length($text) *
fontSize>, C<height = fontSize>, with a C<fontSize> of 16 when it is 0
or missing. Dies with C<Clay::UI: 'measure_text' must be a coderef>.
Change it later with L</measure_text>.

The callback runs inside Clay during the layout pass and must not use
any Clay::UI object. Inside it:

=over 4

=item *

C<render> dies (C<Clay::UI::render: called while this Clay::UI is already rendering>).

=item *

The writers C<width($w)>, C<height($h)> and C<measure_text($coderef)>
die (C<Clay_SetCurrentContext: cannot be called from inside a Clay callback>);
the readers C<width>, C<height> and C<measure_text> work.

=item *

C<bounding_box>, C<scroll_state> and C<scroll_to> die with the same
message for a widget the last completed frame laid out, because they
ask Clay; for a widget it did not lay out they return undef without
asking Clay.

=back

If the callback lets such an error escape, the outer C<render> dies
with it after the layout pass.

=back

=head1 METHODS

=head2 root

=for highlighter language=perl

	my $root = $ui->root;

Returns the root widget passed to L</new>. Read-only.

=head2 max_element_count

	my $count = $ui->max_element_count;

Returns the C<max_element_count> passed to L</new> (8192 by default).
Read-only.

=head2 max_measure_text_cache_word_count

	my $words = $ui->max_measure_text_cache_word_count;

Returns the C<max_measure_text_cache_word_count> passed to L</new>
(twice C<max_element_count> by default). Read-only.

=head2 width

	my $width = $ui->width;
	$ui->width(1024);

Reads or writes the viewport width. A write takes one positive finite
number, passes it to Clay (C<Clay_SetLayoutDimensions>), bumps the
revision (L<Clay::UI::Revision>) and returns the new width; the next
L</render> lays out at the new size. A refused value changes nothing.
Dies with C<Clay::UI: width must be a positive finite number> or
C<Clay::UI: width takes one value>.

=head2 height

	my $height = $ui->height;
	$ui->height(768);

Reads or writes the viewport height, exactly like L</width>.

=head2 measure_text

	my $measure = $ui->measure_text;
	$ui->measure_text(sub ($text, $config, $userdata) { ... });

Reads or replaces the measure-text callback (see C<measure_text> under
L</new>). A write takes one coderef, passes it to Clay, clears Clay's
cache of measurements made by the old callback
(C<Clay_ResetMeasureTextCache>), bumps the revision and returns the new
callback. Dies with C<Clay::UI: measure_text must be a coderef> or
C<Clay::UI: measure_text takes one value>.

=head2 render

	my $commands = $ui->render(%args);

Runs one frame (see L</HOW A FRAME WORKS>): processes the pointer and
scroll input, fires the resulting events, prepares the widgets that
asked for it, lays out the widget tree and returns the render commands
as an arrayref of hashes (see L<Clay::XS/RENDER COMMANDS>). Each
command's C<userData> identifies the widget that produced it (see
L</widget_for>).

All arguments are named and optional:

=over 4

=item pointer_state

	pointer_state => { x => 120, y => 80, down => 1 }

The pointer for this frame: a hashref with finite numbers C<x> and C<y>
(layout units, origin at the top left of the viewport) and C<down>, a
true value while the button is held (default false). No other keys.
When omitted (or undef), the pointer state of the previous frame is
used again. A change of C<down> from false to true is a press, from
true to false a release (see L</EVENTS>). Until the first
C<pointer_state>, the pointer is up and Clay tests no position, so
nothing is under it and no press is reported.

=item delta_time

	delta_time => 0.016

Seconds since the previous frame, a finite number E<gt>= 0, default 0.
Clay uses it for the momentum after drag scrolling and for transitions.

=item scroll_delta

	scroll_delta => { x => 0, y => -1 }    # or [0, -1]

Wheel input for this frame, as C<< { x => ..., y => ... } >> (both keys
required, no others) or C<[$x, $y]>, both finite numbers; default
C<[0, 0]>. Clay multiplies the delta by 10 and adds it to the scroll
position of the scroll container under the pointer (the innermost one
when containers are nested), on each axis that container can scroll (its
content is larger than its viewport); the result is clamped to the
content. A negative C<y> scrolls down, revealing what is below:
C<< scroll_delta => { x => 0, y => -4 } >> scrolls the container 40
layout units down: the content moves up, and its C<position> in
L</scroll_state> goes from C<0> to C<-40>. A scroll container is a
widget composing L<Clay::UI::Role::Layout::HasScroll>. Wheel input has
no momentum: the container stops where the delta puts it, and wheel
input also stops a glide left over from drag scrolling.


=item enable_drag_scrolling

	enable_drag_scrolling => 1

A plain boolean, default false. When true, pressing and dragging inside
a scroll container scrolls it, as on a touch screen. After the release
the container keeps moving with momentum for some frames, slowing down
each frame.

=back

C<render> dies, with the frame discarded, in these cases:

=over 4

=item *

A bad argument, before anything happens:
C<Clay::UI::render: unknown argument(s)>,
C<... 'pointer_state' must be a hashref>,
C<... unknown pointer_state key(s)>,
C<... pointer_state 'x' must be a finite number>,
C<... pointer_state 'down' must be a plain boolean value>,
C<... 'delta_time' must be a finite number E<gt>= 0>,
C<... unknown scroll_delta key(s)>, C<... 'scroll_delta' must be ...>,
C<... 'enable_drag_scrolling' must be a plain boolean value>.


=item *

C<render> is called while the same Clay::UI is rendering, for example
from an event listener, a C<prepare_layout> or the measure-text
callback: C<Clay::UI::render: called while this Clay::UI is already rendering>.

=item *

An event listener died. All events of the frame fire, the preparations
and the layout pass run, then C<render> dies with the first listener
error.

=item *

A C<prepare_layout> died: the other preparations of that round still
run, later rounds do not (see L</HOW A FRAME WORKS>), the layout pass
runs, then C<render> dies with the first error of the frame. Or preparations kept requesting new
ones: C<Clay::UI: widgets kept requesting preparation; 100 rounds of prepare_layout did not settle>.

=item *

Clay reported an error and the error handler died. With the default
handler this is C<Clay error: ...>, for example when two widgets have
the same C<id>
(C<Clay error: An element with this ID was already previously declared during this layout.>).


=item *

The tree has more widgets than C<max_element_count> allows (default
error handler only):
C<Clay::UI: the widget tree has more elements than max_element_count (8192) allows: ...>.

=item *

The texts laid out in the frame have more words than
C<max_measure_text_cache_word_count> allows (default error handler
only):
C<Clay::UI: the texts laid out in one frame have more words than max_measure_text_cache_word_count (16384) allows; ...>.


=item *

The measure-text callback died: C<render> dies with its error.

=item *

A widget class produced settings Clay::XS rejects. Attributes are
validated when they are set, so this happens only when a widget class
builds settings of its own: a C<Clay::XS::StructError> (see
L<Clay::XS/STRUCT ERRORS>) such as
C<Clay_ElementDeclaration.layout.padding.left: expected an integer in 0..65535, got '-3'>,
a key collision between a widget class's own camelCase key and a
stored snake_case one (C<Clay::UI: key '...' camelizes to ...>), or
C<Clay::UI: widget ... set user_data in its config> (see L</NOTES>).


=back

When a listener error and a layout error happen in the same frame,
C<render> dies with the listener error and appends
C<(the layout pass also failed: ...)> to it (when the error is a
string).


After any of these, Clay stays usable and the next C<render> works
once the cause is fixed. Which frame counts as the last completed frame
depends on the case:

=over 4

=item *

After a bad argument, a nested C<render> or a failed layout pass (a
Clay error, too many widgets, a dying measure-text callback, rejected
settings), the last completed frame is unchanged.

=item *

After a listener error or a preparation error (a dying
C<prepare_layout>, or the 100 rounds) without a layout error,
the layout pass completed: that frame becomes the last completed frame
for L</widget_for>, L</bounding_box>, L</scroll_state> and the next
frame's pointer test, even though its render commands were discarded.

=back

=head2 widget_for

	my $widget = $ui->widget_for($command->{userData});

Returns the widget that produced a render command, given the command's
C<userData>. Returns C<undef> when C<$user_data> is undef, 0 or unknown,
or when the widget has been freed since. Lookups use the last completed
frame. Not every command has a widget: Clay gives C<SCISSOR_END>
commands a C<userData> of 0, so C<widget_for> returns C<undef> for them.

	for my $command (@$commands) {
		my $widget = $ui->widget_for($command->{userData}) or next;
		# choose how to draw by ref($widget), read its attributes, ...
	}

=head2 laid_out_revision

	my $shown = $ui->laid_out_revision;

Returns the revision (L<Clay::UI::Revision>) at which the last
C<render> started its layout pass, or C<undef> before the first
C<render>. Every change up to that revision, including the changes the
frame's listeners and preparations made, is part of that frame. A
renderer that skips unchanged frames remembers this value when it
draws a frame, and after each later C<render> draws again only when
C<laid_out_revision> differs from the remembered value:

	my $drawn;    # the laid_out_revision of the last frame drawn

	my $commands = $ui->render(%input);
	if (!defined $drawn || $drawn != $ui->laid_out_revision) {
		draw($commands);
		$drawn = $ui->laid_out_revision;
	}

A running transition (L<Clay::Manual/TRANSITIONS>) counts as a change
too: every frame that animates an element moves the revision, so the
loop above redraws until the animation is over.

=head2 bounding_box

	my $box = $ui->bounding_box($widget);    # { x, y, width, height } or undef

Returns where the last completed frame placed an element widget, as a
new hashref with C<x>, C<y>, C<width> and C<height> in layout units (the
same numbers as the C<boundingBox> of its render commands). Scrolling is
included, so a widget scrolled out of view lies outside its scroll
container. Returns C<undef> for a widget that frame did not lay out (one
added since, one removed, a text widget, or a widget of another UI).

Text widgets have no bounding box of their own: use the C<boundingBox>
of their C<TEXT> render commands (L</widget_for> maps each command back
to its text widget).

The box is the size Clay gave the widget, which can be smaller than
its sizing asks for: when the children of a parent do not fit into
it, Clay shrinks them, down to their minimum size, and
C<bounding_box> reports the shrunk size. A parent that clips an axis
(a scroll container scrolling that way) does not shrink its children
along that axis.

Dies when C<$widget> is not an object: C<Clay::UI: expected a widget, got ...>.

=head2 scroll_state

	my $state = $ui->scroll_state($scroll_box);
	# { position => { x, y }, viewport => { width, height }, content => { width, height } }

Returns the scroll data of a scroll container (a widget composing
L<Clay::UI::Role::Layout::HasScroll>) as a new hashref:

=over 4

=item position

Clay's scroll position: C<0> at the top and left, negative when the
content is scrolled down or right. Reflects every scroll since the last
frame, including L</scroll_to>.

=item viewport

The size of the visible area.

=item content

The size of everything inside the container.

=back

Returns C<undef> when the last completed frame did not lay the
container out. Dies for anything that is not a scroll container:
C<Clay::UI: ... is not a scroll container (it does not compose Clay::UI::Role::Layout::HasScroll)>.

During the layout pass (from a C<contribute_> method, say) it returns
the same: the position as this frame lays it out (the wheel, drag and
momentum scrolling of the frame applied) and the viewport and content
of the last completed frame.

=head2 scroll_to

	$ui->scroll_to($scroll_box, { y => -12 });         # 12 units down
	$ui->scroll_to($scroll_box, { x => 0, y => 0 });   # back to the top left

Moves a scroll container to a scroll position (in the sense of
C<position> under L</scroll_state>). Each axis is clamped to the range
from C<0> down to C<viewport - content> (or C<0> when the content fits);
an axis left out keeps its position. Returns the position as Clay now
holds it, a new hashref C<< { x => ..., y => ... } >> (Clay keeps
single-precision floats, so a large position may come back rounded),
or C<undef> when the last completed frame did not lay the container out
(then nothing moves). The
next C<render> shows the new position. The move counts as a change for
L<Clay::UI::Revision>. It fires no C<OnScroll> (that event reports only the
scrolling Clay does inside C<render>), and it stops momentum: a glide
started by drag scrolling ends at the new position. A position equal to
the current one still ends a glide and counts as a change for the
revision; it does not prepare the container (see below).

A container that composes L<Clay::UI::Role::Core::Preparable> is
prepared before the next layout pass when its position changed (its
C<request_prepare> is called), so a container that builds its children
for the position it shows can follow a move made from code, or from a
listener in the same frame.

Dies with
C<Clay::UI: scroll_to needs a position { x =E<gt> ..., y =E<gt> ... }>,
C<Clay::UI: scroll_to got unknown position key(s)>,
C<Clay::UI: scroll_to position 'y' must be a finite number>, and for a
widget that is not a scroll container (as L</scroll_state>).


=head2 interaction

	my $interaction = $ui->interaction;

Returns this UI's interaction tracker, a L<Clay::UI::Interaction>. It
holds the hovered, armed, pressed and focused widgets and fires the
pointer and focus events. Common uses:

	# widgets under the pointer at the last frame
	my $widgets = $ui->interaction->under_pointer;
	$ui->interaction->set_focused_widget($input);    # move the focus
	$ui->interaction->focus_next;                    # Tab
	$ui->interaction->update(over => [$button], down => 1);   # synthetic input

=head1 EVENTS

C<render> fires the pointer events below at widgets; focus events come
from the focus methods of L<Clay::UI::Interaction>. Listen with C<<
$widget->on($name, sub ($event) { ... }) >>
(L<Clay::UI::Role::Events::Listener>). An event that I<bubbles> is then
offered to the widget's parent, its parent's parent and so on, as its
bubble mode allows (L<Clay::UI::Enum::Bubble>). With C<IF_CONTINUE>, an
ancestor sees the event only when every listener of the widget below
returned C<< Clay::UI::Enum::Result->CONTINUE >> (or the widget has no
listener for it).

B<A listener that returns nothing stops the event.> An empty C<return>,
C<undef>, or the value of the last statement (such as the return value
of C<say>) all count as C<< Clay::UI::Enum::Result->HANDLED >>; only
C<CONTINUE> lets the event bubble on (L<Clay::UI::Enum::Result>):

	$button->on('OnPress', sub ($event) {
		highlight($event->current_target);
		return Clay::UI::Enum::Result->CONTINUE;    # the card around the button sees it too
	});

=head2 OnHoverStart

Fires at a L<Clay::UI::Role::Interaction::Hoverable> widget in the frame
it comes under the pointer. Does not bubble: every hovered widget,
nested ones included, gets its own event. See
L<Clay::UI::Events::OnHoverStart>.

=head2 OnHoverStopped

Fires at a hovered widget in the frame it is no longer under the
pointer, and at once, during the removal, when a hovered widget is
removed from the tree. Does not bubble. See
L<Clay::UI::Events::OnHoverStopped>.

=head2 OnPress

Fires when the pointer goes down, at exactly one
L<Clay::UI::Role::Interaction::Pressable>: the enabled Pressable under
the pointer that is drawn on top. A button inside a pressable card gets
it, not the card; of two overlapping siblings (such as the children of
a C<CLAY_BACK_TO_FRONT> container) the later one gets it; a Pressable
in a floating element beats every Pressable below that element. Every
enabled Pressable under the pointer becomes I<armed>. Bubbles with
C<IF_CONTINUE>. The precise rule is under
L<Clay::UI::Interaction/PRESS AND RELEASE>. See
L<Clay::UI::Events::OnPress>.

=head2 OnRelease

Fires when the pointer goes up, at the topmost I<armed> Pressable still
under the pointer, chosen like the target of C<OnPress>: a completed
click. Every release disarms all Pressables, so a press that started
elsewhere, or one dragged off every armed widget, ends without
C<OnRelease>. Bubbles with C<IF_CONTINUE>. See
L<Clay::UI::Events::OnRelease>.

A Pressable is I<pressed> (C<is_pressed>, the derived C<pressed> state)
while it is armed, enabled and under the pointer and the button is
down.

=head2 OnScroll

Fires at a scroll container (L<Clay::UI::Role::Layout::HasScroll>)
whose scroll position changed in this frame through wheel input, drag
scrolling or the momentum that follows drag scrolling; C<delta_x> and C<delta_y> say how far. Such a
change also bumps the revision. Bubbles with C<IF_CONTINUE>. See
L<Clay::UI::Events::OnScroll>.

=head2 OnFocus

Fires at a L<Clay::UI::Role::Interaction::Focusable> that receives the
focus through C<set_focused_widget>, C<focus_next> or
C<focus_previous>. C<render> never moves the focus. Bubbles with
C<IF_CONTINUE>. See L<Clay::UI::Events::OnFocus>.

=head2 OnBlur

Fires at the widget that loses the focus: when the focus moves
elsewhere or is cleared, when the focused widget is removed from the
tree, is disabled, or cannot take the focus any more. Bubbles with
C<IF_CONTINUE>. See L<Clay::UI::Events::OnBlur>.

=head1 CLAY CONTEXTS

Clay has one I<current> context per process. Every method of
Clay::UI that talks to Clay (C<new>, C<render>, the C<width>,
C<height> and C<measure_text> writers, C<bounding_box>,
C<scroll_state>, C<scroll_to>) first makes this UI's context current
and leaves it current. Several Clay::UI objects can coexist; code that
mixes Clay::UI with direct L<Clay::XS> calls must set the context it
needs with C<Clay_SetCurrentContext> before its own calls.

=head1 NOTES

=over 4

=item Back-references in render commands

The layout pass sets each element's C<userData> to a number that
identifies its widget, so L</widget_for> can map a render command back
to the widget. A widget class must therefore not set C<user_data> (or
C<userData>) in its settings; C<render> dies with
C<Clay::UI: widget ... set user_data in its config> if one does.


=item Scroll containers

For a scroll container without an explicit C<child_offset>, the layout
pass sets Clay's C<childOffset> to the container's current scroll
offset, so its children follow the scroll position. A C<clip> setting
from any other widget clips, but does not scroll.

=item Widgets without an id

A widget without an C<id> gets one derived from its position below the
nearest ancestor that has one; see
L<Clay::UI::Role::Core::Element/resolve_id>. User ids must not start
with C<anon:>.

=item Lifetime

The lookup tables behind L</widget_for> and the interaction tracker
hold widgets weakly. The Clay::UI object keeps its root widget, and so
the whole tree, alive. The tracker and the widgets refer to the
Clay::UI weakly; the methods of L<Clay::UI::Interaction> that need it
die once it is gone.

=item Revision

Every setter that changes what a frame lays out or draws bumps the
process-wide revision (L<Clay::UI::Revision>): widget attributes,
children, user states, this object's C<width>, C<height> and
C<measure_text>, and the hovered, armed, pressed and focused widgets.
Reading never bumps it. Widget classes that keep state of their own
call C<mark_changed> (L<Clay::UI::Role::Core::Element/mark_changed>).

=back

=head1 SEE ALSO

L<Clay::Manual> (user guide), L<Clay::Cookbook> (recipes),
L<Clay::UI::Interaction>, L<Clay::UI::Revision>, L<Clay::UI::Box>,
L<Clay::UI::Text>, L<Clay::UI::Grid>,
L<Clay::UI::Role::Core::Element>, L<Clay::XS>, L<Clay::XS::Structs>.

=head1 LICENSE

Released under the same zlib/libpng license as Clay itself. See
F<src/clay/LICENSE.md> for the upstream notice.

=cut

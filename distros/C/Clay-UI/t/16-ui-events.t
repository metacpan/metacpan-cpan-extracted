use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";

use Clay::UI::Test::Box;
use Clay::UI::Test::Text;
use Clay::UI::Enum::Bubble;
use Clay::UI::Enum::Result;
use Clay::UI::Events::Event;
use Clay::UI::Events::OnHoverStart;
use Clay::UI::Events::OnHoverStopped;
use Clay::UI::Events::OnPress;
use Clay::UI::Events::OnRelease;
use Clay::UI::Events::OnScroll;

my $HANDLED     = Clay::UI::Enum::Result->HANDLED;
my $CONTINUE    = Clay::UI::Enum::Result->CONTINUE;
my $ALWAYS      = Clay::UI::Enum::Bubble->ALWAYS;
my $IF_CONTINUE = Clay::UI::Enum::Bubble->IF_CONTINUE;
my $NEVER       = Clay::UI::Enum::Bubble->NEVER;

# -----------------------------------------------------------------------------
# Constants are singleton objects and compare with ==.
# -----------------------------------------------------------------------------

subtest 'constants are singletons' => sub {
	ok( $HANDLED == Clay::UI::Enum::Result->HANDLED,  'HANDLED is a singleton' );
	ok( $CONTINUE == Clay::UI::Enum::Result->CONTINUE,'CONTINUE is a singleton' );
	ok( $HANDLED != $CONTINUE,                          'HANDLED and CONTINUE distinguishable' );
	ok( $ALWAYS != $NEVER,                              'bubble singletons distinguishable' );
};

# -----------------------------------------------------------------------------
# Subclass event_name defaulting.
# -----------------------------------------------------------------------------

subtest 'event_name default propagates to name' => sub {
	is( Clay::UI::Events::OnHoverStart  ->new->name, 'OnHoverStart',  'OnHoverStart defaults name' );
	is( Clay::UI::Events::OnHoverStopped->new->name, 'OnHoverStopped','OnHoverStopped defaults name' );
	is( Clay::UI::Events::OnPress       ->new->name, 'OnPress',       'OnPress defaults name' );
	is( Clay::UI::Events::OnRelease     ->new->name, 'OnRelease',     'OnRelease defaults name' );
	is( Clay::UI::Events::OnScroll      ->new->name, 'OnScroll',      'OnScroll defaults name' );

	is(
		Clay::UI::Events::OnPress->new(name => 'Custom')->name,
		'Custom',
		'caller-provided name overrides default',
	);
};

# -----------------------------------------------------------------------------
# Basic handler registration + target / current_target.
# -----------------------------------------------------------------------------

subtest 'handler fires with target == current_target on the firer' => sub {
	my $box = Clay::UI::Test::Box->new( id => 'b' );
	my @calls;
	$box->on('OnPress', sub ($e) {
		push @calls, { target => $e->target, current => $e->current_target };
	});

	$box->fire_event(Clay::UI::Events::OnPress->new(x => 5, y => 7));

	is( scalar(@calls), 1, 'handler invoked once' );
	is( $calls[0]{target},  $box, 'target is firer' );
	is( $calls[0]{current}, $box, 'current_target == target on no-bubble path' );
};

# -----------------------------------------------------------------------------
# Bubble: ALWAYS walks every ancestor regardless of return.
# -----------------------------------------------------------------------------

subtest 'ALWAYS visits every ancestor' => sub {
	my $leaf  = Clay::UI::Test::Box->new( id => 'leaf' );
	my $mid   = Clay::UI::Test::Box->new( id => 'mid'  );
	$mid->add_child($leaf);
	my $root  = Clay::UI::Test::Box->new( id => 'root' );
	$root->add_child($mid);

	my @hit_ids;
	$_->on('Ping', sub ($e) { push @hit_ids, $e->current_target->id; return $HANDLED })
		for $leaf, $mid, $root;

	$leaf->fire_event(
		Clay::UI::Events::Event->new(name => 'Ping', bubble_mode => $ALWAYS),
	);

	is( \@hit_ids, [ 'leaf', 'mid', 'root' ], 'all three handlers fired in bubble order' );
};

# -----------------------------------------------------------------------------
# Bubble: IF_CONTINUE stops on undef / HANDLED.
# -----------------------------------------------------------------------------

subtest 'all handlers on the firing node fire even when one returns HANDLED' => sub {
	# Per-node, not per-handler: a sibling returning HANDLED must not skip
	# later handlers at the SAME node. The stop decision applies at the
	# node boundary, after the handler list is exhausted.
	my $leaf = Clay::UI::Test::Box->new( id => 'leaf' );
	my $root = Clay::UI::Test::Box->new( id => 'root' );
	$root->add_child($leaf);

	my @order;
	$leaf->on('Ping', sub ($e) { push @order, 'leaf-1'; return $CONTINUE });
	$leaf->on('Ping', sub ($e) { push @order, 'leaf-2'; return $HANDLED });
	$leaf->on('Ping', sub ($e) { push @order, 'leaf-3'; return $CONTINUE });
	$root->on('Ping', sub ($e) { push @order, 'root'   });

	$leaf->fire_event(
		Clay::UI::Events::Event->new(name => 'Ping', bubble_mode => $IF_CONTINUE),
	);

	is(
		\@order,
		[ 'leaf-1', 'leaf-2', 'leaf-3' ],
		'all three leaf handlers ran in order; bubble stopped before root',
	);
};

subtest 'IF_CONTINUE stops on HANDLED' => sub {
	my $leaf  = Clay::UI::Test::Box->new( id => 'leaf' );
	my $mid   = Clay::UI::Test::Box->new( id => 'mid'  );
	$mid->add_child($leaf);
	my $root  = Clay::UI::Test::Box->new( id => 'root' );
	$root->add_child($mid);

	my @hit_ids;
	$leaf->on('Ping', sub ($e) { push @hit_ids, 'leaf'; return $CONTINUE });
	$mid ->on('Ping', sub ($e) { push @hit_ids, 'mid';  return $HANDLED });
	$root->on('Ping', sub ($e) { push @hit_ids, 'root'; return $CONTINUE });

	$leaf->fire_event(
		Clay::UI::Events::Event->new(name => 'Ping', bubble_mode => $IF_CONTINUE),
	);

	is( \@hit_ids, [ 'leaf', 'mid' ], 'bubble stops once mid returns HANDLED' );
};

subtest 'IF_CONTINUE: undef return halts as HANDLED' => sub {
	my $leaf = Clay::UI::Test::Box->new( id => 'leaf' );
	my $root = Clay::UI::Test::Box->new( id => 'root' );
	$root->add_child($leaf);

	my @hits;
	$leaf->on('Ping', sub ($e) { push @hits, 'leaf'; return });  # undef
	$root->on('Ping', sub ($e) { push @hits, 'root' });

	$leaf->fire_event(Clay::UI::Events::Event->new(name => 'Ping'));  # default IF_CONTINUE

	is( \@hits, [ 'leaf' ], 'undef return halts bubbling' );
};

# -----------------------------------------------------------------------------
# fire_event reports the outcome, and the event records who handled it.
# -----------------------------------------------------------------------------

subtest 'fire_event returns the outcome' => sub {
	my $leaf = Clay::UI::Test::Box->new( id => 'leaf' );
	my $mid  = Clay::UI::Test::Box->new( id => 'mid' );
	my $root = Clay::UI::Test::Box->new( id => 'root' );
	$root->add_child($mid);
	$mid->add_child($leaf);

	my $unhandled = Clay::UI::Events::Event->new(name => 'Ping');
	ok( $leaf->fire_event($unhandled) == $CONTINUE, 'CONTINUE without any handler' );
	is( $unhandled->handled_by, undef,              'nothing handled it' );
	ok( $unhandled->result == $CONTINUE,            'the event reports CONTINUE too' );

	$leaf->on('Ping', sub ($e) { return $CONTINUE });
	$mid->on('Ping',  sub ($e) { return $HANDLED });
	$root->on('Ping', sub ($e) { return $HANDLED });

	my $handled = Clay::UI::Events::Event->new(name => 'Ping');
	ok( $leaf->fire_event($handled) == $HANDLED, 'HANDLED once a node stops the walk' );
	is( $handled->handled_by->id, 'mid',          'handled_by is the node that stopped it' );
	ok( $handled->result == $HANDLED,             'the event reports HANDLED too' );

	my $always = Clay::UI::Events::Event->new(name => 'Ping', bubble_mode => $ALWAYS);
	ok( $leaf->fire_event($always) == $HANDLED, 'HANDLED under ALWAYS as well' );
	is( $always->handled_by->id, 'mid',          'handled_by is the first handling node' );

	my $never = Clay::UI::Events::Event->new(name => 'Ping', bubble_mode => $NEVER);
	ok( $leaf->fire_event($never) == $CONTINUE, 'CONTINUE when the only node continues' );
	is( $never->handled_by, undef,              'nothing handled it' );
};

# -----------------------------------------------------------------------------
# Bubble: NEVER never reaches ancestors.
# -----------------------------------------------------------------------------

subtest 'NEVER stays on firer' => sub {
	my $leaf = Clay::UI::Test::Box->new( id => 'leaf' );
	my $root = Clay::UI::Test::Box->new( id => 'root' );
	$root->add_child($leaf);

	my @hits;
	$leaf->on('Ping', sub ($e) { push @hits, 'leaf'; return $CONTINUE });
	$root->on('Ping', sub ($e) { push @hits, 'root' });

	$leaf->fire_event(
		Clay::UI::Events::Event->new(name => 'Ping', bubble_mode => $NEVER),
	);

	is( \@hits, [ 'leaf' ], 'ancestor handler never fired' );
};

# -----------------------------------------------------------------------------
# current_target tracks bubble cursor; target stays the firer.
# -----------------------------------------------------------------------------

subtest 'current_target updates per hop; target is immutable' => sub {
	my $leaf = Clay::UI::Test::Box->new( id => 'leaf' );
	my $root = Clay::UI::Test::Box->new( id => 'root' );
	$root->add_child($leaf);

	my @observations;
	$leaf->on('Ping', sub ($e) {
		push @observations, [ $e->target->id, $e->current_target->id ];
		return $CONTINUE;
	});
	$root->on('Ping', sub ($e) {
		push @observations, [ $e->target->id, $e->current_target->id ];
		return $CONTINUE;
	});

	$leaf->fire_event(
		Clay::UI::Events::Event->new(name => 'Ping', bubble_mode => $ALWAYS),
	);

	is( \@observations, [ [ 'leaf', 'leaf' ], [ 'leaf', 'root' ] ],
	    'target stays at firer; current_target follows bubble cursor' );
};

# -----------------------------------------------------------------------------
# Re-firing the same event object is forbidden.
# -----------------------------------------------------------------------------

subtest 'event objects are single-use' => sub {
	my $box = Clay::UI::Test::Box->new;
	my $event = Clay::UI::Events::OnPress->new;

	$box->fire_event($event);

	like(
		dies { $box->fire_event($event) },
		qr/already dispatched/,
		're-firing the same event dies',
	);
};

# -----------------------------------------------------------------------------
# Multiple handlers on the same name fire in registration order.
# -----------------------------------------------------------------------------

subtest 'multiple handlers fire in registration order' => sub {
	my $box = Clay::UI::Test::Box->new;
	my @order;
	$box->on('Ping', sub { push @order, 'first' });
	$box->on('Ping', sub { push @order, 'second' });
	$box->on('Ping', sub { push @order, 'third' });

	$box->fire_event(Clay::UI::Events::Event->new(name => 'Ping'));

	is( \@order, [ 'first', 'second', 'third' ], 'registration order preserved' );
};

# -----------------------------------------------------------------------------
# Validation: bad inputs fail loud.
# -----------------------------------------------------------------------------

subtest 'on() rejects bad inputs' => sub {
	my $box = Clay::UI::Test::Box->new;
	like( dies { $box->on('', sub { }) },        qr/non-empty string/, 'empty event name' );
	like( dies { $box->on('X', 'nope') },        qr/coderef/,          'non-coderef handler' );
};

subtest 'fire_event() rejects non-event arg' => sub {
	my $box = Clay::UI::Test::Box->new;
	like( dies { $box->fire_event("not an event") }, qr/Clay::UI::Events::Event/,
	      'fire_event rejects non-event' );
};

# -----------------------------------------------------------------------------
# Every widget can listen; only emitters can fire.
# -----------------------------------------------------------------------------

subtest 'Listener/Emitter split: Text listens, Box emits' => sub {
	# The Listener half is composed into every widget (Text included);
	# the Emitter half only into widgets that originate events (Box).
	# A Text leaf has on() but no fire_event; an event a Box fires bubbles
	# to the listeners of its ancestors.
	my $inner = Clay::UI::Test::Box->new(id => 'inner');
	my $outer = Clay::UI::Test::Box->new(id => 'outer');
	$outer->add_child($inner);
	my $text  = Clay::UI::Test::Text->new(text => 'hi');

	ok( $inner->can('fire_event'), 'Box exposes fire_event' );
	ok(!$text->can('fire_event'),  'Text does NOT expose fire_event' );
	ok( $text->can('on'),          'Text exposes on() (Listener half)' );

	my @hits;
	$outer->on('Ping', sub ($e) { push @hits, 'outer' });
	$inner->fire_event(
		Clay::UI::Events::Event->new(name => 'Ping', bubble_mode => $ALWAYS),
	);
	is( \@hits, [ 'outer' ], 'event from inner Box reached listener on outer Box' );
};

done_testing;

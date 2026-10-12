use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Object::Pad;
use Clay::UI::Role::Core::Element;
use Clay::UI::Role::Style::HasStates;

class TestStatesWidget :does(Clay::UI::Role::Core::Element)
                       :does(Clay::UI::Role::Style::HasStates)
{}

subtest 'fresh widget has no states' => sub {
	my $w = TestStatesWidget->new;
	is( [ $w->states ], [], 'states() returns empty list' );
	ok( !$w->has_state('selected'), 'has_state is false for arbitrary name' );
};

subtest 'add_state and has_state' => sub {
	my $w = TestStatesWidget->new;
	$w->add_state('selected');
	ok( $w->has_state('selected'), 'state is now active' );
	ok( !$w->has_state('loading'), 'other states stay inactive' );
};

subtest 'add_state is idempotent and dedupes' => sub {
	my $w = TestStatesWidget->new;
	$w->add_state('selected');
	$w->add_state('selected');
	$w->add_state('selected');
	is( [ sort $w->states ], ['selected'], 'duplicate adds collapse to one entry' );
};

subtest 'remove_state' => sub {
	my $w = TestStatesWidget->new;
	$w->add_state('loading');
	$w->remove_state('loading');
	ok( !$w->has_state('loading'), 'state is gone after remove' );
};

subtest 'remove_state is idempotent on absent names' => sub {
	my $w = TestStatesWidget->new;
	ok( lives { $w->remove_state('never-added') }, 'remove of absent state does not die' );
	is( [ $w->states ], [], 'states still empty' );
};

subtest 'toggle_state flips presence' => sub {
	my $w = TestStatesWidget->new;
	$w->toggle_state('open');
	ok( $w->has_state('open'), 'toggle adds when absent' );
	$w->toggle_state('open');
	ok( !$w->has_state('open'), 'toggle removes when present' );
};

subtest 'clear_states empties the set' => sub {
	my $w = TestStatesWidget->new;
	$w->add_state('a');
	$w->add_state('b');
	$w->add_state('c');
	$w->clear_states;
	is( [ $w->states ], [], 'all states cleared' );
};

subtest 'states() returns active names' => sub {
	my $w = TestStatesWidget->new;
	$w->add_state('selected');
	$w->add_state('active');
	is( [ sort $w->states ], ['active', 'selected'], 'states() lists active names' );
	is( scalar $w->states, 2, 'in scalar context it counts them' );
};

subtest 'state names must be non-empty strings' => sub {
	my $w = TestStatesWidget->new;
	for my $mutator (qw(add_state remove_state toggle_state)) {
		like( dies { $w->$mutator(undef) }, qr/a state name must be a non-empty string/, "$mutator(undef) dies" );
		like( dies { $w->$mutator('') },    qr/a state name must be a non-empty string/, "$mutator('') dies" );
		like( dies { $w->$mutator([]) },    qr/a state name must be a non-empty string/, "$mutator([]) dies" );
	}
	is( [ $w->states ], [], 'nothing was stored' );
};

subtest 'mutators chain via returned $self' => sub {
	my $w = TestStatesWidget->new;
	$w->add_state('a')->add_state('b')->toggle_state('a')->add_state('c');
	is( [ sort $w->states ], ['b', 'c'], 'chained mutations apply in order' );
};

subtest 'state names are free-form strings' => sub {
	my $w = TestStatesWidget->new;
	$w->add_state('with spaces');
	$w->add_state('UPPER:case-123');
	ok( $w->has_state('with spaces'),    'space-bearing name works' );
	ok( $w->has_state('UPPER:case-123'), 'mixed-case/punctuation name works' );
};

subtest 'state-sets are per-instance' => sub {
	my $w1 = TestStatesWidget->new;
	my $w2 = TestStatesWidget->new;
	$w1->add_state('selected');
	ok( $w1->has_state('selected'),  'w1 has selected' );
	ok( !$w2->has_state('selected'), 'w2 does not bleed state from w1' );
};

subtest 'derived state names are read-only' => sub {
	my $w = TestStatesWidget->new;
	for my $name (qw(hovered pressed focused disabled)) {
		for my $mutator (qw(add_state remove_state toggle_state)) {
			like( dies { $w->$mutator($name) }, qr/state '$name' is derived and cannot be set/,
				"$mutator('$name') dies" );
		}
		ok( !$w->has_state($name), "$name is false without the matching role" );
	}
};

done_testing;

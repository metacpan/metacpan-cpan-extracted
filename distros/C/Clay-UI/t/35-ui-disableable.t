use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";
use Scalar::Util qw(refaddr);

use Object::Pad 0.800;

use Clay::UI;
use Clay::UI::Revision qw(current_revision);
use Clay::UI::Test::Box;
use Clay::UI::Role::Core::Element;
use Clay::UI::Role::Interaction::Disableable;
use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Role::Interaction::Pressable;

class TestButton
	:does(Clay::UI::Role::Core::Element)
	:does(Clay::UI::Role::Interaction::Focusable)
	:does(Clay::UI::Role::Interaction::Pressable)
	:does(Clay::UI::Role::Interaction::Disableable)
{}

# A subclass whose widgets never take the focus themselves.
class TestGroupMember :isa(TestButton) {
	method accepts_focus :override () { return 0 }
}

# A pressable container, for buttons inside a clickable card.
class TestCard
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::Pressable)
{}

sub make_ui (@children) {
	my $root = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child(@children);
	return Clay::UI->new(root => $root, width => 100, height => 100);
}

sub same ($got, $expected, $name) { is( refaddr($got // 0), refaddr($expected // 0), $name ) }

subtest 'disabled and is_enabled' => sub {
	my $button = TestButton->new(id => 'a', disabled => 'yes');
	is( [ $button->disabled, $button->is_enabled ], [ 1, 0 ], 'any true value disables; stored as 1' );
	my $before = current_revision();
	is( $button->disabled(0), 0, 'a write returns the new value' );
	ok( current_revision() > $before, 'and bumps the revision' );
	$before = current_revision();
	$button->disabled(0);
	is( current_revision(), $before, 'writing the same value does not' );
	like( dies { $button->disabled([]) }, qr/'disabled' must be a plain boolean value/, 'a reference dies' );
	like( dies { TestButton->new(id => 'b', disabled => {}) }, qr/'disabled' must be a plain boolean value/, 'also at construction' );
	like( dies { $button->disabled(1, 2) }, qr/'disabled' takes one value/, 'one value only' );
};

subtest 'a disabled widget cannot take the focus' => sub {
	my @buttons = map { TestButton->new(id => $_) } qw(a b c);
	my $ui = make_ui(@buttons);
	my @log;
	$buttons[1]->on('OnBlur', sub ($e) { push @log, 'b:blur'; return });
	$ui->interaction->set_focused_widget($buttons[1]);
	$buttons[1]->disabled(1);
	is( [ \@log, $ui->interaction->get_focused_widget ], [ ['b:blur'], undef ], 'disabling the focused widget blurs it at once' );
	ok( !$buttons[1]->can_focus, 'it cannot take the focus' );
	like( dies { $ui->interaction->set_focused_widget($buttons[1]) }, qr/not currently focusable/, 'set_focused_widget rejects it' );

	$ui->interaction->set_focused_widget($buttons[0]);
	$ui->interaction->focus_next;
	same( $ui->interaction->get_focused_widget, $buttons[2], 'Tab skips it' );
	ok( $buttons[1]->has_state('disabled') && !$buttons[0]->has_state('disabled'), 'disabled is a derived state' );
	like( dies { $buttons[0]->add_state('disabled') }, qr/state 'disabled' is derived and cannot be set/, 'that cannot be set' );
};

subtest 'can_focus keeps the wish' => sub {
	my $button = TestButton->new(id => 'a');
	$button->disabled(1);
	is( $button->can_focus(1), 0, 'can_focus(1) while disabled returns 0' );
	$button->disabled(0);
	is( $button->can_focus, 1, 'and counts once the widget is enabled' );

	my $unwanted = TestButton->new(id => 'b', can_focus => 0, disabled => 1);
	$unwanted->disabled(0);
	is( $unwanted->can_focus, 0, 'can_focus => 0 at construction stays 0 after enabling' );
	$unwanted->disabled(1);
	$unwanted->disabled(0);
	is( $unwanted->can_focus, 0, 'through any number of cycles' );

	my $member = TestGroupMember->new(id => 'c');
	is( [ $member->can_focus, $member->can_focus(1) ], [ 0, 0 ], 'a subclass that does not accept the focus never has it' );
};

subtest 'a disabled widget is never armed or pressed' => sub {
	my $button = TestButton->new(id => 'a');
	my $ui     = make_ui($button);
	my @log;
	$button->on($_, sub ($e) { push @log, $e->name; return }) foreach qw(OnPress OnRelease);
	my $tracker = $ui->interaction;

	$button->disabled(1);
	$tracker->update(over => [$button], down => 1);
	is( [ $tracker->is_armed($button), $button->is_pressed, $button->is_hovered ], [ 0, 0, 1 ], 'a press arms nothing; it is still hovered' );
	$tracker->update(over => [$button], down => 0);
	is( \@log, [], 'no OnPress, no OnRelease' );

	$button->disabled(0);
	$tracker->update(over => [$button], down => 1);
	ok( $button->is_pressed, 'enabled again, it is pressed' );
	$button->disabled(1);
	is( [ $tracker->is_armed($button), $button->is_pressed ], [ 0, 0 ], 'disabling it disarms it at once' );
	$tracker->update(over => [$button], down => 0);
	is( \@log, ['OnPress'], 'so the release fires no OnRelease' );
};

subtest 'a disabled button absorbs the click on its pressable card' => sub {
	my $card   = TestCard->new(id => 'card');
	my $button = TestButton->new(id => 'button', disabled => 1);
	$card->add_child($button);
	my $ui = make_ui($card);
	my @log;
	$card->on($_, sub ($e) { push @log, $e->name; return }) foreach qw(OnPress OnRelease);
	my $tracker = $ui->interaction;

	$tracker->update(over => [$card, $button], down => 1);
	is( [ $tracker->is_armed($card), $card->is_pressed, $card->is_hovered ], [ 0, 0, 1 ], 'the card is neither armed nor pressed' );
	$tracker->update(over => [$card, $button], down => 0);
	is( \@log, [], 'and gets no OnPress or OnRelease' );

	$tracker->update(over => [$card], down => 1);
	ok( $card->is_pressed, 'a press beside the button presses the card' );
	$tracker->update(over => [$card, $button], down => 1);
	ok( !$card->is_pressed, 'dragging onto the disabled button unpresses it' );
	$tracker->update(over => [$card, $button], down => 0);
	is( \@log, ['OnPress'], 'a release over the disabled button is no click' );
};

done_testing;

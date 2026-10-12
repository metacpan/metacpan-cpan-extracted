use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";

use Object::Pad;
use Scalar::Util qw(weaken);
use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Revision qw(current_revision);
use Clay::UI::Role::Core::Preparable;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Layout::HasScroll;
use Clay::UI::Test::Box;
use Clay::UI::Test::Text;

# A list whose labels follow its items; it counts its preparations.
class Clay::UI::Test::List :strict(params) :does(Clay::UI::Box) :does(Clay::UI::Role::Core::Preparable) {
	field @items;
	field $prepared :reader = 0;
	field $on_prepare :param = undef;

	method add_item ($item) {
		push @items, $item;
		return $self->request_prepare;
	}

	method prepare_layout () {
		$prepared++;
		$self->clear_children;
		$self->add_child( map { Clay::UI::Test::Text->new(text => $_) } @items );
		$on_prepare->($self) if $on_prepare;
		return;
	}
}

# A scroll container that prepares its children for the position it shows.
class Clay::UI::Test::ScrollList :strict(params)
	:does(Clay::UI::Role::Layout::HasScroll)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Core::Preparable)
{
	field $prepared :reader = 0;

	method prepare_layout () {
		$prepared++;
		return;
	}
}

# Logs its preparations to @prepared, by name.
our @prepared;
class Clay::UI::Test::Logged :strict(params) :does(Clay::UI::Box) :does(Clay::UI::Role::Core::Preparable) {
	field $name :param;
	field $on_prepare :param = undef;

	method prepare_layout () {
		push @main::prepared, $name;
		$on_prepare->($self) if $on_prepare;
		return;
	}
}

sub ui_with (@children) {
	my $root = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child(@children);
	return Clay::UI->new(root => $root, width => 100, height => 100, measure_text => sub { { width => length $_[0], height => 1 } });
}

sub texts ($commands) {
	return [ map { $_->{renderData}{stringContents} } grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$commands ];
}

subtest 'requests are prepared once, before the layout' => sub {
	my $list = Clay::UI::Test::List->new(id => 'list');
	my $ui   = ui_with($list);
	my $revision = current_revision();
	$list->add_item($_) for qw(a b c);
	ok( current_revision() > $revision, 'a request bumps the revision' );
	ok( $list->is_prepare_pending, 'the list is pending' );
	is( texts($ui->render), [qw(a b c)], 'the frame shows the prepared children' );
	is( $list->prepared, 1, 'three requests, one preparation' );
	ok( !$list->is_prepare_pending, 'nothing pending after it' );
	$ui->render;
	is( $list->prepared, 1, 'a frame without requests prepares nothing' );
};

subtest 'widgets of other UIs, or of none, stay pending' => sub {
	my $loose = Clay::UI::Test::List->new(id => 'loose');
	$loose->add_item('x');
	my $other = Clay::UI::Test::List->new(id => 'other');
	my $ui    = ui_with($other);
	$ui->render;
	is( $loose->prepared, 0, 'a widget outside the UI is not prepared' );
	ok( $loose->is_prepare_pending, 'and stays pending' );
	my $second = ui_with($loose);
	is( texts($second->render), ['x'], 'until a UI it belongs to renders' );
};

subtest 'a preparation may request another' => sub {
	my $count = 0;
	my $list  = Clay::UI::Test::List->new(id => 'chain', on_prepare => sub ($self) { $self->add_item('again') if ++$count < 3 });
	my $ui    = ui_with($list);
	$list->add_item('first');
	$ui->render;
	is( $list->prepared, 3, 'prepared until no request was left' );

	my $endless = Clay::UI::Test::List->new(id => 'endless', on_prepare => sub ($self) { $self->request_prepare });
	my $other   = ui_with($endless);
	$endless->request_prepare;
	like( dies { $other->render }, qr/kept requesting preparation/, 'endless requests die' );
};

subtest 'an error in prepare_layout leaves render after the layout pass' => sub {
	my $list = Clay::UI::Test::List->new(id => 'failing', on_prepare => sub { die "broken\n" });
	my $ui   = ui_with($list);
	$list->request_prepare;
	my $other = Clay::UI::Test::List->new(id => 'other');
	$ui->root->add_child($other);
	$other->request_prepare;
	like( dies { $ui->render }, qr/\Abroken/, 'render dies with the error' );
	is( [ $other->prepared, $other->is_prepare_pending ], [ 1, 0 ], 'the other widget of the round was still prepared' );
	ok( lives { $ui->render }, 'the next render works' );
};

subtest 'the queue holds widgets weakly' => sub {
	my $list = Clay::UI::Test::List->new(id => 'gone');
	$list->request_prepare;
	my $weak = $list;
	weaken $weak;
	undef $list;
	is( $weak, undef, 'a queued widget can be freed' );
	ok( lives { ui_with()->render }, 'and is forgotten' );
};

subtest 'a widget an earlier preparation detached stays queued' => sub {
	my $child  = Clay::UI::Test::Logged->new(name => 'child');
	my $parent = Clay::UI::Test::Logged->new(name => 'parent', on_prepare => sub ($self) { $self->clear_children });
	$parent->add_child($child);
	my $ui = ui_with($parent);
	@prepared = ();
	$child->request_prepare;
	$parent->request_prepare;
	$ui->render;
	is( \@prepared, ['parent'], 'the detached child is not prepared' );
	ok( $child->is_prepare_pending, 'and stays queued' );
	my $other = ui_with($child);
	$other->render;
	is( \@prepared, [ 'parent', 'child' ], 'until a UI it belongs to renders' );
};

subtest 'parents are prepared before their descendants' => sub {
	my $leaf   = Clay::UI::Test::Logged->new(name => 'leaf');
	my $middle = Clay::UI::Test::Logged->new(name => 'middle');
	my $top    = Clay::UI::Test::Logged->new(name => 'top');
	my $peer   = Clay::UI::Test::Logged->new(name => 'peer');
	$middle->add_child($leaf);
	$top->add_child($middle);
	my $ui = ui_with($top, $peer);
	@prepared = ();
	$_->request_prepare for $leaf, $peer, $middle, $top;
	$ui->render;
	is( \@prepared, [qw(peer top middle leaf)], 'by depth, and at one depth in the order they asked' );
};

subtest 'widgets freed while queued leave no entries' => sub {
	my $ui = ui_with();
	Clay::UI::Test::Logged->new(name => "loose $_")->request_prepare for 1 .. 20;
	$ui->render;
	is( Clay::UI::Role::Core::Preparable::_pending_count(), 0, 'the queue is empty after a render' );
};

subtest 'scroll_to prepares a scroll container that prepares itself' => sub {
	my $list = Clay::UI::Test::ScrollList->new(
		id     => 'scroll',
		layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(50), height => sizing_fixed(10) } },
	);
	$list->add_child( map { Clay::UI::Test::Text->new(text => "line $_") } 1 .. 100 );
	my $ui = ui_with($list);
	$ui->render;
	is( $list->prepared, 0, 'a container that never asked is not prepared' );
	is( $ui->scroll_to($list, { y => -5 }), { x => 0, y => -5 }, 'scroll_to moves the container' );
	ok( $list->is_prepare_pending, 'and queues its preparation' );
	$ui->render;
	is( [ $list->prepared, $ui->scroll_state($list)->{position}{y} ], [ 1, -5 ], 'the frame prepared it and shows the position' );
	$ui->scroll_to($list, { y => -5 });
	ok( !$list->is_prepare_pending, 'a move to the current position queues nothing' );
};

done_testing;

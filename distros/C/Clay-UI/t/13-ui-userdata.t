use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";

use Scalar::Util qw(refaddr);

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Test::Box;
use Clay::UI::Test::Text;

use Object::Pad;
use Clay::UI::Role::Core::Element;

class ConflictWidget :does(Clay::UI::Role::Core::Element) {
	method contribute_user ($cfg) {
		$cfg->{user_data} = 42;
	}
}

my @errors;
my $error_handler = sub ($err, $userdata) { push @errors, $err };
my $measure_text  = sub ($text, $config, $userdata) {
	return { width => length($text) * 8, height => 16 };
};

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
# Walker injects refaddr as user_data; render commands carry that back
# so callers can recover the originating widget by refaddr lookup.
# -----------------------------------------------------------------------------

subtest 'render commands carry refaddr in userData' => sub {
	@errors = ();

	my $child_box = Clay::UI::Test::Box->new(
		id               => 'child',
		layout           => { sizing => { width => sizing_fixed(80), height => sizing_fixed(40) } },
		background_color => [200, 100, 50, 255],
	);
	my $text_leaf = Clay::UI::Test::Text->new( text => 'hi', font_size => 16 );

	my $root = Clay::UI::Test::Box->new(
		id               => 'root',
		layout           => { sizing => { width => sizing_fixed(200), height => sizing_fixed(100) } },
		background_color => [40, 50, 60, 255],
	);
	$root->add_child($child_box, $text_leaf);

	my $ui   = make_ui($root);
	my $cmds = $ui->render;

	is( scalar(@errors), 0, 'no Clay errors' );

	my %widgets_seen;
	for my $cmd (@$cmds) {
		next unless $cmd->{userData};
		my $w = $ui->widget_for($cmd->{userData});
		next unless defined $w;
		$widgets_seen{ refaddr $w } = $w;
	}

	# Identity compare via refaddr: widgets reference their parents
	# (Clay::UI::Role::Layout::HasParent), a cycle that Test2's deep `is`
	# cannot traverse.
	is( refaddr $widgets_seen{ refaddr $root },      refaddr $root,      'root widget recovered' );
	is( refaddr $widgets_seen{ refaddr $child_box }, refaddr $child_box, 'child box recovered' );
	is( refaddr $widgets_seen{ refaddr $text_leaf }, refaddr $text_leaf, 'text leaf recovered' );

	is( $ui->widget_for(undef), undef, 'undef -> undef' );
	is( $ui->widget_for(0),     undef, '0 -> undef (Clay default for non-user elements)' );
	is( $ui->widget_for(999),   undef, 'unknown integer -> undef' );
};

# -----------------------------------------------------------------------------
# The interaction tracker reports the widget objects under the pointer.
# -----------------------------------------------------------------------------

subtest 'under_pointer returns widget objects' => sub {
	@errors = ();

	my $child_box = Clay::UI::Test::Box->new(
		id               => 'child',
		layout           => { sizing => { width => sizing_fixed(80), height => sizing_fixed(40) } },
		background_color => [200, 100, 50, 255],
	);
	my $root = Clay::UI::Test::Box->new(
		id       => 'root',
		layout   => { sizing => { width => sizing_fixed(200), height => sizing_fixed(100) } },
	);
	$root->add_child($child_box);

	my $ui = make_ui($root);
	$ui->render;  # the pointer is tested against the previous layout
	$ui->render( pointer_state => { x => 40, y => 20, down => 0 } );

	my $hovered = $ui->interaction->under_pointer;
	ok( scalar(@$hovered) >= 1, 'at least one hovered widget' );
	my %by_addr = map { refaddr($_) => $_ } @$hovered;
	ok( $by_addr{ refaddr $child_box }, 'child widget recovered via under_pointer' );
};

# -----------------------------------------------------------------------------
# A widget that sets user_data itself collides with the auto-injection.
# -----------------------------------------------------------------------------

subtest 'conflict on user-supplied user_data' => sub {
	my $ui = make_ui( ConflictWidget->new(id => 'x') );
	like(
		dies { $ui->render },
		qr/set user_data in its config/,
		'widget that sets user_data dies with a clear message',
	);
};

done_testing;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib 't/lib';

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Grid::Cell;
use Clay::UI::Events::OnPress;
use Clay::UI::Test::Box;
use Clay::UI::Test::Text;
use Clay::UI::Test::Grid;

use Object::Pad;
use Clay::UI::Role::Core::Stateful;
use Clay::UI::Role::Core::TextNode;
use Clay::UI::Role::Layout::HasScroll;
use Clay::UI::Role::Interaction::Hoverable;

class ScrollPanel :strict(params) :does(Clay::UI::Role::Layout::HasScroll) {}

# -----------------------------------------------------------------------------
# Input is validated where it enters Clay::UI: constructor parameters,
# render arguments and widget attributes.
# -----------------------------------------------------------------------------

sub make_ui ($root) {
	return Clay::UI->new(width => 100, height => 100, root => $root,
		measure_text => sub ($text, $config, $userdata) { return { width => 1, height => 1 } });
}

subtest 'misspelled constructor parameters die' => sub {
	like( dies { Clay::UI->new(width => 1, height => 1, root => Clay::UI::Test::Box->new, error_hanlder => sub { }) },
		qr/Unrecognised parameters for Clay::UI constructor: 'error_hanlder'/, 'Clay::UI' );
	like( dies { Clay::UI::Grid::Cell->new(bg_color => [1, 2, 3, 255]) },
		qr/Unrecognised parameters for Clay::UI::Grid::Cell constructor: 'bg_color'/, 'Grid::Cell' );
	like( dies { Clay::UI::Events::OnPress->new(bubble => 1) },
		qr/Unrecognised parameters for Clay::UI::Events::OnPress constructor: 'bubble'/, 'an event' );
	like( dies { Clay::UI::Test::Box->new(backgroud_color => [1, 2, 3, 255]) },
		qr/Unrecognised parameters for Clay::UI::Test::Box constructor: 'backgroud_color'/,
		'a consumer class declared :strict(params)' );
};

subtest 'accessor values are copies' => sub {
	my $color = [ 10, 20, 30, 255 ];
	my $box = Clay::UI::Test::Box->new(background_color => $color, layout => { child_gap => 4 });
	push @$color, 99;
	is( $box->background_color, [ 10, 20, 30, 255 ], 'changing the passed array does not change the widget' );
	$box->layout->{child_gap} = -5;
	is( $box->layout, { child_gap => 4 }, 'changing the returned hash does not either' );
	my $blessed = bless { r => 1, g => 2, b => 3, a => 255 }, 'Some::Colour';
	$box->background_color($blessed);
	$blessed->{r} = 999;
	is( $box->background_color, { r => 1, g => 2, b => 3, a => 255 }, 'a blessed hash is copied as plain data' );
};

subtest 'viewport sizes must be positive finite numbers' => sub {
	my $ui = make_ui(Clay::UI::Test::Box->new(id => 'root'));
	like( dies { $ui->width('inf') }, qr/width must be a positive finite number/, 'an infinite width dies' );
	like( dies { $ui->height('nan') }, qr/height must be a positive finite number/, 'a NaN height dies' );
	like( dies { $ui->width(10, 20) }, qr/width takes one value/, 'one value at a time' );
	is( [ $ui->width, $ui->height ], [ 100, 100 ], 'the size is unchanged' );
	ok( lives { $ui->height(50) }, 'a valid size still works' );
	like( dies { Clay::UI->new(width => 'inf', height => 1, root => Clay::UI::Test::Box->new) },
		qr/'width' and 'height' must be positive finite numbers/, 'also at construction' );
};

subtest 'a non-finite pointer dies in Clay::UI and is not remembered' => sub {
	my $ui = make_ui(Clay::UI::Test::Box->new(id => 'root'));
	$ui->render(pointer_state => { x => 1, y => 1 });
	like( dies { $ui->render(pointer_state => { x => 'nan', y => 2 }) }, qr/pointer_state 'x' must be a finite number/,
		'a NaN position dies' );
	like( dies { $ui->render(scroll_delta => [ 'inf', 0 ]) }, qr/'scroll_delta' must be/, 'so does an infinite delta' );
	ok( lives { $ui->render }, 'the next render reuses the last good pointer' );
};

subtest 'render arguments are validated' => sub {
	my $ui = make_ui(Clay::UI::Test::Box->new(id => 'root'));
	like( dies { $ui->render(pointer => {}) }, qr/unknown argument\(s\): pointer/, 'unknown argument' );
	like( dies { $ui->render(pointer_state => [1, 2]) }, qr/'pointer_state' must be a hashref/, 'pointer_state type' );
	like( dies { $ui->render(pointer_state => { x => 1, y => 2, pressed => 1 }) },
		qr/unknown pointer_state key\(s\): pressed/, 'unknown pointer_state key' );
	like( dies { $ui->render(pointer_state => { x => 'left', y => 2 }) },
		qr/pointer_state 'x' must be a finite number/, 'non-numeric pointer position' );
	like( dies { $ui->render(pointer_state => { x => 1, y => 2, down => {} }) },
		qr/pointer_state 'down' must be a plain boolean value/, 'reference as the down flag' );
	like( dies { $ui->render(delta_time => -1) }, qr/'delta_time' must be a finite number >= 0/, 'negative delta_time' );
	like( dies { $ui->render(scroll_delta => 5) }, qr/'scroll_delta' must be/, 'scalar scroll_delta' );
	like( dies { $ui->render(scroll_delta => { x => 0, yy => -1 }) }, qr/unknown scroll_delta key\(s\): yy/,
		'misspelled scroll_delta key' );
	like( dies { $ui->render(enable_drag_scrolling => {}) }, qr/'enable_drag_scrolling' must be a plain boolean/,
		'reference as a flag' );
	ok( lives { $ui->render(pointer_state => { x => 1, y => 2 }, scroll_delta => [0, -1], enable_drag_scrolling => 1) },
		'valid arguments are accepted' );
};

# -----------------------------------------------------------------------------
# Widget attributes: one invalid value per attribute dies at construction
# and through the accessor, naming the attribute.
# -----------------------------------------------------------------------------

my @invalid = (
	[ 'Clay::UI::Test::Box',  background_color => 'red',                       qr/'background_color' expected a hash or array reference, got 'red'/ ],
	[ 'Clay::UI::Test::Box',  background_color => [1, 2, 3],                   qr/'background_color' expected an array of 4 numbers, got an array of 3 elements/ ],
	[ 'Clay::UI::Test::Box',  background_color => { red => 1 },                qr/'background_color' has unknown key 'red' \(known keys: r, g, b, a\)/ ],
	[ 'Clay::UI::Test::Box',  border_color     => [1, 2, 'x', 4],              qr/'border_color\.b' expected a number in 0\.\.255, got 'x'/ ],
	[ 'Clay::UI::Test::Box',  border_width     => { lft => 1 },                qr/'border_width' has unknown key 'lft'/ ],
	[ 'Clay::UI::Test::Box',  border_width     => -1,                          qr/'border_width' expected an integer in 0\.\.65535, got '-1'/ ],
	[ 'Clay::UI::Test::Box',  corner_radius    => 'round',                     qr/'corner_radius' expected a number >= 0, got 'round'/ ],
	[ 'Clay::UI::Test::Box',  layout           => [],                          qr/'layout' expected a hash reference, got an ARRAY reference/ ],
	[ 'Clay::UI::Test::Box',  layout           => { padding => 8 },            qr/'layout\.padding' expected a hash reference, got '8' \(padding_all\(N\) builds one\)/ ],
	[ 'Clay::UI::Test::Box',  layout           => { padding => { left => -5 } }, qr/'layout\.padding\.left' expected an integer in 0\.\.65535, got '-5'/ ],
	[ 'Clay::UI::Test::Box',  layout           => { child_gap => 70000 },      qr/'layout\.child_gap' expected an integer in 0\.\.65535, got '70000'/ ],
	[ 'Clay::UI::Test::Box',  layout           => { child_gapp => 50 },        qr/'layout' has unknown key 'child_gapp' \(known keys: sizing, padding, child_gap, child_alignment, layout_direction, line_gap, line_sizing\)/ ],
	[ 'Clay::UI::Test::Box',  layout           => { sizing => { width => 5 } }, qr/'layout\.sizing\.width' expected a hash reference, got '5' \(sizing_fit, sizing_grow, sizing_fixed or sizing_percent build one\)/ ],
	[ 'Clay::UI::Test::Box',  layout           => { layout_direction => 7 },   qr/'layout\.layout_direction' expected an integer in 0\.\.3, got '7'/ ],
	[ 'Clay::UI::Test::Box',  floating         => { attach_too => 1 },         qr/'floating' has unknown key 'attach_too'/ ],
	[ 'Clay::UI::Test::Box',  floating         => { offset => 'up' },          qr/'floating\.offset' expected a hash or array reference, got 'up'/ ],
	[ 'Clay::UI::Test::Box',  width_group      => -1,                          qr/'width_group' must be an integer in 0\.\.1048575/ ],
	[ 'Clay::UI::Test::Box',  height_group     => 2**20,                       qr/'height_group' must be an integer in 0\.\.1048575/ ],
	[ 'Clay::UI::Test::Box',  id               => '',                          qr/'id' must be a non-empty string/ ],
	[ 'Clay::UI::Test::Box',  id               => 'anon:0:/0',                 qr/'id' must not start with 'anon:'/ ],
	[ 'ScrollPanel',          child_offset     => 5,                           qr/'child_offset' expected a hash or array reference, got '5'/ ],
	[ 'ScrollPanel',          vertical         => [],                          qr/'vertical' expected a plain boolean value, got an ARRAY reference/ ],
	[ 'Clay::UI::Test::Text', text             => undef,                       qr/'text' must be a defined string/ ],
	[ 'Clay::UI::Test::Text', font_size        => 'big',                       qr/'font_size' expected an integer in 0\.\.65535, got 'big'/ ],
	[ 'Clay::UI::Test::Text', font_size        => 70000,                       qr/'font_size' expected an integer in 0\.\.65535, got '70000'/ ],
	[ 'Clay::UI::Test::Text', text_color       => 'black',                     qr/'text_color' expected a hash or array reference, got 'black'/ ],
	[ 'Clay::UI::Test::Text', wrap_mode        => 9,                           qr/'wrap_mode' expected an integer in 0\.\.2, got '9'/ ],
	[ 'Clay::UI::Test::Text', text_alignment   => 'left',                      qr/'text_alignment' expected an integer in 0\.\.2, got 'left'/ ],
	[ 'Clay::UI::Test::Grid', row_gap          => 'wide',                      qr/'row_gap' expected an integer in 0\.\.65535, got 'wide'/ ],
	[ 'Clay::UI::Test::Grid', cell_gap         => undef,                       qr/'cell_gap' must be defined/ ],
);

subtest 'user ids cannot collide with derived ids' => sub {
	my $root = Clay::UI::Test::Box->new;
	$root->add_child(Clay::UI::Test::Box->new);
	my $ui = Clay::UI->new(width => 100, height => 100, root => $root);
	ok( lives { $ui->render }, 'derived ids render' );
	like( dies { Clay::UI::Test::Box->new(id => 'anon:0:/0') }, qr/reserved for the ids Clay::UI derives/,
		'the id the first child of an id-less root gets cannot be claimed' );
	ok( lives { Clay::UI::Test::Box->new(id => 'my-anon:1') }, "'anon:' elsewhere in an id is fine" );
};

subtest 'invalid attributes die at construction and through accessors' => sub {
	for my $case (@invalid) {
		my ($class, $name, $value, $error) = @$case;
		my %base = $class eq 'ScrollPanel' ? (id => 'scroll') : ();
		my $label = "$class $name => " . (ref $value ? ref $value : $value // 'undef');
		like( dies { $class->new(%base, $name => $value) }, $error, "$label at construction" );
		next if $name eq 'id';
		my $widget = $class->new(%base);
		like( dies { $widget->$name($value) }, $error, "$label through the accessor" );
	}
};

subtest 'Clay keys are accepted in snake_case and camelCase' => sub {
	ok( lives { Clay::UI::Test::Box->new(layout => { child_gap => 4, layout_direction => 1 }) }, 'snake_case' );
	ok( lives { Clay::UI::Test::Box->new(layout => { childGap => 4, layoutDirection => 1 }) }, 'camelCase' );
};

subtest 'a camelCase slice reads back in snake_case' => sub {
	my $box = Clay::UI::Test::Box->new(layout => { childGap => 4, childAlignment => { x => CLAY_ALIGN_X_RIGHT } });
	is( $box->layout, { child_gap => 4, child_alignment => { x => CLAY_ALIGN_X_RIGHT } }, 'from the constructor' );
	$box->corner_radius({ topLeft => 2 });
	is( $box->corner_radius, { top_left => 2 }, 'from an accessor' );
};

subtest 'both spellings of one key die where the slice is set' => sub {
	my $both = qr/Clay::UI: key 'childGap' in 'layout' is 'child_gap' in snake_case, which is already present in the same hash/;
	like( dies { Clay::UI::Test::Box->new(layout => { child_gap => 1, childGap => 2 }) }, $both, 'at construction' );
	my $box = Clay::UI::Test::Box->new;
	like( dies { $box->layout({ child_gap => 1, childGap => 2 }) }, $both, 'through the accessor' );
	like( dies { $box->layout({ padding => { topLeft => 1, top_left => 2 } }) }, qr/key 'topLeft' in 'layout\.padding'/,
		'a nested hash names its path' );
	is( $box->layout, {}, 'the slice is unchanged' );
};

subtest 'hover roles cannot be composed onto a text node' => sub {
	my $ok = eval q{
		class HoverText :does(Clay::UI::Role::Core::TextNode) :does(Clay::UI::Role::Interaction::Hoverable) {
			method text { 'x' }
			method text_config { {} }
		}
		1;
	};
	ok( $ok, 'the class compiles' ) or diag $@;
	like( dies { HoverText->new }, qr/wrap the text in an Element/, 'constructing it dies' );
};

subtest 'errors point at the caller' => sub {
	my $box = Clay::UI::Test::Box->new;
	like( dies { $box->background_color([300, 0, 0, 255]) }, qr/^Clay::UI: 'background_color\.r' expected a number in 0\.\.255, got '300' at \Q$0\E line \d+\.\n\z/,
		'a validation error names this file' );
	like( dies { $box->add_child('nope') }, qr/^Clay::UI: child is not a widget \(got non-ref\) at \Q$0\E line \d+\.\n\z/,
		'so does a structural error' );
};

done_testing;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS;
use Clay::UI::_keys qw(camelize_keys camelize_string snake_keys snake_string);

# -----------------------------------------------------------------------------
# camelize_string: single-token cases.
# -----------------------------------------------------------------------------

is( camelize_string('layout'),            'layout',           'no underscore = unchanged' );
is( camelize_string('background_color'),  'backgroundColor',  'two-word snake_case' );
is( camelize_string('layout_direction'),  'layoutDirection',  'layout_direction' );
is( camelize_string('between_children'),  'betweenChildren',  'between_children' );
is( camelize_string('top_left'),          'topLeft',          'corner key' );
is( camelize_string('child_alignment'),   'childAlignment',   'child_alignment' );
is( camelize_string('color_0'),           'color0',           'numeric suffix preserved' );
is( camelize_string('alreadyCamel'),      'alreadyCamel',     'no-op on camelCase without underscore' );

# -----------------------------------------------------------------------------
# camelize_keys: recursive structures matching real Clay declarations.
# -----------------------------------------------------------------------------

my $declaration = {
	layout => {
		sizing           => { width => { type => 'fixed', size => { minMax => { min => 300, max => 300 } } } },
		padding          => { left => 10, right => 10, top => 5, bottom => 5 },
		child_gap        => 4,
		child_alignment  => { x => 1, y => 2 },
		layout_direction => 0,
	},
	background_color => [40, 50, 60, 200],
	overlay_color    => [255, 0, 0, 50],
	corner_radius    => { top_left => 6, top_right => 6, bottom_left => 0, bottom_right => 0 },
	border           => {
		color => [100, 100, 100, 255],
		width => { left => 1, right => 1, top => 1, bottom => 1, between_children => 0 },
	},
};

my $camelized = camelize_keys($declaration);

is(
	$camelized,
	{
		layout => {
			sizing          => { width => { type => 'fixed', size => { minMax => { min => 300, max => 300 } } } },
			padding         => { left => 10, right => 10, top => 5, bottom => 5 },
			childGap        => 4,
			childAlignment  => { x => 1, y => 2 },
			layoutDirection => 0,
		},
		backgroundColor => [40, 50, 60, 200],
		overlayColor    => [255, 0, 0, 50],
		cornerRadius    => { topLeft => 6, topRight => 6, bottomLeft => 0, bottomRight => 0 },
		border          => {
			color => [100, 100, 100, 255],
			width => { left => 1, right => 1, top => 1, bottom => 1, betweenChildren => 0 },
		},
	},
	'full Clay declaration round-trips correctly',
);

# -----------------------------------------------------------------------------
# Original input is not mutated.
# -----------------------------------------------------------------------------

ok( exists $declaration->{background_color}, 'source key still present on input' );
ok( !exists $declaration->{backgroundColor}, 'source not mutated in place' );

# -----------------------------------------------------------------------------
# Scalars and non-ref values pass through.
# -----------------------------------------------------------------------------

is( camelize_keys(42),       42,       'scalar passes through' );
is( camelize_keys(undef),    undef,    'undef passes through' );
is( camelize_keys('hello'),  'hello',  'string passes through' );

# -----------------------------------------------------------------------------
# Blessed refs and coderefs are not recursed into.
# -----------------------------------------------------------------------------

my $blessed = bless { snake_case => 1 }, 'Some::Class';
my $result  = camelize_keys($blessed);
is( ref $result,            'Some::Class', 'blessed ref returned as-is' );
is( $result->{snake_case},  1,             'blessed contents untouched' );

my $code = sub { 1 };
is( camelize_keys($code), $code, 'coderef returned as-is' );

# -----------------------------------------------------------------------------
# Collision detection: both snake and camel forms of the same key fail loud.
# -----------------------------------------------------------------------------

like(
	dies { camelize_keys({ background_color => [1], backgroundColor => [2] }) },
	qr/already present|collides/,
	'snake/camel collision in same hash throws',
);

# -----------------------------------------------------------------------------
# snake_keys: the mirror, run where attributes are set.
# -----------------------------------------------------------------------------

is(
	snake_keys({ childGap => 1, padding => { left => 2 }, childAlignment => { x => 0 }, colors => [ { topLeft => 3 } ] }),
	{ child_gap => 1, padding => { left => 2 }, child_alignment => { x => 0 }, colors => [ { top_left => 3 } ] },
	'snake_keys rewrites nested hashes and arrays',
);
my $blessed_camel = bless { someKey => 1 }, 'Some::Class';
is( snake_keys($blessed_camel), exact_ref($blessed_camel), 'snake_keys returns a blessed ref as-is' );
like(
	dies { snake_keys({ background_color => [1], backgroundColor => [2] }, 'style') },
	qr/key 'backgroundColor' in 'style' is 'background_color' in snake_case, which is already present/,
	'snake_keys: both spellings of one key in a hash throw',
);

# Every Clay field name survives the trip to snake_case and back, so
# stored snake_case slices reach Clay with its own keys.
my $schemas = Clay::XS::_struct_schemas();
my @fields  = sort { $a cmp $b } keys %{ { map { $_->{name} => 1 } map { @$_ } values %$schemas } };
my @broken  = grep { camelize_string(snake_string($_)) ne $_ } @fields;
is( \@broken, [], scalar(@fields) . ' schema field names round-trip through snake_string' );

done_testing;

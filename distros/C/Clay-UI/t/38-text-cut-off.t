use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Cutting off text (patches/0005-clay-text-cut-off.patch): text that does not
# wrap at the width (CLAY_TEXT_WRAP_NEWLINES, CLAY_TEXT_WRAP_NONE) keeps its
# width while everything else can still shrink. Only when the content does not
# fit even then does it get narrower, down to nothing; the renderer cuts it off
# at its box. CLAY_TEXT_WRAP_NEWLINES still breaks only at its newlines.
# -----------------------------------------------------------------------------

my @errors;
my $ctx = Clay_Initialize(Clay_MinMemorySize(), { width => 1000, height => 1000 },
	sub ($error, $userdata) { push @errors, $error });
# Every character is 10 wide and 20 high.
Clay_SetMeasureTextFunction(sub ($text, @) { return { width => 10 * length($text), height => 20 } });

sub el ($name, $decl, @children) {
	Clay__OpenElementWithId(Clay_GetElementId($name));
	Clay__ConfigureOpenElement($decl);
	$_->() for @children;
	Clay__CloseElement();
}

sub row ($name, $width, @children) {
	return sub { el($name, { layout => { sizing => { width => sizing_fixed($width), height => sizing_fit() } } }, @children) };
}

sub column ($name, $width, @children) {
	return sub { el($name, { layout => { layoutDirection => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed($width), height => sizing_fit() } } }, @children) };
}

sub box ($name, $decl, @children) {
	return sub { el($name, $decl, @children) };
}

sub text ($string, $mode) {
	return sub { Clay__OpenTextElement($string, { fontSize => 10, wrapMode => $mode }) };
}

# The TEXT commands of a frame as [string, x, width].
sub frame (@content) {
	Clay_BeginLayout();
	$_->() for @content;
	my $commands = Clay_EndLayout(0.016);
	return [ map { [ $_->{renderData}{stringContents}, 0 + $_->{boundingBox}{x}, 0 + $_->{boundingBox}{width} ] }
		grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$commands ];
}

sub width_of ($name) {
	return 0 + Clay_GetElementData(Clay_GetElementId($name))->{boundingBox}{width};
}

subtest 'text that does not wrap keeps its width while others can still shrink' => sub {
	my $lines = frame(row('row', 110,
		box('label', {}, text('Settings', CLAY_TEXT_WRAP_NONE)),
		box('body',  {}, text('aaa bbb ccc', CLAY_TEXT_WRAP_WORDS))));
	is( width_of('label'), 80, 'the label keeps all 8 characters' );
	is( width_of('body'),  30, 'the wrapping text gives up the width, down to its longest word' );
	is( $lines->[0], [ 'Settings', 0, 80 ], 'and the label is drawn whole' );
};

subtest 'a word longer than the room is cut off' => sub {
	my $lines = frame(row('row', 120,
		box('cell', { layout => { padding => { left => 10, right => 10 } } }, text('https://example.com/a', CLAY_TEXT_WRAP_NONE))));
	is( width_of('cell'), 120, 'the box is no wider than its parent' );
	is( $lines, [ [ 'https://example.com/a', 10, 100 ] ], 'the text is cut off inside the padding' );
};

subtest 'text in a column narrower than the text is cut off at its width' => sub {
	my $lines = frame(column('column', 50, text('averylongword', CLAY_TEXT_WRAP_NONE)));
	is( $lines, [ [ 'averylongword', 0, 50 ] ], 'the line box is as wide as the column' );
};

subtest 'newlines text breaks only at its newlines, and cuts off a longer line' => sub {
	my $lines = frame(row('row', 60, text("one two three\nfour", CLAY_TEXT_WRAP_NEWLINES)));
	is( $lines, [ [ 'one two three', 0, 60 ], [ 'four', 0, 40 ] ], 'two lines; the first one cut off at the row' );
};

subtest 'members of a sizing group are cut off alike' => sub {
	# A grid of two columns: the a cells are group 7, the b cells group 8.
	my $cell = sub ($name, $string, $mode) {
		my $group = $name =~ /^a/ ? 7 : 8;
		return box($name, { layout => { sizing => { width => sizing_grow(), height => sizing_fit() } }, sizingGroup => { width => $group } },
			text($string, $mode));
	};
	frame(column('grid', 100,
		box('r1', { layout => { sizing => { width => sizing_grow(), height => sizing_fit() } } },
			$cell->('a1', 'averyveryverylongword', CLAY_TEXT_WRAP_NONE), $cell->('b1', 'xx', CLAY_TEXT_WRAP_WORDS)),
		box('r2', { layout => { sizing => { width => sizing_grow(), height => sizing_fit() } } },
			$cell->('a2', 'abcdefghi', CLAY_TEXT_WRAP_WORDS), $cell->('b2', 'yy', CLAY_TEXT_WRAP_WORDS))));
	# a2 cannot get narrower than its word (90), so a1 is cut off no further than that either.
	is( width_of('a1'), 90, 'the cut-off cell is as wide as the narrowest the other cell can be' );
	is( width_of('a2'), 90, 'which is the width of its longest word' );
	is( width_of('b1'), width_of('b2'), 'the cells next to them are equally wide too' );
};

is( \@errors, [], 'Clay reported no errors' );

done_testing;

package Clay::UI::Text;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::_validate qw(optional required validate_text clay_struct clay_field copy_value);
use Clay::UI::Revision qw(bump_revision);
use Clay::UI::Role::Core::TextNode;

role Clay::UI::Text :does(Clay::UI::Role::Core::TextNode) {
	field $text :param = '';

	field $font_id         :param = 0;
	field $font_size       :param = 16;
	field $text_color      :param = [0, 0, 0, 255];
	field $letter_spacing  :param = 0;
	field $line_height     :param = 0;
	field $wrap_mode       :param = undef;
	field $text_alignment  :param = undef;

	ADJUST {
		$text           = required(\&validate_text,   text           => $text);
		$font_id        = required(clay_field('Clay_TextElementConfig', 'fontId'), font_id        => $font_id);
		$font_size      = required(clay_field('Clay_TextElementConfig', 'fontSize'), font_size      => $font_size);
		$text_color     = required(clay_struct('Clay_Color'),  text_color     => $text_color);
		$letter_spacing = required(clay_field('Clay_TextElementConfig', 'letterSpacing'), letter_spacing => $letter_spacing);
		$line_height    = required(clay_field('Clay_TextElementConfig', 'lineHeight'), line_height    => $line_height);
		$wrap_mode      = optional(clay_field('Clay_TextElementConfig', 'wrapMode'),   wrap_mode      => $wrap_mode);
		$text_alignment = optional(clay_field('Clay_TextElementConfig', 'textAlignment'),   text_alignment => $text_alignment);
	}

	method text (@new) {
		return $text unless @new;
		$text = required(\&validate_text, text => @new);
		bump_revision();
		return $text;
	}

	method font_id (@new) {
		return $font_id unless @new;
		$font_id = required(clay_field('Clay_TextElementConfig', 'fontId'), font_id => @new);
		bump_revision();
		return $font_id;
	}

	method font_size (@new) {
		return $font_size unless @new;
		$font_size = required(clay_field('Clay_TextElementConfig', 'fontSize'), font_size => @new);
		bump_revision();
		return $font_size;
	}

	method text_color (@new) {
		return copy_value($text_color) unless @new;
		$text_color = required(clay_struct('Clay_Color'), text_color => @new);
		bump_revision();
		return copy_value($text_color);
	}

	method letter_spacing (@new) {
		return $letter_spacing unless @new;
		$letter_spacing = required(clay_field('Clay_TextElementConfig', 'letterSpacing'), letter_spacing => @new);
		bump_revision();
		return $letter_spacing;
	}

	method line_height (@new) {
		return $line_height unless @new;
		$line_height = required(clay_field('Clay_TextElementConfig', 'lineHeight'), line_height => @new);
		bump_revision();
		return $line_height;
	}

	method wrap_mode (@new) {
		return $wrap_mode unless @new;
		$wrap_mode = optional(clay_field('Clay_TextElementConfig', 'wrapMode'), wrap_mode => @new);
		bump_revision();
		return $wrap_mode;
	}

	method text_alignment (@new) {
		return $text_alignment unless @new;
		$text_alignment = optional(clay_field('Clay_TextElementConfig', 'textAlignment'), text_alignment => @new);
		bump_revision();
		return $text_alignment;
	}

	method text_config {
		my %cfg = (
			font_id        => $font_id,
			font_size      => $font_size,
			text_color     => copy_value($text_color),
			letter_spacing => $letter_spacing,
			line_height    => $line_height,
		);
		$cfg{wrap_mode}      = $wrap_mode      if defined $wrap_mode;
		$cfg{text_alignment} = $text_alignment if defined $text_alignment;
		return \%cfg;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Text - text widget role for Clay::UI

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(CLAY_TEXT_WRAP_NONE CLAY_TEXT_ALIGN_CENTER);
	use Clay::UI;
	use Clay::UI::Text;

	class My::Label :strict(params) :does(Clay::UI::Text) {}

	my $label = My::Label->new(
		text           => 'Hello, world!',
		font_size      => 18,
		text_color     => [255, 255, 255, 255],
		wrap_mode      => CLAY_TEXT_WRAP_NONE,
		text_alignment => CLAY_TEXT_ALIGN_CENTER,
	);
	$label->text('Goodbye');    # shown from the next render on

	my $ui = Clay::UI->new(width => 400, height => 100, root => $label);
	my ($command) = @{ $ui->render };
	# $command->{renderData}{stringContents} eq 'Goodbye'

=head1 DESCRIPTION

C<Clay::UI::Text> is the ready-made text widget. A text widget becomes
one Clay text element: a leaf that shows a string, wraps it to the
width its parent gives it and cannot have children. Like every widget
in Clay::UI it is a role; compose it in a class of your own (as
C<My::Label> above) to get a widget you can construct.

It composes L<Clay::UI::Role::Core::TextNode>, which provides
C<parent>, C<root>, C<ui>, C<contains>, C<tree_changed>, C<on> and
C<mark_changed>. A text widget has no C<id>, no children, no sizing
groups and no background; put it in a L<Clay::UI::Box> to style or size
it.

Clay measures text with the C<measure_text> function of the
L<Clay::UI> (see L<Clay::UI/new>). The function receives the string and
the text settings below, and returns the width and height the renderer
will need for that text with that font; the default is a rough
monospace estimate.

Classes should be declared C<:strict(params)>, so that a misspelled
constructor parameter dies instead of being ignored.

=head1 ATTRIBUTES

Each attribute is a constructor parameter and a read/write accessor of
the same name: call it without an argument to read, with one argument to
write. A write bumps the revision (L<Clay::UI::Revision>), takes effect
at the next C<render> and returns the new value. Values are checked when
they are set, at construction or by the accessor; a bad value dies
naming the attribute, for example
C<Clay::UI: 'font_size' expected an integer in 0..65535, got '1.5'>.
Calling an accessor with more than one argument dies with
C<Clay::UI: 'text' takes one value>.


The settings are the fields of Clay's text configuration; see
L<Clay::XS::Structs/Clay_TextElementConfig> for their exact meaning.

=head2 text

	$label->text('New caption');

The string to show: any defined, non-reference Perl string (characters,
so any Unicode text). Default C<''>. Dies with
C<Clay::UI: 'text' must be a defined string> otherwise.


=head2 font_id

	$label->font_id(1);

Which font to use: an integer from 0 to 65535 that your
C<measure_text> function and your renderer map to a font. Default
C<0>.

=head2 font_size

	$label->font_size(24);

The font size, an integer from 0 to 65535. Default C<16>.

=head2 text_color

	$label->text_color([255, 255, 255, 255]);
	$label->text_color({ r => 255, g => 255, b => 255, a => 255 });

The text colour: C<[$r, $g, $b, $a]> (exactly four numbers) or
C<< { r, g, b, a } >> (a channel left out is 0). Channels are finite
numbers, by convention 0 to 255. Default C<[0, 0, 0, 255]> (opaque
black). Reading returns a new copy; writing stores a copy. Undef dies.

=head2 letter_spacing

	$label->letter_spacing(1);

Extra space between characters, an integer from 0 to 65535. Default
C<0>.

=head2 line_height

	$label->line_height(20);

The height of one line, an integer from 0 to 65535. Default C<0>,
which means: use the height C<measure_text> returns. With a
C<line_height> larger than that height, Clay moves each line's text box
down by half the difference, so the box of the last line reaches below
the element; renderers should centre the glyphs in the box.

=head2 wrap_mode

	$label->wrap_mode(CLAY_TEXT_WRAP_NEWLINES);
	$label->wrap_mode(undef);                      # Clay's default

How the text wraps: C<CLAY_TEXT_WRAP_WORDS> (at spaces and newlines),
C<CLAY_TEXT_WRAP_NEWLINES> (only at newlines) or C<CLAY_TEXT_WRAP_NONE>
(meant to never wrap; see below). Default undef: the setting is left out and Clay uses
C<CLAY_TEXT_WRAP_WORDS>.

In the Clay version this distribution ships, C<CLAY_TEXT_WRAP_NONE>
behaves like C<CLAY_TEXT_WRAP_NEWLINES>: it still breaks lines at
C<"\n">, although Clay describes it as disabling wrapping.

=head2 text_alignment

	$label->text_alignment(CLAY_TEXT_ALIGN_RIGHT);

How wrapped lines are aligned inside the text element:
C<CLAY_TEXT_ALIGN_LEFT>, C<CLAY_TEXT_ALIGN_CENTER> or
C<CLAY_TEXT_ALIGN_RIGHT>. Default undef: the setting is left out and
Clay uses C<CLAY_TEXT_ALIGN_LEFT>. To place the whole text element
inside its parent, use the parent's C<child_alignment> (see
L<Clay::UI::Role::Layout::HasLayout/layout>).

=head1 METHODS

=head2 text_config

	my $config = $label->text_config;
	# { font_id => 0, font_size => 16, text_color => [0, 0, 0, 255],
	#   letter_spacing => 0, line_height => 0 }

Returns the text settings the layout pass (the part of
L<Clay::UI/render> that declares the tree to Clay) passes to Clay: a
new hashref with the snake_case keys above. C<wrap_mode> and
C<text_alignment> are included only when they are set. The
C<text_color> inside is a new copy as well, so changing the result
changes nothing in the widget. This is the method
L<Clay::UI::Role::Core::TextNode> requires.

=head1 SEE ALSO

L<Clay::UI::Role::Core::TextNode>, L<Clay::UI/new> (C<measure_text>),
L<Clay::XS::Structs/Clay_TextElementConfig>, L<Clay::UI::Box>.

=cut

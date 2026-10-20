package Clay::UI::Role::Style::HasBackground;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::_validate qw(optional clay_struct copy_value);
use Clay::UI::Revision qw(bump_revision);

role Clay::UI::Role::Style::HasBackground {
	field $background_color :param = undef;

	ADJUST {
		$background_color = optional(clay_struct('Clay_Color'), background_color => $background_color);
	}

	method background_color (@new) {
		return copy_value($background_color) unless @new;
		$background_color = optional(clay_struct('Clay_Color'), background_color => @new);
		bump_revision();
		return copy_value($background_color);
	}

	method contribute_background ($config) {
		return unless defined $background_color;
		$config->{background_color} = copy_value($background_color);
		return;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Style::HasBackground - background colour attribute for Clay::UI widgets

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::UI::Role::Core::Container;
	use Clay::UI::Role::Style::HasBackground;

	class My::Panel :strict(params)
		:does(Clay::UI::Role::Core::Container)
		:does(Clay::UI::Role::Style::HasBackground)
	{}

	my $panel = My::Panel->new(background_color => [40, 50, 60, 255]);
	$panel->background_color({ r => 200, g => 30, b => 30, a => 255 });
	$panel->background_color(undef);    # no background

=head1 DESCRIPTION

C<Clay::UI::Role::Style::HasBackground> gives a widget the
C<background_color> attribute: the colour the renderer fills the
element's box with. The widget adds it to its declaration (the hash of
settings Clay receives for the element) as C<background_color>
(C<backgroundColor> for Clay). L<Clay::UI::Box>, L<Clay::UI::Grid> and
L<Clay::UI::Grid::Cell> compose it.

=head1 ATTRIBUTES

=head2 background_color

	my $color = $widget->background_color;    # read: a copy, or undef
	$widget->background_color([40, 50, 60, 255]);

A constructor parameter and a read/write accessor. The value is undef
(no background) or a colour in one of two forms:

	[$r, $g, $b, $a]                          # exactly four numbers
	{ r => $r, g => $g, b => $b, a => $a }    # a channel left out is 0

The channels are numbers, by convention 0 to 255 (C<a> 255 is opaque).
Clay passes them to the renderer unchanged and checks only that they
are finite numbers. With alpha 0 Clay emits no rectangle; mind that a
hash without C<a> is fully transparent. See
L<Clay::XS::Structs/Clay_Color>.

Default undef: the declaration gets no background colour and Clay
draws no rectangle for the element.

Reading returns a new copy (or undef); writing stores a copy of the
value, so changing the array or hash afterwards does not change the
widget. A write bumps the revision (L<Clay::UI::Revision>), takes
effect at the next C<render> and returns a copy of the new value.

The value is checked when it is set, at construction or by the
accessor. A bad value dies naming the attribute, for example:

=for highlighter language=text

	Clay::UI: 'background_color' expected an array of 4 numbers, got an array of 3 elements
	Clay::UI: 'background_color' has unknown key 'x' (known keys: r, g, b, a)
	Clay::UI: 'background_color' expected a hash or array reference, got 'red'

=head1 METHODS

=head2 contribute_background

Adds C<background_color> to the widget's declaration while the
attribute is set (see
L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION>).

=head1 SEE ALSO

L<Clay::XS::Structs/backgroundColor>, L<Clay::UI::Box>.

=cut

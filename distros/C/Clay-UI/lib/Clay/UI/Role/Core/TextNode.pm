package Clay::UI::Role::Core::TextNode;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Revision qw(bump_revision);
use Clay::UI::Role::Layout::HasParent;
use Clay::UI::Role::Events::Listener;

role Clay::UI::Role::Core::TextNode :does(Clay::UI::Role::Layout::HasParent)
                              :does(Clay::UI::Role::Events::Listener) {
	method text;
	method text_config;

	# Text widgets have no id; the reader exists so predicates that read
	# ids work on every child.
	method id () {
		return undef;
	}

	method mark_changed () {
		bump_revision();
		return $self;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Core::TextNode - base role of every Clay::UI text widget

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::UI;
	use Clay::UI::Role::Core::TextNode;

	# A text widget of your own: a counter that renders its value.
	class My::Counter :strict(params) :does(Clay::UI::Role::Core::TextNode) {
		field $count :param = 0;

		method increment () {
			$count++;
			$self->mark_changed;
			return $self;
		}

		method text () { return "Count: $count" }

		method text_config () {
			return { font_size => 20, text_color => [255, 255, 255, 255] };
		}
	}

	my $counter  = My::Counter->new;
	my $ui       = Clay::UI->new(width => 400, height => 300, root => $counter);
	$counter->increment;
	my $commands = $ui->render;

=head1 DESCRIPTION

C<Clay::UI::Role::Core::TextNode> is the role every text widget
composes. A text widget becomes one Clay text element: a leaf that
shows a string and cannot have children. L<Clay::UI::Text> is the
ready-made text widget role; compose TextNode directly only to compute
the text or its settings yourself.

For a text widget the layout pass (the part of L<Clay::UI/render> that
declares the tree to Clay) calls C<text> and C<text_config> and passes
both to C<Clay__OpenTextElement>, instead of the open / configure /
close calls it makes for element widgets.

TextNode also composes L<Clay::UI::Role::Layout::HasParent> (C<parent>,
C<root>, C<ui>, C<contains>, C<tree_changed>) and
L<Clay::UI::Role::Events::Listener> (C<on>). A text widget has no
C<id>, no children and no sizing groups.

=head1 REQUIRED METHODS

=head2 text

	method text () { return 'Hello' }

Returns the string to show: a defined Perl string of characters.

=head2 text_config

	method text_config () { return { font_size => 16, text_color => [0, 0, 0, 255] } }

Returns the text settings as a hashref: the fields of
L<Clay::XS::Structs/Clay_TextElementConfig>, with snake_case or
camelCase keys (C<font_id>, C<font_size>, C<text_color>,
C<letter_spacing>, C<line_height>, C<wrap_mode>, C<text_alignment>).
The layout pass copies the hash; it must not contain C<user_data>
(C<render> dies, because the layout pass sets it to find the widget
again). The values are checked only when the text element is
declared: a value of the wrong shape makes C<render> die, an unknown
key is ignored.

=head1 METHODS

=head2 id

	my $id = $text->id;    # undef

Returns undef: text widgets have no id. The reader exists so that a
predicate reading ids (L<Clay::UI::Role::Core::Element/get_children_with>)
works on every child.

=head2 mark_changed

	$widget->mark_changed;

Bumps the revision (L<Clay::UI::Revision>) and returns the widget. The
accessors of L<Clay::UI::Text> bump it themselves; a text widget class
with state of its own calls C<mark_changed> from its setters, so that a
renderer that skips unchanged frames draws the next one.

=head1 SEE ALSO

L<Clay::UI::Text>, L<Clay::UI::Role::Core::Element>,
L<Clay::UI::Revision>.

=cut

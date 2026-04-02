package Chandra::Element;

use strict;
use warnings;

use Chandra::Bind;

our $VERSION = '0.09';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
require Chandra;

1;

__END__

=head1 NAME

Chandra::Element - DOM-like element construction for Chandra

=head1 SYNOPSIS

	use Chandra::Element;

	my $div = Chandra::Element->new({
	    tag   => 'div',
	    id    => 'app',
	    class => 'container',
	    style => { padding => '20px', background => '#fff' },
	    children => [
	        { tag => 'h1', data => 'Hello World' },
	        {
	            tag     => 'button',
	            data    => 'Click Me',
	            onclick => sub {
	                my ($event, $app) = @_;
	                print "Clicked!\n";
	            },
	        },
	    ],
	});

	my $html = $div->render;

=head1 DESCRIPTION

Chandra::Element provides a Moonshine::Element-compatible API for building
HTML element trees in Perl. Event handlers (onclick, onchange, etc.) are
automatically compiled into JavaScript that communicates with Perl via the
Chandra bridge.

=head1 METHODS

=head2 new(\%args)

Create a new element. Options:

=over 4

=item tag - HTML tag name (default: 'div')

=item id - Element ID (auto-generated if not provided)

=item class - CSS class(es)

=item style - CSS styles as hashref or string

=item data - Text content

=item children - Arrayref of child elements (hashrefs or Element objects)

=item onclick, onchange, etc. - Event handler coderefs

=back

=head2 add_child($child)

Add a child element. Accepts a hashref (auto-wrapped) or Element object.

=head2 children

	my $children = $element->children;

Returns the arrayref of child elements.

=head2 render()

Render the element tree to an HTML string with event wiring.

=head2 get_element_by_id($id)

Find a descendant element by ID.

=head2 get_element_by_tag($tag)

Find the first descendant element with the given tag name.

=head2 get_elements_by_class($class)

Find all descendant elements with the given CSS class.

=head2 handlers()

Class method. Returns the global handler registry hashref.

=head2 get_handler($id)

Class method. Returns the handler coderef registered under C<$id>.

=head2 clear_handlers()

Class method. Clears all registered handlers.

=head2 reset_ids()

Class method. Resets the auto-generated ID counter and clears all
registered handlers. Useful in tests.

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Bind>, L<Chandra::Event>

=cut

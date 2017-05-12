package Business::Cart::Generic::Controller::Search;

use parent 'Business::Cart::Generic::Controller';
use strict;
use warnings;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '0.85';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'display()');

	# search($name) returns an arrayref of hashrefs.

	my($id) = $self -> query -> param('search_number');

	my($order);

	if ($id && ($id =~ /^\d+$/) )
	{
		$order = $self -> param('db') -> search -> find($id);
		$order = $order ? $self -> param('db') -> order -> inflate_order($order) : '';
		$order = $order ? $self -> param('view') -> order -> format_search_order($order) : '';
	}
	else
	{
		$id = 0;
	}

	return $self -> param('view') -> search -> display($id, $order);

} # End of display.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Controller::Search> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This is a sub-class of L<Business::Cart::Generic::Controller>.

=head2 Using new()

This class is never used stand-alone. However, its run mode 'display is run automatically when the user clicks
one of the submit buttons on the search form. See generic.cart.cgi or generic.cart.psgi and
also search.js for the statement var request = Y.io("/Search/display", cfg).

=head1 Methods

=head2 display()

Responds to an AJAX request when the user clicks on the [Search] button on the Search form.

Returns a message which is sent to the client.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who chose to make osCommerce and PrestaShop, Zen Cart, etc, Open Source.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business::Cart::Generic>.

=head1 Author

L<Business::Cart::Generic> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut

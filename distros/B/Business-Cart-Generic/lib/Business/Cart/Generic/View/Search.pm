package Business::Cart::Generic::View::Search;

use strict;
use warnings;

use JSON::XS;

use Moose;

extends 'Business::Cart::Generic::View::Base';

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub build_search_html
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'build_search_html()');

	# Make YUI happy by turning the HTML into 1 long line.

	my($html) = $self -> templater -> render
		(
		 'search.tx',
		 {
			 sid => $self -> db -> session -> id,
		 }
		);
	$html =~ s/\n//g;

	return $html;

} # End of build_search_html.

# -----------------------------------------------

sub build_head_js
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'build_head_js()');

	return $self -> templater -> render
		(
		 'search.js',
		 {
		 }
		);

} # End of build_head_js.

# -----------------------------------------------

sub display
{
	my($self, $id, $order) = @_;

	$self -> db -> logger -> log(debug => "display($id, ...)");

	if (! $order)
	{
		$order = [ [{td => "No order matches # '$id'"}] ];
	}

	return $self -> templater -> render
		(
		'basic.table.tx',
		 {
			 border => 0,
			 row    => $order,
		 }
		);

} # End of display.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::View::Search> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This class extends L<Business::Cart::Generic::View::Base>.

=head2 Using new()

C<new()> is called as C<< my($obj) = Business::Cart::Generic::View::Search -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Business::Cart::Generic::View::Search>. See L<Business::Cart::Generic::View>.

Key-value pairs accepted in the parameter list:

=over 4

=item o config => $config

Takes an object of type L<Business::Cart::Generic::Util::Config>.

This key => value pair is mandatory.

=item o db => $db

Takes an object of type L<Business::Cart::Generic::Database>.

This key => value pair is mandatory.

=item o templater => $templater

Takes a L<Text::Xslate> object.

This key => value pair is mandatory.

=back

These keys are also getter-type methods.

=head1 Methods

=head2 build_search_html()

Returns a block of HTML for the search form.

=head2 build_head_js()

Returns a block of Javascript for insertion into the web page's head, and for use by the search form.

=head2 config()

Returns a hashref.

=head2 db()

Returns an object of type L<Business::Cart::Generic::Database>.

=head2 display($id, $order)

$id is the primary key of the order being searched for.

$order is a hashref of an order inflated by L<Business::Cart::Generic::Database::Order/inflate_order($order)>.

Returns a HTML table suitable for sending to the client.

=head2 templater()

Returns an object of type L<Text::Xslate>.

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

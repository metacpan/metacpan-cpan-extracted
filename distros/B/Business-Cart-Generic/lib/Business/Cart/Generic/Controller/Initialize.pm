package Business::Cart::Generic::Controller::Initialize;

use parent 'Business::Cart::Generic::Controller';
use strict;
use warnings;

use Text::Xslate 'mark_raw';

our $VERSION = '0.85';

# -----------------------------------------------

sub build_about_html
{
	my($self) = @_;

	$self -> log(debug => 'build_about_html()');

	my($config) = $self -> param('config');

	my(@tr);

	push @tr, {left => 'Program', right => "$$config{program_name} $$config{program_version}"};
	push @tr, {left => 'Author',  right => $$config{program_author} };
	push @tr, {left => 'Help',    right => mark_raw(qq|<a href="$$config{program_faq_url}">FAQ</a>|)};

	# Make YUI happy by turning the HTML into 1 long line.

	my($html) = $self -> param('templater') -> render('fancy.table.tx', {data => [@tr]});
	$html     =~ s/\n//g;

	return $html;

} # End of build_about_html.

# -----------------------------------------------

sub build_head_init
{
	my($self) = @_;

	$self -> log(debug => 'build_head_init()');

	my($about_html)  = $self -> build_about_html;
	my($order_html)  = $self -> param('view') -> order -> build_order_html;
	my($search_html) = $self -> param('view') -> search -> build_search_html;
	my($head_init)   = <<EJS;

YUI().use('node-base', 'tabview', function(Y)
{
	function init()
	{
		var tabview = new Y.TabView
			({
			  children:
				[
				 {
				   label:   'Search',
				   content: '$search_html'
				 },
				 {
				   label:   'Order',
				   content: '$order_html'
				 },
				 {
				   label:   'About',
				   content: '$about_html'
				 }
				]
			 });

		tabview.render('#tabview_container');
		tabview.on
			('selectionChange', function(e)
			 {
				 var label = e.newVal.get('label');

				 if (label === "Search")
				 {
					 make_search_number_focus();
				 }
				 else if (label === "Order")
				 {
					 make_quantity_focus();
				 }
			 }
			);
		make_search_number_focus();
		prepare_order_form();
		prepare_search_form();
	}

	Y.on("domready", init);
});

EJS

	return $head_init;

} # End of build_head_init.

# -----------------------------------------------

sub build_head_js
{
	my($self) = @_;

	$self -> log(debug => 'build_head_js()');

	my($view_js) =
		$self -> param('view') -> order -> build_head_js .
		$self -> param('view') -> search -> build_head_js;

	# These things are being declared within the web page's head.

	my($js) = <<EJS;
// Code in head of web page.

$view_js

function make_search_number_focus(eve)
{
	document.search_form.search_number.focus();
}

function make_quantity_focus(eve)
{
	document.order_form.quantity.focus();
}

EJS

	return $js;

} # End of build_head_js.

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'display()');

	# Generate the web page itself. This is not loaded by sub cgiapp_init(),
	# because, with AJAX, we only need it the first time the script is run.

	my($config) = $self -> param('config');
	my($param)  =
	{
	 css_url           => $$config{css_url},
	 head_js           => mark_raw($self -> build_head_js . $self -> build_head_init),
	 validator_css_url => $$config{validator_css_url},
	 validator_js_url  => $$config{validator_js_url},
	 yui_url           => $$config{yui_url},
	};

	return $self -> param('templater') -> render('web.page.tx', $param);

} # End of display.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Controller::Initialize> - Basic shopping cart

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

This class is never used stand-alone. However, its run mode 'display' is run automatically when the user hits the
default PSGI or CGI script URL, e.g. http://127.0.0.1:5008/.

=head1 Methods

=head2 build_about_html()

Returns the string of HTML used in the About tab.

=head2 build_head_init()

Returns a string of HTML and Javascript used in the tabset.

=head2 build_head_js()

Returns a string of Javascript inserted into the head of the web page.

=head2 display()

Called automatically, since display is the default run mode. See the method cgiapp_prerun() in the parent.

See also the comment above, under L</Constructor and Initialization>.

Returns the default web page to the client.

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

package Business::Cart::Generic::Controller;

use parent 'CGI::Application';
use strict;
use warnings;

use Business::Cart::Generic::Database;
use Business::Cart::Generic::Util::Config;
use Business::Cart::Generic::Util::Logger;
use Business::Cart::Generic::View;

use Text::Xslate;

# We don't use Moose because we ias CGI::Application.

our $VERSION = '0.85';

# -----------------------------------------------

sub cgiapp_prerun
{
	my($self, $rm) = @_;

	# Can't call, since logger not yet set up.
	#$self -> log(debug => 'cgiapp_prerun()');

	$self -> param(config => Business::Cart::Generic::Util::Config -> new -> config);
	$self -> param(logger => Business::Cart::Generic::Util::Logger -> new(config => $self -> param('config') ) );

	my($q) = $self -> query;

	# Log the CGI form parameters.

	$self -> log(info  => '');
	$self -> log(info  => $q -> url(-full => 1, -path => 1) );
	$self -> log(info  => "Param: $_: " . $q -> param($_) ) for $q -> param;

	# Other controllers add their own run modes.

	$self -> run_modes([qw/display/]);
	$self -> log(debug => 'tmpl_path: ' . ${$self -> param('config')}{template_path});

	# Set up the session. To simplify things we always use
	# Data::Session, and ignore the PSGI alternative.

	my($config) = $self -> param('config');

	$self -> param
		(
		 db => Business::Cart::Generic::Database -> new
		 (
		  logger => $self -> param('logger'),
		  query  => $q,
		 )
		);

	$self -> param
		(
		 templater => Text::Xslate -> new
		 (
		  input_layer => '',
		  path        => ${$self -> param('config')}{template_path},
		 )
		);

	$self -> param
		(
		 view => Business::Cart::Generic::View -> new
		 (
		  config    => $self -> param('config'),
		  db        => $self -> param('db'),
		  templater => $self -> param('templater'),
		 )
		);

	$self -> log(info  => 'Session id: ' . $self -> param('db') -> session -> id);

} # End of cgiapp_prerun.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> param('logger') -> log($level => $s);

} # End of log.

# -----------------------------------------------

sub teardown
{
	my($self) = @_;

	$self -> log(debug => 'teardown()');

	# This is mandatory under Plack.

	$self -> param('db') -> session -> flush;
	$self -> param('db') -> connector -> disconnect;
	$self -> param('logger') -> logger -> disconnect;

} # End of teardown.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Controller> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This is a sub-class of L<CGI::Application>.

=head2 Using new()

This class is never used stand-alone. See e.g. L<Business::Cart::Generic::Controller::Order>.

=head1 Methods

=head2 cgiapp_prerun($rm)

$rm is a run mode.

This method is a classic L<CGI::Application> cgiapp_prerun() method. See that module's documentation for details.

Using the L<CGI::Application> object's param() method, it sets these parameters:

=over 4

=item o config

This is the hashref returned from Business::Cart::Generic::Util::Config -> new() -> config();

=item o db

This is an object of type L<Business::Cart::Generic::Database>.

=item o logger

This is an object of type L<Business::Cart::Generic::Util::Logger>.

=item o templater

This is an object of type L<Text::Xslate>.

=item o view

This is an object of type L<Business::Cart::Generic::View>.

=back

=head2 log($level, $s)

This is a shortcut for $self -> param('logger') -> log($level => $s) for use by Business::Cart::Generic::Controller::* objects,
which are all sub-classes of this module.

See L<Business::Cart::Generic::Util::Logger> for details.

=head2 teardown()

This method is a classic L<CGI::Application> teardown() method. See that module's documentation for details.

It flushes the session to disk (if there were any changes), and closes down the database connexions for both the
connector object and the logger object.

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

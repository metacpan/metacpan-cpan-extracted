package Business::Cart::Generic::Base;

use strict;
use warnings;

use Business::Cart::Generic::Util::Config;
use Business::Cart::Generic::Util::Logger;

use DBIx::Connector;

use Moose;

has config =>
(
 default  => sub{ return Business::Cart::Generic::Util::Config -> new -> config },
 is       => 'rw',
 isa      => 'HashRef',
 required => 0,
);

has connector =>
(
 is  => 'rw',
 isa => 'Any',
 required => 0,
);

has logger =>
(
 is       => 'rw',
 isa      => 'Business::Cart::Generic::Util::Logger',
 required => 0,
);

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub BUILD
{
	my($self)   = @_;
	my($config) = $self -> config;
	my($attr)   = {AutoCommit => $$config{AutoCommit}, RaiseError => $$config{RaiseError} };

	if ( ($$config{dsn} =~ /SQLite/i) && $$config{sqlite_unicode})
	{
		$$attr{sqlite_unicode} = 1;
	}

	$self -> connector
		(
		 DBIx::Connector -> new($$config{dsn}, $$config{username}, $$config{password}, $attr)
		);

	if ($$config{dsn} =~ /SQLite/i)
	{
		$self -> connector -> dbh -> do('PRAGMA foreign_keys = ON');
	}

	$self -> logger
		(
		 Business::Cart::Generic::Util::Logger -> new(config => $config)
		);

} # End of BUILD.

# -----------------------------------------------

sub format_amount
{
	my($self, $amount, $currency) = @_;
	my($decimal_places) = $currency -> decimal_places;
	my($symbol_left)    = $currency -> symbol_left;
	my($format)         = sprintf('%s%%.%sf', $symbol_left, $decimal_places);

	return sprintf($format, $amount),

} # End of format_amount.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Base> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

This class is never used stand-alone. See e.g. L<Business::Cart::Generic::Database>.

=head1 Methods

=head2 config()

Returns an object of type L<Business::Cart::Generic::Util::Config>.

This value is provided automatically at object construction time.

=head2 connector()

Returns an object of type L<DBIx::Connector>.

This value is provided automatically at object construction time.

It uses to L<DBI> connexion parameters from the config file. See L<Business::Cart::Generic/The Configuration File>.

=head2 format_amount($amount, $currency)

$amount is a float. $currency is an object of type L<DBIx::Class::Row>.

Returns the amount formatted using the currency's parameters.

=head2 logger()

Returns an object of type L<Business::Cart::Generic::Util::Logger>.

This value is provided automatically at object construction time.

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

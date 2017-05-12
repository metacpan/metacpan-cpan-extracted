package Business::Cart::Generic::Util::Logger;

use strict;
use warnings;

use Log::Handler::Output::DBI;

use Moose;

has config =>
(
 is       => 'rw',
 isa      => 'HashRef',
 required => 1,
);

has logger =>
(
 is  => 'rw',
 isa => 'Any',
);

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub BUILD
{
	my($self)   = @_;
	my($config) = $self -> config;

	$self -> logger
		(
		 Log::Handler::Output::DBI -> new
		 (
		  columns     => [qw/level message/],
		  data_source => $$config{dsn},
		  password    => $$config{password},
		  persistent  => 1,
		  table       => 'log',
		  user        => $$config{username},
		  values      => [qw/%level %message/],
		  )
		);

}	# End of BUILD.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log(level => $level, message => $s || '')

} # End of log.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Logger> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This class has no parents.

=head2 Using new()

C<new()> is called as C<< my($obj) = Business::Cart::Generic::Util::Logger -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Business::Cart::Generic::Util::Logger>.

Key-value pairs accepted in the parameter list:

=over 4

=item o config => $config

This takes an object of type L<Business::Cart::Generic::Util::Config>.

This key => value pair is mandatory.

=back

These keys are also getter-type methods.

=head1 Methods

=head2 log($level, $s)

$level is a value recognized by L<Log::Handler>. $s is a string to write to the log table in the database.

A datestamp is added automatically. See the source code of L<Business::Cart::Generic::Database::Create> for
the definition of the log table.

Typical values for $level are 'debug', 'error' and 'info'.

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

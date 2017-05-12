package Business::Cart::Generic::Database::Search;

use strict;
use warnings;

use Moose;

extends 'Business::Cart::Generic::Database::Base';

use namespace::autoclean;

our $VERSION = '0.85';

# --------------------------------------------------

sub find
{
	my($self, $id) = @_;

	$self -> db -> logger -> log(debug => "search($id)");

	return $self -> db -> schema -> resultset('Order') -> search
		(
		 {
		   id => $id,
		 },
		 {
		 }
		) -> single;

} # End of find.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Database::Search> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This class extends L<Business::Cart::Generic::Database::Base>.

=head2 Using new()

This class is used by L<Business::Cart::Generic::Controller::Search>. See L<Business::Cart::Generic::Database>.

=head1 Methods

=head2 find($id)

Find a product via its primary key, and return the corresponding L<DBIx::Class::Row> object, or undef.

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

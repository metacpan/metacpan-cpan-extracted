package Business::CreditCard::Object;

$VERSION = '1.00';

use strict;
use warnings;

use Business::CreditCard ();

use overload
  '""'     => sub { shift->number },
	fallback => 1;

=head1 NAME

Business::CreditCard::Object - a Credit Card object

=head1 SYNOPSIS

	my $card = Business::CreditCard::Object->new("4929-4929-4929-4929");

	if ($card->is_valid) { 
		print "Card " . $card->number . " is a " . $card->type;
	}

=head1 DESCRIPTION

This provides an OO interface around the Business::CreditCard module.
You instantiate it with a card number, and can ask if it is valid, for
a standardised version of the card number, and what type of card it is.

=head1 METHODS

=head2 new

	my $card = Business::CreditCard::Object->new("4929-4929-4929-4929");

Construct a new Card object. The card number can contain optional
numbers and/or spaces. 

=head2 is_valid

This computes the checksum for the card given and returns a boolean
value for whether or not the number passes this check.

=head2 type

This returns the type of card given. See L<Business::CreditCard> for a
list of possible values.

=head2 number

This returns a standardised version of the card number as a string of
digits with all spaces and minus signs removed. The object will also
stringify to this value.

=cut

sub new {
	my ($class, $no) = @_;
	bless { 
		_no => $no,
	} => $class;
}

sub number { 
	my $self = shift;
	$self->{number} ||= do { 
		(my $no = $self->{_no}) =~ s/[-\s]//g;
		$no;
	};
}

sub is_valid { 
	Business::CreditCard::validate(shift->number)
}

sub type { 
	Business::CreditCard::cardtype(shift->number)
}

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Business-CreditCard-Object@rt.cpan.org

=head1 SEE ALSO

Business::CreditCard

=head1 COPYRIGHT

	Copyright (C) 2004-2005 Tony Bowden. 

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut


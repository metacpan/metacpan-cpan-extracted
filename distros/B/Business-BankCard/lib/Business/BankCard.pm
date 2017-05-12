package Business::BankCard;

our $VERSION = '0.01'; # VERSION

1;
# ABSTRACT: Utilities for dealing with bank card number (ISO/IEC 7812)


__END__
=pod

=head1 NAME

Business::BankCard - Utilities for dealing with bank card number (ISO/IEC 7812)

=head1 VERSION

version 0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

B<NOTE: This module is still empty without implementation. Plans are to provide
a list of IIN codes, routines to parse a card number into components, routines
to validate card number, etc.>

About bank card number: Bank card numbers are found on payment cards, such as
credit cards and debit cards. They have a certain amount of internal structure
and shares a common numbering scheme. Bank card numbers are allocated in
accordance with ISO/IEC 7812. An ISO/IEC 7812 number is typically 16 digits in
length. It consists of: 1) a six-digit Issuer Identification Number (IIN), the
first digit of which is the Major Industry Identifier (MII); 2) a variable
length (up to 12 digits) individual account identifier; 3) a single check digit
calculated using the Luhn algorithm.

The term "Issuer Identification Number" (IIN) replaces the previously used "Bank
Identification Number" (BIN). See ISO/IEC 7812 for more information.

=head1 SEE ALSO

L<Business::BankCard::Indonesia>

L<Business::CardInfo>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


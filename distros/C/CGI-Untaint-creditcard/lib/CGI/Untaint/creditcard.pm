package CGI::Untaint::creditcard;

$VERSION = '1.00';

use strict;
use base 'CGI::Untaint::printable';
require Business::CreditCard::Object;

sub is_valid { 
  my $self = shift;
	my $card = Business::CreditCard::Object->new($self->value);
  return unless $card->is_valid;
  $self->value($card);
  return $card->number;
}

=head1 NAME

CGI::Untaint::creditcard - validate a creditcard

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $cc = $handler->extract(-as_creditcard => 'ccno');

	print $cc->number;

=head1 DESCRIPTION

=head2 is_valid

This Input Handler verifies that it is dealing with a reasonable credit
card number (i.e. one that L<Business::CreditCard::Object> believes to
be valid.)

The resulting object will be set back into value().

=head1 SEE ALSO

L<CGI::Untaint>. L<Business::CreditCard::Object>.

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-CGI-Untaint-creditcard@rt.cpan.org

=head1 COPYRIGHT

  Copyright (C) 2001-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

1;

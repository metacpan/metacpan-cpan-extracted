package Business::Payment::SwissESR;

=header1 NAME

Business::Payment::SwissESR - Modules for handling Swiss Postfinance ESR

=head1 SYNOPSYS

 use Business::Payment::SwissESR::V11Parser;
 use Business::Payment::SwissESR::PaymentSlip;

=head1 DESCRIPTION

The package contains two modules. L<Business::Payment::SwissESR::V11Parser>
for proscessing payment notification lists and
L<Business::Payment::SwissESR::PaymentSlip> for creating pdf payment slips.

=cut

our $VERSION = '0.13.3';

1;

__END__

=back

=head1 COPYRIGHT

Copyright (c) 2015 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2015-07-20 to 0.9.0 initial version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et

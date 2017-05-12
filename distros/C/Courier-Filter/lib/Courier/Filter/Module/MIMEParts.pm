#
# Courier::Filter::Module::MIMEParts class
#
# (C) 2003-2008 Julian Mehnle <julian@mehnle.net>
# $Id: MIMEParts.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::MIMEParts - Message (MIME multipart and ZIP archive)
parts filter module for the Courier::Filter framework

=cut

package Courier::Filter::Module::MIMEParts;

use warnings;
use strict;

use base 'Courier::Filter::Module::Parts';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 DESCRIPTION

As of Courier::Filter 0.13, the B<MIMEParts> filter module is I<deprecated> in
favor of the new B<Parts> filter module, which is compatible but a lot more
powerful.  The B<MIMEParts> module will be removed in Courier::Filter 0.20.
You can still instantiate B<MIMEParts> modules in your config file for now, but
what will be created is really nothing more than B<Parts> modules.  See
L<Courier::Filter::Module::Parts> for the interface description.

=cut

sub new {
    my ($class, %options) = @_;
    STDERR->print("Warning: The MIMEParts filter module is deprecated. Use the Parts module instead.\n");
    return $class->SUPER::new(%options);
}

=head1 SEE ALSO

L<Courier::Filter::Module::Parts>, L<Courier::Filter::Module>,
L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

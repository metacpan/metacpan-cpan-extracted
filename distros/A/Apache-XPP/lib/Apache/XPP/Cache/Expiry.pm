=head1 NAME

Apache::XPP::Cache::Expiry - Cache expiry superclass

=cut

package Apache::XPP::Cache::Expiry;

=head1 SYNOPSIS

...

=head1 REQUIRES

Nothing

=cut

use Carp;
use strict;
use vars qw( $AUTOLOAD $debug $debuglines );

BEGIN {
	$Apache::XPP::Cache::Expiry::REVISION = (qw$Revision: 1.7 $)[-1];
	$Apache::XPP::Cache::Expiry::VERSION = '2.01';
	$debug		= undef;
	$debuglines	= 0;
}

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

Apache::XPP::Cache::Expiry provides a barebones AUTOLOAD for XPP's Cache-Expiry classes.

=head1 METHDOS

=over

=item C<r> (  )

Returns the Apache request object

=cut
*r = \&{ "Apache::XPP::r" };

*AUTOLOAD = \&{ "Apache::XPP::AUTOLOAD" };

1;

__END__

=back

=head1 REVISION HISTORY

 $Log: Expiry.pm,v $
 Revision 1.7  2002/01/16 21:06:01  kasei
 Updated VERSION variables to 2.01

 Revision 1.6  2000/09/11 20:12:23  david
 Various minor code efficiency improvements.

 Revision 1.5  2000/09/07 19:02:41  dougw
 Pod, over fix

 Revision 1.4  2000/09/07 18:50:01  dougw
 Fixed pod error

 Revision 1.3  2000/09/07 18:44:52  dougw
 POD updates.


=head1 AUTHORS

Greg Williams <greg@cnation.com>

=head1 SEE ALSO

perl(1).
Apache::XPP
Apache::XPP::Cache

=cut

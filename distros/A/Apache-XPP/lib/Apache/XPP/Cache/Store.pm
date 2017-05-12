# Apache::XPP::Cache::Store
#----------------------------
# $Revision: 1.6 $
# $Date: 2002/01/16 21:06:01 $
#---------------------------------

=head1 NAME

Apache::XPP::Cache::Store - Cache store superclass

=cut

package Apache::XPP::Cache::Store;

=head1 SYNOPSIS

...

=head1 REQUIRES

Carp

=cut

use Carp;
use strict;
use vars qw( $AUTOLOAD $debug $debuglines );

BEGIN {
	$Apache::XPP::Cache::Store::REVISION = (qw$Revision: 1.6 $)[-1];
	$Apache::XPP::Cache::Store::Version  = '2.01';
	$debug		= undef;
	$debuglines	= 0;
}

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

Apache::XPP::Cache::Store provides a barebones AUTOLOAD for XPP's Cache-Store classes.

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

 $Log: Store.pm,v $
 Revision 1.6  2002/01/16 21:06:01  kasei
 Updated VERSION variables to 2.01

 Revision 1.5  2000/09/11 20:12:23  david
 Various minor code efficiency improvements.

 Revision 1.4  2000/09/07 19:02:14  dougw
 Pod, over fix.

 Revision 1.3  2000/09/07 18:50:52  dougw
 Pod fixes


=head1 AUTHORS

Greg Williams <greg@cnation.com>

=head1 SEE ALSO

perl(1).
Apache::XPP
Apache::XPP::Cache

=cut

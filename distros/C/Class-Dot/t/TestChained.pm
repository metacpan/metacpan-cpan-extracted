# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package TestChained;

use strict;
use warnings;

use Class::Dot qw(-new -chained :std);

property name           => isa_String;
property email          => isa_String;
property address        => isa_String;
property birthdate_year => isa_Int;

1;

__END__

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround

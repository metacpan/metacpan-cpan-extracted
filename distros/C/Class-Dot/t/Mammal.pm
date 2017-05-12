# $Id: Mammal.pm 24 2007-10-29 17:15:19Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/branches/stable-1.5.0/t/Mammal.pm $
# $Revision: 24 $
# $Date: 2007-10-29 18:15:19 +0100 (Mon, 29 Oct 2007) $
package Mammal;

use strict;
use warnings;

use Class::Dot qw( -new property isa_Data isa_Hash );

property brain  => isa_Hash;
property dna    => isa_Data;

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround

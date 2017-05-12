# Copyrights 2009-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Data::DublinCore::Util;
use vars '$VERSION';
$VERSION = '1.00';

use base 'Exporter';

our @EXPORT      = qw/
    NS_DC_DCMITYPE
    NS_DC_ELEMS11
    NS_DC_TERMS
  /;


use constant
 { NS_DC_ELEMS11  => 'http://purl.org/dc/elements/1.1/'
 , NS_DC_DCMITYPE => 'http://purl.org/dc/dcmitype/'
 , NS_DC_TERMS    => 'http://purl.org/dc/terms/'
 };

1;

# Copyrights 2009-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package BPM::XPDL::Util;
use vars '$VERSION';
$VERSION = '0.93';

use base 'Exporter';

our @EXPORT      = qw/
 NS_XPDL_009
 NS_XPDL_10
 NS_XPDL_20
 NS_XPDL_21
 NS_XPDL_22
/;

our %EXPORT_TAGS =
 ( xpdl009 => [ qw/NS_XPDL_009/           ]
 , xpdl10  => [ qw/NS_XPDL_10/            ]
 , xpdl20  => [ qw/NS_XPDL_20 NS_XPDL_10/ ]
 , xpdl21  => [ qw/NS_XPDL_21 NS_XPDL_20 NS_XPDL_10/ ]
 , xpdl22  => [ qw/NS_XPDL_22 NS_XPDL_20 NS_XPDL_10/ ]
 );


use constant
 { NS_XPDL_009 => 'http://www.wfmc.org/2002/XPDL1.0'
 , NS_XPDL_10  => 'http://www.wfmc.org/2002/XPDL1.0'
 , NS_XPDL_20  => 'http://www.wfmc.org/2004/XPDL2.0alpha'
 , NS_XPDL_21  => 'http://www.wfmc.org/2008/XPDL2.1'
 , NS_XPDL_22  => 'http://www.wfmc.org/2009/XPDL2.2'
 };

1;

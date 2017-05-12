#!/usr/bin/perl -w

#!/usr/bin/perl -w

#=============================================================================
#
# $Id: test.t,v 0.02 2002/02/05 01:09:21 mneylon Exp $
# $Revision: 0.02 $
# $Author: mneylon $
# $Date: 2002/02/05 01:09:21 $
# $Log: test.t,v $
# Revision 0.02  2002/02/05 01:09:21  mneylon
# Slight fix in POD docs
#
# Revision 0.01  2002/02/03 17:11:44  mneylon
# Initial release to Perlmonks
#
#
#=============================================================================


use CGI;
use CGI::ToXML qw( CGItoXML );
use Test::Simple tests=>1;

$query = new CGI('dinosaur=barney&dinosaur=grimus&color=purple');

ok( CGItoXML( $query ), "XML Creation" );
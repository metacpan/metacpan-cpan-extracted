#
# file: t/use.t
#
# Last Update:		$Author: marvin $
# Update Date:		$Date: 2007/11/27 16:51:44 $
# Source File:		$Source: /home/cvsroot/tools/FileSystem/t/00_shell.t,v $
# CVS/RCS Revision:	$Revision: 1.1 $
# Status:		$State: Exp $
# 
use strict;
use Test;

# use a BEGIN block so we print our plan before FileSystem is loaded
BEGIN { plan tests => 1 }

# load your module...
use DBIx::FileSystem;

print "# currently no usefull test available for an interactive shell\n";
ok(1); # success

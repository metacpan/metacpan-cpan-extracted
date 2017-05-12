#!/usr/bin/env perl -w

# Creation date: 2003-08-13 20:57:24
# Authors: Don
# Change log:
# $Id: 00use.t,v 1.1 2003/10/07 04:44:06 don Exp $

use strict;

# main
{
    use Test;
    BEGIN { plan tests => 1 }
    
    use Apache::Authen::Generic; ok(1);

}

exit 0;

###############################################################################
# Subroutines


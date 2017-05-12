#!/usr/bin/env perl -w

# Creation date: 2004-01-31 20:39:15
# Authors: Don
# Change log:
# $Id: 00use.t,v 1.1 2004/02/01 05:00:17 don Exp $

use strict;

# main
{
    use Test;
    BEGIN { plan tests => 1 }
    
    use Class::Config; ok(1);

}

exit 0;

###############################################################################
# Subroutines


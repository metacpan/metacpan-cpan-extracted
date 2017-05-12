#!/usr/bin/env perl -w

# Creation date: 2003-03-05 07:42:25
# Authors: Don
# Change log:
# $Id: 00use.t,v 1.4 2005/10/19 04:34:08 don Exp $

use strict;

# main
{
    use strict;
    use Test;

    # BEGIN { plan tests => 1 }

    # use DBIx::Wrapper; ok(1);
    
    use vars qw($Skip);
    BEGIN {
        eval 'use DBI';
        if ($@) {
            plan tests => 1;
            print STDERR "\n\n  " . '=' x 10 . '> ';
            print STDERR "Skipping tests because DBI is not installed.\n";
            print STDERR "  " . '=' x 10 . '> ';
            print STDERR "You must install DBI before this module will work.\n\n";
            $Skip = 1;
            die "$@";
        } else {
            plan tests => 1;
            $Skip = 0;
        }
    }
        
    eval 'require DBIx::Wrapper'; skip($Skip, ($Skip ? 1 : not $@));

}

exit 0;

###############################################################################
# Subroutines


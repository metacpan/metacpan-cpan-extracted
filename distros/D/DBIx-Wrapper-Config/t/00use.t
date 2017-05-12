#!/usr/bin/env perl

# Creation date: 2005-10-23 19:42:34
# Authors: don

use strict;

# main
{
    use Test;
    
    BEGIN { plan tests => 1 }

    use DBIx::Wrapper::Config; ok(1);
}

exit 0;

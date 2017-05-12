#!/usr/bin/perl
# $Id: 00_load.t 17 2009-01-24 10:38:38Z rjray $

use 5.008;
use strict;
use vars qw(@MODULES);

use Test::More;

BEGIN
{
    @MODULES = qw(App::Changelog2x);

    plan tests => scalar(@MODULES);
}

use_ok($_) for (@MODULES);

exit 0;

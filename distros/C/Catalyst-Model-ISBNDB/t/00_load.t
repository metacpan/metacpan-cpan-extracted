#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

# $Id$
# Ensure that the modules load

BEGIN {
    use_ok('Catalyst::Model::ISBNDB');
    use_ok('Catalyst::Helper::Model::ISBNDB');
}

exit;

#################################################################
#
#   $Id: 01_test_compile.t,v 1.1.1.1 2006/04/28 13:58:15 erwan Exp $
#

use strict;
use warnings;
use Test::More;
use lib "../lib";
use lib "lib";

BEGIN {
    eval "use Class::Accessor"; plan skip_all => "Class::Accessor is required for testing Class::DBI::AutoIncrement" if $@;
    plan tests => 1;
    use_ok('Class::DBI::AutoIncrement');
};



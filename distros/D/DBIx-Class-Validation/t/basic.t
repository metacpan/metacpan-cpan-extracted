#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test tests => 1;

    use_ok('DBIx::Class::Validation');
};

#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test tests => 2;

    use_ok('DBIx::Class::UUIDColumns');
    use_ok('DBIx::Class::UUIDColumns::UUIDMaker');
};

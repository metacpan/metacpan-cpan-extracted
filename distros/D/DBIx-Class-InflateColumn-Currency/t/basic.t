#!perl -wT
# $Id: /local/DBIx-Class-InflateColumn-Currency/t/basic.t 1282 2007-02-09T20:58:19.038513Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test tests => 1;

    use_ok('DBIx::Class::InflateColumn::Currency');
};

#!perl -wT
# $Id: /local/DBIx-Class-InflateColumn-Currency/t/style_no_tabs.t 1286 2007-05-05T02:09:49.782972Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test;

    plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

    eval 'use Test::NoTabs 0.03';
    plan skip_all => 'Test::NoTabs 0.03 not installed' if $@;
};

all_perl_files_ok('lib');

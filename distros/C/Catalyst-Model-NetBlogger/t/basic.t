#!perl -wT
# $Id: /local/CPAN/Catalyst-Model-NetBlogger/t/basic.t 1390 2005-12-08T23:40:44.862870Z claco  $
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok('Catalyst::Model::NetBlogger');
    use_ok('Catalyst::Helper::Model::NetBlogger');
};

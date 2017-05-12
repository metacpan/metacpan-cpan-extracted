#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok('Catalyst::Model::Facebook');
    use_ok('Catalyst::Helper::Model::Facebook');
}

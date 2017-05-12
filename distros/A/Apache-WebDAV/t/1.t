#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
    use_ok('Apache::WebDAV');
};


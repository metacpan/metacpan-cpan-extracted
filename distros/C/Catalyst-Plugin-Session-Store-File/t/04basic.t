#!/usr/bin/perl

use strict;
use warnings;

use File::Temp qw/tempdir/;

use Catalyst::Plugin::Session::Test::Store (
    backend => "File",
    config  => {
        storage => tempdir( CLEANUP => 1 ),    # $tmp: positive refcount
    },
);


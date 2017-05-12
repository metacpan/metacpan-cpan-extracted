#!perl

use strict;
use warnings;
use Test::More $] < 5.010 ? (skip_all => 'broken Time::HiRes on perl 5.8') : ();
use FindBin '$Bin';
use lib "$Bin/lib";
use TestApp;
use Test::Warnings;
use Time::HiRes;
use Time::Out 'timeout';

timeout 0.1 => sub {
    local $@;
    eval { TestApp->new->request->path };
    like $@, qr/^Can't call method "path" on an undefined value at/,
        'no infinite recursion when $req->uri is undef';
};

done_testing;

# vim: expandtab shiftwidth=4 ts=4 tw=80:

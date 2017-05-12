#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';

{   package MyTestSchemaReplacer;
    sub txn_do {
        my ($self, $code) = @_;
        ::ok('txn_do called...');
        $code->();
        ::ok('txn_do exitting...');
    }
};

use Catalyst::Test 'TestApp';

get('/foo/bar');

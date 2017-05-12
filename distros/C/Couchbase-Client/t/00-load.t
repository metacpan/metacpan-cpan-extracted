#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Couchbase::Client');
    use_ok('Couchbase::Client::Async');
}
done_testing();

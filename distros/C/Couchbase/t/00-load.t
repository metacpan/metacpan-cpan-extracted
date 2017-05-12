#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Couchbase::Bucket');
    use_ok('Couchbase::Document');
    use_ok('Couchbase::Constants');
}
done_testing();

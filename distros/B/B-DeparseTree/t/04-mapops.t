#!/usr/bin/env perl
use rlib '.';
use helper;
use strict;
use English;

use feature (sprintf(":%vd", $^V)); # to avoid relying on the feature
                                    # logic to add CORE::

BEGIN {
    plan skip_all => 'Need Perl 5.20 or greater for this test'
	if $] < 5.020;
}
test_ops('mapops.pm');
done_testing();

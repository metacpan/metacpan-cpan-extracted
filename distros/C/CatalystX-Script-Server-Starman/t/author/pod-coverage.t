#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Pod::Coverage 1.04;
all_pod_coverage_ok({
    trustme => [qr/^print_usage_text$/]
});

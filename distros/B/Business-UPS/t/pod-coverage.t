use strict;
use warnings;
use Test::More;

plan skip_all => 'Author tests not required for installation'
    unless $ENV{AUTHOR_TESTING};

eval 'use Test::Pod::Coverage 1.08';
plan skip_all => 'Test::Pod::Coverage 1.08 required' if $@;

# Error() is a legacy internal sub pending removal (PR #23).
# Exclude it from coverage until then.
all_pod_coverage_ok({ trustme => [qr/^Error$/] });

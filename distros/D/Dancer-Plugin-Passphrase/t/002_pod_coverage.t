use Test::More;

use strict;
use warnings;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

plan tests => 1;

# Trustme contains subs that are deprecated, and just wrappers for renamed versions
pod_coverage_ok(
    "Dancer::Plugin::Passphrase",
    { trustme => ['as_rfc2307', 'generate_hash', 'raw_hash', 'raw_salt'] },
    "Dancer::Plugin::Passphrase has full POD coverage"
);

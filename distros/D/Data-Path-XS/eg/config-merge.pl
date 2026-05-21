#!/usr/bin/env perl
# config-merge: apply a list of "PATH=VALUE" overrides to a JSON config.
#
# Usage:
#   perl eg/config-merge.pl base.json /db/host=db1 /db/port=5433 \
#                                      /features/0/enabled=true
#
# Each override is "PATH=VALUE". VALUE is parsed as JSON if possible
# (so 5433, true, false, null, [1,2,3], {"k":"v"} all work), otherwise
# treated as a string literal. Output is pretty-printed JSON.
#
# Demonstrates path_set's autovivification — overrides may create
# entirely new branches in the config tree.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use JSON::PP;
use Data::Path::XS qw(path_set);

@ARGV >= 2 or die <<'USE';
Usage: config-merge.pl base.json PATH=VALUE [PATH=VALUE ...]
Examples:
   /db/host=primary
   /db/port=5433
   /features/0/enabled=true
   /tags='["staging","priority"]'
USE

my $file = shift @ARGV;
open my $fh, '<', $file or die "$file: $!";
my $cfg = decode_json(do { local $/; <$fh> });

for my $kv (@ARGV) {
    my ($path, $raw) = split /=/, $kv, 2;
    $path && length $raw or die "bad override '$kv' (need PATH=VALUE)\n";

    my $val = eval { decode_json($raw) };
    $val = $raw if $@;
    path_set($cfg, $path, $val);
}

my $json = JSON::PP->new->utf8->pretty->canonical;
print $json->encode($cfg);

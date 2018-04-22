use v5.22;
use strict;
use warnings;
use Test::More;
eval { require Test::Kwalitee::Extra; Test::Kwalitee::Extra->import(qw(:experimental !has_known_license_in_source_file)); };
plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;
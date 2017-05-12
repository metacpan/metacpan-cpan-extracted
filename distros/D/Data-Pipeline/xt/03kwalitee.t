use Test::More;

# we don't test for 'use strict' since we're using Moose
eval { require Test::Kwalitee; Test::Kwalitee->import(tests => [qw(-use_strict)]) };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

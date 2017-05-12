#!/usr/bin/env perl

use t::TestHelper;

plan tests => 6;

use_ok('Bio::Cellucidate::Base');

# args
is_deeply(Bio::Cellucidate::Base->args( { foo => 'bar' }), { foo => 'bar' }, "Should parse arguments properly");
is_deeply(Bio::Cellucidate::Base->args('foo'), 'foo', "Should parse arguments properly");

# formulate_query
my $args = { foo => 'bar', fizzle => 'fuzzle' };
like(Bio::Cellucidate::Base->formulate_query($args), qr/^\?.*/, "Should parse arguments properly");
like(Bio::Cellucidate::Base->formulate_query($args), qr/foo=bar/, "Should parse arguments properly");
like(Bio::Cellucidate::Base->formulate_query($args), qr/fizzle=fuzzle/, "Should parse arguments properly");

1;

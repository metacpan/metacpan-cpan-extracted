use strict;
use warnings;
use Test::More;

eval { require Test::Perl::Critic; 1 }
    or plan skip_all => 'Test::Perl::Critic required';

# Severity 5 (the highest, "stop the world" issues only). The .pm is a
# 50-line keyword/import shim — PBP advice about return-from-import,
# unpacking @_, or local-ising $^H does not apply (the whole point of
# import is to set $^H lexically in the caller).
Test::Perl::Critic->import( -severity => 5 );
Test::Perl::Critic::all_critic_ok('lib');

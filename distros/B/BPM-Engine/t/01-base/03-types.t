use strict;
use warnings;
use Test::More;
use Test::Exception;

use BPM::Engine::Exceptions;
use BPM::Engine::Types qw/Exception/;

eval { BPM::Engine::Exception->throw(error => 'I feel funny.') };
my $e = $@;
ok(is_Exception($e));

done_testing;

use Test::More tests => 2;
use strict;
use warnings;

BEGIN { use_ok 'Acme::AliG' }

is alig('hello') => 'allo', 'allo';

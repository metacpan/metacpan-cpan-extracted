#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

BEGIN {
    use_ok 'Catmandu::Cmd::breaker';
}

require_ok 'Catmandu::Cmd::breaker';

done_testing;

#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

BEGIN {
    use_ok 'Catmandu::Breaker';
}

require_ok 'Catmandu::Breaker';

done_testing;

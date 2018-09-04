#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

BEGIN {
    use_ok 'Catmandu::Exporter::Breaker::Parser::mab';
}

require_ok 'Catmandu::Exporter::Breaker::Parser::mab';

done_testing;

#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

BEGIN {
    use_ok 'Catmandu::Exporter::Breaker::Parser::marc';
}

require_ok 'Catmandu::Exporter::Breaker::Parser::marc';

done_testing;

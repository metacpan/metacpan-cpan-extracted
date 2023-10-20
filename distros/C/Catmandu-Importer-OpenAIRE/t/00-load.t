#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Importer::OpenAIRE';
}

require_ok 'Catmandu::Importer::OpenAIRE';

done_testing 2;
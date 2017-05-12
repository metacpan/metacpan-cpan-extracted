#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Importer::OAI';
}

require_ok 'Catmandu::Importer::OAI';

done_testing 2;

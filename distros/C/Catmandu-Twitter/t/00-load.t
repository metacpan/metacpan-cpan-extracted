#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Importer::Twitter';
}

require_ok 'Catmandu::Importer::Twitter';

done_testing 2;
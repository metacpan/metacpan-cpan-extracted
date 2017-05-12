use strict;
use warnings;
use Test::More;

use_ok 'Catmandu::Importer::Wikidata';
use_ok 'Catmandu::Fix::wd_language';
use_ok 'Catmandu::Fix::wd_simple_strings';
use_ok 'Catmandu::Fix::wd_simple_claims';
use_ok 'Catmandu::Fix::wd_simple';
use_ok 'Catmandu::Wikidata';

done_testing;

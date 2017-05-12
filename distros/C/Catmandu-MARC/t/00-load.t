#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Importer::MARC';
    use_ok 'Catmandu::Exporter::MARC';
    use_ok 'Catmandu::Fix::marc_map';
    use_ok 'Catmandu::Fix::marc_xml';
    use_ok 'Catmandu::Fix::marc_in_json';
    use_ok 'Catmandu::Fix::marc_set';
    use_ok 'Catmandu::Fix::marc_remove';
    use_ok 'Catmandu::Fix::marc_add';
    use_ok 'Catmandu::Fix::marc_spec';
    use_ok 'Catmandu::Fix::marc_decode_dollar_subfields';
    use_ok 'Catmandu::Fix::Condition::marc_match';
}

done_testing 11;

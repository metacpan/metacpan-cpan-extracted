#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Fix::geocode';
    use_ok 'Catmandu::Fix::reverse_geocode';
}

require_ok 'Catmandu::Fix::geocode';
require_ok 'Catmandu::Fix::reverse_geocode';

done_testing 4;

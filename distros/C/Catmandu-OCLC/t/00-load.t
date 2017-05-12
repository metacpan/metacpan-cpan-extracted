#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Fix::xID';
    use_ok 'Catmandu::OCLC';
    use_ok 'Catmandu::OCLC::xID';
}

done_testing 3;

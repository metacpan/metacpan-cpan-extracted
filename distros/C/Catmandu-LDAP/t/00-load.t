#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Importer::LDAP';
}

require_ok 'Catmandu::Importer::LDAP';

done_testing 2;

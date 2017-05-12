#!/usr/bin/perl -w
use strict;

use Test::More tests => 13;

BEGIN {
    use_ok 'Data::Phrasebook';
	use_ok 'Data::Phrasebook::Debug';
	use_ok 'Data::Phrasebook::Generic';
	use_ok 'Data::Phrasebook::Loader';
	use_ok 'Data::Phrasebook::Loader::Base';
	use_ok 'Data::Phrasebook::Loader::Text';
	use_ok 'Data::Phrasebook::Plain';
	use_ok 'Data::Phrasebook::SQL';
	use_ok 'Data::Phrasebook::SQL::Query';
}

use lib 't/lib';
BEGIN {
    use_ok 'BookDB';
    use_ok 'MyClass';
    use_ok 'MyPhrasebook';
	use_ok 'Data::Phrasebook::Loader::Fake';
}

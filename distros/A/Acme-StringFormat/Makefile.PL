use 5.010_000;
use strict;
use warnings;

use inc::Module::Install;

name 'Acme-StringFormat';

all_from 'StringFormat.pm';

test_requires
	'Test::Exception' => 0.27,
	'Test::Warn' => 0.11;

WriteAll;

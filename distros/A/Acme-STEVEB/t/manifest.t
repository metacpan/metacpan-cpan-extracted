use warnings;
use strict;

use Test::More;
use ExtUtils::Manifest;

is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';

done_testing;

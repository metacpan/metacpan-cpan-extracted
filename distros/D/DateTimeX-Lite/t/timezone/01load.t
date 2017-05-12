use strict;
use warnings;

use File::Spec;
use Test::More;

use lib File::Spec->catdir( File::Spec->curdir, 't' );

plan tests => 1;

use_ok('DateTimeX::Lite::TimeZone');


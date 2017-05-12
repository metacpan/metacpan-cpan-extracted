use Test::More;
use strict;
use warnings;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

plan( tests => 3 );

use_ok 'Dancer2::Plugin::Auth::YARBAC';
use_ok 'Dancer2::Plugin::Auth::YARBAC::Provider::Base';
use_ok 'Dancer2::Plugin::Auth::YARBAC::Provider::Database';

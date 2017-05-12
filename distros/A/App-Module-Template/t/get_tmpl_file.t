#!perl

use strict;
use warnings;

use Test::More tests => 3;

use_ok( 'App::Module::Template::Initialize', '_get_tmpl_file' );

is( _get_tmpl_file(), undef, 'returns undef' );
is( _get_tmpl_file('changes'), 'Changes', 'returns template file' );

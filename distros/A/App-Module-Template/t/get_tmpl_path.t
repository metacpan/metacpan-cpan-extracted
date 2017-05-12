#!perl

use strict;
use warnings;

use Test::More tests => 3;

use_ok( 'App::Module::Template::Initialize', '_get_tmpl_path' );

is( _get_tmpl_path(), undef, 'returns undef' );
is( _get_tmpl_path('changes'), '.module-template/templates', 'returns template path' );

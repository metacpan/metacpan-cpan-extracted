#!perl

use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'App::Module::Template::Initialize', '_get_tmpl_body' );

ok( my $body = <<'END_OF_BODY',
Revision history for [% module %]

Author [% author %]
Email [% email %]

0.01    [% today %]
        [% module %] created

END_OF_BODY
, 'set template body' );

is( _get_tmpl_body(), undef, 'returns undef' );
is( _get_tmpl_body('changes'), $body, 'returns template body' );

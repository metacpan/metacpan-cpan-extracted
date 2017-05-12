#!perl
use Test::More tests => 3;

require Acme::Nothing;
pass('Loaded Acme::Nothing');

require CGI;
pass(q{"Loaded" CGI});

ok( ! CGI::->can('new'), "Didn't actually load CGI" );

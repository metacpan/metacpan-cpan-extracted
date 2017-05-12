# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Bot::BasicBot::Pluggable::Module::HTTPIRCGW' ); }

my $object = Bot::BasicBot::Pluggable::Module::HTTPIRCGW->new ();
isa_ok ($object, 'Bot::BasicBot::Pluggable::Module::HTTPIRCGW');



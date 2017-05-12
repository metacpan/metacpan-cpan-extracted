# -*- perl -*-

# t/001_load.t - check module loading

use Test::More tests => 6;

#01
BEGIN { use_ok 'Bot::BasicBot::Pluggable::Module::RD_Basic'; }

my $object;

eval { $object = Bot::BasicBot::Pluggable::Module::RD_Basic->new };

#02
like( $@, qr/load RD module/, "Threw exception if RD not loaded" );

eval { require 'Bot/BasicBot/Pluggable/Module/RD.pm' };

#03
ok( !$@, "Got RD module" );

diag $@ if $@;

$object = Bot::BasicBot::Pluggable::Module::RD->new;

#04
isa_ok( $object, 'Bot::BasicBot::Pluggable::Module::RD' );

eval { $object = Bot::BasicBot::Pluggable::Module::RD_Basic->new };

#05
ok( !$@, "RD_Basic worked after RD" );

#06
isa_ok( $object, 'Bot::BasicBot::Pluggable::Module::RD_Basic' );

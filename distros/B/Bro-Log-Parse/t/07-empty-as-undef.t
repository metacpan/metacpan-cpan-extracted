use 5.10.1;
use strict;
use warnings;

use Test::More tests=>2;

BEGIN { use_ok( 'Bro::Log::Parse' ); }

my $parse = Bro::Log::Parse->new({file => 'logs/ssl.log', empty_as_undef => 1});
my $line = $parse->getLine();
is($line->{client_cert_chain_fuids}, undef, "client_cert_chain_fuids");


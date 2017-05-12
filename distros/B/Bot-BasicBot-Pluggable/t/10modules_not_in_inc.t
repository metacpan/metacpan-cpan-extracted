use Test::More tests => 4;
use Test::Bot::BasicBot::Pluggable;

chdir("t/modules/");

my $bot = Test::Bot::BasicBot::Pluggable->new();
my %available = map { $_ => 1 } $bot->available_modules;

ok( $available{Foo}, 'modules in curdir are available' );
ok( $available{Bar}, 'modules in ./modules are available' );

ok( $bot->load('Foo'), 'load modules in curdir' );
ok( $bot->load('Bar'), 'load modules in ./modules' );

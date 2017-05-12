use Test::More;

use App::Kit;

diag("Testing http() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

ok( !exists $INC{'HTTP/Tiny.pm'}, 'lazy under pinning not loaded before' );
isa_ok( $app->http(), 'HTTP::Tiny' );
ok( exists $INC{'HTTP/Tiny.pm'}, 'lazy under pinning loaded after' );

done_testing;

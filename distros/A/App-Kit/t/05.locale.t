use Test::More;

use App::Kit;

diag("Testing locale() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

ok( !exists $INC{'Locale/Maketext/Utils/Mock.pm'}, 'lazy under pinning not loaded before' );
isa_ok( $app->locale, 'Locale::Maketext::Utils::Mock::en' );
ok( exists $INC{'Locale/Maketext/Utils/Mock.pm'}, 'lazy under pinning loaded after' );

is( $app->locale->maketext( 'Hello World: [_1]', 42 ), 'Hello World: 42', 'locale can maketext' );

done_testing;

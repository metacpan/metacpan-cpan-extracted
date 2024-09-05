use Test::More;
use Ascii::Text::Image;
use lib '.';

my $ascii = Ascii::Text::Image->new( color => 'red', imager_font => 't/RobotoMono.ttf' );
$ascii->render("Hello World", "test.png", 1);

ok(1);

done_testing();

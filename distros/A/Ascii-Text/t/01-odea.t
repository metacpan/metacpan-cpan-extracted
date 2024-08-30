use Test::More;

use Ascii::Text;

my $text = Ascii::Text->new( font => 'Boomer' );

$text->("Hello World");

$text->font("Amongus");

$text->("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");

is($text->font_class, 'Ascii::Text::Font::Amongus');

ok(1);

done_testing();

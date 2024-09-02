use Test::More;

use Ascii::Text;

my $text = Ascii::Text->new( font => 'Boomer', align  => 'center' );

$text->("Hello World");

$text->font("Block");

$text->("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");

is($text->font_class, 'Ascii::Text::Font::Block');

my $a = $text->stringify("A");

print $a;

ok(1);

done_testing();

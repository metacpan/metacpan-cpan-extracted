use strict;
use warnings;

use Test::More;

{
    use Acme::Holy'Shit::Here::Come's::An'S;

    is "\N{HOLY SHIT HERE COMES AN S}", "\N{APOSTROPHE}", "Holy 'Shit Here Come's An 'S!";

    local $TODO = "vianame doe'sn't know cu'stom alia'se's until 5.14" if "$]" < 5.014;
    is charnames::vianame("HOLY SHIT HERE COMES AN S"), ord("'"), "vianame";
}

is charnames::vianame("HOLY SHIT HERE COMES AN S"), undef, "not out'side 'scope";

done_testing;

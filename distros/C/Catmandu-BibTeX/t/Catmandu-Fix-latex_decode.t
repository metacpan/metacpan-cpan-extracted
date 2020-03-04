use Test2::V0;
use Catmandu::Fix::latex_decode;

my $pkg = "Catmandu::Fix::latex_decode";

my $strA
    = '\\S{}\\L\\^e\\={\\i}\\u j\\`{i}\\H u\\o\\c{S}{\\u {v}}{\\~{\\i}}\"a';

my $resA1 = '§Łêīj̆ìűøŞ{v̆}{ĩ}ä';
my $resA2 = '§Łêīj̆ìűøŞv̆ĩä';

is $pkg->new('name')->fix({name => $strA}), {name => $resA1}, "latex_decode";

is $pkg->new('name', strip_outer_braces => 1)->fix({name => $strA}),
    {name => $resA2}, "latex_decode with strip_outer_braces";

done_testing;

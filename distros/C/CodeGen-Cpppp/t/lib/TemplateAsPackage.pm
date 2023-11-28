package TemplateAsPackage;
use CodeGen::Cpppp::Template -setup => 0;

compile_cpppp '__DATA__';

__DATA__
## param $p0 = 1;
## param $p1 = 2;

Initial Line of Output

## sub more_lines($text, $count) {
$text ## for 1..$count;
## }



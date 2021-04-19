# t/40-dline.t v0.0.1-1
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw(lib ../lib);
use Book::Bilingual::Dline;

my ($sub, $got, $exp, $msg, $tmp, $tmp1, $tmp2, $tmp3);


BEGIN {
    use_ok( 'Book::Bilingual::Dline' ) || print "Bail out!\n";
}
{ ## Basic test
$msg = 'Basic test -- Ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);
}
{ ## new($href) works
$msg = 'new($href) works';
$tmp = Book::Bilingual::Dline->new({class=>'chapter-title', str=>'A Great Surprise'});
$got = $tmp->class.$tmp->str;
$exp = 'chapter-titleA Great Surprise';
is($got, $exp, $msg);
}{ ## to_html works
$msg = 'to_html works';
$tmp = Book::Bilingual::Dline->new;
$tmp->class('chapter-title')->str('A Great Surprise');
$got = $tmp->to_html;
$exp = "<div class=\"chapter-title\">A Great Surprise</div>";
is($got, $exp, $msg);
}


done_testing();


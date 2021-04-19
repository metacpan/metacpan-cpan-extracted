# t/30-dlineset.t v0.0.1-1
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw(lib ../lib);
use Book::Bilingual::Dline;
use Book::Bilingual::Dlineset;

my ($sub, $got, $exp, $msg, $tmp, $tmp1, $tmp2, $tmp3);


BEGIN {
    use_ok( 'Book::Bilingual::Dline' ) || print "Bail out!\n";
    use_ok( 'Book::Bilingual::Dlineset' ) || print "Bail out!\n";
}
{ ## Basic test
$msg = 'Basic test -- Ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);
}
{ ## $dlineset->push($dline) result in correct length
$msg = '$dlineset->push($dline) result in correct length';
$tmp = Book::Bilingual::Dline->new({class=>'chapter-title',str=>'A Great Surprise'});
$got = Book::Bilingual::Dlineset->new->push($tmp)->dline_count;
$exp = 1;
is($got, $exp, $msg);
}
{ ## $dlineset->push($dline) dies on bad type
$msg = '$dlineset->push($dline) dies on bad type';
eval { Book::Bilingual::Dlineset->new->push({})->dline_count; };
$got = $@ =~ /Not a Book::Bilingual::Dline/ ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);
}

{ ## $dlineset->at($idx) returns correct Dline
$msg = '$dlineset->at($idx) returns correct Dline';
$tmp  = Book::Bilingual::Dlineset->new;
$tmp1 = Book::Bilingual::Dline->new({class=>'chapter-number',str=>'Chapter One'});
$tmp2 = Book::Bilingual::Dline->new({class=>'chapter-title',str=>'A Great Surprise'});
$tmp->push($tmp1)->push($tmp2);
$got = $tmp->dline_at(1)->to_html;
$exp = '<div class="chapter-title">A Great Surprise</div>';
is($got, $exp, $msg);
}


done_testing();


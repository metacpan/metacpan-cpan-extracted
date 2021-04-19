# t/50-reader.t v0.0.1-1
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw(lib ../lib);
use Book::Bilingual::Reader;

my ($sub, $got, $exp, $msg, $tmp, $tmp1, $tmp2, $tmp3);


BEGIN {
    use_ok( 'Book::Bilingual::Reader' ) || print "Bail out!\n";
}
{ ## Basic test
$msg = 'Basic test -- Ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);
}
{ ## Self->file is a Path::Tiny object
$msg = 'file is a Path::Tiny object';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = ref $tmp->file;
$exp = 'Path::Tiny';
is($got, $exp, $msg);
}
{ ## Self->book is a Book::Bilingual object
$msg = 'Self->book is a Book::Bilingual object';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = ref $tmp->book;
$exp = 'Book::Bilingual';
is($got, $exp, $msg);
}

{ ## Self->_chapter_dlines loaded the correct set of lines
$msg = 'Self->_chapter_dlines loaded the correct set of lines';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = scalar keys %{$tmp->_chapter_dlines};
$exp = '6';
is($got, $exp, $msg);
}
{ ## Self->_curr_dlineset loaded the correct set of lines
$msg = 'Self->_curr_dlineset loaded the correct set of lines';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = scalar keys %{$tmp->_curr_dlineset};
$exp = '3';
is($got, $exp, $msg);
}

{ ## Self->html returns correct string
$msg = 'Self->html returns correct string';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = $tmp->html =~ /They are quite full this year/m ? 1 : 0;
$exp = '1';
is($got, $exp, $msg);
}
{ ## _render_normal("chapter-number",$str,"0.0.0") returns correct string
$msg = '_render_normal("chapter-number",$str,"0.0.0") returns correct string';
$tmp = Book::Bilingual::Reader::_render_normal('chapter-number',' /Chapter One','0.0.0');
$got = $tmp;
$exp = "\n  <h1 data-ptr=\"0.0.0\" class=\"chapter-number\">Chapter One </h1>\n";
is($got, $exp, $msg);
}
{ ## _render_normal("chapter-title",$str,"0.1.0") returns correct string
$msg = '_render_normal("chapter-title",$str,"0.1.0") returns correct string';
$tmp = Book::Bilingual::Reader::_render_normal('chapter-title',' /A Great One','0.1.0');
$got = $tmp;
$exp = "\n  <h2 data-ptr=\"0.1.0\" class=\"chapter-title\">A Great One </h2>";
is($got, $exp, $msg);
}
{ ## _render_normal("paragraph-start",$str,"0.2.0") returns correct string
$msg = '_render_normal("paragraph-start",$str) returns correct string';
$tmp = Book::Bilingual::Reader::_render_normal('paragraph-start',' /A Great','0.2.0');
$got = $tmp;
$exp = "\n\n  <br/><span data-ptr=\"0.2.0\" class=\"paragraph-start\">A Great </span>";
is($got, $exp, $msg);
}
{ ## _render_normal("",$str,"0.3.0") returns correct string
$msg = '_render_normal("",$str,"0.3.0") returns correct string';
$tmp = Book::Bilingual::Reader::_render_normal('',' /A Great One','0.3.0');
$got = $tmp;
$exp = "<span data-ptr=\"0.3.0\">A Great One </span>";
is($got, $exp, $msg);
}

{ ## _render_pointed("chapter-number",'บทที่หนึ่ง /',"0.0.0") returns correct string
$msg = '_render_pointed("chapter-number","บทที่หนึ่ง /","0.0.0") returns correct string';
$tmp = Book::Bilingual::Reader::_render_pointed('chapter-number','บทที่หนึ่ง /','0.0.0');
$got = $tmp;
$exp = "\n  <h1 data-ptr=\"0.0.0\" class=\"chapter-number\"><span id=\"Ptr\" class=\"pointed\"><span class=\"src-lang\">บทที่หนึ่ง </span></span> </h1>\n";
is($got, $exp, $msg);
}
{ ## _render_pointed("chapter-number",'บทที่ /One',"0.0.0") returns correct string
$msg = '_render_pointed("chapter-number","บทที่ /One","0.0.0") returns correct string';
$tmp = Book::Bilingual::Reader::_render_pointed('chapter-number','บทที่ /One','0.0.0');
$got = $tmp;
$exp = "\n  <h1 data-ptr=\"0.0.0\" class=\"chapter-number\"><span id=\"Ptr\" class=\"pointed\"><span class=\"src-lang\">บทที่ </span>One</span> </h1>\n";
is($got, $exp, $msg);
}

{ ## _cmp_loc('0.0.0','0.0.0') returns 0
$msg = "_cmp_loc('0.0.0','0.0.0') returns 0";
$got = Book::Bilingual::Reader::_cmp_loc('0.0.0','0.0.0');
$exp = 0;
is($got, $exp, $msg);
}
{ ## _cmp_loc('0.1.0','0.0.1') returns 1
$msg = "_cmp_loc('0.1.0','0.0.1') returns 1";
$got = Book::Bilingual::Reader::_cmp_loc('0.1.0','0.0.1');
$exp = 1;
is($got, $exp, $msg);
}
{ ## _cmp_loc('0.1.2','0.1.13') returns -1
$msg = "_cmp_loc('0.1.2','0.1.13') returns -1";
$got = Book::Bilingual::Reader::_cmp_loc('0.1.2','0.1.13');
$exp = -1;
is($got, $exp, $msg);
}
{ ## _cmp_loc('0.1.23','0.1.13') returns 1
$msg = "_cmp_loc('0.1.23','0.1.13') returns 1";
$got = Book::Bilingual::Reader::_cmp_loc('0.1.23','0.1.13');
$exp = 1;
is($got, $exp, $msg);
}

{ ## _max_loc({'0.1.2'=>0,'0.1.13'=>0}) returns '0.1.13'
$msg = "_max_loc({'0.1.2'=>0,'0.1.13'=>0}) returns '0.1.13'";
$got = Book::Bilingual::Reader::_max_loc({'0.1.2'=>0,'0.1.13'=>0});
$exp = '0.1.13';
is($got, $exp, $msg);
}

{ ## _next_ptr Case 1: NOT end of current dlineset
$msg = '_next_ptr Case 1: NOT end of current dlineset';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = $tmp->_next_ptr->[0];
$exp = '0.0.1';
is($got, $exp, $msg);
}
{ ## _next_ptr Case 1: NOT end of dlineset
$msg = '_next_ptr Case 1: NOT end of dlineset';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = $tmp->_ptr([0,5,4])->_next_ptr->[0];
$exp = '0.5.5';
is($got, $exp, $msg);
}
{ ## _next_ptr Case 2: End of current dlineset, NOT end of dlines in chapter
$msg = '_next_ptr Case 2: End of current dlineset, NOT end of dlines in chapter';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = $tmp->_ptr([0,0,2])->_next_ptr->[0];
$exp = '0.1.0';
is($got, $exp, $msg);
}
{ ## _next_ptr Case 3: End of chapter dlineset, NOT end of chapters in book
$msg = '_next_ptr Case 3: End of chapter dlineset, NOT end of chapters in book';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = $tmp->_ptr([0,5,5])->_next_ptr->[0];
$exp = '1.0.0';
is($got, $exp, $msg);
}
{ ## _next_ptr Case 4: End of book chapters
$msg = '_next_ptr Case 4: End of book chapters';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = defined $tmp->_ptr([1,2,6])->_next_ptr ? 'nok' : 'ok';
$exp = 'ok';
is($got, $exp, $msg);
}

{ ## _prev_ptr Case 1: NOT at first Dline in current Dlineset
$msg = '_prev_ptr Case 1: NOT at first Dline in current Dlineset';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = $tmp->_ptr([0,5,4])->_prev_ptr->[0];
$exp = '0.5.3';
is($got, $exp, $msg);
}
{ ## _prev_ptr Case 2: At first Dline, curr Dlineset; NOT at first Dlineset in Chapter
$msg = '_prev_ptr Case 2: At first Dline, curr Dlineset; NOT at first Dlineset in Chapter';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
#say join('.',0,4,$tmp->book->chapter_dlineset_dline_len(0,4)-1);
$got = $tmp->_ptr([0,5,0])->_prev_ptr->[0];
$exp = '0.4.6';
is($got, $exp, $msg);
}
{ ## _prev_ptr Case 3: At first Dlineset in Chapter, NOT at first Chapter
$msg = '_prev_ptr Case 3: At first Dlineset in Chapter, NOT at first Chapter';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
#say join('.',0,4,$tmp->book->chapter_dlineset_dline_len(0,4)-1);
$got = $tmp->_ptr([1,0,0])->_prev_ptr->[0];
$exp = '0.5.5';
is($got, $exp, $msg);
}
{ ## _prev_ptr Case 4: At start of Book
$msg = '_prev_ptr Case 4: At start of book';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = defined $tmp->_ptr([0,0,0])->_prev_ptr ? 'nok' : 'ok';
$exp = 'ok';
is($got, $exp, $msg);
}

{ ## book_json() return correct JSON with correct length
$msg = 'book_json() return correct JSON with correct length';
$tmp = Book::Bilingual::Reader->new('t/ff01.mdown');
$got = length $tmp->book_json;
$exp = 6526;
is($got, $exp, $msg);
}

done_testing();


# t/40-file.t v0.0.1-1
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw(lib ../lib);
use Book::Bilingual::File;


my ($sub, $got, $exp, $msg, $tmp, $tmp1, $tmp2, $tmp3);


BEGIN {
    use_ok( 'Book::Bilingual::File' ) || print "Bail out!\n";
}
{ ## Basic test
$msg = 'Basic test -- Ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);
}
{ ## file is a Path::Tiny object
$msg = 'file is a Path::Tiny object';
$tmp = Book::Bilingual::File->new('t/ff01.mdown');
$got = ref $tmp->file;
$exp = 'Path::Tiny';
is($got, $exp, $msg);
}
{ ## test file object exists
$msg = 'test file object exists';
$tmp = Book::Bilingual::File->new('t/ff01.mdown');
$got = $tmp->file->exists ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);
}
{ ## num chapters extracted correct
$msg = 'num chapters extracted correct';
$tmp = Book::Bilingual::File->new('t/ff01.mdown');
$got = scalar @{$tmp->chapters};
$exp = 2;
is($got, $exp, $msg);
}
{ ## _extract_dlineset() extracts correctly
$msg = '_extract_dlineset() extracts correctly';
$tmp = Book::Bilingual::File->new('t/ff01.mdown');
$tmp1 = Book::Bilingual::File::_extract_dlineset($tmp->chapters->[0]);
$got = scalar @$tmp1;
$exp = 6;
is($got, $exp, $msg);
}
{ ## _extract_dline() extract count is correctly
$msg = '_extract_dline() extract count is correctly';
$tmp = Book::Bilingual::File->new('t/ff01.mdown');
$tmp1 = Book::Bilingual::File::_extract_dlineset($tmp->chapters->[0]);
$tmp2 = Book::Bilingual::File::_extract_dlines($tmp1->[0]);
$got = scalar @$tmp2;
$exp = 3;
is($got, $exp, $msg);
}
{ ## _extract_dline() returns an arrayref of Dlines
$msg = '_extract_dline() returns an arrayref of Dlines';
$tmp = Book::Bilingual::File->new('t/ff01.mdown');
$tmp1 = Book::Bilingual::File::_extract_dlineset($tmp->chapters->[0]);
$tmp2 = Book::Bilingual::File::_extract_dlines($tmp1->[0]);
$got = ref $tmp2->[2];
$exp = 'Book::Bilingual::Dline';
is($got, $exp, $msg);
}

{ ## _extract_class() handles empty strings
$msg = '_extract_class() handles empty strings';
$got = Book::Bilingual::File::_extract_class("\n");
$exp = '';
is($got, $exp, $msg);
}
{ ## _extract_class() handles non-empty strings
$msg = '_extract_class() handles non-empty strings';
$got = Book::Bilingual::File::_extract_class("    #chapter-title\n");
$exp = 'chapter-title';
is($got, $exp, $msg);
}
{ ## _extract_class() handles multiple classes
$msg = '_extract_class() handles multiple classes';
$got = Book::Bilingual::File::_extract_class("    #chapter-title  #chapter-start\n");
$exp = 'chapter-title chapter-start';
is($got, $exp, $msg);
}


done_testing();

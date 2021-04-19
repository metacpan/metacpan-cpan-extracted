# t/20-chapter.t v0.0.1-1
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw(lib ../lib);
use Book::Bilingual;

my ($sub, $got, $exp, $msg, $tmp, $tmp1, $tmp2, $tmp3);


BEGIN {
    use_ok( 'Book::Bilingual::Chapter' ) || print "Bail out!\n";
}
{ ## Basic test
$msg = 'Basic test -- Ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);
}
{ ## body is ArrayRef
$msg = 'body is ArrayRef';
$tmp = Book::Bilingual::Chapter->new->body;
$got = ref $tmp;
$exp = 'ARRAY';
is($got, $exp, $msg);
}
{ ## body ArrayRef is empty
$msg = 'body ArrayRef is empty';
$tmp = Book::Bilingual::Chapter->new->body;
$got = @$tmp;
$exp = 0;
is($got, $exp, $msg);
}
{ ## number on init is undef
$msg = 'number on init is undef';
$tmp = Book::Bilingual::Chapter->new;
$got = $tmp->number;
$exp = undef;
is($got, $exp, $msg);
}
{ ## title on init is undef
$msg = 'title on init is undef';
$tmp = Book::Bilingual::Chapter->new;
$got = $tmp->title;
$exp = undef;
is($got, $exp, $msg);
}
{ ## num_paragraphs on init is 0
$msg = 'num_paragraphs on init is 0';
$tmp = Book::Bilingual::Chapter->new;
$got = $tmp->num_paragraphs;
$exp = 0;
is($got, $exp, $msg);
}



done_testing();


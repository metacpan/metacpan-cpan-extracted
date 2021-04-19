# t/10-book.t v0.0.1-1
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw(lib ../lib);
use Book::Bilingual;
use Book::Bilingual::Chapter;
use Book::Bilingual::Dlineset;
use Book::Bilingual::Dline;

my ($sub, $got, $exp, $msg, $tmp, $tmp1, $tmp2, $tmp3);


BEGIN {
    use_ok( 'Book::Bilingual' ) || print "Bail out!\n";
}
{ ## Basic test
$msg = 'Basic test -- Ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);
}
{ ## chapters is ArrayRef
$msg = 'chapters is ArrayRef';
$tmp = Book::Bilingual->new->chapters;
$got = ref $tmp;
$exp = 'ARRAY';
is($got, $exp, $msg);
}
{ ## chapters ArrayRef is empty
$msg = 'chapters ArrayRef is empty';
$tmp = Book::Bilingual->new->chapters;
$got = @$tmp;
$exp = 0;
is($got, $exp, $msg);
}
{ ## chapter_count on init is 0
$msg = 'chapter_count on init is 0';
$tmp = Book::Bilingual->new;
$got = $tmp->chapter_count;
$exp = 0;
is($got, $exp, $msg);
}

{ ## push($chapter) result in correct length
$msg = 'push($chapter) result in correct length';
$tmp = Book::Bilingual->new;
$got = $tmp->push(Book::Bilingual::Chapter->new)->chapter_count;
$exp = 1;
is($got, $exp, $msg);
}
{ ## push($chapter) dies on bad type
$msg = 'push($chapter) result in correct length';
eval { Book::Bilingual->new->push({})->chapter_count };
$got = $@ =~ /Not a Book::Bilingual::Chapter/ ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);
}

{ ## chapter_dlineset_count($chapter_idx) is correct
$msg = 'chapter_dlineset_count($chapter_idx) is correct';
$tmp = Book::Bilingual->new;
$tmp->push(Book::Bilingual::Chapter->new)               # Add chapter
    ->chapter_at(0)                                     # Nav to chapter
        ->number(Book::Bilingual::Dlineset->new)        #   Add chapter number
        ->title(Book::Bilingual::Dlineset->new);        #   Add chapter title
$got = $tmp->chapter_dlineset_count(0);
$exp = 2;
is($got, $exp, $msg);
}
{ ## chapter_dlineset_dline_len($ch_idx, $dset_idx) is correct
$msg = 'chapter_dlineset_dline_len($ch_idx, $dset_idx) is correct';
$tmp = Book::Bilingual->new;
$tmp->push(Book::Bilingual::Chapter->new)               # Add chapter
    ->chapter_at(0)                                     # Nav to chapter
        ->number(Book::Bilingual::Dlineset->new)        #   Add chapter number
        ->title(Book::Bilingual::Dlineset->new);        #   Add chapter title

$tmp->chapter_at(0)->dlineset_at(1)                     # Nav to Dlineset
    ->push(Book::Bilingual::Dline->new)                 #   Add first Dline
    ->push(Book::Bilingual::Dline->new)                 #   Add second Dline
    ->push(Book::Bilingual::Dline->new);                #   Add third Dline

$got = $tmp->chapter_dlineset_dline_len(0,1);
$exp = 3;
is($got, $exp, $msg);
}


done_testing();


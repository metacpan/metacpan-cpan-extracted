use strict;
use warnings;
use utf8;
use Test::More;
use Aozora2Epub;
use Aozora2Epub::CachedGet;
use lib qw/./;
use t::Util;
use Path::Tiny;

plan skip_all => "LIVE_TEST not enabled" unless $ENV{LIVE_TEST};

sub dotest {
    my ($url, $title, $author) = @_;

    my $book = Aozora2Epub->new($url);
    is $book->title, $title, "title  $url";
    is $book->author, $author, "author $url";
}

{
    local $ENV{AOZORA2EPUB_CACHE} = Path::Tiny->tempdir;
    Aozora2Epub::CachedGet::init_cache();

    dotest('001637/files/59055_69954.html', 'ある日', '中野鈴子');
    dotest('001637/card59055.html', 'ある日', '中野鈴子');
    is(http_get('https://www.aozora.gr.jp/gaiji/1-01/1-01-35.png'), png_1_01_35(), "png");
    is(http_get('https://www.aozora.gr.jp/gaiji/1-01/1-01-35.png'), png_1_01_35(), "png cached");
}

done_testing();

sub png_1_01_35 {
    join('',
         qq{\211PNG\r\n\032\n\0\0\0\rIHDR},
         qq{\0\0\0\020\0\0\0\020\001\003\0\0\0%=m},
         qq{"\0\0\0\006PLTE\377\377\377\0\0\0U},
         qq{\302\323~\0\0\0\024IDATx\234b`h},
         qq{` \005\001\0\0\0\377\377\003\0\2740\b\001\264},
         qq{:\a\277\0\0\0\0IEND\256B`\202},
     );
}

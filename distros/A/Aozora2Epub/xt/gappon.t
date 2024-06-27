use strict;
use warnings;
use utf8;
use Test::More;
use Aozora2Epub;
use lib qw/./;
use xt::ZipDiff;
use t::Util;
use Path::Tiny;
use Aozora2Epub::Gensym;

{
    local($Aozora2Epub::AOZORA_CARDS_URL) = 'xt/input';
    local($Aozora2Epub::AOZORA_GAIJI_URL) = 'xt/input/gaiji/';

    subtest "gappon" => sub {
        my ($title, $author, $html) = do {
            Aozora2Epub::Gensym->reset_counter;
            my $book = Aozora2Epub->new();
            $book->append('01/files/01_000.html');
            $book->append('02/files/02_000.html');
            ($book->title, $book->author, $book->as_html);
        };
        is $title, "テスト１", "title";
        is $author, "酔狂亭不出来", "author";
        is $html, book1(), "book";
        done_testing;
    };

    subtest "with title" => sub {
        my ($title, $author, $html) = do {
            Aozora2Epub::Gensym->reset_counter;
            my $book = Aozora2Epub->new();
            $book->title('gappon');
            $book->append('01/files/01_000.html', title=>"part1");
            $book->append('02/files/02_000.html', title=>"part2");
            ($book->title, $book->author, $book->as_html);
        };
        is $title, "gappon", "title";
        is $author, "酔狂亭不出来", "author";
        is $html, book2(), "book";
        done_testing;
    };

    subtest "with title level" => sub {
        my ($title, $author, $html) = do {
            Aozora2Epub::Gensym->reset_counter;
            my $book = Aozora2Epub->new();
            $book->title('gappon');
            $book->append('01/files/01_000.html', title=>"part1", title_level=>1);
            $book->append('02/files/02_000.html', title=>"part2");
            ($book->title, $book->author, $book->as_html);
        };
        is $title, "gappon", "title";
        is $author, "酔狂亭不出来", "author";
        is $html, book3(), "book";
        done_testing;
    };

    subtest "with subtitle" => sub {
        my ($title, $author, $html) = do {
            Aozora2Epub::Gensym->reset_counter;
            my $book = Aozora2Epub->new();
            $book->append('02/files/02_000.html', use_subtitle=>1);
            $book->append('03/files/03_000.html', use_subtitle=>1);
            ($book->title, $book->author, $book->as_html);
        };
        is $title, "テスト-no-toc", "title";
        is $author, "酔狂亭不出来", "author";
        is $html, book4(), "book";
        done_testing;
    };

    subtest "with title_html" => sub {
        my ($title, $author, $html) = do {
            Aozora2Epub::Gensym->reset_counter;
            my $book = Aozora2Epub->new();
            $book->append('02/files/02_000.html',
                          title_html=>'<h1>序</h1><h2>abc</h2>');
            $book->append('03/files/03_000.html',
                          title_html=>'<h1>本編</h1><h2>その1</h2>');
            ($book->title, $book->author, $book->as_html);
        };
        is $title, "テスト-no-toc", "title";
        is $author, "酔狂亭不出来", "author";
        is $html, book5(), "book";
        done_testing;
    };
}
done_testing();

sub book1 {
    my $html =<<'HTML';
<h2 id="g000000006">テスト１</h2>
<h3 id="g000000000">大見出し1</h3>
<h4 id="g000000002">中見出し1-1</h4>
 あれや。これや。<br />
<img src="../images/fig0.png" /><br />
 図その１。<br />
<h3 id="g000000001">大見出し2</h3>
<h4 id="g000000003">中見出し2-1</h4>
 どれや。それや。<img class="gaiji" src="../gaiji/1-90/1-90-61.png" />ですね。<br />
<h2 id="g000000008">テスト-no-toc</h2>
 あれや。これや。<br />
 どれや。それや。ですね。<br />
HTML
    $html =~ s/\n//sg;
    return $html
}

sub book2 {
    my $html =<<'HTML';
<h2 id="g000000006">part1</h2>
<h3 id="g000000000">大見出し1</h3>
<h4 id="g000000002">中見出し1-1</h4>
 あれや。これや。<br />
<img src="../images/fig0.png" /><br />
 図その１。<br />
<h3 id="g000000001">大見出し2</h3>
<h4 id="g000000003">中見出し2-1</h4>
 どれや。それや。<img class="gaiji" src="../gaiji/1-90/1-90-61.png" />ですね。<br />
<h2 id="g000000008">part2</h2>
 あれや。これや。<br />
 どれや。それや。ですね。<br />
HTML
    $html =~ s/\n//sg;
    return $html
}

sub book3 {
    my $html =<<'HTML';
<h1 id="g000000006">part1</h1>
<h3 id="g000000000">大見出し1</h3>
<h4 id="g000000002">中見出し1-1</h4>
 あれや。これや。<br />
<img src="../images/fig0.png" /><br />
 図その１。<br />
<h3 id="g000000001">大見出し2</h3>
<h4 id="g000000003">中見出し2-1</h4>
 どれや。それや。<img class="gaiji" src="../gaiji/1-90/1-90-61.png" />ですね。<br />
<h2 id="g000000008">part2</h2>
 あれや。これや。<br />
 どれや。それや。ですね。<br />
HTML
    $html =~ s/\n//sg;
    return $html
}

sub book4 {
    my $html =<<'HTML';
<h2 id="g000000001">テスト-no-toc</h2>
 あれや。これや。<br />
 どれや。それや。ですね。<br />
<h2 id="g000000003">サブタイトル3</h2>
 あれや。これや。<br />
 どれや。それや。ですね。<br />
HTML
    $html =~ s/\n//sg;
    return $html
}

sub book5 {
    my $html =<<'HTML';
<h1 id="g000000001">序</h1>
<h2 id="g000000002">abc</h2>
 あれや。これや。<br />
 どれや。それや。ですね。<br />
<h1 id="g000000004">本編</h1>
<h2 id="g000000005">その1</h2>
 あれや。これや。<br />
 どれや。それや。ですね。<br />
HTML
    $html =~ s/\n//sg;
    return $html
}

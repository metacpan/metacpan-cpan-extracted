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

    sub epub_eq {
        my ($input_file, $expected, %epub_options) = @_;

        my $pre_epub_hook = $epub_options{pre_epub_hook};
        delete $epub_options{pre_epub_hook};

        if ($ENV{BUILD_EPUB}) {
            Aozora2Epub::Gensym->reset_counter;
            my $book = Aozora2Epub->new($input_file);
            $pre_epub_hook and $pre_epub_hook->($book);
            $book->to_epub(output=>"xt/expected/$expected",
                           %epub_options);
            ok 1;
            return;
        }
        Aozora2Epub::Gensym->reset_counter;
        my $tb = Test::More->builder;
        my $zd = xt::ZipDiff->new;
        my $got = $zd->workdir . "/got.epub";
        my $book = Aozora2Epub->new($input_file);
        $pre_epub_hook and $pre_epub_hook->($book);
        $book->to_epub(output=>$got, %epub_options);
        my $diffout = $zd->diff($got, "xt/expected/$expected");
        if ($diffout eq "") {
            $tb->ok(1, $expected);
        } else {
            $tb->ok(0, $expected);
            $tb->diag("    Epub differ:\n", $diffout);
        }
    }

    epub_eq('01/files/01_000.html', '01_000.epub');
    epub_eq('02/files/02_000.html', '02_000.epub');
    epub_eq('02/files/02_000.html', '02_000-with-cover.epub',
            cover=>'xt/input/cover.jpg');
    epub_eq('04/files/04_000.html', '04_000.epub',
            pre_epub_hook=>sub {
                my $book = shift;
                my $toc = $book->toc;
                my @honpen = splice @{$toc->[0]->{children}}, 1;
                push @$toc, @honpen;
                $book->toc($toc);
            });
}
done_testing();

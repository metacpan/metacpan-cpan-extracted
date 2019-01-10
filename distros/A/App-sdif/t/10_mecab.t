use v5.014;
use strict;
use warnings;
use utf8;
use Test::More;
use Data::Dumper;

binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use App::cdif::Command::Mecab;
$App::cdif::Command::Mecab::debug = 0;

sub mecab_words {
    my $text = shift;
    state $mecab = new App::cdif::Command::Mecab;
    $mecab->wordlist($text);
}

sub mecab {
    my $text = shift;
    my $expect = shift;
    my $name = shift || $text =~ s/\n/\\n/gr;
    is_deeply (	[ mecab_words $text ], $expect, $name );
}

my $mecab = "mecab";
eval {
     system "$mecab --version";
     $? == 0;
}
or do {
    plan skip_all => "No `$mecab' command available.";
};

mecab "a b c\n",
    [ "a", " ", "b", " ", "c", "\n" ];

mecab "a b c \n",
    [ "a", " ", "b", " ", "c", " ", "\n" ];

mecab " a b c\n",
    [ " ", "a", " ", "b", " ", "c", "\n" ];

mecab " a b c \n",
    [ " ", "a", " ", "b", " ", "c", " ", "\n" ];

mecab "私の名前は中野です\n",
    [ "私", "の", "名前", "は", "中野", "です", "\n" ],
    "Japanese";

mecab "私の名前は中野です  \n",
    [ "私", "の", "名前", "は", "中野", "です", "  ", "\n" ],
    "Japanese with trailing space";

done_testing;

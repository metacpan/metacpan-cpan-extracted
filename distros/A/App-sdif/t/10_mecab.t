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

##
## `mecab --version' does not read the dictionary, so it succeeds even
## when no dictionary is installed.  Probe an actual analysis instead:
## without a usable dictionary mecab reports
##     param.cpp(69) [ifs] no such file or directory: .../dicrc
## (often on stdout, and even exiting with status 0), which would
## otherwise pollute the results.
##
{
    my $probe = `echo a | $mecab 2>&1`;
    if ($? != 0 or $probe =~ /no such file or directory/) {
	plan skip_all => "`$mecab' is not available or has no usable dictionary.";
    }
}

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

mecab " +=~~((()))\n",
    [ " ", "+", "=", "~~", "(((", ")))", "\n" ];

done_testing;

#!perl
# 009-hopen-constants.t: test Data::Hopen constants
use rlib 'lib';
use HopenTest;

use Data::Hopen ':all';

ok $_ ~~ UNSPECIFIED, "UNSPECIFIED accepts $_"
    foreach qw(a 0 - ab a0 0a a- -a русский язык 日本語 ひらがな);

ok !($_ ~~ NOTHING), "NOTHING rejects $_"
    foreach qw(a 0 - ab a0 0a a- -a русский язык 日本語 ひらがな);

ok !("" ~~ UNSPECIFIED), "UNSPECIFIED rejects the empty string";
    # Because UNSPECIFIED doesn't mean missing
ok !("" ~~ NOTHING), "NOTHING rejects the empty string";
    # Because NOTHING really means nothing!

done_testing();
# vi: set fenc=utf8:

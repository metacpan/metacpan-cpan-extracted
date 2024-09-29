#!perl
# 009-hopen-constants.t: test Data::Hopen constants
use rlib 'lib';
use HopenTest;

use Data::Hopen ':all';

ok UNSPECIFIED->contains($_), "UNSPECIFIED accepts $_"
    foreach qw(a 0 - ab a0 0a a- -a русский язык 日本語 ひらがな);

ok !NOTHING->contains($_), "NOTHING rejects $_"
    foreach qw(a 0 - ab a0 0a a- -a русский язык 日本語 ひらがな);

ok !UNSPECIFIED->contains(""), "UNSPECIFIED rejects the empty string";
    # Because UNSPECIFIED doesn't mean missing
ok !NOTHING->contains(""), "NOTHING rejects the empty string";
    # Because NOTHING really means nothing!

done_testing();
# vi: set fenc=utf8:

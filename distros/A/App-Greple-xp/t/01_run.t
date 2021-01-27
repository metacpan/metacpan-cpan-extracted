use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

is(greple(qw(-Mxp -c -i daemon t/passwd))->result, "25\n", "normal");
is(greple(qw(-Mxp -c -i daemon t/passwd --exclude-pattern t/gcos.ptn))->result, "1\n", "--exclude-pattern t/gcos.ptn");
is(greple(qw(-Mxp -c -i daemon t/passwd --exclude-pattern t/*.ptn))->result, "0\n", "--exclude-pattern t/*.ptn");
is(greple(qw(-Mxp -c -i daemon t/passwd --exclude-pattern t/all.regex))->result, "0\n", "--exclude-pattern t/all.regex");
is(greple(qw(-Mxp -c -i daemon t/passwd --include-pattern t/all.regex))->result, "25\n", "--include-pattern t/all.regex");

is(greple(qw(-Mxp -c -i \\pP t/passwd --exclude-string t/punct.fixed))->result, "0\n", "--exclude-string t/punct.fixed");

done_testing;

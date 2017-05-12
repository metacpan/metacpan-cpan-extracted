use strict;
use warnings;
use utf8;
use Test::More;

SKIP: {
    skip 'kv2json is not copied to releasing dist', 1 if $ENV{RELEASE_TESTING};
    is `./kv2json hoge=fuga`, q!{"hoge":"fuga"}!."\n";
}

done_testing;

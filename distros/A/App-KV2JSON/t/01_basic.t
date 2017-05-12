use strict;
use warnings;
use utf8;
use Test::More;

use App::KV2JSON;
my $sub = App::KV2JSON->can('kv2hash');

is_deeply $sub->(qw/hoge=fuga/),   {hoge => 'fuga'};
is_deeply $sub->(qw/hoge[]=fuga/), {hoge => ['fuga']};
is_deeply $sub->(qw/var=baz hoge[]=fuga/), {var => 'baz', hoge => ['fuga']};
is_deeply $sub->(qw/hoge[a]=1 hoge[b]=fuga fuga=piyo/), {hoge => {a => 1, b => 'fuga'}, fuga => 'piyo'};
is_deeply $sub->(qw/hoge[a][b]=1 hoge[a][c]=fuga/), {
    hoge => {
        a => {
            b => 1,
            c => 'fuga'
        }
    }
};

done_testing;

#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More;

eval " use YAML ";
plan skip_all => "YAML is not installed." if $@;
eval " use Encode ";
plan skip_all => "Encode is not installed." if $@;

plan tests => 4;

eval "use MyPlaggerize ";

my $pla = MyPlaggerize->new({ config => {
    global => {
        test => 'data',
    },
    plugins => [
        {
            module => 'Test',
            config => { return => 'a' },
        },
        {
            module => 'Test',
            config => { return => 'b' },
        },
        {
            module => 'Test',
            config => { return => 'c' },
        },
    ],
}});

is $pla->conf->{global}->{test}, 'data';

my $ret = $pla->run_hook('feed');
is $ret->[0], 'a';
is $ret->[1], 'b';
is $ret->[2], 'c';

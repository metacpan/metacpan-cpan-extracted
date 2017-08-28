#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 10;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::TarantoolQueue::PackUnpack';
}

sub rand_str() {
    my $str = '';
    for (1 .. 100 + int rand 100) {
        $str .= chr int rand 20000;
    }

    $str;
}

my $p = DR::TarantoolQueue::PackUnpack->new(gzip_size_limit => 0);
isa_ok $p => DR::TarantoolQueue::PackUnpack::, 'instance created';


subtest 'rand str' => sub {
    plan tests => 2;
    my $test = { a => rand_str };
    like $p->encode($test), qr{^base64:}, 'packed';
    is_deeply $p->decode($p->encode($test)), $test, 'decode';
};

subtest 'utf8' => sub {
    plan tests => 2;
    my $test = { привет => 'медвед' };
    like $p->encode($test), qr{^base64:}, 'packed';
    is_deeply $p->decode($p->encode($test)), $test, 'decode';
};

subtest 'special characters' => sub {
    plan tests => 2;
    my $test = { привет => "медвед\0\1\2\3\4\5" };
    like $p->encode($test), qr{^base64:}, 'packed';
    is_deeply $p->decode($p->encode($test)), $test, 'decode';
};


$p = DR::TarantoolQueue::PackUnpack->new(gzip_size_limit => 1024);
isa_ok $p => DR::TarantoolQueue::PackUnpack::, 'instance recreated';

subtest 'rand str' => sub {
    plan tests => 2;
    my $test = { a => rand_str };
    unlike $p->encode($test), qr{^base64:}, 'packed';
    is_deeply $p->decode($p->encode($test)), $test, 'decode';
};

subtest 'utf8' => sub {
    plan tests => 2;
    my $test = { привет => 'медвед' };
    unlike $p->encode($test), qr{^base64:}, 'packed';
    is_deeply $p->decode($p->encode($test)), $test, 'decode';
};

subtest 'special characters' => sub {
    plan tests => 2;
    my $test = { привет => "медвед\0\1\2\3\4\5" };
    unlike $p->encode($test), qr{^base64:}, 'packed';
    is_deeply $p->decode($p->encode($test)), $test, 'decode';
};


subtest 'blessed' => sub {
    plan tests => 1;
    my $o = bless { a => 'b' } => 'TstP';
    is $p->encode($o), '{"a":"b"}', 'encode';
};

package TstP;

sub TO_JSON {
    return { %{ $_[0] } }
}

sub encode {
    die 123;
}

1;

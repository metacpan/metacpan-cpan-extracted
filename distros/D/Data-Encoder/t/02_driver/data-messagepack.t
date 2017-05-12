use strict;
use warnings;
use Test::Requires 'Data::MessagePack';
use Data::Encoder::Data::MessagePack;
use Test::More;
use t::Util;

show_version('Data::MessagePack');

subtest 'simple' => sub {
    my $encoder = Data::Encoder::Data::MessagePack->new;
    my $data = $encoder->encode(['foo']);
    is $data, Data::MessagePack->pack(['foo']);
    is_deeply $encoder->decode($data), ['foo'];

    done_testing;
};

if ($Data::MessagePack::VERSION >= 0.36) {
    subtest 'ooish' => sub {
        my $encoder = Data::Encoder::Data::MessagePack->new({
            utf8           => 1,
            prefer_integer => 1,
            canonical      => 1,
        });
        my $data = $encoder->encode({ a => 10, b => "\x{3042}" });
        is $data, Data::MessagePack->new->canonical(1)->utf8(1)->prefer_integer(1)->pack({
            a => 10,
            b => "\x{3042}",
        });
        is_deeply $encoder->decode($data), { a => 10, b => "\x{3042}" };
    };
}

done_testing;

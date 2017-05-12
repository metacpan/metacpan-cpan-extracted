use strict;
use warnings;
use Test::Requires 'JSON';
use Data::Encoder::JSON;
use Test::More;
use t::Util;

show_version('JSON');

subtest 'simple' => sub {
    my $encoder = Data::Encoder::JSON->new;
    my $data = $encoder->encode(['foo']);
    is $data, '["foo"]';
    is_deeply $encoder->decode($data), ['foo'];

    done_testing;
};

subtest 'args' => sub {
    my $encoder = Data::Encoder::JSON->new({ pretty => 1 });
    like $encoder->encode(['foo']), qr|[\n\s+"foo"\n]|;

    done_testing;
};

done_testing;

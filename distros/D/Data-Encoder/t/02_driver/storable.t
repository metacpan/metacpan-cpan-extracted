use strict;
use warnings;
use Test::Requires 'Storable';
use Data::Encoder::Storable;
use Test::More;
use t::Util;

show_version('Storable');

subtest 'simple' => sub {
    my $encoder = Data::Encoder::Storable->new;
    my $data = $encoder->encode(['foo']);
    is $data, Storable::nfreeze(['foo']);
    is_deeply $encoder->decode($data), ['foo'];

    done_testing;
};

done_testing;

use strict;
use warnings;
use Test::Requires 'YAML';
use Data::Encoder::YAML;
use Test::More;
use t::Util;

show_version('YAML');

subtest 'simple' => sub {
    my $encoder = Data::Encoder::YAML->new;
    my $data = $encoder->encode(['foo']);
    is $data, YAML::Dump(['foo']);
    is_deeply $encoder->decode($data), ['foo'];

    done_testing;
};

done_testing;

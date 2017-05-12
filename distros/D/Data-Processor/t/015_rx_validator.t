use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    'v\S' => {
        regex => 1,
        description => 'some magic stuff',
        validator => sub {
            my $value = shift;
            $value eq 'magic' ? undef : 'BAD';
        }
    },
    'a\S' => {
        regex => 1,
        array => 1,
        description => 'some magic stuff',
        validator => sub {
            my $value = shift;
            $value eq 'magic' ? undef : 'BAD';
        }
    }
};

my $data = {
    vX => 'magix',
    aX => ['magix'],
};


my $p = Data::Processor->new($schema);

like ( [$p->validate($data)->as_array]->[0]->{message}, qr'BAD', 'got an error as expected');

like ( [$p->validate($data)->as_array]->[1]->{message}, qr'BAD', 'got an error as expected');

done_testing;

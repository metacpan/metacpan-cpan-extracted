use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    'v\S' => {
        validator => 'peter',
        transformer => 'peter',
        regex => 'asd',
        albert => []
    },       
};

eval { Data::Processor->new($schema);};

my $err = $@;

like ( $err, qr'validator', 'found validator problem');
like ( $err, qr'transformer', 'found transformer');
like ( $@, qr'regex', 'found regex');
like ( $@, qr'albert', 'found albert');


done_testing;

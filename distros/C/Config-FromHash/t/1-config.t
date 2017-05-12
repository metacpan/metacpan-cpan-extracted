use strict;
use warnings;

use FindBin '$Bin';
use Test::More;
use Test::Deep;
use Config::FromHash;

ok 1 => 'Loads';

my $hash_config = {
    escalator => 'habit',
    silence   => 'goal',
    doomsday => 'suburbia',
    sphere => 'shine',
    village => 'barren',
    headphones => [qw/odd gibberish artist/],
    king => {
        badmouth => {
            selfish => 'again',
            angel => 'vacant',
        },
        estate => 'marginal',
        military => 2,
    },
};

my $conf = Config::FromHash->new(data => $hash_config);

isa_ok $conf, 'Config::FromHash';

is_deeply $conf->{'data'} => $hash_config               => 'Matches the hash';
is $conf->get('escalator') => 'habit'                   => 'First level';
is $conf->get('king/estate') => 'marginal'              => 'Second level';
is $conf->get('king/badmouth/selfish') => 'again'       => 'Third level';
cmp_deeply $conf->get('headphones')->[2] => 'artist'    => 'Second level arrayref';

{
    my $conf = Config::FromHash->new(data => $hash_config, filename => ["$Bin/configs/config-1.conf"]);

    cmp_deeply $conf->get('escalator') => 'broken'      => 'Data overwritten from config file';
}

done_testing;

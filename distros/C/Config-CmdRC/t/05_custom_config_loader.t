use strict;
use warnings;
use Test::More;

use YAML;

use Config::CmdRC (
    file   => 'share/custom.yml',
    loader => sub {
        my $path = shift;
        my $cfg = YAML::LoadFile($path);
        return $cfg;
    },
);

is RC->{gmt}, '47';

done_testing;

use strict;
use Test::More;
use Test::Clear;
use Config::ENV::Multi;

my $delimiter = '@#%@#';

case 'target is string : {envs}' => {
    envs => 'ENV',
}, sub {
    my $key = Config::ENV::Multi::__envs2key($_[0]->{envs});
    is $key, 'ENV';
};

case 'target is array ref : {envs}' => {
    envs => [ 'ENV', 'REGION', 'MODE' ]
}, sub {
    my $key = Config::ENV::Multi::__envs2key($_[0]->{envs});
    is $key, 'ENV' . $delimiter . 'REGION' . $delimiter . 'MODE';
};

case 'target is array ref containing undefined : {envs}' => {
    envs => [ 'sandbox', undef, 'development' ]
}, sub {
    my $key = Config::ENV::Multi::__envs2key($_[0]->{envs});
    is $key, 'sandbox' . $delimiter . $delimiter . 'development';
};

done_testing;


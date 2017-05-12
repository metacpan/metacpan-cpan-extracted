use strict;
use warnings;

use Test::Fatal;
use Test::More;

BEGIN { use_ok('App::Commando::Logger'); }

my $logger = App::Commando::Logger->new(*STDOUT);
isa_ok $logger, 'App::Commando::Logger', '$logger';

like exception { App::Commando::Logger->new(undef) },
    qr/Can't open log device/, 'Exception is thrown for an invalid log device';

done_testing;

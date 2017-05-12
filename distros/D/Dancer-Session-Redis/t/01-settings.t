use strict;
use warnings;
use Test::More;
use Test::Exception;
use Dancer::Config 'setting';
use Dancer::Session::Redis;

can_ok 'Dancer::Session::Redis', qw(create retrieve flush destroy init redis);

# no settings
throws_ok { Dancer::Session::Redis->create }
    qr/redis_session is not defined/, 'settings for backend is not found';

# invalid settings
setting redis_session => [];
throws_ok { Dancer::Session::Redis->create }
    qr/redis_session must be a hash reference/, 'settings is not a hashref';

# incomplete settings
setting redis_session => {};
throws_ok { Dancer::Session::Redis->create }
    qr/redis_session should.*either server or sock parameter/, 'connection param is not found in settings';

done_testing();

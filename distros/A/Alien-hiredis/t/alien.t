use Test::More;
use Test::Alien;
use Alien::hiredis;

alien_ok 'Alien::hiredis';
ffi_ok { symbols => ['redisReaderCreate','redisReaderFree','redisReaderFeed','redisReaderGetReply'] };

done_testing;

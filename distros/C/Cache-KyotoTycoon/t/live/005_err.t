use strict;
use warnings;
use Test::More;
use Cache::KyotoTycoon;
use Test::TCP;

my $kt = Cache::KyotoTycoon->new(host => '127.0.0.1', port => empty_port());
eval { $kt->get('test') };
my $e = $@;
like $e, qr/Cache::KyotoTycoon unexpected response code: 500/;
note $e;

done_testing;


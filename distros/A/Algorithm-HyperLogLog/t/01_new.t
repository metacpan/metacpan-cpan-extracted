use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception lives_ok);
use Algorithm::HyperLogLog;
use Algorithm::HyperLogLog::PP;

my $hll = Algorithm::HyperLogLog->new(5);
is $hll->register_size, 2**5;
isa_ok $hll, 'Algorithm::HyperLogLog';
like exception { Algorithm::HyperLogLog->new(3); },  qr/^Number of ragisters must be in the range \[4,16\]/;
like exception { Algorithm::HyperLogLog->new(17); }, qr/^Number of ragisters must be in the range \[4,16\]/;
lives_ok { Algorithm::HyperLogLog->new(4); };
lives_ok { Algorithm::HyperLogLog->new(16); };

my $hllpp = Algorithm::HyperLogLog::PP->new(5);
is $hllpp->register_size, 2**5;
isa_ok $hllpp, 'Algorithm::HyperLogLog::PP';
like exception { Algorithm::HyperLogLog::PP->new(3); },  qr/^Number of ragisters must be in the range \[4,16\]/;
like exception { Algorithm::HyperLogLog::PP->new(17); }, qr/^Number of ragisters must be in the range \[4,16\]/;
lives_ok { Algorithm::HyperLogLog::PP->new(4); };
lives_ok { Algorithm::HyperLogLog::PP->new(16); };

done_testing();

__END__


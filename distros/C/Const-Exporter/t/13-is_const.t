use Test::Most;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Sub::Identify 0.06 qw/ is_sub_constant /;

use Const::Exporter default => [ A => 1, B => sub { 2 } ];

is A, 1, 'expected value';
ok is_sub_constant(\&A), 'is_sub_constant';

is B, 2, 'expected value';
ok is_sub_constant(\&B), 'is_sub_constant';

done_testing;

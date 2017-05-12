use Test::Modern;
use Business::BalancedPayments;

my $bp = Business::BalancedPayments->client(secret => 3, version => 1.0);

like exception { $bp->create_hold({}) }, qr/amount/, 'No ammount';

like exception { $bp->create_hold({ amount => 500 }) }, qr/account or card/,
    'No account or card';

done_testing;

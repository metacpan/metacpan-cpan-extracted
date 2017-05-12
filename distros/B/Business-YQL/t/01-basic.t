use Test::Most;

use Business::YQL;
use Log::Any::Adapter;
use Log::Dispatch;

sub _enable_logging {
    my $log = Log::Dispatch->new(
        outputs => [
            [
                'Screen',
                min_level => 'debug',
                stderr    => 1,
                newline   => 1,
            ]
        ],
    );

    Log::Any::Adapter->set(
        'Dispatch',
        dispatcher => $log,
    );
}

my $yql = Business::YQL->new;

#_enable_logging;

ok $yql->q('show tables');
ok $yql->q("select * from yahoo.finance.xchange where pair in ('CADGBP')");
ok $yql->q("SELECT * from geo.places WHERE text='San Francisco'");
ok $yql->q("INSERT INTO yahoo.y.ahoo.it (url) VALUES ('http://google.com')");

done_testing;

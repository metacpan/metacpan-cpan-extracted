use strict;
use warnings;
use AnyEvent;
use AnyEvent::ConnPool;
use Data::Dumper;
use Test::More;

my $global_counter = 0;

my $cv = AnyEvent->condvar();

my $connpool = AnyEvent::ConnPool->new(
    constructor =>  sub {
        $cv->begin();
        return {value => $global_counter++};
    },
    check       =>  {
        cb          =>  sub {
            my $conn = shift;
            $cv->end();
        },
        interval    =>  1,
    },
    init    =>  1,
    size    =>  3,
);

my $timer; $timer = AnyEvent->timer(
    after   =>  10,
    cb      =>  sub {
        BAIL_OUT "Asynchronous check was failed. Bailing out.";
    },
);
$cv->recv();

my $done = 1;
ok ($done, 'Successfully checked');
done_testing();


use strict;
use warnings;
use Test::More;

use Cocoa::EventLoop;

{
    my $counter = 0;
    my $t; $t = Cocoa::EventLoop->timer(
        interval => 0.01,
        cb       => sub {
            ++$counter;
            if ($counter == 5) {
                undef $t;
            }
        },
    );
    Cocoa::EventLoop->run_while(0.1) while ($t);

    ok 'Loop stopped ok';
    is $counter, 5, 'counter ok';
}

{
    my $t; $t = Cocoa::EventLoop->timer(
        after => 0.01,
        cb    => sub {
            ok 'after timer ok';
        },
    );
    Cocoa::EventLoop->run_while(0.1);
}


done_testing;

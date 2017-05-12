use strict;
use warnings;
use Test::More tests => 2;
use AnyEvent;
use AnyEvent::Collect;

{
    my $cnt = 0;
    my( $t1, $t2 );
    collect {
        $t1 = AE::timer 0.2, 0.2, event { $cnt ++ };
        $t2 = AE::timer 0.5, 0.5, event { $cnt += 10 };
    };
    is( $cnt, 12, "We collected three event triggers of the right kinds" );
}
{
    my $cnt = 0;
    my( $t1, $t2 );
    collect_any {
        $t1 = AE::timer 0.2, 0.2, event { $cnt ++ };
        $t2 = AE::timer 0.5, 0.5, event { $cnt += 10 };
    };
    is( $cnt, 1, "We collected only one event of the right kind" );
}

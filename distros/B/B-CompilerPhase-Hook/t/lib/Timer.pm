package Timer;

use strict;
use warnings;

use Time::HiRes            qw[ gettimeofday tv_interval ];
use B::CompilerPhase::Hook qw[ enqueue_UNITCHECK ];

our $TIME = 0;

sub import {
    $TIME = 0;
    my $start = [ gettimeofday ];
    #warn sprintf "Starting at %d:%d\n" => @$start;
    sleep(1);
    enqueue_UNITCHECK {
        $TIME = tv_interval( $start, [ gettimeofday ] );
        #warn "Finished after $TIME\n";
    };
}

1;

__END__

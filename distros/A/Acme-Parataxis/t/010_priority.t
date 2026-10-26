use v5.40;
use blib;
use Acme::Parataxis qw[async yield fiber];
use Test2::V1 -ipP;
$|++;
#
subtest 'Default priority and accessor' => sub {
    my $f = fiber {1};
    is $f->priority,     0,  'newly spawned fiber defaults to priority 0';
    is $f->priority(10), 10, 'setter returns the new priority';
    is $f->priority,     10, 'getter reflects the set priority';
};
subtest 'Higher priority resumes before lower priority' => sub {
    my @log;
    async {
        my $low = fiber { push @log, 'l1'; yield; push @log, 'l2'; };
        $low->priority(1);
        my $high = fiber { push @log, 'h1'; yield; push @log, 'h2'; };
        $high->priority(10);
        yield;
        push @log, 'main-end';
    };
    is "@log", 'l1 h1 h2 l2 main-end', 'priority 10 fiber resumed before priority 1 fiber';
};
subtest 'Re-prioritizing a queued fiber moves it' => sub {
    my @log;
    async {
        my $a = fiber { push @log, 'a1'; yield; push @log, 'a2'; };
        my $b = fiber { push @log, 'b1'; yield; push @log, 'b2'; };
        $b->priority(5);    # jump ahead of $a
        $b->priority(0);    # and back behind it
        $b->priority(7);    # ahead again
        yield;
        push @log, 'main-end';
    };
    is "@log", 'a1 b1 b2 a2 main-end', 're-prioritized fiber resumed before the lower-priority tie';
};
subtest 'Equal priorities keep FIFO order' => sub {
    my @log;
    async {
        my $x = fiber { push @log, 'x1'; yield; push @log, 'x2'; };
        my $y = fiber { push @log, 'y1'; yield; push @log, 'y2'; };
        yield;
        push @log, 'main-end';
    };
    is "@log", 'x1 y1 x2 y2 main-end', 'same-priority fibers resume in enqueue order';
};
subtest 'Changing priority of a running fiber is allowed' => sub {
    my @log;
    async {
        fiber {
            my $me = Acme::Parataxis->by_id( Acme::Parataxis::current_fid() );
            is $me->priority(-3), -3, 'running fiber reads/writes its own priority';
            push @log, 'start';
        };
        push @log, 'main-end';
    };
    is "@log", 'start main-end', 'both fibers completed';
};
#
done_testing();

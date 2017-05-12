use strict;
use warnings;
use Test::More 0.98;

use Data::Queue::Batch;

subtest 'basic' => sub {
    my ($q, $tester) = generate(batch_size => 3);
    for (1..2) {
        $tester->(sub { $q->push(1) }, +{ called => 0 });
        $tester->(sub { $q->push(2) }, +{ called => 0 });
        $tester->(sub { $q->push(3) }, +{ called => 1, dequeued => [ [1, 2, 3] ] });
    }
    is $q->size, 0, 'consumed all';
};

subtest 'flush' => sub {
    my ($q, $tester) = generate(batch_size => 3);
    $tester->(sub { $q->push(1) }, +{ called => 0 });
    $tester->(sub { $q->push(2) }, +{ called => 0 });
    $tester->(sub { $q->flush },  +{ called => 1, dequeued => [ [1, 2] ] }, 'flush');
    is $q->size, 0;
    
    $tester->(sub { $q->push(1) }, +{ called => 0 });
    $tester->(sub { $q->push(2) }, +{ called => 0 });
    $tester->(sub { undef $q },  +{ called => 1, dequeued => [ [1, 2] ] }, 'automatically flush on destroy');
};

sub generate {
    my (%args) = @_;
    my ($called, @dequeued);
    my $q = Data::Queue::Batch->new(
        %args,
        callback => sub {
            my @d = @_;
            push(@dequeued, \@d);
            ++$called;
        },
    );

    my $tester = sub {
        my ($code, $expected, $desc) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;

        $desc = $desc ? "$desc: " : '';
        $called = 0;
        @dequeued = ();
        $code->();
        is $called, $expected->{called}, $desc . "called";
        if ($called && $expected->{dequeued}) {
            is_deeply \@dequeued, $expected->{dequeued}, $desc . "dequeued items";
        }
    };
    return ($q, $tester);
}

done_testing;


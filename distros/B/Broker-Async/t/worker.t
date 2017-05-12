use strict;
use warnings;
use Broker::Async::Worker;
use Future;
use Test::Fatal qw( dies_ok lives_ok );
use Test::More;

subtest arguments => sub {
    my $worker = Broker::Async::Worker->new(
        code => sub { return Future->done(@_) },
    );

    my @args = qw( mark is awesome );
    my $f = $worker->do(@args);
    is_deeply [$f->get], \@args, 'worker code saw arguments from do';
};

subtest availability => sub {
    my $worker = Broker::Async::Worker->new(
        code => sub { return Future->new },
    );
    is $worker->available, 1, 'worker is available after construction';

    my $f = $worker->do();
    is $worker->available, 0, 'worker is unavailable while future is pending';

    $f->done;
    is $worker->available, 1, 'worker is available after future is ready';
};

subtest concurrency => sub {
    my $worker = Broker::Async::Worker->new(
        code        => sub { return Future->new },
        concurrency => 2,
    );

    my @futures;
    lives_ok { push @futures, $worker->do() } 'concurrent worker accepts a task';
    lives_ok { push @futures, $worker->do() } 'concurrent worker accepts multiple tasks';
    dies_ok  { push @futures, $worker->do() } 'concurrent worker refuses tasks after hitting limit';

    $_->done for @futures;
    lives_ok { push @futures, $worker->do() } 'concurrent worker accepts task after resolving pending tasks';
};

done_testing;

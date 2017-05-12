use strict;
use warnings;
use FindBin;
use lib ("$FindBin::RealBin/lib");
use Test::More;
use Test::Exception;
use Test::AQWrapper;

BEGIN {
    use_ok('Async::Queue');
}

{
    note('--- invalid concurrency');
    my $q;
    throws_ok { $q = Async::Queue->new(worker => sub{}, concurrency => "hoge") }
        qr/must be a number/i, 'concurrency must be a number. not a string.';
    lives_ok { $q = Async::Queue->new(worker => sub{}, concurrency => undef) }
        'undef concurrency means the default...';
    is($q->concurrency, 1, '... which is 1.');
    throws_ok { $q->concurrency(sub { "hoge" }) }
        qr/must be a number/i, 'concurrency must be a number. not a coderef.';
}

{
    note('--- undef worker');
    my $q;
    my $error_pattern = qr/worker must not be undef/i;
    throws_ok { $q = Async::Queue->new() }
        $error_pattern, 'omitted worker in new()';
    throws_ok { $q = Async::Queue->new(worker => undef) }
        $error_pattern, 'explicit undef worker in new()';
    $q = Async::Queue->new(worker => sub {});
    throws_ok { $q->worker(undef) }
        $error_pattern, 'explicit undef worker in accessor';
}

{
    note("--- undef event handlers (it's ok)");
    foreach my $key (qw(empty saturated drain)) {
        my $q;
        lives_ok { $q = Async::Queue->new(worker => sub {}, $key => undef) } "undef $key handler is ok.";
        ok(!defined($q->$key()), "$key() getter returns undef.");
        lives_ok { $q->$key(undef) } "setting undef to $key is ok";
    }
}

{
    note('--- invalid worker and event handlers (non-undef)');
    my $somescalar = 20;
    foreach my $key (qw(worker empty saturated drain)) {
        foreach my $invalid_worker (20, "hoge", [], {foo => "bar"}, \$somescalar) {
            my %options = (
                worker => sub {},
            );
            $options{$key} = $invalid_worker;
            my $q;
            throws_ok { $q = Async::Queue->new(%options) }
                qr/$key must be a coderef/i, "$key must be a coderef";
            $q = Async::Queue->new(worker => sub {});
            throws_ok { $q->$key($invalid_worker) }
                qr/$key must be a coderef/i, "$key must be a coderef";
        }
    }
}

{
    note('--- not calling the callback in the worker');
    my @results = ();
    my $q = Test::AQWrapper->new(
        concurrency => 3,
        worker => sub {
            my ($task, $cb) = @_;
            push(@results, $task);
            ## forget to do $cb->()
        },
        map { my $e = $_; $e => sub {
            push(@results, uc(substr($e, 0, 1)));
        } } qw(empty saturated drain)
    );
    $q->clearCounter;
    @results = ();
    $q->push($_, sub { push(@results, "finish"); $q->finish }) foreach 1..8;
    $q->check(5, 3, 0, 8);
    is_deeply(\@results, [qw(E 1 E 2 S E 3)], 'queued tasks are never processed.');
}

{
    note('--- empty push');
    my @results = ();
    my $q = Async::Queue->new(
        worker => sub {
            my ($task, $cb) = @_;
            push(@results, $task);
            $cb->();
        }
    );
    throws_ok { $q->push() } qr/you must specify something to push/i, "push() without argument is NOT allowed.";
    lives_ok { $q->push(undef) } 'pushing undef is allowed.';
    is(int(@results), 1, "got result...");
    ok(!defined($results[0]), "... and it's undef.");

    @results = ();
    note('--- invalid finish callbacks');
    lives_ok { $q->push(undef, undef) } 'undef as a finish callback is just ignored.';
    my $somescalar = 11;
    foreach my $junk (10, "hoge", [], {}, \$somescalar) {
        throws_ok { $q->push(undef, $junk) } qr/must be a coderef/i, 'finish callback must be a coderef';
    }
}

{
    note('--- worker and event handlers must not throw exceptions');
    my $q; $q = Async::Queue->new(
        worker => sub { die "worker dies" }
    );
    throws_ok { $q->push("a") } qr/worker dies/, "exception in the worker is not handled.";
    foreach my $event (qw(empty saturated drain)) {
        $q = Async::Queue->new(worker => sub { $_[1]->() });
        $q->$event(sub { die "$event dies" });
        throws_ok { $q->push("a") } qr/$event dies/, "exception in $event handler is not handled.";
    }
}

{
    note('--- changing attributes while running');
    my $q;
    my %attrs = (
        concurrency => 5,
        map { $_ => sub {} } qw(worker saturated empty drain)
    );
    my $setAttributes = sub {
        foreach my $attr (keys %attrs) {
            throws_ok { $q->$attr($attrs{$attr}) }
                qr/cannot set $attr.*running/, "you cannot set $attr while running";
        }
    };
    foreach my $handler (qw(worker empty saturated drain)) {
        $q = Async::Queue->new(worker => sub {});
        $q->$handler($setAttributes);
        $q->push(undef);
    }
    $q = Async::Queue->new(worker => sub {});
    $q->push(undef, $setAttributes);
}

done_testing();

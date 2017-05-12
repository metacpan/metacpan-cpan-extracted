use strict;
use warnings;

use Test::More;
use Async::Defer;

plan tests => 7;

my $cd = new_ok('Async::Defer');

$cd->do(sub {
    my ($d, @args) = @_;
    $d->done(map { $_ * 2 } @args);
});

{
    note('--- directly put a child defer in do() method.');
    my $pd = new_ok('Async::Defer');
    my @results = ();
    $pd->do(sub {
        my ($d, @args) = @_;
        $d->done(map { $_ + 1 } @args);
    });
    $pd->do($cd);
    $pd->do(sub {
        my ($d, @args) = @_;
        @results = @args;
    });
    $pd->run(undef, 1, 2, 3);
    is_deeply(\@results, [4, 6, 8], 'child defer executed.');
}

{
    note('--- call $cd->run() inside do() method');
    my $pd = new_ok('Async::Defer');
    my @results = ();
    $pd->do(sub {
        my ($d, @args) = @_;
        $cd->run($d, map { $_ + 1 } @args);
    });
    $pd->do(sub {
        my ($d, @args) = @_;
        @results = @args;
    });
    $pd->run(undef, 1, 2, 3);
    is_deeply(\@results, [4, 6, 8], 'child defer executed.');
}

{
    note('--- dynamic creation of $cd');
    my $pd = new_ok('Async::Defer');
    my @results = ();
    $pd->do(sub {
        my ($d, @args) = @_;
        @args = map { $_ + 1 } @args;
        my $cd = Async::Defer->new();
        $cd->do(sub {
            my ($d, @args) = @_;
            $d->done(map { $_ * 2 } @args);
        });
        $cd->run($d, @args);
    });
    $pd->do(sub {
        my ($d, @args) = @_;
        @results = @args;
    });
    $pd->run(undef, 1, 2, 3);
    is_deeply(\@results, [4, 6, 8], 'child defer executed.');
}

## done_testing();




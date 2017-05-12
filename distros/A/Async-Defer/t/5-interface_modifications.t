
use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

BEGIN {
    use_ok('Async::Defer');
}

my @results = ();

sub pusher {
    my $val = shift;
    return sub {
        my ($d) = @_;
        push(@results, $val);
        $d->done();
    };
}

{
    my $d = Async::Defer->new();
    note('--- multiple tasks for a single do().');
    @results = ();
    $d->do(map { pusher($_) } (1 .. 10));
    $d->run();
    is_deeply(\@results, [(1..10)], "results ok");
}

# {
#     note('--- do(undef) complains nothing. It is just ignored. ');
#     my $d = Async::Defer->new();
#     lives_ok { $d->do(undef, undef, undef) } "pushing undefs is ok";
#     $d->do(pusher(1));
#     lives_ok { $d->do(undef, pusher(2), undef) } "pushing undefs and a coderef is ok";
#     $d->do(pusher(3));
#     @results = ();
#     $d->run();
#     is_deeply(\@results, [1,2,3], "results ok");
# }

{
    note('--- statements return the object');
    my $d = Async::Defer->new();
    is($d->while(sub { shift->iter <= 3 }), $d, "while()");
    is($d->do(pusher(11)), $d, "do()");
    is($d->end_while(), $d, "end_while()");
    is($d->do(
        [pusher(15), pusher(15), pusher(15)]
    ), $d, "do() (batch job)");
    is($d->if(sub { 1 }), $d, "if()");
    $d->do(pusher(16));
    is($d->else(), $d, "else()");
    $d->do(pusher(17));
    is($d->end_if(), $d, "end_if()");
    is($d->try(), $d, "try()");
    $d->do(
        sub { shift->throw(50) },
        pusher(18)
    );
    is($d->catch(
        qr// => sub {
            my ($d, $e) = @_;
            push(@results, $e);
            $d->done;
        }
    ), $d, "catch()");
    @results = ();
    is_deeply([$d->run()], [], "run()");
    is_deeply(\@results, [11, 11, 11, 15, 15, 15, 16, 50], "results ok");
}

## done_testing();

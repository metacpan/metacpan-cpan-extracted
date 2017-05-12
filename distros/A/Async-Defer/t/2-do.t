use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;

use AE;
my $cv;


plan tests => 4;


my ($d, $p);
my ($result, @result);
my ($t, $tx);


# do
# - accept both CODE and Defer objects
# - handle correctly both sync and async functions
# - correctly transfer results from previous to continue step, but only if
#   both previous and continue steps was do(), otherwise drop results from
#   previous step

$d = Async::Defer->new();
throws_ok { $d->do() } qr{require CODE/Defer};

$p = Async::Defer->new();
$d = Async::Defer->new();
$p->do(sub{
    my ($d, $n) = @_;
    $n++;
    push @result, $n;
    $d->done($n);
});
$d->do(sub{
    my ($d, $n) = @_;
    $n+=10;
    push @result, $n;
    $d->done($n);
});
$p->do($d);
@result = ();
$p->run(undef, 3);
is_deeply \@result, [4,14], 'accept both CODE and Defer objects';

$d = Async::Defer->new();
$d->do(sub{
    my ($d, $n) = @_;
    $n++;
    $d->{t} = AE::timer 0.01, 0, sub{ $d->done($n) };
});
$d->do(sub{
    my ($d, $n) = @_;
    $n+=10;
    $result = $n;
    $d->done($n);
});
$t = AE::timer 0.01, 0, sub{ $d->run(undef, 3) };
$tx= AE::timer 0.5, 0, sub{ $cv->send };
$result = undef;
$cv = AE::cv; $cv->recv;
is $result, 14, 'handle correctly both sync and async functions';

$p = Async::Defer->new();
$d = Async::Defer->new();
$d->do(sub{
    my ($d, $n) = @_;
    $n //= 0;
    push @result, $n;
    $d->done($n+1);
});
$p->do($d);
$p->do($d);
$p->try();
    $p->do($d);
    $p->do($d);
    $p->if(sub{ 1 });
        $p->do($d);
        $p->do($d);
        $p->while(sub{ !defined $_[0]->{break} });
            $p->do($d);
            $p->do($d);
            $p->do(sub{
                my ($d, $n) = @_;
                $d->{break} = 1;
                $d->done($n+1);
            });
        $p->end_while();
        $p->do($d);
        $p->do($d);
    $p->end_if();
    $p->do($d);
    $p->do($d);
$p->catch(qr// => sub{});
$p->do($d);
$p->do($d);
$p->try();
    $p->do(sub{ $_[0]->throw('err') });
$p->catch(
    qr// => sub { $_[0]->done(10) },
);
$p->do($d);
$p->try();
    $p->do($d);
$p->catch(
    FINALLY => sub { $_[0]->done(20) },
);
$p->do($d);
$p->try();
    $p->do(sub{ $_[0]->throw('err') });
$p->catch(
    qr// => sub { $_[0]->done(30) },
    FINALLY => sub { $d->run(@_) },
);
$p->do($d);
@result = ();
$p->run();
is_deeply \@result, [
    (0,1),  # start
    (2,3),  # after try
    (0,1),  # after if
    (0,1),  # after while
    (0,1),  # after end_while
    (0,1),  # after end_if
    (2,3),  # after catch (no exception - skipped)
    10,     # after catch (got exception)
    11,     # after try
    20,     # after finally
    (30,31),# after catch (got exception) with finally
    ], 'transfer results from previous to continue step only if both are do()';


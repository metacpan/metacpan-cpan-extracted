use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;


plan tests => 7;


my ($d, $p, $c);
my ($result, @result);


# done
# - correctly move to continue opcode and transfer result:
#   * CODE to Defer
#   * Defer to CODE
#   * catch() to CODE or Defer
#   * if break operation is CODE or Defer or catch() to parent (if parent
#     exists and it continue operation is CODE or Defer)

$p = Async::Defer->new();
$d = Async::Defer->new();
$d->do(sub{
    my ($d, $n) = @_;
    push @result, $n;
    $d->done($n+1);
});
$p->do(sub{
    my ($d, $n) = @_;
    push @result, $n;
    $d->done($n+1);
});
$p->do($d);
$p->do(sub{
    my ($d, $n) = @_;
    push @result, $n;
    $d->done($n+1);
});
@result = (); $p->run(undef, 10);
is_deeply \@result, [10,11,12], 'transfer result: CODE -> Defer -> CODE';

$p = Async::Defer->new();
$d = Async::Defer->new();
$p->try();
$p->do(sub{ $_[0]->throw(20) });
$p->catch(qr//=>sub{ $_[0]->done($_[1]) });
$p->do(sub{ push @result, $_[1]; $_[0]->done() });
$p->try();
$p->do(sub{ $_[0]->throw(30) });
$p->catch(qr//=>sub{ $_[0]->done($_[1]) });
$d->do(sub{ push @result, $_[1]; $_[0]->done() });
$p->do($d);
@result = (); $p->run();
is_deeply \@result, [20,30], 'transfer result: catch -> CODE, catch -> Defer';

$p = Async::Defer->new();
$d = Async::Defer->new();
$p->try();
$p->do(sub{ $_[0]->done(40) });
$p->catch(FINALLY=>sub{ $_[0]->done($_[1]) });
$p->do(sub{ push @result, $_[1]; $_[0]->done() });
$p->try();
$p->do(sub{ $_[0]->done(50) });
$p->catch(FINALLY=>sub{ $_[0]->done($_[1]) });
$d->do(sub{ push @result, $_[1]; $_[0]->done() });
$p->do($d);
@result = (); $p->run();
is_deeply \@result, [40,50], 'transfer result: finally -> CODE, finally -> Defer';

$d = Async::Defer->new();
$d->do(sub{ $_[0]->done(10) });
$p = Async::Defer->new();
$p->do($d);
$p->do(sub{ $result = $_[1]; $_[0]->done() });
$result = undef; $p->run();
is $result, 10, 'transfer result: break CODE -> parent';
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done(20) });
$c = Async::Defer->new();
$c->do($d);
$p = Async::Defer->new();
$p->do($c);
$p->do(sub{ $result = $_[1]; $_[0]->done() });
$result = undef; $p->run();
is $result, 20, 'transfer result: break Defer -> parent';
$d = Async::Defer->new();
$d->try();
$d->do(sub{ $_[0]->throw(30) });
$d->catch(qr//=>sub{ $_[0]->done($_[1]) });
$p = Async::Defer->new();
$p->do($d);
$p->do(sub{ $result = $_[1]; $_[0]->done() });
$result = undef; $p->run();
is $result, 30, 'transfer result: break catch -> parent';
$d = Async::Defer->new();
$d->try();
$d->catch(FINALLY=>sub{ $_[0]->done(40) });
$p = Async::Defer->new();
$p->do($d);
$p->do(sub{ $result = $_[1]; $_[0]->done() });
$result = undef; $p->run();
is $result, 40, 'transfer result: break finally -> parent';



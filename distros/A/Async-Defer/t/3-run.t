use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;


plan tests => 27;


my ($d, $p);
my (@result);


# run
# - no modification (do/if/etc.) for Defer object allowed while running
# - croak on empty object
# - croak on object with some opcodes, but without even one do()
# - croak on already running
# - croak on unbalanced blocks:
#   * if
#   * if else
#   * else
#   * end_if
#   * if else else end_if
#   * while
#   * end_while
#   * if while if end_if end_if
#   * try
#   * catch
#   * try try catch
#   * try if catch end_if
#   * while try end_while catch
# - works with and without parent Defer
# - transfer it params to first do()

$d = Async::Defer->new();
$d->do(sub{
    my ($d) = @_;
    throws_ok { $d->do(sub{});          } qr/unable to modify while running/;
    throws_ok { $d->if(sub{});          } qr/unable to modify while running/;
    throws_ok { $d->else();             } qr/unable to modify while running/;
    throws_ok { $d->end_if();           } qr/unable to modify while running/;
    throws_ok { $d->while(sub{});       } qr/unable to modify while running/;
    throws_ok { $d->end_while();        } qr/unable to modify while running/;
    throws_ok { $d->try();              } qr/unable to modify while running/;
    throws_ok { $d->catch(qr//=>sub{}); } qr/unable to modify while running/;
    $d->done();
});
$d->run();

$d = Async::Defer->new();
throws_ok { $d->run() } qr/no operations to run/;
$d->if(sub{});
$d->else();
$d->end_if();
$d->while(sub{});
$d->end_while();
$d->try();
$d->catch(qr//=>sub{});
throws_ok { $d->run() } qr/no operations to run/;
$d->try();
$d->catch(FINALLY=>sub{$_[0]->done()});
lives_ok { $d->run() }  'one finally enough to run';

$d = Async::Defer->new();
$d->do(sub{
    my ($d) = @_;
    throws_ok { $d->run() } qr/already running/;
    $d->done();
});
$d->run();

$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->if(sub{});
throws_ok { $d->run() } qr/expected end_if\(\) at end/;
$d->else();
throws_ok { $d->run() } qr/expected end_if\(\) at end/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->else();
throws_ok { $d->run() } qr/unexpected else\(\) at operation 2/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->end_if();
throws_ok { $d->run() } qr/unexpected end_if\(\) at operation 2/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->if(sub{});
$d->else();
$d->else();
$d->end_if();
throws_ok { $d->run() } qr/unexpected double else\(\) at operation 4/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->while(sub{});
throws_ok { $d->run() } qr/expected end_while\(\) at end/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->end_while();
throws_ok { $d->run() } qr/unexpected end_while\(\) at operation 2/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->if(sub{});
    $d->while(sub{});
        $d->if(sub{});
        $d->end_if();
$d->end_if();
throws_ok { $d->run() } qr/unexpected end_if\(\) at operation 6/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->try();
throws_ok { $d->run() } qr/expected catch\(\) at end/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->catch(qr//=>sub{});
throws_ok { $d->run() } qr/unexpected catch\(\) at operation 2/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->try();
    $d->try();
    $d->catch(qr//=>sub{});
throws_ok { $d->run() } qr/expected catch\(\) at end/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->try();
    $d->if(sub{});
        $d->catch(qr//=>sub{});
    $d->end_if();
throws_ok { $d->run() } qr/unexpected catch\(\) at operation 4/;
$d = Async::Defer->new();
$d->do(sub{ $_[0]->done() });
$d->while(sub{});
    $d->try();
$d->end_while();
$d->catch(qr//=>sub{});
throws_ok { $d->run() } qr/unexpected end_while\(\) at operation 4/;

$p = Async::Defer->new();
$d = Async::Defer->new();
$d->do(sub{
    my ($d, $n) = @_;
    push @result, "d$n";
    $d->done($n+1);
});
$p->do(sub{
    my ($p, $n) = @_;
    push @result, "p$n";
    $d->run($p, $n+1);
});
$p->do($d);
@result = (); $p->run(undef, 10);
is_deeply \@result, ['p10','d11','d12'], 'works with parent Defer';
@result = (); $d->run(undef, 20);
is_deeply \@result, ['d20'], 'works without parent Defer';



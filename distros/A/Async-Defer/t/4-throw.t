use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;


plan tests => 8;


my ($d, $p, $c);
my ($result, @result);


# throw
# - correctly skip to corresponding catch
#   * try+throw+try+catch+catch use second catch
#   * try+try+throw+catch+catch use second catch if first doesn't match
#   * if called from deep Defer which doesn't have own try()/catch()
# - croak if no one catch match
# - finally can replace current exception with throw/continue/break

$d = Async::Defer->new();
$d->try();
    $d->do(sub{ $_[0]->throw('oops') });
    $d->try();
    $d->catch(qr//=>sub{ push @result, 'c1'; $_[0]->done() });
$d->catch(qr//=>sub{ push @result, 'c2'; $_[0]->done() });
@result = (); $d->run();
is_deeply \@result, ['c2'], 'try+throw+try+catch+catch use second catch';

$d = Async::Defer->new();
$d->try();
    $d->try();
        $d->do(sub{ $_[0]->throw( $_[0]->{err} ) });
    $d->catch(qr/oops/=>sub{ push @result, 'c1'; $_[0]->done() });
$d->catch(qr/fatal:/=>sub{ push @result, 'c2'; $_[0]->done() });
($d->{err}, @result) = ('fatal:some'); $d->run();
is_deeply \@result, ['c2'], 'try+try+throw+catch+catch use second catch (first not match)';
($d->{err}, @result) = ('fatal:oops'); $d->run();
is_deeply \@result, ['c1'], 'try+try+throw+catch+catch use first catch (first match)';

$d = Async::Defer->new();
$d->do(sub{ $_[0]->throw('oops') });
$c = Async::Defer->new();
$c->do($d);
$p = Async::Defer->new();
$p->try();
    $p->do($c);
$p->catch(qr//=>sub{ $result = $_[1]; $_[0]->done() });
$result = undef; $p->run();
is $result, 'oops', 'catch from deep Defer(s) which does not have their own try()/catch()';

$d = Async::Defer->new();
$d->try();
    $d->do(sub{ $_[0]->throw('oops') });
$d->catch(qr/fatal/=>sub{ $_[0]->done() });
throws_ok { $d->run(); } qr/uncatched exception/;

$d = Async::Defer->new();
$d->try();
    $d->do(sub{ push @result, 'd1'; $_[0]->done() });
    $d->try();
        $d->do(sub{ push @result, 'd2'; $_[0]->done() });
        $d->do(sub{ $_[0]->throw('err1') });
        $d->do(sub{ push @result, 'd3'; $_[0]->done() });
    $d->catch(
        qr//   =>sub{ push @result, 'c1'; $_[0]->throw('err2') },
        FINALLY=>sub{ push @result, 'f1'; $_[0]->throw('err3') },
    );
    $d->do(sub{ push @result, 'd4'; $_[0]->done() });
$d->catch(
    qr//=>sub{ push @result, 'c2', $_[1]; $_[0]->done() },
);
@result = (); $d->run();
is_deeply \@result, [qw(d1 d2 c1 f1 c2 err3)], 'finally can replace current exception';

$d = Async::Defer->new();
$d->while(sub{ $_[0]->iter() <= 3 });
    $d->do(sub{ push @result, 'i='.$_[0]->iter(); $_[0]->done() });
    $d->try();
        $d->do(sub{ $_[0]->throw('err1') });
    $d->catch(
        FINALLY=>sub{ push @result, 'f1'; $_[0]->continue() },
    );
    $d->do(sub{ push @result, 'd'; $_[0]->done() });
$d->end_while();
@result = (); $d->run();
is_deeply \@result, [qw(i=1 f1 i=2 f1 i=3 f1)], 'finally can replace current exception with continue()';

$d = Async::Defer->new();
$d->while(sub{ $_[0]->iter() <= 3 });
    $d->do(sub{ push @result, 'i='.$_[0]->iter(); $_[0]->done() });
    $d->try();
        $d->do(sub{ $_[0]->throw('err1') });
    $d->catch(
        FINALLY=>sub{ push @result, 'f1'; $_[0]->break() },
    );
    $d->do(sub{ push @result, 'd'; $_[0]->done() });
$d->end_while();
@result = (); $d->run();
is_deeply \@result, [qw(i=1 f1)], 'finally can replace current exception with break()';



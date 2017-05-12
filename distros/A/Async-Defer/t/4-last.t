use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;


plan tests => 9;


my ($d, $p);
my (@result);


# break
# - correctly exit nearest while, destroying it iter()
# - correctly work inside if/try/catch/finally (inside while)
# - end current Defer (with empty result) if used outside while
# - finally can replace current break with throw/continue/break

$d = Async::Defer->new();
$d->while(sub{ $_[0]->iter() <= 3 });
    $d->do(sub{ push @result, 'i='.$_[0]->iter(); $_[0]->done() });
    $d->if(sub{ $_[0]->iter() == 2 });
        $d->try();
            $d->do(  sub{ push @result, 'do';
                          $_[0]->{op} eq 'do'      ? $_[0]->break() : $_[0]->throw(); });
        $d->catch(
            qr//   =>sub{ push @result, 'ca';
                          $_[0]->{op} eq 'catch'   ? $_[0]->break() : $_[0]->done(); },
            FINALLY=>sub{ push @result, 'fi';
                          $_[0]->{op} eq 'finally' ? $_[0]->break() : $_[0]->done(); },
        );
    $d->end_if();
    $d->do(sub{ push @result, 'x'; $_[0]->done() });
$d->end_while();
$d->do(sub{ push @result, eval{$_[0]->iter()} ? '+' : '-'; $_[0]->done() });
($d->{op}, @result) = (q{}); $d->run();
is_deeply \@result, [qw(i=1 x i=2 do ca fi x i=3 x -)], 'without break';
($d->{op}, @result) = ('do'); $d->run();
is_deeply \@result, [qw(i=1 x i=2 do    fi         -)], 'break inside if/try';
($d->{op}, @result) = ('catch'); $d->run();
is_deeply \@result, [qw(i=1 x i=2 do ca fi         -)], 'break inside catch';
($d->{op}, @result) = ('finally'); $d->run();
is_deeply \@result, [qw(i=1 x i=2 do ca fi         -)], 'break inside finally';

$d = Async::Defer->new();
$d->do(sub{ push @result, 'a'; $_[0]->done() });
$d->do(sub{ $_[0]->break() });
$d->do(sub{ push @result, 'x'; $_[0]->done(10) });
$p = Async::Defer->new();
$p->do($d);
$p->do(sub{ push @result, $_[1] // 'undef'; $_[0]->done() });
@result = (); $p->run();
is_deeply \@result, [qw(a undef)],
    'end current Defer (with empty result) if used outside while';

$d = Async::Defer->new();
$d->while(sub{ $_[0]->iter() <= 3 });
    $d->do(sub{ push @result, 'i='.$_[0]->iter(); $_[0]->done() });
    $d->try();
        $d->try();
            $d->do(sub{ push @result, 'a'; $_[0]->done() });
            $d->do(sub{ $_[0]->break(); });
            $d->do(sub{ push @result, 'b'; $_[0]->done() });
        $d->catch(
            qr//   =>sub{ push @result, 'c1'; $_[0]->done(); },
            FINALLY=>sub{ push @result, 'f1';
                          $_[0]->{op} eq 'throw' ? $_[0]->throw()
                        : $_[0]->{op} eq 'continue'  ? $_[0]->continue()
                        : $_[0]->{op} eq 'break'  ? $_[0]->break()
                        :                          $_[0]->done(); },
        );
    $d->catch(
        qr//   =>sub{ push @result, 'c2'; $_[0]->done(); },
        FINALLY=>sub{ push @result, 'f2'; $_[0]->done(); },
    );
    $d->do(sub{ push @result, 'x'; $_[0]->done() });
$d->end_while();
($d->{op}, @result) = (q{}); $d->run();
is_deeply \@result, [qw(i=1 a f1 f2)],
    'finally do not replace current break';
($d->{op}, @result) = ('throw'); $d->run();
is_deeply \@result, [qw(i=1 a f1 c2 f2 x i=2 a f1 c2 f2 x i=3 a f1 c2 f2 x)],
    'finally can replace current break with throw';
($d->{op}, @result) = ('continue'); $d->run();
is_deeply \@result, [qw(i=1 a f1 f2 i=2 a f1 f2 i=3 a f1 f2)],
    'finally can replace current break with continue';
($d->{op}, @result) = ('break'); $d->run();
is_deeply \@result, [qw(i=1 a f1 f2)],
    'finally can replace current break with break';



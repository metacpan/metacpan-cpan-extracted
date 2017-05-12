use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;


plan tests => 9;


my ($d);
my (@result);


# continue
# - correctly restart nearest while, with incremented iter()
# - correctly work inside if/try/catch/finally (inside while)
# - restart current Defer (with empty params) if used outside while
# - finally can replace current continue with throw/continue/break

$d = Async::Defer->new();
$d->while(sub{ $_[0]->iter() <= 3 });
    $d->do(sub{ push @result, 'i='.$_[0]->iter(); $_[0]->done() });
    $d->if(sub{ $_[0]->iter() == 2 });
        $d->try();
            $d->do(  sub{ push @result, 'do';
                          $_[0]->{op} eq 'do'      ? $_[0]->continue() : $_[0]->throw(); });
        $d->catch(
            qr//   =>sub{ push @result, 'ca';
                          $_[0]->{op} eq 'catch'   ? $_[0]->continue() : $_[0]->done(); },
            FINALLY=>sub{ push @result, 'fi';
                          $_[0]->{op} eq 'finally' ? $_[0]->continue() : $_[0]->done(); },
        );
    $d->end_if();
    $d->do(sub{ push @result, 'x'; $_[0]->done() });
$d->end_while();
($d->{op}, @result) = (q{}); $d->run();
is_deeply \@result, [qw(i=1 x i=2 do ca fi x i=3 x)], 'without continue';
($d->{op}, @result) = ('do'); $d->run();
is_deeply \@result, [qw(i=1 x i=2 do    fi   i=3 x)], 'continue inside if/try';
($d->{op}, @result) = ('catch'); $d->run();
is_deeply \@result, [qw(i=1 x i=2 do ca fi   i=3 x)], 'continue inside catch';
($d->{op}, @result) = ('finally'); $d->run();
is_deeply \@result, [qw(i=1 x i=2 do ca fi   i=3 x)], 'continue inside finally';

$d = Async::Defer->new();
$d->do(sub{ push @result, 'p='.($_[1]||q{}); $_[0]->done() });
$d->do(sub{ push @result, 'n='.++$_[0]->{n}; $_[0]->done() });
$d->do(sub{ $_[0]->{n} == 3 ? $_[0]->done() : $_[0]->continue() });
$d->do(sub{ push @result, 'x'; $_[0]->done() });
($d->{n}, @result) = (0); $d->run(undef, 10);
is_deeply \@result, [qw(p=10 n=1 p= n=2 p= n=3 x)],
    'restart current Defer (with empty params) if used outside while';

$d = Async::Defer->new();
$d->while(sub{ $_[0]->iter() <= 3 });
    $d->do(sub{ push @result, 'i='.$_[0]->iter(); $_[0]->done() });
    $d->try();
        $d->try();
            $d->do(sub{ push @result, 'a'; $_[0]->done() });
            $d->do(sub{ $_[0]->continue(); });
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
is_deeply \@result, [qw(i=1 a f1 f2 i=2 a f1 f2 i=3 a f1 f2)],
    'finally do not replace current continue';
($d->{op}, @result) = ('throw'); $d->run();
is_deeply \@result, [qw(i=1 a f1 c2 f2 x i=2 a f1 c2 f2 x i=3 a f1 c2 f2 x)],
    'finally can replace current continue with throw';
($d->{op}, @result) = ('continue'); $d->run();
is_deeply \@result, [qw(i=1 a f1 f2 i=2 a f1 f2 i=3 a f1 f2)],
    'finally can replace current continue with continue';
($d->{op}, @result) = ('break'); $d->run();
is_deeply \@result, [qw(i=1 a f1 f2)],
    'finally can replace current continue with break';



use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;


plan tests => 4;


my ($d);
my (@result);


# iter
# - croak outside while
# - increments both on end_while() and continue()
# - work correctly for outer and inner while
# - … even after exception jump from inner to outer while

$d = Async::Defer->new();
$d->do(sub{
    my ($d) = @_;
    $d->iter();
    $d->done();
});
throws_ok { $d->run() } qr{^iter\(\)}, 'croak outside while';

$d = Async::Defer->new();
$d->while(sub{ $_[0]->iter() < 4 });
    $d->do(sub{
        my ($d) = @_;
        push @result, $d->iter();
        if ($d->iter() == 2) {
            $d->continue();
        } else {
            $d->done();
        }
    });
$d->end_while();
@result = ();
$d->run();
is_deeply \@result, [1,2,3], 'increments both on continue() and end_while()';

$d = Async::Defer->new();
$d->while(sub{ $_[0]->iter() < 4 });
    $d->do(sub{
        my ($d) = @_;
        push @result, $d->iter();
        $d->done();
    });
    $d->while(sub{ $_[0]->iter() < 3 });
        $d->do(sub{
            my ($d) = @_;
            push @result, $d->iter() * 10;
            $d->done();
        });
    $d->end_while();
$d->end_while();
@result = ();
$d->run();
is_deeply \@result, [1,10,20,2,10,20,3,10,20], 'work correctly for outer and inner while';

$d = Async::Defer->new();
$d->while(sub{ $_[0]->iter() < 4 });
    $d->do(sub{
        my ($d) = @_;
        push @result, $d->iter();
        $d->done();
    });
    $d->try();
        $d->while(sub{ $_[0]->iter() < 3 });
            $d->do(sub{
                my ($d) = @_;
                push @result, $d->iter() * 10;
                $d->throw();
            });
        $d->end_while();
    $d->catch(
        qr// => sub{
            my ($d) = @_;
            $d->done();
        },
    );
$d->end_while();
@result = ();
$d->run();
is_deeply \@result, [1,10,2,10,3,10], '… even after exception jump from inner to outer while';



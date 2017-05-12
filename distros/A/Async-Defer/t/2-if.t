use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;


plan tests => 18;


my ($d);
my ($result, @result);


# if
# - require CODE in first param
# - receive $d in first param
# else
# end_if
# - if+end_if
# - if+else+end_if,
# - if+if+end_if+else+end_if
# - if+if+else+end_if+end_if
# - if+if+else+end_if+else+end_if
# - if+else+if+else+if+else+end_if+end_if+end_if

$d = Async::Defer->new();
throws_ok { $d->if() } qr/require CODE/;

$d = Async::Defer->new();
$d->if(sub{ $_[0]->{cond} });
    $d->do(sub{
        my ($d) = @_;
        $result = 1;
        $d->done();
    });
$d->end_if();
($d->{cond}, $result) = (1); $d->run();
is $result, 1, 'if+end_if (true)';
($d->{cond}, $result) = (0); $d->run();
is $result, undef, 'if+end_if (false)';

$d = Async::Defer->new();
$d->if(sub{ $_[0]->{cond} });
    $d->do(sub{
        my ($d) = @_;
        push @result, 1;
        $d->done();
    });
$d->else();
    $d->do(sub{
        my ($d) = @_;
        push @result, 2;
        $d->done();
    });
$d->end_if();
($d->{cond}, @result) = (1); $d->run();
is_deeply \@result, [1], 'if+else+end_if (true)';
($d->{cond}, @result) = (0); $d->run();
is_deeply \@result, [2], 'if+else+end_if (false)';

$d = Async::Defer->new();
$d->if(sub{ $_[0]->{cond}[0] });
    $d->if(sub{ $_[0]->{cond}[1] });
        $d->do(sub{
            my ($d) = @_;
            push @result, 1;
            $d->done();
        });
    $d->end_if();
$d->else();
    $d->do(sub{
        my ($d) = @_;
        push @result, 2;
        $d->done();
    });
$d->end_if();
($d->{cond}, @result) = ([1,0]); $d->run();
is_deeply \@result, [], 'if+if+endif+else+end_if (true,false)';
($d->{cond}, @result) = ([1,1]); $d->run();
is_deeply \@result, [1], 'if+if+endif+else+end_if (true,true)';
($d->{cond}, @result) = ([0,1]); $d->run();
is_deeply \@result, [2], 'if+if+endif+else+end_if (false,true)';

$d = Async::Defer->new();
$d->if(sub{ $_[0]->{cond}[0] });
    $d->if(sub{ $_[0]->{cond}[1] });
        $d->do(sub{
            my ($d) = @_;
            push @result, 1;
            $d->done();
        });
    $d->else();
        $d->do(sub{
            my ($d) = @_;
            push @result, 2;
            $d->done();
        });
    $d->end_if();
$d->end_if();
($d->{cond}, @result) = ([1,0]); $d->run();
is_deeply \@result, [2], 'if+if+else+endif+end_if (true,false)';
($d->{cond}, @result) = ([1,1]); $d->run();
is_deeply \@result, [1], 'if+if+else+endif+end_if (true,true)';
($d->{cond}, @result) = ([0,1]); $d->run();
is_deeply \@result, [], 'if+if+else+endif+end_if (false,true)';

$d = Async::Defer->new();
$d->if(sub{ $_[0]->{cond}[0] });
    $d->if(sub{ $_[0]->{cond}[1] });
        $d->do(sub{
            my ($d) = @_;
            push @result, 1;
            $d->done();
        });
    $d->else();
        $d->do(sub{
            my ($d) = @_;
            push @result, 2;
            $d->done();
        });
    $d->end_if();
$d->else();
    $d->do(sub{
        my ($d) = @_;
        push @result, 3;
        $d->done();
    });
$d->end_if();
($d->{cond}, @result) = ([1,0]); $d->run();
is_deeply \@result, [2], 'if+if+else+end_if+else+end_if (true,false)';
($d->{cond}, @result) = ([1,1]); $d->run();
is_deeply \@result, [1], 'if+if+else+end_if+else+end_if (true,true)';
($d->{cond}, @result) = ([0,1]); $d->run();
is_deeply \@result, [3], 'if+if+else+end_if+else+end_if (false,true)';

$d = Async::Defer->new();
$d->if(sub{ $_[0]->{cond}[0] });
    $d->do(sub{
        my ($d) = @_;
        push @result, 1;
        $d->done();
    });
$d->else();
    $d->if(sub{ $_[0]->{cond}[1] });
        $d->do(sub{
            my ($d) = @_;
            push @result, 2;
            $d->done();
        });
    $d->else();
        $d->if(sub{ $_[0]->{cond}[2] });
            $d->do(sub{
                my ($d) = @_;
                push @result, 3;
                $d->done();
            });
        $d->else();
            $d->do(sub{
                my ($d) = @_;
                push @result, 4;
                $d->done();
            });
        $d->end_if();
    $d->end_if();
$d->end_if();
($d->{cond}, @result) = ([1,1,1]); $d->run();
is_deeply \@result, [1], 'if+else+if+else+if+else+end_if+end_if+end_if (true,true,true)';
($d->{cond}, @result) = ([0,1,1]); $d->run();
is_deeply \@result, [2], 'if+else+if+else+if+else+end_if+end_if+end_if (false,true,true)';
($d->{cond}, @result) = ([0,0,1]); $d->run();
is_deeply \@result, [3], 'if+else+if+else+if+else+end_if+end_if+end_if (false,false,true)';
($d->{cond}, @result) = ([0,0,0]); $d->run();
is_deeply \@result, [4], 'if+else+if+else+if+else+end_if+end_if+end_if (false,false,false)';



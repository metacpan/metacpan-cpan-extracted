#!perl -w

use strict;
use constant HAS_THREADS => eval{ require threads };
use if !HAS_THREADS, 'Test::More', skip_all => 'This test requires threads';
use Test::More;

use warnings FATAL => 'all';

use Data::Clone;
use Time::HiRes qw(usleep);

{
    package MyBase;

    sub new {
        my $class = shift;
        return bless {@_}, $class;
    }

    package MyNoclonable;
    our @ISA = qw(MyBase);

    package MyClonable;
    use Data::Clone;
    our @ISA = qw(MyBase);

    package MyCustomClonable;
    use Data::Clone qw(data_clone);
    our @ISA = qw(MyBase);

    sub clone {
        my $cloned = data_clone(@_);
        $cloned->{bar} = 42;
        return $cloned;
    }

    package CreateThreadsInClone;
    use Data::Clone qw(data_clone);
    our @ISA = qw(MyBase);

    sub clone {
        my $cloned = data_clone(@_);
        $cloned->{bar} = threads->create(sub{ data_clone([42]) })->join();
        return $cloned;
    }
}

my @threads;
for(1 .. 3){

    push @threads, threads->create(sub{
        usleep 10;;

        my $o = MyNoclonable->new(foo => 10);
        my $c = do{
            local $Data::Clone::ObjectCallback = sub{ $_[0] };
            clone($o);
        };

        is $c, $o, "tid - " . threads->tid;
        $c->{foo}++;
        is $o->{foo}, 11, 'noclonable';

        usleep 10;

        $o = MyClonable->new(foo => 10);
        $c = clone($o);
        isnt $c, $o;
        $c->{foo}++;
        is $o->{foo}, 10, 'clonable';

        usleep 10;

        $o = MyCustomClonable->new(foo => 10);
        $c = clone($o);
        isnt $c, $o;
        $c->{foo}++;
        is $o->{foo}, 10, 'clonable';
        is_deeply $c, { foo => 11, bar => 42 }, 'custom clone()';

        usleep 10;

        $o = MyCustomClonable->new(foo => MyClonable->new(bar => 42));
        $c = clone($o);

        $c->{foo}{bar}++;

        is $o->{foo}{bar}, 42, 'clone() is reentrant';
        is $c->{foo}{bar}, 43;

        $o = CreateThreadsInClone->new(foo => 50);
        $c = clone($o);

        usleep 10;

        is $c->{foo}, 50;
        is_deeply $c->{bar}, [42], 'threads->create in clone()';

        return threads->tid;
    });
}

foreach my $thr(@threads){
    pass "\$thr->join: " . $thr->join;
}

done_testing;

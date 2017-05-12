#!perl -w

use strict;
use warnings FATAL => 'all';

use Test::More;

use Data::Clone;

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

    package FatalClonable;
    our @ISA = qw(MyBase);

    sub clone {
        die 'FATAL';
    }
}

for(1 .. 2){ # do it twice to test internal data
    note($_);

    my($o, $c);

    $o = MyNoclonable->new(foo => 10);

    eval {
        local $Data::Clone::ObjectCallback = sub{ die 'Non-clonable object' };
        $c = clone($o);
    };
    like $@, qr/Non-clonable object/, 'die on non-clonables';
    is $c, undef;

    eval {
        $c = clone($o);
    };

    is $@, '';
    is $c, $o;
    $c->{foo}++;
    is $o->{foo}, 11, 'noclonable with surface copy';

    $o = MyClonable->new(foo => 10);
    $c = clone($o);
    isnt $c, $o;
    $c->{foo}++;
    is $o->{foo}, 10, 'clonable';

    $o = MyCustomClonable->new(foo => 10);
    $c = clone($o);
    isnt $c, $o;

    $c->{foo}++;
    is $o->{foo}, 10, 'clonable';
    is_deeply $c, { foo => 11, bar => 42 }, 'custom clone()';

    $o = MyClonable->new(
        aaa => [[42], MyCustomClonable->new(value => 100)],
        bbb => [[42], MyCustomClonable->new(value => 200)],
    );
    $c = clone($o);

    $c->{aaa}[1]{value}++;
    $c->{bbb}[1]{value}++;

    is $o->{aaa}[1]{value}, 100, 'clone() is reentrant';
    is $c->{aaa}[1]{value}, 101;
    is $c->{aaa}[1]{bar},    42;

    is $o->{bbb}[1]{value}, 200, 'clone() is reentrant';
    is $c->{bbb}[1]{value}, 201;
    is $c->{bbb}[1]{bar},    42;

    $o = MyCustomClonable->new();
    $o->{ccc} = [MyCustomClonable->new(value => 300)];
    $o->{ddd} = $o->{ccc};

    $c = clone($o);
    $c->{ccc}[0]{value}++;
    $c->{ddd}[0]{value}++;

    is $o->{ccc}[0]{value}, 300;
    is $c->{ccc}[0]{value}, 302;
    is $c->{ccc}[0]{bar},   42,  'clone methods in clone()';

    $o = FatalClonable->new(foo => 10);
    eval{
        clone($o);
    };
    like $@, qr/^FATAL \b/xms, 'FATAL in clone()';
    is $o->{foo}, 10;

    $o = MyCustomClonable->new(value => FatalClonable->new(foo => 10));
    eval{
        clone($o);
    };
    like $@, qr/^FATAL \b/xms, 'FATAL in clone()';
    is $o->{value}{foo}, 10;
}

done_testing;

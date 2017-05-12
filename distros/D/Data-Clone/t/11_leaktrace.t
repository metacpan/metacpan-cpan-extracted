#!perl -w

use strict;
use Test::Requires qw(Test::LeakTrace);
use Test::More;
use warnings FATAL => 'all';

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
    use Data::Clone qw(data_clone);
    our @ISA = qw(MyBase);

    sub clone {
        my $cloned = data_clone(@_);
        die 'FATAL';
    }
}

no_leaks_ok {
    my $o = [ 42 ];
    my $c = clone($o);
} or die "Memory leaked";

no_leaks_ok {
    local $Data::Clone::ObjectCallback = sub{ $_[0] };
    my $o = MyNoclonable->new(foo => 10);
    my $c = clone($o);
};

no_leaks_ok {
    my $o = MyClonable->new(foo => 20);
    my $c = clone($o);
};

no_leaks_ok {
    my $o = MyCustomClonable->new(foo => 30);
    my $c = clone($o);
};

no_leaks_ok {
    my $o = MyCustomClonable->new(foo => MyClonable->new(bar => 42));
    my $c = clone($o);
};

no_leaks_ok {
    my $o = FatalClonable->new(value => MyClonable->new(foo => 50));
    eval{ clone($o) };
} 'fatal in clone()';

done_testing;

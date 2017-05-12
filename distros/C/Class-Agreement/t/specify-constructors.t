#!perl
use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

my $file = __FILE__;

# As described above, invariants are checked on public methods when the first
# argument is an object. Since constructors are typically class methods (if not
# also object methods), C<Class::Agreement> needs to know which methods are
# constructors so that it can check invariants against the constructors' return
# values instead of simply ignoring them.
#
# By default, it is assumed that a method named C<new> is the constructor. You
# don't have to bother with this keyword if you don't specify any invariants or if
# your only constructor is C<new>.

{
    my $counter = 0;
    {

        package Camel;
        use Class::Agreement;
        invariant sub { ++$counter };
        sub new { bless [], shift }
        sub not_a_constructor { }
    }

    my $c = Camel->new;
    is $counter, 1, "invariants checked once after constructor";
    $c->not_a_constructor;
    is $counter, 3, "invariants checked twice for regular method";
}

# Any subclasses of C<Othello::Board> would also have the invariants of the
# methods C<new()> and C<new_random()> checked as constructors. You can override
# the specified constructors of any class -- all subclasses will use the settings
# specified by their parents.

{
    my $counter = 0;
    {

        package Ox;
        use Class::Agreement;
        invariant sub { ++$counter };
        specify_constructors('custom_constructor');
        sub custom_constructor { bless [], shift }

        package Moose;
        use base 'Ox';

        package Antelope;
        use base 'Moose';
    }

    my $m = Moose->custom_constructor;
    is $counter, 1,
        "invariants checked once after custom constructor in subclass";

    my $a = Antelope->custom_constructor;
    is $counter, 2,
        "invariants checked once after custom constructor in subsubclass";
}

# If your class has more constructors, you should specify all of them (including
# C<new>) with C<specify_constructors> so that invariants can be checked properly:

{
    my $counter = 0;
    {

        package Auroch;
        use Class::Agreement;
        invariant sub { ++$counter };
        specify_constructors qw( new another_constructor );
        sub new                 { bless [], shift }
        sub another_constructor { bless [], shift }
        sub not_a_constructor   { }
    }

    my $a1 = Auroch->new;
    isa_ok $a1, 'Auroch';
    is $counter, 1, "invariants checked once after regular constructor";
    my $a2 = Auroch->another_constructor;
    isa_ok $a2, 'Auroch';
    is $counter, 2, "invariants checked once after an extra constructor";
    $a2->not_a_constructor;
    is $counter, 4, "invariants checked twice for regular method";
}

# If, for some reason, your class has no constructors, you can pass
# C<specify_constructors> an empty list:

{
    my $counter = 0;
    {

        package Buffalo;
        use Class::Agreement;
        invariant sub { ++$counter };
        specify_constructors();
        sub new                 { }
        sub another_constructor { }
        sub not_a_constructor   { }
    }

    my $b = bless [], 'Buffalo';
    $b->new;
    is $counter, 2, "thinks new() is a regular method";
    $b->another_constructor;
    is $counter, 4, "thinks another_constructor() is a regular method";
    $b->not_a_constructor;
    is $counter, 6, "thinks not_a_constructor() is a regular method";
}


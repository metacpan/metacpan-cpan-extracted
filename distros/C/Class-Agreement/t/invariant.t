#!perl

use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;

# BLOCK will be evaluated before and after every public method in the current
# class. A I<public method> is described as any subroutine in the package whose
# name begins with a letter and is not composed entirely of uppercase letters.

{
    my $actual_counter = 0;

    {

        package Camel;
        use Class::Agreement;
        invariant sub { ++$actual_counter };
        sub new { bless {}, shift }
        sub some_method       { }
        sub anotherMethod     { }
        sub _a_private_method { }
        sub RESERVED          { }
        sub DESTROY           { }
    }

    my $c = Camel->new;
    isa_ok $c, 'Camel';
    is $actual_counter, 1, "counter check after new()";

    my $expected_counter = 1;
    foreach my $tuple (
        [ some_method       => 2 ],
        [ anotherMethod     => 2 ],
        [ _a_private_method => 0 ],
        [ RESERVED          => 0 ],
        )
    {
        my ( $method, $increment ) = @$tuple;
        $c->$method;
        $expected_counter += $increment;
        is $actual_counter, $expected_counter,
            "counter check after $method()";
    }

    undef $c;
    is $actual_counter, $expected_counter, "counter check after destructor";

}

# Invariant BLOCKS are provided with only one argument: the current object.

{
    my $counter = 0;

    {

        package Llama;
        use strict;
        use warnings;
        use Class::Agreement;

        invariant sub {
            Test::More::is( scalar(@_), 1, "only one argument to invariant" );
            Test::More::is( ref $_[0] || $_[0], 'Llama', "argument is Llama obj or class" );
            ++$counter;
        };

        sub new { bless [], shift }
        sub some_method { }
    }

    Llama->new->some_method;
    is $counter, 3, "counter check after invariant args test";
}

# Invariants will not be evaluated for class methods. More specifically,
# invariants will only be evaluated when the first argument to a subroutine is
# a blessed reference. This would mean that invariants would not be checked for
# constructors, but C<Class::Agreement> provides another function,
# L<"specify_constructors">, which is used for this purpose. (See the following
# section for details.)

{
    my $counter = 0;

    {

        package Alpaca;
        use strict;
        use warnings;
        use Class::Agreement;

        invariant sub { ++$counter };
        sub new { bless [], shift }
        sub some_method { }
    }

    my $a = Alpaca->new;
    Alpaca->some_method;
    is $counter, 1, "invariant not checked on class method...";
    $a->some_method;
    is $counter, 3, "...but it's checked after an instance method";
}

# Invariants are not checked when destructors are invoked. For an explanation as
# to why, see L<"WHITEPAPER">.

# --------> checked in first block above <------------

# You can use this keyword multiple times to declare multiple invariant contracts
# for the class.

{
    my $string = '';

    {

        package Ox;
        use strict;
        use warnings;
        use Class::Agreement;

        invariant sub { $string .= 'a' };
        invariant sub { $string .= 'b' };
        invariant sub { $string .= 'c' };
        sub new { bless [], shift }
        sub some_method { }
    }

    my $o = Ox->new;
    foreach my $i (qw( a b c )) {
        my @matches = $string =~ /$i/g;
        is scalar(@matches), 1,
            "invariant $i was checked once after constructor";
    }

    $string = '';
    $o->some_method;
    foreach my $i (qw( a b c )) {
        my @matches = $string =~ /$i/g;
        is scalar(@matches), 2,
            "invariant $i was checked twice after a method";
    }

}

# Blaming violators of invariants is easy. If an invariant contract fails
# following a method invocation, we assume that the check prior to the
# invocation must have succeeded, so the implementation of the method is at
# fault. If an invariant fails before the method runs, invariants must have
# succeeded after the last method was called, so the object must have been
# tampered with by an exogenous source. Eeek!

{

    package Buffalo;
    use strict;
    use warnings;
    use Class::Agreement;

    invariant sub { ${shift()} > 0 };

    sub new {
        my $x = 1;
        bless \$x, shift;
    }

    sub do_nothing { 'dum dee dum-dum' }
    sub cause_error { ${shift()} = -5 }
}

{
    my $b = Buffalo->new;
    lives_ok { $b->do_nothing } "no error";
}

{
    my $b = Buffalo->new;
    throws_ok { $b->cause_error } qr/method's implementation/,
        "faulty method is blamed";
}

{
    my $b = Buffalo->new;
    $$b = -2;
    throws_ok { $b->do_nothing } qr/outside source/,
        "tampering is blamed";
}


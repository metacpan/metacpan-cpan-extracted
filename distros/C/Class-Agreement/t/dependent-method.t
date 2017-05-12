#!perl

use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;

use Class::Agreement;

my $file = __FILE__;

# dependent NAME, BLOCK
#
# Specify that the method NAME will use the subroutine reference returned by
# BLOCK as a postcondition.

{

    package Camel;
    use Class::Agreement;

    sub simple { $_[1] }

    dependent simple => sub {
        return sub { result > 0 }
    };
}

lives_ok { Camel->simple(5) } "method simple success";
dies_ok  { Camel->simple(-1) } "method simple failure";

eval { Camel->simple(-1) };
like $@, qr/line \s+ 27/x, "simple failure line number";
like $@, qr/$file/x,       "simple failure filename";

# If BLOCK returns undefined, no postcondition will be added.

{

    package Camel;

    sub undefiner { $_[1] }

    dependent undefiner => sub { undef };
}

lives_ok { Camel->undefiner(5) } "no reason this should fail, one";
lives_ok { Camel->undefiner(-1) } "no reason this should fail, two";

# BLOCK is run at the same time as preconditions, thus the @_ variable works in
# the same manner as in preconditions.

{

    package Camel;

    sub outerargcheck { }

    dependent outerargcheck => sub {
        Test::More::is_deeply(
            \@_,
            [ 'Camel', 1, 2, 3 ],
            "method arguments outside"
        );
        return;
    };
}

Camel->outerargcheck( 1, 2, 3 );

# However, the subroutine reference that BLOCK returns will be invoked as
# a postcondition, thus it may use @_, $r and @r.

{

    package Camel;

    sub innerargcheck { }

    dependent innerargcheck => sub {
        sub {
            Test::More::is_deeply(
                \@_,
                [ 'Camel', 1, 2, 3 ],
                "method arguments inside"
            );
            }
    };
}

Camel->innerargcheck( 1, 2, 3 );

{

    package Camel;

    sub returnlist { ( 6, 5, 4 ) }

    dependent returnlist => sub {
        sub {
            Test::More::is_deeply( [result], [ 6, 5, 4 ],
                "return list, array" );
            Test::More::is( result, 6, "return list, scalar" );
            }
    };
}

Camel->returnlist;

{

    package Camel;

    sub returnscalar { 7 }

    dependent returnscalar => sub {
        sub {
            Test::More::is_deeply( [result], [7], "return scalar, array" );
            Test::More::is( result, 7, "return scalar, scalar" );
            }
    };
}

Camel->returnscalar;

# You'll probably use these, along with closure, to check the old copies of
# values. See the example in "Testing old values".

{

    package Camel;

    sub new { bless { foo => 0 }, shift }

    sub add_to_foo
    {
        my ( $self, $value ) = @_;
        $self->{foo} += $value;
    }

    dependent add_to_foo => sub {
        my ( $self, $value ) = @_;
        my $old_foo = $self->{foo};
        return sub {
            return ( $self->{foo} > $old_foo );
        };
    };
}

{
    my $camel = Camel->new;
    lives_ok { $camel->add_to_foo(4) } "proof of concept success";
    dies_ok  { $camel->add_to_foo(-4) } "proof of concept failure";
}

# You can use this keyword multiple times to declare multiple dependent
# contracts on the given method.

{

    package Camel;

    sub multiple { $_[1] }

    dependent multiple => sub {
        sub { result > 0 }
    };
    dependent multiple => sub {
        sub { not result % 2 }
    };
}

lives_ok { Camel->multiple(4) } "method multiple success";
dies_ok  { Camel->multiple(-4) } "method multiple failure first";
dies_ok  { Camel->multiple(3) } "method multiple failure second";
dies_ok  { Camel->multiple(-3) } "method multiple failure both";


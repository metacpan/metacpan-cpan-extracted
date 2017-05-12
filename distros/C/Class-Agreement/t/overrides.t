#!perl

use strict;
use warnings;

#
# Contracts of the given type (pre, post, dependent) should propagate to
# subclasses until they are overridden.
#
# Declaring multiple contracts of the same type shouldn't be affected.
#
# XXX - document this - if method exists? if not? abstract classes?
#

use Test::More tests => 25;
use Test::Exception;

{

    package PopPop;
    use Class::Agreement;
    precondition method  => sub { not $_[1] % 2 };
    precondition method  => sub { not $_[1] % 3 };
    postcondition method => sub { not result % 5 };
    postcondition method => sub { not result % 7 };
    sub new { bless {}, shift }
    sub method { $_[1] }
}

sub perform_parent_checks {
    my ( $class, $name ) = @_;
    dies_ok  { $class->new->method(3) } "1st pre on $name fails";
    dies_ok  { $class->new->method(2) } "2nd pre on $name fails";
    dies_ok  { $class->new->method( 2 * 3 ) } "1st post on $name fails";
    dies_ok  { $class->new->method( 2 * 3 * 5 ) } "2nd post on $name fails";
    lives_ok { $class->new->method( 2 * 3 * 5 * 7 ) } "all is well on $name";
}

perform_parent_checks( 'PopPop', 'grandparent class' );

{

    package Dad;
    use base 'PopPop';
}

perform_parent_checks( 'Dad', 'parent class' );

{

    package Timmy;
    use base 'Dad';
    use Class::Agreement;
    precondition method  => sub { $_[1] < 1000 };
    postcondition method => sub { result < 500 };
    sub method { $_[1] }
}

sub perform_child_checks {
    my ( $class, $name ) = @_;
    lives_ok { $class->new->method(3) }
        "$name lives and ignores 1st old precondition";
    lives_ok { $class->new->method(2) }
        "$name lives and ignores 2nd old precondition";
    lives_ok { $class->new->method( 2 * 3 ) }
        "$name lives and ignores 1st old postcondition";
    lives_ok { $class->new->method( 2 * 3 * 5 * 7 ) }
        "$name lives and ignores 2nd old postcondition";
    dies_ok { $class->new->method(1001) }
        "$name checks new precondition and dies";
    dies_ok { $class->new->method(501) }
        "$name checks new postcondition and dies";
}

perform_child_checks( 'Timmy', 'child class' );

{

    package TimmyJR;
    use base 'Timmy';
}

perform_child_checks( 'TimmyJR', 'subchild class' );

{

    package Susie;
    use base 'PopPop';
    use Class::Agreement;
    precondition method => sub { $_[1] != 2 * 3 * 5 * 7 };

    package SusieJR;
    use base 'Susie';
}

dies_ok { Susie->new->method( 2 * 3 * 5 * 7 ) }
    "alt child appends a contract";
dies_ok { SusieJR->new->method( 2 * 3 * 5 * 7 ) } "alt subchild use appended";

{

    package Abstract;
    use Class::Agreement;
    Test::Exception::throws_ok {
        precondition method => sub { $_[1] > 0 };
        }
        qr/undefined subroutine/,
        "can't specify contracts for abstract classes";
}

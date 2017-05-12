#!perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

{

    package ClassA;
    use Class::Agreement;

    package ClassB;
    use base 'ClassA';
    use Class::Agreement;
}

{

    package ClassA;
    use Class::Agreement;

    sub m { $_[1] }
    postcondition m => sub { result() > 0 };

    package ClassB;
    use Class::Agreement;

    sub m { $_[1] }
    postcondition m => sub { not result() % 2 };
}

eval { my $x = ClassB->m(4) };
is $@, '', "no failure, multiple classes";

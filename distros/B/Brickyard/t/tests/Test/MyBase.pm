use 5.010;
use strict;
use warnings;

package Test::MyBase;
# ABSTRACT: XXX

use parent 'Test::Class';

INIT { Test::Class->runtests }

sub make_object {
    my $test = shift;
    my $package = $test->class;
    eval "require $package";
    die "Cannot require $package: $@" if $@;
    $test->class->new(@_);
}

1;

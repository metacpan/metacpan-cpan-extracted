#! /bin/env perl

use v5.26;
use experimental 'signatures';

package Foo {
    use overload '|' => \&_or;

    sub new                      { bless {}, __PACKAGE__ }
    sub _or ( $self, $other, $ ) { }

}

my $bar = Foo->new | Foo->new;

{
    use feature 'bitwise';
    my $bar = Foo->new | Foo->new;
}

use lib 'lib';
use Test::More tests => 1;
use strict;

package Foo;
# use Class::Field -clean => 'field';
# use Class::Field -debug => 'field';
use Class::Field 'field';

sub new { return bless {}, shift }
print field x => -init => 'main::test1()';

package main;

my $f = Foo->new();

$f->x();

sub test1 {
    my $name = (caller(1))[3];
    is $name, 'Foo::x',
        'ANON replaced with real sub name for field';
}

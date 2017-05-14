use Test::More;

package TestClass_XS;
use strict; use warnings; use diagnostics;
use Class::Std::Fast_XS;
use Class::Std::Fast::Storable;
use Test::More;
{
    my %foo_of :ATTR(:name<bla>);
    my %baz_of :ATTR(:name<baz>);
}
sub DEMOLISH {
    pass 'base class demolish';
}

package TestClass_XS_2;
use Test::More;
use Class::Std::Fast_XS;
use Class::Std::Fast::Storable;

use base qw(TestClass_XS);
{
    my %foo_of :ATTR(:name<foo>);
    my %bar_of :ATTR(:name<bar>);
}
sub DEMOLISH {
    pass 'demolish';
}


package TestClass_XS_3;
use Class::Std::Fast_XS;
use Class::Std::Fast cache => 1;
{
    my %foo_of :ATTR(:name<foo>);
    my %bar_of :ATTR(:name<bar>);
}

package main;
use Test::More;
plan tests => 3;
{
    my $obj_demolish2 = TestClass_XS_2->new({ bla => 1, foo => 2, bar => 2, baz => 3});
}

{
    my $obj_demolish3 = TestClass_XS_3->new({ foo => 2, bar => 2 });
    undef $obj_demolish3;
    $obj_demolish3 = TestClass_XS_3->new({ foo => 2, bar => 2 });
    undef $obj_demolish3;
}

#use Data::Dumper;
#print Dumper Class::Std::Fast::OBJECT_CACHE_REF();
is ${ Class::Std::Fast::OBJECT_CACHE_REF()->{ TestClass_XS_3 }->[0] }, 2;

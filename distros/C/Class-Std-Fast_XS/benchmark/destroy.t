use strict;

package TestClass;
use Class::Std::Fast constructor => 'basic';

my %bla_of :ATTR(:name<bla>);

package TestClass2;
use base qw(TestClass);
use Class::Std::Fast constructor => 'basic';

my %bar_of :ATTR(:name<bar>);
my %foo_of :ATTR(:name<foo>);

package TestClass_XS;

use Class::Std::Fast_XS;
use Class::Std::Fast constructor => 'basic';
{
    my %foo_of :ATTR(:name<bla>);
    my %baz_of :ATTR(:name<baz>);
}
package TestClass2_XS;
# use base qw(TestClass_XS UNIVERSAL);
use Class::Std::Fast constructor => 'basic';
{
    my %bar_of :ATTR(:name<bar>);
    my %foo_of :ATTR(:name<foo>);
    my %baz_of :ATTR(:name<baz>);
}
package main;
use lib '../blib/lib';
use lib '../blib/arch';

use strict;
use warnings;

use Benchmark;
my $n = 150000; #0_000;
my @obj_from = ();
my @xs_from = ();

for (1..$n) {
    push @obj_from, TestClass2->new({ bla => 'foo', foo => 1, bar => 2 });
    push @xs_from, TestClass2_XS->new({ bla => 'foo', foo => 1, bar => 2 });
}
#
print "\ndestroy\n";
Benchmark::cmpthese $n, {
    obj => sub {
        pop @obj_from; return;
    },
    xs => sub {
        pop @xs_from; return;
    },
};

__END__

#while (1) {
use Devel::Leak;
my $handle;
print Devel::Leak::NoteSV($handle), "\n";

for (1..5) {
    TestClass2_XS->new({ foo => [ 'foo', 2 ], bar => [ 'foo', 2 ] });
    print Devel::Leak::NoteSV($handle), "\n";
}

while (1) {
    TestClass2_XS->new({ foo => [ 'foo', 2 ], bar => [ 'foo', 2 ] });
}
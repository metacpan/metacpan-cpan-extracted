use lib '../lib';
package MyPackage;
use strict;
use Class::Std::Fast cache => 1;
use Test::More;

my %value_of :ATTR(:name<value> :default<()>);

sub START {
    pass("START method called for ID ${ $_[0] }");
}

sub BUILD {
    pass("BUILD called for ID ${ $_[0] }");
}

sub DEMOLISH { pass "DEMOLISH called for ID ${ $_[0] }" }

1;

package MyPackageBasic;
use strict;
use Class::Std::Fast caching => 1, constructor => 'basic';
1;

package main;
use strict;
use Test::More;

plan tests => 9;

my $test;
# fire ok, BUILD, START
# Tests 1,2,3
ok $test = MyPackage->new();

my $id = ${ $test };
# fire DEMOLISH (4)
undef $test;

my $basic = MyPackageBasic->new();

# fire ok, BUILD, START - #5,6,7
ok $test = MyPackage->new({
    value => $basic
});
#8
is ${ $test }, $id, 'Obj has ID of destroyed object';

#9
ok ${ $basic } > ${ $test }, 'Obj created before has greater ID than cached obj';
# undef $test;

# Avoid calling DEMOLISH in global destruction
{ 
    no warnings qw(redefine);
    *MyPackage::DEMOLISH = sub {}
}
#!perl

package MyClass::Foo;

use Class::Root 'isa';

my $foo = __PACKAGE__;

package MyClass::Foo::LOCAL;

use strict;
use warnings;

use declare class_attribute ca1 => 1;
class_initialize;
use declare attribute a1 => 101;
use declare m1 => method sub(){};
class_verify;

package MyClass::Bar;

use Class::Root "isa";

my $bar = __PACKAGE__; 

package MyClass::Bar::LOCAL;

use strict;
use warnings;

use declare class_attribute ca1 => 2;
class_initialize;
use declare attribute a1 => 202;
class_verify;

package MyClass::Baz;

use Class::Root "isa";

my $baz = __PACKAGE__; 

package MyClass::Baz::LOCAL;

use strict;
use warnings;

use declare class_attribute ca1 => 2;
class_initialize;
use declare attribute a1 => 202;
use declare m1 => method sub(){};
class_verify;

package main;

use strict;
use warnings;

use Test::More tests => 3;
use English;

use MyClass::Foo qw(+DEFINE_LOCAL_SUBS);
use MyClass::Bar qw(+DEFINE_LOCAL_SUBS);

#1
eval "use MyClass::Baz qw(+DEFINE_LOCAL_SUBS)";
like($EVAL_ERROR,qr/Function "m1" already defined in package "main"/,"DIED: import existing local sub"); 

my $f = $foo->new;
my $b = $bar->new;

#2
$_ = $foo;
is(ca1, 1, '$_ = Foo; ca1 eq 1');

#3
$_ = $bar;
is(ca1, 2, '$_ = Bar; ca1 eq 2');

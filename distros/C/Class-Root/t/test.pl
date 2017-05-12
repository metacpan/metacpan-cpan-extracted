#!perl
use strict;
use warnings;

sub ::RT_CHECKS(){1};
sub ::CT_CHECKS(){1};
sub ::LOCAL_SUBS(){1};

package Foo;

my $class = __PACKAGE__;

use Class::Root 'isa';

package Foo::LOCAL;

use strict;
use warnings;

declare (
    aaa => private method {"bbb"},			#werer
    ccc => protected class_method {"ddd"},		#twtrttr
    private attribute AAA => setopts { value => 5 },	#rtrtrt

    BBB => attribute,
    setopts BBB => { value => 10 },

    ddd => attribute,
    xxx => "_XXX",
    ccc => virtual method,
);

declare attributes '

    ax _privax     :*cprotax ?roax
';
	
class_initialize;

print Foo->class_schema;

package main;
use Foo;

#my $foo = Foo->new( BBB => 11, _AAA => 10, _ccc => 2 );
my $foo = Foo->new( BBB => 11 );
print $foo->instance_dump;


use strict;
use Test;

# use a BEGIN block so we print our plan before module is loaded
BEGIN { use Class::OOorNO qw( :all ) }
BEGIN { plan tests => scalar(@Class::OOorNO::EXPORT_OK), todo => [] }
BEGIN { $| = 1 }

# load your module...
use lib './';

# automated empty subclass test

# subclassClass::OOorNO in package _Foo
package _Foo;
use strict;
use warnings;
$Foo::VERSION = 0.00_0;
@_Foo::ISA = qw( Class::OOorNO );
1;

# switch back to main package
package main;

# see if _Foo can do everything thatClass::OOorNO can do
map {

   ok ref(UNIVERSAL::can('_Foo', $_)) eq 'CODE'

} @Class::OOorNO::EXPORT_OK;


exit;

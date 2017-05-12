# 01_init.t
#
# Tests for proper loading of the module

use Test::More tests => 6;

use strict;
use warnings;

ok( eval 'require Class::EHierarchy;', 'Loaded Class::EHierarchy' );

my $obj = new Class::EHierarchy;
ok( defined $obj,                   'Created object 1' );
ok( $obj->isa('Class::EHierarchy'), 'Verified object class' );
ok( $$obj == 0,                     'Verified object ID 1' );

my $obj2 = new Class::EHierarchy;
ok( defined $obj2, 'Created object 2' );
ok( $$obj2 == 1,   'Verified object ID 2' );


#!perl -wT

use strict;

# use lib 'lib';
use Test::Most tests => 9;
use Scalar::Util qw(blessed);

BEGIN { use_ok('Data::Text') }

isa_ok(Data::Text->new(), 'Data::Text', 'Creating Data::Text object');
isa_ok(Data::Text->new()->new(), 'Data::Text', 'Cloning Data::Text object');
isa_ok(Data::Text::new(), 'Data::Text', 'Creating Data::Text object');

# Creating a new object without arguments
my $obj1 = Data::Text->new();
ok(blessed($obj1) eq 'Data::Text', 'Created object is blessed into Data::Text');
ok(!%$obj1, 'Object has no attributes when created without arguments');

# Creating a new object with arguments
my $obj2 = Data::Text->new('nan');
is($obj2->{text}, 'nan', 'Attribute "text" is set correctly');

# Cloning an existing object, setting new text
my $obj3 = $obj2->new(text => 'cloned');
cmp_ok($obj3->{text}, 'eq', 'cloned', 'Cloned object retains attributes and adds new ones');

# Cloning an existing object, keeping old text
my $obj4 = $obj2->new();
cmp_ok($obj4->{text}, 'eq', 'nan', 'Cloned object retains attributes and adds new ones');

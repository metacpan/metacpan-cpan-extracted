##############################
#
# Array_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Array_package.t`

##############################
# C O P Y R I G H T   N O T I C E
#  Copyright (c) 2001-2006 by:
#    * The MicroArray Gene Expression Database Society (MGED)
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.



use Carp;
# use blib;
use Test::More tests => 33;
use strict;

BEGIN { use_ok('Bio::MAGE::Array') };

# we test the classes() method
my @classes = Bio::MAGE::Array->classes();
is((scalar @classes), 10, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::Array::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $array = Bio::MAGE::Array->new();
isa_ok($array, "Bio::MAGE::Array");

# test the tagname method
ok(defined $array->tagname, 'tagname');


# test the xml_lists method
ok(defined $array->xml_lists,
  'xml_lists');


# test the arraygroup_list method
$array->arraygroup_list([]);
isa_ok($array->arraygroup_list,'ARRAY');
is(scalar @{$array->arraygroup_list}, 0,
   'arraygroup_list empty');

# test the getArrayGroup_list method
isa_ok($array->getArrayGroup_list,'ARRAY');
is(scalar @{$array->getArrayGroup_list}, 0,
   'getArrayGroup_list empty');

# test the addArrayGroup() method
$array->addArrayGroup($classes{ArrayGroup});
isa_ok($array->getArrayGroup_list,'ARRAY');
ok(scalar @{$array->getArrayGroup_list},
   'getArrayGroup_list not empty');


# test the array_list method
$array->array_list([]);
isa_ok($array->array_list,'ARRAY');
is(scalar @{$array->array_list}, 0,
   'array_list empty');

# test the getArray_list method
isa_ok($array->getArray_list,'ARRAY');
is(scalar @{$array->getArray_list}, 0,
   'getArray_list empty');

# test the addArray() method
$array->addArray($classes{Array});
isa_ok($array->getArray_list,'ARRAY');
ok(scalar @{$array->getArray_list},
   'getArray_list not empty');


# test the arraymanufacture_list method
$array->arraymanufacture_list([]);
isa_ok($array->arraymanufacture_list,'ARRAY');
is(scalar @{$array->arraymanufacture_list}, 0,
   'arraymanufacture_list empty');

# test the getArrayManufacture_list method
isa_ok($array->getArrayManufacture_list,'ARRAY');
is(scalar @{$array->getArrayManufacture_list}, 0,
   'getArrayManufacture_list empty');

# test the addArrayManufacture() method
$array->addArrayManufacture($classes{ArrayManufacture});
isa_ok($array->getArrayManufacture_list,'ARRAY');
ok(scalar @{$array->getArrayManufacture_list},
   'getArrayManufacture_list not empty');



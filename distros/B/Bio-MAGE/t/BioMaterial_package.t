##############################
#
# BioMaterial_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioMaterial_package.t`

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
use Test::More tests => 25;
use strict;

BEGIN { use_ok('Bio::MAGE::BioMaterial') };

# we test the classes() method
my @classes = Bio::MAGE::BioMaterial->classes();
is((scalar @classes), 8, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::BioMaterial::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $biomaterial = Bio::MAGE::BioMaterial->new();
isa_ok($biomaterial, "Bio::MAGE::BioMaterial");

# test the tagname method
ok(defined $biomaterial->tagname, 'tagname');


# test the xml_lists method
ok(defined $biomaterial->xml_lists,
  'xml_lists');


# test the compound_list method
$biomaterial->compound_list([]);
isa_ok($biomaterial->compound_list,'ARRAY');
is(scalar @{$biomaterial->compound_list}, 0,
   'compound_list empty');

# test the getCompound_list method
isa_ok($biomaterial->getCompound_list,'ARRAY');
is(scalar @{$biomaterial->getCompound_list}, 0,
   'getCompound_list empty');

# test the addCompound() method
$biomaterial->addCompound($classes{Compound});
isa_ok($biomaterial->getCompound_list,'ARRAY');
ok(scalar @{$biomaterial->getCompound_list},
   'getCompound_list not empty');


# test the biomaterial_list method
$biomaterial->biomaterial_list([]);
isa_ok($biomaterial->biomaterial_list,'ARRAY');
is(scalar @{$biomaterial->biomaterial_list}, 0,
   'biomaterial_list empty');

# test the getBioMaterial_list method
isa_ok($biomaterial->getBioMaterial_list,'ARRAY');
is(scalar @{$biomaterial->getBioMaterial_list}, 0,
   'getBioMaterial_list empty');

# test the addBioMaterial() method
$biomaterial->addBioMaterial($classes{BioMaterial});
isa_ok($biomaterial->getBioMaterial_list,'ARRAY');
ok(scalar @{$biomaterial->getBioMaterial_list},
   'getBioMaterial_list not empty');



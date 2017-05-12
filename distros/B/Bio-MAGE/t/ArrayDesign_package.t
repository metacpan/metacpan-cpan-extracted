##############################
#
# ArrayDesign_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ArrayDesign_package.t`

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
use Test::More tests => 32;
use strict;

BEGIN { use_ok('Bio::MAGE::ArrayDesign') };

# we test the classes() method
my @classes = Bio::MAGE::ArrayDesign->classes();
is((scalar @classes), 9, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::ArrayDesign::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $arraydesign = Bio::MAGE::ArrayDesign->new();
isa_ok($arraydesign, "Bio::MAGE::ArrayDesign");

# test the tagname method
ok(defined $arraydesign->tagname, 'tagname');


# test the xml_lists method
ok(defined $arraydesign->xml_lists,
  'xml_lists');


# test the reportergroup_list method
$arraydesign->reportergroup_list([]);
isa_ok($arraydesign->reportergroup_list,'ARRAY');
is(scalar @{$arraydesign->reportergroup_list}, 0,
   'reportergroup_list empty');

# test the getReporterGroup_list method
isa_ok($arraydesign->getReporterGroup_list,'ARRAY');
is(scalar @{$arraydesign->getReporterGroup_list}, 0,
   'getReporterGroup_list empty');

# test the addReporterGroup() method
$arraydesign->addReporterGroup($classes{ReporterGroup});
isa_ok($arraydesign->getReporterGroup_list,'ARRAY');
ok(scalar @{$arraydesign->getReporterGroup_list},
   'getReporterGroup_list not empty');


# test the compositegroup_list method
$arraydesign->compositegroup_list([]);
isa_ok($arraydesign->compositegroup_list,'ARRAY');
is(scalar @{$arraydesign->compositegroup_list}, 0,
   'compositegroup_list empty');

# test the getCompositeGroup_list method
isa_ok($arraydesign->getCompositeGroup_list,'ARRAY');
is(scalar @{$arraydesign->getCompositeGroup_list}, 0,
   'getCompositeGroup_list empty');

# test the addCompositeGroup() method
$arraydesign->addCompositeGroup($classes{CompositeGroup});
isa_ok($arraydesign->getCompositeGroup_list,'ARRAY');
ok(scalar @{$arraydesign->getCompositeGroup_list},
   'getCompositeGroup_list not empty');


# test the arraydesign_list method
$arraydesign->arraydesign_list([]);
isa_ok($arraydesign->arraydesign_list,'ARRAY');
is(scalar @{$arraydesign->arraydesign_list}, 0,
   'arraydesign_list empty');

# test the getArrayDesign_list method
isa_ok($arraydesign->getArrayDesign_list,'ARRAY');
is(scalar @{$arraydesign->getArrayDesign_list}, 0,
   'getArrayDesign_list empty');

# test the addArrayDesign() method
$arraydesign->addArrayDesign($classes{ArrayDesign});
isa_ok($arraydesign->getArrayDesign_list,'ARRAY');
ok(scalar @{$arraydesign->getArrayDesign_list},
   'getArrayDesign_list not empty');



##############################
#
# DesignElement_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DesignElement_package.t`

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
use Test::More tests => 48;
use strict;

BEGIN { use_ok('Bio::MAGE::DesignElement') };

# we test the classes() method
my @classes = Bio::MAGE::DesignElement->classes();
is((scalar @classes), 13, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::DesignElement::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $designelement = Bio::MAGE::DesignElement->new();
isa_ok($designelement, "Bio::MAGE::DesignElement");

# test the tagname method
ok(defined $designelement->tagname, 'tagname');


# test the xml_lists method
ok(defined $designelement->xml_lists,
  'xml_lists');


# test the compositesequence_list method
$designelement->compositesequence_list([]);
isa_ok($designelement->compositesequence_list,'ARRAY');
is(scalar @{$designelement->compositesequence_list}, 0,
   'compositesequence_list empty');

# test the getCompositeSequence_list method
isa_ok($designelement->getCompositeSequence_list,'ARRAY');
is(scalar @{$designelement->getCompositeSequence_list}, 0,
   'getCompositeSequence_list empty');

# test the addCompositeSequence() method
$designelement->addCompositeSequence($classes{CompositeSequence});
isa_ok($designelement->getCompositeSequence_list,'ARRAY');
ok(scalar @{$designelement->getCompositeSequence_list},
   'getCompositeSequence_list not empty');


# test the reporter_list method
$designelement->reporter_list([]);
isa_ok($designelement->reporter_list,'ARRAY');
is(scalar @{$designelement->reporter_list}, 0,
   'reporter_list empty');

# test the getReporter_list method
isa_ok($designelement->getReporter_list,'ARRAY');
is(scalar @{$designelement->getReporter_list}, 0,
   'getReporter_list empty');

# test the addReporter() method
$designelement->addReporter($classes{Reporter});
isa_ok($designelement->getReporter_list,'ARRAY');
ok(scalar @{$designelement->getReporter_list},
   'getReporter_list not empty');


# test the compositecompositemap_list method
$designelement->compositecompositemap_list([]);
isa_ok($designelement->compositecompositemap_list,'ARRAY');
is(scalar @{$designelement->compositecompositemap_list}, 0,
   'compositecompositemap_list empty');

# test the getCompositeCompositeMap_list method
isa_ok($designelement->getCompositeCompositeMap_list,'ARRAY');
is(scalar @{$designelement->getCompositeCompositeMap_list}, 0,
   'getCompositeCompositeMap_list empty');

# test the addCompositeCompositeMap() method
$designelement->addCompositeCompositeMap($classes{CompositeCompositeMap});
isa_ok($designelement->getCompositeCompositeMap_list,'ARRAY');
ok(scalar @{$designelement->getCompositeCompositeMap_list},
   'getCompositeCompositeMap_list not empty');


# test the reportercompositemap_list method
$designelement->reportercompositemap_list([]);
isa_ok($designelement->reportercompositemap_list,'ARRAY');
is(scalar @{$designelement->reportercompositemap_list}, 0,
   'reportercompositemap_list empty');

# test the getReporterCompositeMap_list method
isa_ok($designelement->getReporterCompositeMap_list,'ARRAY');
is(scalar @{$designelement->getReporterCompositeMap_list}, 0,
   'getReporterCompositeMap_list empty');

# test the addReporterCompositeMap() method
$designelement->addReporterCompositeMap($classes{ReporterCompositeMap});
isa_ok($designelement->getReporterCompositeMap_list,'ARRAY');
ok(scalar @{$designelement->getReporterCompositeMap_list},
   'getReporterCompositeMap_list not empty');


# test the featurereportermap_list method
$designelement->featurereportermap_list([]);
isa_ok($designelement->featurereportermap_list,'ARRAY');
is(scalar @{$designelement->featurereportermap_list}, 0,
   'featurereportermap_list empty');

# test the getFeatureReporterMap_list method
isa_ok($designelement->getFeatureReporterMap_list,'ARRAY');
is(scalar @{$designelement->getFeatureReporterMap_list}, 0,
   'getFeatureReporterMap_list empty');

# test the addFeatureReporterMap() method
$designelement->addFeatureReporterMap($classes{FeatureReporterMap});
isa_ok($designelement->getFeatureReporterMap_list,'ARRAY');
ok(scalar @{$designelement->getFeatureReporterMap_list},
   'getFeatureReporterMap_list not empty');



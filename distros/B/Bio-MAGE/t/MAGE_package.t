##############################
#
# MAGE_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MAGE_package.t`

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
use Test::More tests => 29;
use strict;

BEGIN { use_ok('Bio::MAGE') };

# we test the classes() method
my @classes = Bio::MAGE->classes();
is((scalar @classes), 4, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $mage = Bio::MAGE->new();
isa_ok($mage, "Bio::MAGE");

# test the tagname method
ok(defined $mage->tagname, 'tagname');


# test the xml_packages() method
is((scalar $mage->xml_packages), 16, 'package count');

# test the packages() method
ok(defined $mage->packages);

# test the identifiers() method
$mage->identifiers(27);
is($mage->identifiers, 27, 'identifiers');

# test the objects() method
$mage->objects(42);
is($mage->objects, 42, 'objects');


# test the getAuditAndSecurity_package singleton method
isa_ok($mage->getAuditAndSecurity_package, 'Bio::MAGE::AuditAndSecurity');


# test the getDescription_package singleton method
isa_ok($mage->getDescription_package, 'Bio::MAGE::Description');


# test the getMeasurement_package singleton method
isa_ok($mage->getMeasurement_package, 'Bio::MAGE::Measurement');


# test the getBQS_package singleton method
isa_ok($mage->getBQS_package, 'Bio::MAGE::BQS');


# test the getBioEvent_package singleton method
isa_ok($mage->getBioEvent_package, 'Bio::MAGE::BioEvent');


# test the getProtocol_package singleton method
isa_ok($mage->getProtocol_package, 'Bio::MAGE::Protocol');


# test the getBioMaterial_package singleton method
isa_ok($mage->getBioMaterial_package, 'Bio::MAGE::BioMaterial');


# test the getBioSequence_package singleton method
isa_ok($mage->getBioSequence_package, 'Bio::MAGE::BioSequence');


# test the getDesignElement_package singleton method
isa_ok($mage->getDesignElement_package, 'Bio::MAGE::DesignElement');


# test the getArrayDesign_package singleton method
isa_ok($mage->getArrayDesign_package, 'Bio::MAGE::ArrayDesign');


# test the getArray_package singleton method
isa_ok($mage->getArray_package, 'Bio::MAGE::Array');


# test the getBioAssay_package singleton method
isa_ok($mage->getBioAssay_package, 'Bio::MAGE::BioAssay');


# test the getQuantitationType_package singleton method
isa_ok($mage->getQuantitationType_package, 'Bio::MAGE::QuantitationType');


# test the getBioAssayData_package singleton method
isa_ok($mage->getBioAssayData_package, 'Bio::MAGE::BioAssayData');


# test the getExperiment_package singleton method
isa_ok($mage->getExperiment_package, 'Bio::MAGE::Experiment');


# test the getHigherLevelAnalysis_package singleton method
isa_ok($mage->getHigherLevelAnalysis_package, 'Bio::MAGE::HigherLevelAnalysis');


# now that we've accessed each package, we check the count
is(keys %{$mage->packages}, 16, 'package list count');



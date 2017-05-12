##############################
#
# BioAssayData_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssayData_package.t`

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
use Test::More tests => 61;
use strict;

BEGIN { use_ok('Bio::MAGE::BioAssayData') };

# we test the classes() method
my @classes = Bio::MAGE::BioAssayData->classes();
is((scalar @classes), 20, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::BioAssayData::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $bioassaydata = Bio::MAGE::BioAssayData->new();
isa_ok($bioassaydata, "Bio::MAGE::BioAssayData");

# test the tagname method
ok(defined $bioassaydata->tagname, 'tagname');


# test the xml_lists method
ok(defined $bioassaydata->xml_lists,
  'xml_lists');


# test the bioassaydimension_list method
$bioassaydata->bioassaydimension_list([]);
isa_ok($bioassaydata->bioassaydimension_list,'ARRAY');
is(scalar @{$bioassaydata->bioassaydimension_list}, 0,
   'bioassaydimension_list empty');

# test the getBioAssayDimension_list method
isa_ok($bioassaydata->getBioAssayDimension_list,'ARRAY');
is(scalar @{$bioassaydata->getBioAssayDimension_list}, 0,
   'getBioAssayDimension_list empty');

# test the addBioAssayDimension() method
$bioassaydata->addBioAssayDimension($classes{BioAssayDimension});
isa_ok($bioassaydata->getBioAssayDimension_list,'ARRAY');
ok(scalar @{$bioassaydata->getBioAssayDimension_list},
   'getBioAssayDimension_list not empty');


# test the designelementdimension_list method
$bioassaydata->designelementdimension_list([]);
isa_ok($bioassaydata->designelementdimension_list,'ARRAY');
is(scalar @{$bioassaydata->designelementdimension_list}, 0,
   'designelementdimension_list empty');

# test the getDesignElementDimension_list method
isa_ok($bioassaydata->getDesignElementDimension_list,'ARRAY');
is(scalar @{$bioassaydata->getDesignElementDimension_list}, 0,
   'getDesignElementDimension_list empty');

# test the addDesignElementDimension() method
$bioassaydata->addDesignElementDimension($classes{DesignElementDimension});
isa_ok($bioassaydata->getDesignElementDimension_list,'ARRAY');
ok(scalar @{$bioassaydata->getDesignElementDimension_list},
   'getDesignElementDimension_list not empty');


# test the quantitationtypedimension_list method
$bioassaydata->quantitationtypedimension_list([]);
isa_ok($bioassaydata->quantitationtypedimension_list,'ARRAY');
is(scalar @{$bioassaydata->quantitationtypedimension_list}, 0,
   'quantitationtypedimension_list empty');

# test the getQuantitationTypeDimension_list method
isa_ok($bioassaydata->getQuantitationTypeDimension_list,'ARRAY');
is(scalar @{$bioassaydata->getQuantitationTypeDimension_list}, 0,
   'getQuantitationTypeDimension_list empty');

# test the addQuantitationTypeDimension() method
$bioassaydata->addQuantitationTypeDimension($classes{QuantitationTypeDimension});
isa_ok($bioassaydata->getQuantitationTypeDimension_list,'ARRAY');
ok(scalar @{$bioassaydata->getQuantitationTypeDimension_list},
   'getQuantitationTypeDimension_list not empty');


# test the bioassaymap_list method
$bioassaydata->bioassaymap_list([]);
isa_ok($bioassaydata->bioassaymap_list,'ARRAY');
is(scalar @{$bioassaydata->bioassaymap_list}, 0,
   'bioassaymap_list empty');

# test the getBioAssayMap_list method
isa_ok($bioassaydata->getBioAssayMap_list,'ARRAY');
is(scalar @{$bioassaydata->getBioAssayMap_list}, 0,
   'getBioAssayMap_list empty');

# test the addBioAssayMap() method
$bioassaydata->addBioAssayMap($classes{BioAssayMap});
isa_ok($bioassaydata->getBioAssayMap_list,'ARRAY');
ok(scalar @{$bioassaydata->getBioAssayMap_list},
   'getBioAssayMap_list not empty');


# test the quantitationtypemap_list method
$bioassaydata->quantitationtypemap_list([]);
isa_ok($bioassaydata->quantitationtypemap_list,'ARRAY');
is(scalar @{$bioassaydata->quantitationtypemap_list}, 0,
   'quantitationtypemap_list empty');

# test the getQuantitationTypeMap_list method
isa_ok($bioassaydata->getQuantitationTypeMap_list,'ARRAY');
is(scalar @{$bioassaydata->getQuantitationTypeMap_list}, 0,
   'getQuantitationTypeMap_list empty');

# test the addQuantitationTypeMap() method
$bioassaydata->addQuantitationTypeMap($classes{QuantitationTypeMap});
isa_ok($bioassaydata->getQuantitationTypeMap_list,'ARRAY');
ok(scalar @{$bioassaydata->getQuantitationTypeMap_list},
   'getQuantitationTypeMap_list not empty');


# test the bioassaydata_list method
$bioassaydata->bioassaydata_list([]);
isa_ok($bioassaydata->bioassaydata_list,'ARRAY');
is(scalar @{$bioassaydata->bioassaydata_list}, 0,
   'bioassaydata_list empty');

# test the getBioAssayData_list method
isa_ok($bioassaydata->getBioAssayData_list,'ARRAY');
is(scalar @{$bioassaydata->getBioAssayData_list}, 0,
   'getBioAssayData_list empty');

# test the addBioAssayData() method
$bioassaydata->addBioAssayData($classes{BioAssayData});
isa_ok($bioassaydata->getBioAssayData_list,'ARRAY');
ok(scalar @{$bioassaydata->getBioAssayData_list},
   'getBioAssayData_list not empty');



##############################
#
# BioAssay_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssay_package.t`

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
use Test::More tests => 28;
use strict;

BEGIN { use_ok('Bio::MAGE::BioAssay') };

# we test the classes() method
my @classes = Bio::MAGE::BioAssay->classes();
is((scalar @classes), 11, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::BioAssay::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $bioassay = Bio::MAGE::BioAssay->new();
isa_ok($bioassay, "Bio::MAGE::BioAssay");

# test the tagname method
ok(defined $bioassay->tagname, 'tagname');


# test the xml_lists method
ok(defined $bioassay->xml_lists,
  'xml_lists');


# test the channel_list method
$bioassay->channel_list([]);
isa_ok($bioassay->channel_list,'ARRAY');
is(scalar @{$bioassay->channel_list}, 0,
   'channel_list empty');

# test the getChannel_list method
isa_ok($bioassay->getChannel_list,'ARRAY');
is(scalar @{$bioassay->getChannel_list}, 0,
   'getChannel_list empty');

# test the addChannel() method
$bioassay->addChannel($classes{Channel});
isa_ok($bioassay->getChannel_list,'ARRAY');
ok(scalar @{$bioassay->getChannel_list},
   'getChannel_list not empty');


# test the bioassay_list method
$bioassay->bioassay_list([]);
isa_ok($bioassay->bioassay_list,'ARRAY');
is(scalar @{$bioassay->bioassay_list}, 0,
   'bioassay_list empty');

# test the getBioAssay_list method
isa_ok($bioassay->getBioAssay_list,'ARRAY');
is(scalar @{$bioassay->getBioAssay_list}, 0,
   'getBioAssay_list empty');

# test the addBioAssay() method
$bioassay->addBioAssay($classes{BioAssay});
isa_ok($bioassay->getBioAssay_list,'ARRAY');
ok(scalar @{$bioassay->getBioAssay_list},
   'getBioAssay_list not empty');



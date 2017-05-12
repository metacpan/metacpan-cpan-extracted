##############################
#
# Protocol_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Protocol_package.t`

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

BEGIN { use_ok('Bio::MAGE::Protocol') };

# we test the classes() method
my @classes = Bio::MAGE::Protocol->classes();
is((scalar @classes), 10, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::Protocol::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $protocol = Bio::MAGE::Protocol->new();
isa_ok($protocol, "Bio::MAGE::Protocol");

# test the tagname method
ok(defined $protocol->tagname, 'tagname');


# test the xml_lists method
ok(defined $protocol->xml_lists,
  'xml_lists');


# test the hardware_list method
$protocol->hardware_list([]);
isa_ok($protocol->hardware_list,'ARRAY');
is(scalar @{$protocol->hardware_list}, 0,
   'hardware_list empty');

# test the getHardware_list method
isa_ok($protocol->getHardware_list,'ARRAY');
is(scalar @{$protocol->getHardware_list}, 0,
   'getHardware_list empty');

# test the addHardware() method
$protocol->addHardware($classes{Hardware});
isa_ok($protocol->getHardware_list,'ARRAY');
ok(scalar @{$protocol->getHardware_list},
   'getHardware_list not empty');


# test the software_list method
$protocol->software_list([]);
isa_ok($protocol->software_list,'ARRAY');
is(scalar @{$protocol->software_list}, 0,
   'software_list empty');

# test the getSoftware_list method
isa_ok($protocol->getSoftware_list,'ARRAY');
is(scalar @{$protocol->getSoftware_list}, 0,
   'getSoftware_list empty');

# test the addSoftware() method
$protocol->addSoftware($classes{Software});
isa_ok($protocol->getSoftware_list,'ARRAY');
ok(scalar @{$protocol->getSoftware_list},
   'getSoftware_list not empty');


# test the protocol_list method
$protocol->protocol_list([]);
isa_ok($protocol->protocol_list,'ARRAY');
is(scalar @{$protocol->protocol_list}, 0,
   'protocol_list empty');

# test the getProtocol_list method
isa_ok($protocol->getProtocol_list,'ARRAY');
is(scalar @{$protocol->getProtocol_list}, 0,
   'getProtocol_list empty');

# test the addProtocol() method
$protocol->addProtocol($classes{Protocol});
isa_ok($protocol->getProtocol_list,'ARRAY');
ok(scalar @{$protocol->getProtocol_list},
   'getProtocol_list not empty');



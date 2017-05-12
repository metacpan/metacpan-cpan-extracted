##############################
#
# AuditAndSecurity_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AuditAndSecurity_package.t`

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

BEGIN { use_ok('Bio::MAGE::AuditAndSecurity') };

# we test the classes() method
my @classes = Bio::MAGE::AuditAndSecurity->classes();
is((scalar @classes), 6, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::AuditAndSecurity::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $auditandsecurity = Bio::MAGE::AuditAndSecurity->new();
isa_ok($auditandsecurity, "Bio::MAGE::AuditAndSecurity");

# test the tagname method
ok(defined $auditandsecurity->tagname, 'tagname');


# test the xml_lists method
ok(defined $auditandsecurity->xml_lists,
  'xml_lists');


# test the contact_list method
$auditandsecurity->contact_list([]);
isa_ok($auditandsecurity->contact_list,'ARRAY');
is(scalar @{$auditandsecurity->contact_list}, 0,
   'contact_list empty');

# test the getContact_list method
isa_ok($auditandsecurity->getContact_list,'ARRAY');
is(scalar @{$auditandsecurity->getContact_list}, 0,
   'getContact_list empty');

# test the addContact() method
$auditandsecurity->addContact($classes{Contact});
isa_ok($auditandsecurity->getContact_list,'ARRAY');
ok(scalar @{$auditandsecurity->getContact_list},
   'getContact_list not empty');


# test the securitygroup_list method
$auditandsecurity->securitygroup_list([]);
isa_ok($auditandsecurity->securitygroup_list,'ARRAY');
is(scalar @{$auditandsecurity->securitygroup_list}, 0,
   'securitygroup_list empty');

# test the getSecurityGroup_list method
isa_ok($auditandsecurity->getSecurityGroup_list,'ARRAY');
is(scalar @{$auditandsecurity->getSecurityGroup_list}, 0,
   'getSecurityGroup_list empty');

# test the addSecurityGroup() method
$auditandsecurity->addSecurityGroup($classes{SecurityGroup});
isa_ok($auditandsecurity->getSecurityGroup_list,'ARRAY');
ok(scalar @{$auditandsecurity->getSecurityGroup_list},
   'getSecurityGroup_list not empty');


# test the security_list method
$auditandsecurity->security_list([]);
isa_ok($auditandsecurity->security_list,'ARRAY');
is(scalar @{$auditandsecurity->security_list}, 0,
   'security_list empty');

# test the getSecurity_list method
isa_ok($auditandsecurity->getSecurity_list,'ARRAY');
is(scalar @{$auditandsecurity->getSecurity_list}, 0,
   'getSecurity_list empty');

# test the addSecurity() method
$auditandsecurity->addSecurity($classes{Security});
isa_ok($auditandsecurity->getSecurity_list,'ARRAY');
ok(scalar @{$auditandsecurity->getSecurity_list},
   'getSecurity_list not empty');



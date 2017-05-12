##############################
#
# Experiment_package.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Experiment_package.t`

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
use Test::More tests => 15;
use strict;

BEGIN { use_ok('Bio::MAGE::Experiment') };

# we test the classes() method
my @classes = Bio::MAGE::Experiment->classes();
is((scalar @classes), 4, 'number of subclasses');

my %classes;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  foreach my $class_name (@classes) {
    my $class = "Bio::MAGE::Experiment::$class_name";
    $classes{$class_name} = $class->new();
    isa_ok($classes{$class_name}, $class);
  }
}
# test isa
my $experiment = Bio::MAGE::Experiment->new();
isa_ok($experiment, "Bio::MAGE::Experiment");

# test the tagname method
ok(defined $experiment->tagname, 'tagname');


# test the xml_lists method
ok(defined $experiment->xml_lists,
  'xml_lists');


# test the experiment_list method
$experiment->experiment_list([]);
isa_ok($experiment->experiment_list,'ARRAY');
is(scalar @{$experiment->experiment_list}, 0,
   'experiment_list empty');

# test the getExperiment_list method
isa_ok($experiment->getExperiment_list,'ARRAY');
is(scalar @{$experiment->getExperiment_list}, 0,
   'getExperiment_list empty');

# test the addExperiment() method
$experiment->addExperiment($classes{Experiment});
isa_ok($experiment->getExperiment_list,'ARRAY');
ok(scalar @{$experiment->getExperiment_list},
   'getExperiment_list not empty');



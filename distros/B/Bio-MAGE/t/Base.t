##############################
#
# Base.pm test
#

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl base.t'

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
use lib 't';

use strict;

BEGIN { use_ok('Bio::MAGE::Base') };

my $class = <<'CLASS';
package Foo::Bar;
use strict;
use base qw(Bio::MAGE::Base);

use vars qw($__SLOT_NAMES $__ATTRIBUTE_NAMES $__ASSOCIATION_NAMES $__SUPERCLASSES $__SUBCLASSES $__CLASS_NAME $__PACKAGE_NAME);

$__SLOT_NAMES = [qw(foo bar)];
$__ATTRIBUTE_NAMES = [qw(attr1)];
$__ASSOCIATION_NAMES = [qw(assoc1)];
$__SUBCLASSES = [qw(Foo::Bar::Sub)];
$__SUPERCLASSES = [qw(Foo)];
$__CLASS_NAME = 'Foo::Bar';
$__PACKAGE_NAME = 'Foo';

sub foo {
  my $self = shift;
  $self->{__FOO} = $_[0]
    if scalar @_;
  return $self->{__FOO};
}

sub getBar {
  my $self = shift;
  return $self->{__BAR};
}

sub setBar {
  my $self = shift;
  return $self->{__BAR} = $_[0];
}

sub attr1 {
  my $self = shift;
  $self->{__ATTR1} = $_[0]
    if scalar @_;
  return $self->{__ATTR1};
}

sub assoc1 {
  my $self = shift;
  $self->{__ASSOC1} = $_[0]
    if scalar @_;
  return $self->{__ASSOC1};
}

1;
CLASS


my $mod_name = 'Bar';
my $pkg_name = 'Foo';
my $full_class_name = $pkg_name . '::' . $mod_name;

my $pkg_dir = "t/$pkg_name";
my $mod = "$mod_name.pm";
my $mod_file = "$pkg_dir/$mod";
mkdir($pkg_dir)
  or die "Couldn't create $pkg_dir";
open(TEMP, ">$mod_file")
  or die "Couldn't open $mod_file for writing";
print TEMP $class;
close(TEMP)
  or die "Couldn't close $mod_file";

END {unlink($mod_file) && rmdir($pkg_dir)}

SKIP: {
  my $skip = 0;
  use_ok($full_class_name, 'use base qw(Base)')
    or $skip = "Couldn't use $full_class_name";

  my @tests = qw(new_foo
		 get_slot set_slot get_slots set_slots
		 get_slot_names get_attr_names get_assoc_names
		 get_sub get_super class_name
		 foo_slot foo_type foo_val bar_slot bar_type bar_val
		 copy_foo_slot copy_foo_type copy_foo_val copy_bar_slot copy_bar_type copy_bar_val
		 get_set_slot_new get_type get_count get_val
		 attr_assoc_new new_attr new_assoc
		);
  my $skip_count = scalar @tests;

  skip $skip, $skip_count if $skip;

  my $foo = $full_class_name->new();
  isa_ok($foo, $full_class_name);

  is(scalar $foo->get_slot_names(), 2,
     "$full_class_name has 2 slots");

  is(scalar $foo->get_attribute_names(), 1,
     "$full_class_name has one attribute");

  is(scalar $foo->get_association_names(), 1,
     "$full_class_name has one association");

  is(scalar $foo->get_subclasses(), 1,
     "$full_class_name has one subclass");

  is(scalar $foo->get_superclasses(), 1,
     "$full_class_name has one superclass");

  is($foo->class_name(), $full_class_name,
     "$full_class_name class_name");

  $foo = $full_class_name->new(foo=>{twelve=>12}, bar=>[1,2,3]);
  isa_ok($foo, $full_class_name,
         'can set slots in new()');
  isa_ok($foo->foo(), 'HASH',
         'can retrieve foo value');
  is($foo->foo->{twelve}, 12,
         'foo has correct value');
  isa_ok($foo->getBar(), 'ARRAY',
         'can retrieve bar value');
  is(scalar @{$foo->getBar}, 3,
         'bar has correct count');
  is($foo->getBar->[1], 2,
         'bar has correct value');

  # test copy constructor
  my $foo2 = $foo->new();
  isa_ok($foo, $full_class_name,
         'copy constructor works');
  isa_ok($foo->foo(), 'HASH',
         'copy constructor can retrieve foo value');
  is($foo->foo->{twelve}, 12,
         'copy constructor foo has correct value');
  isa_ok($foo->getBar(), 'ARRAY',
         'copy constructor can retrieve bar value');
  is(scalar @{$foo->getBar}, 3,
         'copy constructor bar has correct count');
  is($foo->getBar->[1], 2,
         'copy constructor bar has correct value');

  $foo = $full_class_name->new(bar=>[1,2,3]);
  isa_ok($foo, $full_class_name,
         'can set get/set slots in new()');
  isa_ok($foo->getBar(), 'ARRAY',
         'can retrieve bar value');
  is(scalar @{$foo->getBar}, 3,
         'bar has correct count');
  is($foo->getBar->[1], 2,
         'bar has correct value');

  $foo = $full_class_name->new(attr1=>1, assoc1=>$foo2);
  isa_ok($foo, $full_class_name,
         'can set association/attribute slots in new()');
  is($foo->attr1(), 1,
        'attr1 has correct value');
  is($foo->assoc1(), $foo2,
        'assoc1 has correct value');

  is($foo->get_slot('assoc1'), $foo2,
        'get_slot works');

  my @res = $foo->get_slots('assoc1', 'attr1');
  ok(((scalar @res == 2)
     && ($res[0] == $foo2)
     && ($res[1] == 1)),
     'get_slots works');

  $foo->set_slot('assoc1', 'none');
  is($foo->get_slot('assoc1'), 'none',
        'set_slot works');

  $foo->set_slots(['assoc1', 'attr1'], ['val1','val2']);
  ok((($foo->get_slot('assoc1') == 'val1')
       && ($foo->get_slot('assoc1') == 'val1')),
        'set_slots works');
}

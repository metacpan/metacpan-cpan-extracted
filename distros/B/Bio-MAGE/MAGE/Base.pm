##############################
#
# Bio::MAGE::Base
#
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



package Bio::MAGE::Base;

use strict;
use Carp;

=head1 NAME

Bio::MAGE::Base - generic base class

=head1 SYNOPSIS

  use Bio::MAGE::Base;

  # create an empty instance
  my $obj = Bio::MAGE::Base->new();

  # create an instance and populate with data
  my $obj = Bio::MAGE::Base->new(attr1=>$val1, attr2=>$val2);

  # copy an existing instance
  my $obj_copy = $obj->new();

=head1 DESCRIPTION

The base class for all other Bio::MAGE classes

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Namespace::Class->methodname()
syntax, i.e. the class name B<must> be given as an argument to the
method.

=over

=item $obj = class->new(%params)

The C<new()> method is the class constructor.

B<Parameters>: if given a list of name/value parameters the
corresponding slots, attributes, or associations will have their
initial values set by the constructor.

B<Return value>: It returns a reference to an object of the class.

B<Side effects>: It invokes the C<initialize()> method if it is defined
by the class.

=cut

sub new {
  my $class = shift;
  my $obj;
  if (ref($class)) {
    # copy an existing object
    $obj = $class;
    $class = ref($class);
  }
  my $self = bless {}, $class;
  if (defined $obj) {
    $self->set_slots([$obj->get_slot_names],
                     [$obj->get_slots($obj->get_slot_names)],
                    );
  } else {
    $self->set_slots(@_) if @_;
  }
  my $rc = $self->initialize;
  return undef if $rc == -1;
  return $self;
}

sub __get_superclass {
  my $class = shift;

  {
    no strict 'refs';
    my $var = $class . '::ISA';
    my @isa = @$var;
    if (scalar @isa) {
      return $isa[0];
    } else {
      return undef;
    }
  }
}

sub __get_slot_array {
  my $class = shift;
  my $slot_name = shift;

  # allow the $obj->method() syntax
  $class = ref($class) if ref($class);
  {
    no strict 'refs';
    my $var = $class . '::' . $slot_name;
    my $val = $$var;
    while (not defined $val) {
      $class = $class->__get_superclass($class);
      last unless defined $class;
      $var = $class . '::' . $slot_name;
      $val = $$var;
    }

    if (defined $val) {
      return @{$val};
    } else {
      return ();
    }
  }
}

sub __get_slot_val {
  my $class = shift;
  my $slot_name = shift;

  # allow the $obj->method() syntax
  $class = ref($class) if ref($class);
  {
    no strict 'refs';
    my $var = $class . '::' . $slot_name;
    my $val = $$var;
    while (not defined $val) {
      $class = $class->__get_superclass($class);
      last unless defined $class;
      $var = $class . '::' . $slot_name;
      $val = $$var;
    }

    return $val;
  }
}

=back

The following methods can all be called with either the
Namespace::Class->methodname() and $obj->methodname() syntaxes.

=over

=item @names = get_slot_names()

The C<get_slot_names()> method is used to retrieve the name of all
slots defined for a given object.

B<NOTE>: the list of names does not include attribute or association
names.

B<Return value>: A list of the names of all slots defined for this class.

B<Side effects>: none

=cut

sub get_slot_names {
  my $class = shift;
  return $class->__get_slot_array('__SLOT_NAMES');
}


=item @name_list = get_attribute_names()

returns the list of attribute data members for this class.

=cut

sub get_attribute_names {
  my $class = shift;
  return $class->__get_slot_array('__ATTRIBUTE_NAMES');
}

=item @name_list = get_association_names()

returns the list of association data members for this class.

=cut

sub get_association_names {
  my $class = shift;
  return $class->__get_slot_array('__ASSOCIATION_NAMES');
}

=item @class_list = get_superclasses()

returns the list of superclasses for this class.

=cut

sub get_superclasses {
  my $class = shift;
  return $class->__get_slot_array('__SUPERCLASSES');
}

=item @class_list = get_subclasses()

returns the list of subclasses for this class.

=cut

sub get_subclasses {
  my $class = shift;
  return $class->__get_slot_array('__SUBCLASSES');
}

=item $name = class_name()

Returns the full class name for this class.

=cut

sub class_name {
  my $class = shift;
  return $class->__get_slot_val('__CLASS_NAME');
}

=item $package_name = package_name()

Returns the base package name (i.e. no 'namespace::') of the package
that contains this class.

=cut

sub package_name {
  my $class = shift;
  return $class->__get_slot_val('__PACKAGE_NAME');
}

=item %assns = associations()

returns the association meta-information in a hash where the keys are
the association names and the values are C<Association> objects that
provide the meta-information for the association.

=cut

sub associations {
  my $class = shift;

  # allow the $obj->method() syntax
  $class = ref($class) if ref($class);
  my @list = ();

  # superclasses first
  my @superclasses = $class->get_superclasses();
  foreach my $super (@superclasses) {
    push(@list, $super->associations());
  }

  # then associations from this class
  push(@list, $class->__get_slot_array('__ASSOCIATIONS'));

  return @list;
}

=back

=head1 INSTANCE METHODS

These methods must be invoked with the direct object syntax using an
existing instance, i.e. $object->method_name().

=over

=item $obj_copy = $obj->new()

When invoked with an existing object reference and not a class name,
the C<new()> method acts as a copy constructor - with the new object's
initial values set to be those of the existing object.

B<Parameters>: No input parameters  are used in the copy  constructor,
the initial values are taken directly from the object to be copied.

B<Return value>: It returns a reference to an object of the class.

B<Side effects>: It invokes the C<initialize()> method if it is defined
by the class.

=cut

#
# see above in new()
#

=item $obj->set_slots(%parameters)

=item $obj->set_slots(\@name_list, \@value_list)

The C<set_slots()> method is used to set a number of slots at the same
time. It has two different invocation methods. The first takes a named
parameter list, and the second takes two array references.

B<Return value>: none

B<Side effects>: will call C<croak()> if a slot_name is used that the class
does not define.

=cut

sub set_slots {
  my $self = shift;
  my %slots;
  if (ref($_[0])) {
    my @slot_names = @{shift()};
    my @slot_values = @{shift()};
    @slots{@slot_names} = @slot_values;
  } else {
    %slots = @_;
  }
  while (my ($slot_name,$slot_val) = each %slots) {
    $self->set_slot($slot_name,$slot_val);
  }
}


=item $obj->get_slots(@name_list)

The C<get_slots()> method is used to get the values of a number of
slots at the same time.

B<Return value>: a list of instance objects

B<Side effects>: none

=cut

sub get_slots {
  my ($self, @slot_names) = @_;
  my @return;
  foreach my $slot (@slot_names) {
    push(@return,$self->get_slot($slot));
  }
  return @return;
}


=item $val = $obj->set_slot($name,$val)

The C<set_slot()> method sets the slot C<$name> to the value C<$val>

B<Return value>: the new value of the slot, i.e. C<$val>

B<Side effects>: none

=cut

sub set_slot {
  my ($self, $slot_name, $slot_val) = @_;
  my $method = 'set' . ucfirst($slot_name);
  unless ($self->can($method)) {
    unless ($self->can($slot_name)) {
      croak(__PACKAGE__ . "::set_slot: slot $slot_name doesn't exist");
    }
    # this is a class slot, not an attribute or association. They still
    # use the confusing polymorphic setter/getter methods.
    $method = $slot_name;
  }
  {
    no strict 'refs';
    # invoke the setter directly to gain type checking
    return $self->$method($slot_val);
  }
}


=item $val = $obj->get_slot($name)

The C<get_slot()> method is used to get the values of a number of
slots at the same time.

B<Return value>: a single slot value, or undef if the slot has not been
initialized.

B<Side effects>: none

=cut

sub get_slot {
  my ($self, $slot_name) = @_;
  my $method = 'get' . ucfirst($slot_name);
  unless ($self->can($method)) {
    unless ($self->can($slot_name)) {
      croak(__PACKAGE__ . "::get_slot: slot $slot_name doesn't exist");
    }
    # this is a class slot, not an attribute or association. They still
    # use the confusing polymorphic setter/getter methods.
    $method = $slot_name;
  }
  {
    no strict 'refs';
    # invoke the getter directly
    return $self->$method();
  }
}


sub initialize {
  return 1;
}

=item throw

 Title   : throw
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub throw {
   my ($self, $msg) = @_;

   die(caller().': '.$msg);
}

=item throw_not_implemented

 Title   : throw_not_implemented
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub throw_not_implemented {
   my ($self) = @_;

   die("Abstract method ".caller()." implementing class did not provide method");
}

=back

=head1 BUGS

Please send bug reports to the project mailing list: ()

=head1 AUTHOR



=head1 SEE ALSO

perl(1).

=cut

# all perl modules must be true...
1;


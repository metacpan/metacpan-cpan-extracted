package Class::ObjectTemplate;
require Exporter;

use vars qw(@ISA @EXPORT $VERSION $DEBUG);
use Carp;
use strict;
no strict 'refs';

@ISA = qw(Exporter);
@EXPORT = qw(attributes);
$VERSION = 0.7;

$DEBUG = 0; # assign 1 to it to see code generated on the fly

# Create accessor functions
sub attributes {
  my ($pkg) = caller;

  croak "Error: attributes() invoked multiple times"
    if scalar @{"${pkg}::_ATTRIBUTES_"};

  #
  # We must define a constructor for the class, because we must
  # declare the variables used for the free list, $_max_id and
  # @_free. If we don't, we will get compile errors for any class
  # that declares itself a subclass of any Class::ObjectTemplate
  # class
  #
  my $code .= _define_constructor($pkg);

  # _defined_constructor() may have added attributes that we inherited
  # from any superclasses now add the new attributes
  push(@{"${pkg}::_ATTRIBUTES_"},@_);

  # now define any accessor methods
  print STDERR "Creating methods for $pkg\n" if $DEBUG;
  foreach my $attr (@_) {
    print STDERR "  defining method $attr\n" if $DEBUG;
    # If a field name is "color", create a global list in the
    # calling package called @_color
    @{"${pkg}::_$attr"} = ();

    # If the accessor is already present, give a warning
    if (UNIVERSAL::can($pkg,"$attr")) {
      carp "$pkg already has method: $attr";
    } else {
      $code .= _define_accessor ($pkg, $attr);
    }
  }
  eval $code;
  if ($@) {
    die  "ERROR defining constructor and attributes for '$pkg':\n"
       . "\t$@\n"
       . "-----------------------------------------------------"
       . $code;
  }
}

# $obj->set_attributes (name => 'John', age => 23);
# Or, $obj->set_attributes (['name', 'age'], ['John', 23]);
sub set_attributes {
  my $obj = shift;
  my $attr_name;
  if (ref($_[0])) {
    my ($attr_name_list, $attr_value_list) = @_;
    my $i = 0;
    foreach $attr_name (@$attr_name_list) {
      $obj->$attr_name($attr_value_list->[$i++]);
    }
  } else {
    my ($attr_name, $attr_value);
    while (@_) {
      $attr_name = shift;
      $attr_value = shift;
      $obj->$attr_name($attr_value);
    }
  }
}


# @attrs = $obj->get_attributes (qw(name age));
sub get_attributes {
  my $obj = shift;
  my $pkg = ref($obj);
  my (@retval);
  return map {$ {"${pkg}::_$_"}[$$obj]} @_;
}

sub get_attribute_names {
  my $pkg = shift;
  $pkg = ref($pkg) if ref($pkg);
  return @{"${pkg}::_ATTRIBUTES_"};
}

sub set_attribute {
  my ($obj, $attr_name, $attr_value) = @_;
  my ($pkg) = ref($obj);
  return $ {"${pkg}::_$attr_name"}[$$obj] = $attr_value;
}

sub get_attribute {
  my ($obj, $attr_name, $attr_value) = @_;
  my ($pkg) = ref($obj);
  return $ {"${pkg}::_$attr_name"}[$$obj];
}

sub DESTROY {
  # release id back to free list
  my $obj = shift;
  my $pkg = ref($obj);
  my $inst_id = $$obj;

  # Release all the attributes in that row
  my (@attributes) = get_attribute_names($pkg);
  foreach my $attr (@attributes) {
    undef $ {"${pkg}::_$attr"}[$inst_id];
  }

  # The free list is *always* maintained independently by each base
  # class
  push(@{"${pkg}::_free"},$inst_id);
}

sub initialize { }; # dummy method, if subclass doesn't define one.

#################################################################

sub _define_constructor {
  my $pkg = shift;
  my $free = "\@${pkg}::_free";

  # inherit any attributes from our superclasses
  if (defined (@{"${pkg}::ISA"})) {
    foreach my $base_pkg (@{"${pkg}::ISA"}) {
      push (@{"${pkg}::_ATTRIBUTES_"}, get_attribute_names($base_pkg));
    }
  }

  my $code = <<"CODE";
    package $pkg;
    use vars qw(\$_max_id \@_free);
    sub new {
      my \$class = shift;
      my \$inst_id;
      if (scalar $free) {
	\$inst_id = shift($free);
      } else {
	\$inst_id = \$_max_id++;
      }
      my \$obj = bless \\\$inst_id, \$class;
      \$obj->set_attributes(\@_) if \@_;
      my \$rc = \$obj->initialize;
      return undef if \$rc == -1;
      \$obj;
    }

    # Set up the free list, and the ID counter
    \@_free = ();
    \$_max_id = 0;

CODE
  return $code;
}

sub _define_accessor {
  my ($pkg, $attr) = @_;

  # This code creates an accessor method for a given
  # attribute name. This method  returns the attribute value
  # if given no args, and modifies it if given one arg.
  # Either way, it returns the latest value of that attribute

  my $code = <<"CODE";
    package $pkg;
    sub $attr {                                      # Accessor ...
      my \$name = ref(\$_[0]) . "::_$attr";
         \@_ > 1 ? \$name->[\${\$_[0]}] = \$_[1]  # set
                 : \$name->[\${\$_[0]}];          # get
    }
CODE
  return $code;
}

1;
__END__
### =head1 IMPLEMENTATION DETAILS
###
### This section is intended for the maintainers of Class::ObjectTemplate
### and not the users, and this is why it is not include in the POD.
###
### This section was added to describe pieces that were added after
### Sriram\'s original code.
###
### =head2 INHERITANCE
###
### There were some problems with inheritance in the original version
### described by Sriram, with how attribute values were stored, and with
### how the free list was maintained.
###
### Each subclass must define its own constructor, C<new()>. This is why
### B<every> class that subclasses from another must call C<attributes()>
### even if it doesn\'t define any new attributes. If this does not
### happen, then the class will not properly define its attribute list or
### its free list.
###
### Each subclass maintains its own attribute list, stored in the variable
### C<@_ATTRIBUTES_>, and all attributes defined by any superclasses will
### be copied into the subclass attribute lists by the
### _define_constructor() method.
###
### =head2 FREE LIST
###
### Every class maintains two important variables that are used by the
### class constructor method, C<new()> to assign object id\'s to newly
### created objects, $_max_id and @_free. Each subclass maintains its own
### copy of each of these.
###
### =over
###
### =item @_free
###
### Is the free list which tracks scalar values that were previously but
### are now free to be re-assigned to new objects. 
###
###
### =item $_max_id
###
### Tracks the largest object id used. If the free list is empty, then
### C<new()> assigns a brand new object id by incrementing $_max_id.
###
### =back

=head1 NAME

Class::ObjectTemplate - Perl extension for an optimized template
builder base class.

=head1 SYNOPSIS

  package Foo;
  use Class::ObjectTemplate;
  require Exporter;
  @ISA = qw(Class::ObjectTemplate Exporter);

  attributes('one', 'two', 'three');

  # initialize will be called by new()
  sub initialize {
    my $self = shift;
    $self->three(1) unless defined $self->three();
  }

  use Foo;
  $foo = Foo->new();

  # store 27 in the 'one' attribute
  $foo->one(27);

  # check the value in the 'two' attribute
  die "should be undefined" if defined $foo->two();

  # set using the utility method
  $foo->set_attribute('one',27);

  # check using the utility method
  $two = $foo->get_attribute('two');

  # set more than one attribute using the named parameter style
  $foo->set_attributes('one'=>27, 'two'=>42);

  # or using array references
  $foo->set_attributes(['one','two'],[27,42]);

  # get more than one attribute
  @list = $foo->get_attributes('one', 'two');

  # get a list of all attributes known by an object
  @attrs = $foo->get_attribute_names();

  # check that initialize() is called properly
  die "initialize didn't set three()" unless $foo->three();

=head1 DESCRIPTION

Class::ObjectTemplate is a utility class to assist in the building of
other Object Oriented Perl classes.

It was described in detail in the O\'Reilly book, "Advanced Perl
Programming" by Sriram Srinivasam. 

=head2 EXPORT

attributes(@name_list)

This method creates a shared setter and getter methods for every name
in the list. The method also creates the class constructor, C<new()>.

B<WARNING>: This method I<must> be invoked within the module for every
class that inherits from Class::ObjectTemplate, even if that class
defines no attributes. For a class defining no new attributes, it
should invoke C<attributes()> with no arguments.

=head1 AUTHOR

Original code by Sriram Srinivasam.

Fixes and CPAN module by Jason E. Stewart (jason@openinformatics.com)

=head1 SEE ALSO

http://www.oreilly.com/catalog/advperl/

perl(1).

Class::ObjectTemplate::DB

=cut

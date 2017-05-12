package Array::To::Moose;

# Copyright (c) Stanford University. June 6th, 2010.
# All rights reserved.
# Author: Sam Brain <samb@stanford.edu>
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.8 or,
# at your option, any later version of Perl 5 you may have available.
#

use 5.008008;
use strict;
use warnings;

require Exporter;
use base qw( Exporter );

our %EXPORT_TAGS = (
    'ALL'     => [ qw( array_to_moose
                       throw_nonunique_keys throw_multiple_rows
                       set_class_ind set_key_ind                 ) ],
    'TESTING' => [ qw( _check_descriptor _check_subobj
                       _check_ref_attribs _check_non_ref_attribs ) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'ALL'} }, @{ $EXPORT_TAGS{'TESTING'} } );

our @EXPORT = qw( array_to_moose 

);

use version; our $VERSION = qv('0.0.9');

# BEGIN { $Exporter::Verbose=1 };

#BEGIN { print "Got Array::To:Moose Module\n" }

use Params::Validate::Array qw(:all);
use Array::GroupBy qw(igroup_by str_row_equal);
use Carp;
use Data::Dumper;

$Carp::Verbose = 1;

$Data::Dumper::Terse  = 1;
$Data::Dumper::Indent = 1;

# strings for "key => ..." and "class => ..." indicators
my ($KEY, $CLASS);

BEGIN { $KEY = 'key' ; $CLASS = 'class' }

# throw error if a HashRef[] key found to be non-unique
my $throw_nonunique_keys;

# throw error if there are multiple candidate rows for an attribute
# which is a single object, "isa => 'MyObject'"
my $throw_multiple_rows;

############################################
# Set the indicators for "key => ..." and "class => ..."
# If there is no arg, reset them back to the default 'key' and 'class'
############################################
sub set_key_ind {
  croak "set_key_ind('$_[0]') not a legal identifier"
    if defined $_[0] and $_[0] !~ /^\w+$/;

  $KEY = defined $_[0] ? $_[0] : 'key';
}

############################################
sub set_class_ind {
  croak "set_class_ind('$_[0]') not a legal identifier"
    if defined $_[0] and $_[0] !~ /^\w+$/;

  $CLASS = defined $_[0] ? $_[0] : 'class';
}

########################################
# throw error if non-unique keys in a HashRef['] is causing already-constructed
# Moose objects to be overwritten
# throw_nonunique_keys() to set, throw_nonunique_keys(0) to unset
########################################
sub throw_nonunique_keys { $throw_nonunique_keys = defined $_[0] ? $_[0] : 1 }

########################################
# throw error if a single object attribute has multiple data rows
# throw_multiple_rows() to set throw_multiple_rows(0) to unset
########################################
sub throw_multiple_rows { $throw_multiple_rows = defined $_[0] ? $_[0] : 1 }

##########
# Usage
#   my $moose_object_ref = array_to_moose( data => $array_ref,
#                                          desc => { ... },
#                                        );
############################################
sub array_to_moose {
  my ($data, $desc) = validate(@_,
                          [ data => { type => ARRAYREF },
                            desc => { type => HASHREF  },
                          ]
  );

  croak "'data => ...' isn't a 2D array (AoA)"
    unless ref($data->[0]);

  croak 'empty descriptor'
    unless keys %$desc;

  #print "data ", Dumper($data), "\ndesc ", Dumper($desc);


  my $result = [];   # returned result is either an array or a hash of objects

  # extract column of possible hash key
  my $keycol;

  if (exists $desc->{$KEY}) {
    $keycol = $desc->{$KEY};

    $result = {};         # returning a hashref

  }

  # _check_descriptor returns:
  # $class,       the class of the object
  # $attribs,     a hashref (attrib => column_number) of "simple" attributes
  #               (column numbers only)
  # $ref_attribs, a hashref of attribute/column number values for
  #               non-simple attributes, currently limited to "ArrayRef[`a]",
  #               where `a is e.g 'Str', etc (i.e. `a is not a class)
  # $sub_desc,    a hashref of sub-objects.
  #               the keys are the attrib. names, the values the
  #               descriptors of the next level down

  my ($class, $attribs, $ref_attribs, $sub_obj_desc) =
            _check_descriptor($data, $desc);

  #print "data ", Dumper($data), "\nattrib = ", Dumper($attribs),
  #      "\nargs = ", Dumper([ values %$attribs ]);

  #print "\$ref_attribs ", Dumper($ref_attribs); exit;

  my $iter = igroup_by(
                data    => $data,
                compare => \&str_row_equal,
                args    => [ values %$attribs ],
  );

  while (my $subset = $iter->()) {

    #print "subset: ", Dumper($subset), "\n";

    #print "before 1: attrib ", Dumper($attribs), "\ndata ", Dumper($subset);

    # change attribs from col numbers to values:
    # from:  { name => 1,           sex => 2,      ... }
    # to     { name => 'Smith, J.', sex => 'male', ... }
    my %attribs = map { $_ => $subset->[0]->[$attribs->{$_}] } keys %$attribs;
   

    # print "after 1: attrib ", Dumper(\%attribs), "\n";

    # add the 'simple ArrayRef' sub-objects
    # (there should really be only one of these - test for it?)
    while (my($attr_name, $col) = each %$ref_attribs) {
      my @col = map { $_->[$col] } @$subset;
      $attribs{$attr_name} = \@col;

      # ... or ...
      #$attribs{$attr_name} = [ map { $_->[$col] } @$subset ];
    }

    # print "after 2: attrib ", Dumper(\%attribs), "\n";

    # sub-objects - recursive call to array_to_moose()
    while( my($attr_name, $desc) = each %$sub_obj_desc) {

      my $type = $class->meta->find_attribute_by_name($attr_name)->type_constraint
        or croak "Moose attribute '$attr_name' has no type";

      #print "'$attr_name' has type '$type'";

      my $sub_obj = array_to_moose( data => $subset,
                                    desc => $desc,
                                  );

      $sub_obj = _check_subobj($class, $attr_name, $type, $sub_obj);

      #print "type $type\n";

      $attribs{$attr_name} = $sub_obj;
    }

    # print "after 2: attrib ", Dumper(\%attribs), "\n";

    my $obj;
    eval { $obj = $class->meta->new_object(%attribs) };
    croak "Can't make a new '$class' object:\n$@\n"
          if $@;

    if (defined $keycol) {
      my $key_name = $subset->[0]->[$keycol];

      # optionally croak if we are overwriting an existing hash entry
      croak "Non-unique key '$key_name' in '", $desc->{$CLASS}, "' class"
        if exists $result->{$key_name} and $throw_nonunique_keys;

      $result->{$key_name} = $obj;
    } else {
      push @{$result}, $obj;
    }
  }
  return $result;
}

############################################
# Usage: my ($class, $attribs, $ref_attribs, $sub_desc)
#                  = _check_descriptor($data, $desc)
#
# Check the correctness of the descriptor hashref, $desc.
#
# Checks of descriptor $desc include:
# 1. "class => 'MyClass'" line exists, and that class "MyClass" has
#                         been defined
# 2. for "attrib => N" 
#     or "key    => N" lines, N, the column number, is an integer, and that
#                      the column numbers is within limits of the data
# 3. For "attrib => [N]", (note square brackets), N, the columnn number,
#                         is within limits of the data
#
# Returns:
# $class,      the class name,
# $attribs,    hashref (name => column_index) of "simple" attributes
# $ref_attribs hashref (name => column_index) of attribs which are
#               ArrayRef[']s of simple types (i.e. not a Class)
#               (HashRef[']s not implemented)
# $sub_desc    hashref (name => desc) of sub-object descriptors
############################################
sub _check_descriptor {
  my ($data, $desc) = @_;

  # remove from production!
  croak "_check_descriptor() needs two arguments"
    unless @_ == 2;

  my $class = $desc->{$CLASS}
    or croak "No class descriptor '$CLASS => ...' in descriptor:\n",
       Dumper($desc);

  my $meta;

  # see other example of getting meta in Moose::Manual::???
  eval{ $meta = $class->meta };
  croak "Class '$class' not defined: $@"
    if $@;

  my $ncols = @{ $data->[0] };

  # separate out simple (i.e. non-reference) attributes, reference
  # attributes, and sub-objects
  my ($attrib, $ref_attrib, $sub_desc);

  while ( my ($name, $value) =  each %$desc) {

    # check lines which have 'simple' column numbers ( attrib or key => N)
    unless (ref($value) or $name eq $CLASS) {

      my $msg = "attribute '$name => $value'";

      croak "$msg must be a (non-negative) integer"
        unless $value =~ /^\d+$/;

      croak "$msg greater than # cols in the data ($ncols)"
        if $value > $ncols - 1;
    }

    # check to see if there are attributes called 'class' or 'key'
    if ($name eq $CLASS or $name eq $KEY) {
      croak "The '$class' object has an attribute called '$name'"
        if $meta->find_attribute_by_name($name);

      next;
    }

    croak "Attribute '$name' not in '$class' object"
      unless $meta->find_attribute_by_name($name);

    if ((my $ref = ref($value)) eq 'HASH') {
      $sub_desc->{$name} = $value;

    } elsif ($ref eq 'ARRAY') {
      # descr entry looks like, e.g.:
      #   attrib => [6],
      #
      # ( or attrib => [key => 6, value => 7],  in future... ?)

      croak "attribute must be of form, e.g.: '$name => [N], "
            . "where N is a single integer'"
          unless @$value == 1;

      my $msg = "attribute '$name => [ " . $value->[0] . " ]'. '" .
                  $value->[0] . "'";

      croak "$msg must be a (non-negative) integer"
        unless $value->[0]  =~ /^\d+$/;

      croak "$msg greater than # cols in the data ($ncols)"
        if $value->[0] > $ncols - 1;

      $ref_attrib->{$name} = $value->[0];

    } elsif ($ref) {
      croak "attribute '$name' can't be a '$ref' reference";

    } else {
      # "simple" attribute
      $attrib->{$name} = $value;
    }
  }


  # check ref- and ...
  _check_ref_attribs($class, $ref_attrib)
    if $ref_attrib;

  # ... non-ref attributes from the descriptor against the Moose object
  _check_non_ref_attribs($class, $attrib)
    if $attrib;

  croak "no attributes with column numbers in descriptor:\n", Dumper($desc)
    unless $attrib and %$attrib;

  return ($class, $attrib, $ref_attrib, $sub_desc);
}

########################################
# Usage: $sub_obj = _check_subobj($class, $attr_name, $type, $sub_obj);
#
# $class        is the name of the current class
# $attr_name    is the name of the attribute in the descriptor, e.g.
#               MyObjs => { ... } (used only diagnostic messages)
# $type         is the expected Moose type of the sub-object
#               i.e. 'HashRef[MyObj]', 'ArrayRef[MyObj]', or 'MyObj'
# $sub_obj_ref  Reference to the data (just returned from a recursive call to
#               array_to_moose() ) to be stored in the sub-object,
#               i.e. isa => 'HashRef[MyObj]', isa => 'ArrayRef[MyObj]',
#               or isa => 'MyObj'
#
#
# Checks that the data in $sub_obj_ref agrees with the type of the object to
# contain it
# if $type is a ref to an object (isa => 'MyObj'), _check_subobj() converts
# $sub_obj_ref from an arrayref to sub-object to ref to a subobj
# (see notes in code below)
#
# Throws error is it finds a type mis-match
########################################
sub _check_subobj {
  my ($class, $attr_name, $type, $sub_obj) = @_;

  # for now...
  croak "_check_subobj() should have 4 args" unless @_ == 4;

  #my $type = $class->meta->find_attribute_by_name($attr_name)->type_constraint
  #  or croak "Moose class '$class' attribute '$attr_name' has no type";

  if ( $type =~ /^HashRef\[([^]]*)\]/ ) {

    #print "subobj is of type ", ref($sub_obj), "\n";
    #print "subobj ", Dumper($sub_obj);

    croak "Moose attribute '$attr_name' has type '$type' "
          . "but your descriptor produced an object "
          . "of type '" . ref($sub_obj) . "'\n"
      if ref($sub_obj) ne 'HASH';

    #print "\$1 '$1', value: ", ref( ( values %{$sub_obj} )[0] ), "\n";

    croak("Moose attribute '$attr_name' has type '$type' "
          . "but your descriptor produced an object "
          . "of type 'HashRef[" . ref( ( values %{$sub_obj} )[0] )
          . "]'\n")
      if ref( ( values %{$sub_obj} )[0] ) ne $1;

  } elsif ( $type =~ /^ArrayRef\[([^]]*)\]/ ) {

    croak "Moose attribute '$attr_name' has type '$type' "
          . "but your descriptor produced an object "
          . "of type '" . ref($sub_obj) . "'\n"
      if ref($sub_obj) ne 'ARRAY';

    croak "Moose attribute '$attr_name' has type '$type' "
          . "but your descriptor produced an object "
          . "of type 'ArrayRef[" . ref( $sub_obj->[0] ) . "]'\n"
      if ref( $sub_obj->[0] ) ne $1;

  } else {

    # not isa => 'ArrayRef[MyObj]' or 'HashRef[MyObj]' but isa => 'MyObj',
    # *but* since array_to_moose() can return only a hash- or arrayref of Moose
    # objects, $sub_obj will be an arrayref of Moose objects, which we convert to a
    # ref to an object

    croak "Moose attribute '$attr_name' has type '$type' "
          . "but your descriptor generated a '"
          . ref($sub_obj)
          . "' object and not the expected ARRAY"
      unless ref $sub_obj eq 'ARRAY';

    # optionally give error if we got more than one row
    croak "Expected a single '$type' object, but got ",
        scalar @$sub_obj, " of them"
      if @$sub_obj != 1 and $throw_multiple_rows;

    # convert from arrayref of objects to ref to object
    $sub_obj = $sub_obj->[0];

    # print "\$sub_obj type is ", ref($sub_obj), "\n";

    croak "Moose attribute '$attr_name' has type '$type' "
          . "but your descriptor produced an object "
          . "of type '" . ref( $sub_obj ) . "'"
      unless ref( $sub_obj ) eq $type;
  }
  return $sub_obj;
}

{

  # The Moose type hierarchy (from Moose::Manual::Types) is:
  # Any
  # Item
  #     Bool
  #     Maybe[`a]
  #     Undef
  #     Defined
  #         Value
  #             Str
  #                 Num
  #                     Int
  #                 ClassName
  #                 RoleName
  #         Ref
  #             ScalarRef[`a]
  #             ArrayRef[`a]
  #             HashRef[`a]
  #             CodeRef
  #             RegexpRef
  #             GlobRef
  #                 FileHandle
  #             Object

  # So the test for 

  my %simple_types;

  BEGIN
  {
    %simple_types = map { $_ => 1 }
      qw ( Any Item Bool Undef Defined Value Str Num Int __ANON__ );
  }

########################################
# Usage:
#   _check_ref_attribs($class, $ref_attribs);
# Checks that "reference" attributes from the descriptor (e.g., attr => [N])
# are ArrayRef[]'s of simple attributes in the Moose object
# (e.g., isa => ArrayRef['Str'])
# Throws an exception if check fails
#
# where:
#   $class is the current Moose class
#   $ref_attribs an hashref of Moose attributes which are "ref
#   attributes", e.g., " has 'hobbies' (isa => 'ArrayRef[Str]'); "
#
########################################
sub _check_ref_attribs {
  my ($class, $ref_attribs) = @_;

  my $meta = $class->meta
    or croak "No meta for class '$class'?";

  foreach my $attrib ( keys %{ $ref_attribs } ) {
    my $msg = "Moose class '$class' ref attrib '$attrib'";

    my $constraint = $meta->find_attribute_by_name($attrib)->type_constraint
      or croak "$msg has no type constraint";

    #print "_check_ref_attribs(): $attrib $constraint\n";

    if ($constraint =~ /^ArrayRef\[([^]]*)\]/ ) {

      croak "$msg has bad type '$constraint' ('$1' is not a simple type)"
        unless $simple_types{$1};

      return;
    }
    croak "$msg must be an ArrayRef[`a] and not a '$constraint'";
  }
}


########################################
# Usage:
#   _check_non_ref_attribs($class, $non_ref_attribs);
# Checks that non-ref attributes from the descriptor (e.g., attr => N)
# are indeed simple attributes in the Moose object (e.g., isa => 'Str')
# Throws an exception if check fails
#
#
# where:
#   $class is the current Moose class
#   $non_ref_attribs an hashref of Moose attributes which are 
#   non-reference, or "simple" attributes like 'Str', 'Int', etc.
#   The key is the attribute name, the value the type
#
########################################
sub _check_non_ref_attribs {
  my ($class, $attribs) = @_;

  my $meta = $class->meta
    or croak "No meta for class '$class'?";

  foreach my $attrib ( keys %{ $attribs } ) {
    my $msg = "Moose class '$class', attrib '$attrib'";

    my $constraint = $meta->find_attribute_by_name($attrib)->type_constraint
      or croak "$msg has no type (isa => ...)";

    #print "_check_non_ref_attribs(): $attrib '$constraint'\n";

    # kludge for Maybe[`]
    $constraint =~ /^Maybe\[([^]]+)\]/;
    $constraint = $1 if $1;

    #print " after: $attrib '$constraint'\n";

    next if $simple_types{$constraint};

    $msg = "$msg has type '$constraint', but your descriptor had '$attrib => " 
         . $attribs->{$attrib} . "'.";

    $msg .= " (Did you forget the '[]' brackets?)"
      if $constraint =~ /^ArrayRef/;
      
    croak $msg;
  }
}
      
} # end of local block


1;

__END__

=head1 NAME

Array::To::Moose - Build Moose objects from a data array

=head1 VERSION

This document describes Array::To::Moose version 0.0.9

=head1 SYNOPSIS

  use Array::To::Moose;
  # or
  use Array::To::Moose qw(array_to_moose set_class_ind set_key_ind
                          throw_nonunique_keys throw_multiple_rows   );

C<Array::To::Moose> exports function C<array_to_moose()> by default, and
convenience functions C<set_class_ind()>, C<set_key_ind()>,
C<throw_nonunique_keys()> and C<throw_multiple_rows()> if requested.

=head2 array_to_moose

C<array_to_moose()> builds Moose objects from suitably-sorted
2-dimensional arrays of data of the type returned by, e.g.,
L<DBI::selectall_arrayref()|DBI/selectall_arrayref>
i.e.  a reference to an array containing
references to an array for each row of data fetched.

=head2 Example 1a

  package Car;
  use Moose;

  has 'make'  => (is => 'ro', isa => 'Str');
  has 'model' => (is => 'ro', isa => 'Str');
  has 'year'  => (is => 'ro', isa => 'Int');

  package CarOwner;
  use Moose;

  has 'last'  => (is => 'ro', isa => 'Str');
  has 'first' => (is => 'ro', isa => 'Str');
  has 'Cars'  => (is => 'ro', isa => ArrayRef[Car]');

  ...

  # in package main:

  use Array::To::Moose;

  # In this dataset Alex owns two cars, Jim one, and Alice three
  my $data = [
    [ qw( Green Alex  Ford   Focus 2011 ) ],
    [ qw( Green Alex  VW     Jetta 2009 ) ],
    [ qw( Green Jim   Honda  Civic 2007 ) ],
    [ qw( Smith Alice Buick  Regal 2012 ) ],
    [ qw( Smith Alice Toyota Camry 2008 ) ],
    [ qw( Smith Alice BMW    X5    2010 ) ],
  ];

  my $CarOwners = array_to_moose(
                      data => $data,
                      desc => {
                        class => 'CarOwner',
                        last  => 0,
                        first => 1,
                        Cars  => {
                          class => 'Car',
                          make  => 2,
                          model => 3,
                          year  => 4,
                        } # Cars
                      } # Car Owners
  );

  print $CarOwners->[2]->Cars->[1]->model; # prints "Camry"

=head2 Example 1b - Hash(ref) Sub-objects

In the above example, C<array_to_moose()> returns a reference to an
B<array> of C<CarOwner> objects, C<$CarOwners>.

If a B<hash> of C<CarOwner> objects is required, a "C<key =E<gt>>... " entry
must be added to the descriptor hash. For example, to construct a hash of
C<CarOwner> objects, whose key is the owner's first name, (unique for
every person in the example data), the call
becomes:

  my $CarOwnersH = array_to_moose(
                      data => $data,
                      desc => {
                        class => 'CarOwner',
                        key   => 1,   # note key
                        last  => 0,
                        first => 1,
                        Cars  => {
                          class => 'Car',
                          make  => 2,
                          model => 3,
                          year  => 4,
                        } # Cars
                      } # Car Owners
  );

  print $CarOwnersH->{Alex}->Cars->[0]->make; # prints "Ford"

Similarly, to construct the C<Cars> sub-objects as I<hash> sub-objects
(and not an I<array> as above), define C<CarOwner> as:

  package CarOwner;
  use Moose;

  has 'last'  => (is => 'ro', isa => 'Str'         );
  has 'first' => (is => 'ro', isa => 'Str'         );
  has 'Cars'  => (is => 'ro', isa => 'HashRef[Car]'); # Was 'ArrayRef[Car]'

and noting that the car C<make> is unique for each person in the C<$data> dataset, we
construct the reference to an array of objects with the call:

  $CarOwners = array_to_moose(
                      data => $data,
                      desc => {
                        class => 'CarOwner',
                        last  => 0,
                        first => 1,
                        Cars  => {
                          class => 'Car',
                          key   => 2,   # note key
                          model => 3,
                          year  => 4,
                        } # Cars
                      } # Car Owners
  );

  print $CarOwners->[2]->Cars->{BMW}->model; # prints 'X5'

=head2 Example 1c - "Simple" Reference Attributes

If, instead of the car owner object containing an ArrayRef or HashRef of
C<Car> sub-objects, it contains, say, a ArrayRef of strings representing the
names of the car makers:

  package SimpleCarOwner;
  use Moose;

  has 'last'      => (is => 'ro', isa => 'Str'          );
  has 'first'     => (is => 'ro', isa => 'Str'          );
  has 'CarMakers' => (is => 'ro', isa => 'ArrayRef[Str]');

Using the same dataset from Example 1a, we construct an arrayref
C<SimpleCarOwner> objects as:

  $SimpleCarOwners = array_to_moose(
                        data => $data,
                        desc => {
                          class     => 'SimpleCarOwner',
                          last      => 0,
                          first     => 1,
                          CarMakers => [2],  # Note the '[...]' brackets
                        }
  );

  print $SimpleCarOwners->[2]->[1];   # prints 'Toyota'

I.e., when the object attribute is an I<ArrayRef> of one of the Moose "simple" types,
e.g. C<'Str'>, C<'Num'>, C<'Bool'>,
etc (See L<Moose::Manual::Types|THE TYPES>), then the column number should
appear in square brackets ('C<CarMakers =E<gt> [2]>' above) to differentiate them from the bare
types (C<last =E<gt> 0,> and C<first =E<gt> 1,> above).

Note that Array::To::Moose doesn't (yet) handle the case of hashrefs of
"simple" types, e.g., C<( isa =E<gt> "HashRef[Str]" )>

=head2 Example 2 - Use with DBI

The main rationale for writing C<Array::To::Moose> is to make it easy to build
Moose objects from data extracted from relational databases,
especially when the database query
involves multiple tables with one-to-many relationships to each other.

As an example, consider a database which models patients making visits
to a clinic on multiple occasions, and on each visit, having a doctor
run some tests and diagnose the patient's complaint. In this model, the
database I<Patient> table would have a one-to-many relationship with the
I<Visit> table, which in turn would have a one-to-many relationship with
the I<Test> table

The corresponding Moose model has nested Moose objects which reflects those
one-to-many relationships, i.e.,
multiple Visit objects per Patient object and multiple Test objects
per Visit object, declared as:

  package Test;
  use Moose;
  has 'name'        => (is => 'rw', isa => 'Str');
  has 'result'      => (is => 'rw', isa => 'Str');

  package Visit;
  use Moose;
  has 'date'        => (is => 'rw', isa => 'Str'           );
  has 'md'          => (is => 'rw', isa => 'Str'           );
  has 'diagnosis'   => (is => 'rw', isa => 'Str'           );
  has 'Tests'       => (is => 'rw', isa => 'HashRef[Test]' );

  package Patient;
  use Moose;
  has 'last'        => (is => 'rw', isa => 'Str'             );
  has 'first'       => (is => 'rw', isa => 'Str'             );
  has 'Visits'      => (is => 'rw', isa => 'ArrayRef[Visit]' );

In the main program:

  use DBI;
  use Array::To::Moose;

  ...

  my $sql = q{
    SELECT
       P.Last, P.First
      ,V.Date, V.Doctor, V.Diagnosis
      ,T.Name, T.Result
    FROM
       Patient P
      ,Visit   V
      ,Test    T
    WHERE
          -- join clauses
          P.Patient_key = V.Patient_key
      AND V.Visit_key   = T.Visit_key
      ...
    ORDER BY
        P.Last, P.First, V.Date
  };

  my $dbh = DBI->connect(...);

  my $data = $dbh->selectall_arrayref($sql);

  # rows of @$data contain:
  #               Last, First, Date, Doctor, Diagnosis, Name, Result
  # at positions: [0]   [1]    [2]   [3]     [4]        [5]   [6]

  my $patients = array_to_moose(
                      data => $data,
                      desc => {
                        class => 'Patient',
                        last  => 0,
                        first => 1,
                        Visits => {
                          class => 'Visit',
                          date      => 2,
                          md        => 3,
                          diagnosis => 4,
                          Tests => {
                            class  => 'Test',
                            key    => 5,
                            name   => 5,
                            result => 6,
                          } # tests
                        } # visits
                      } # patients
  );

  print $patients->[2]->Visits->[0]->Tests->{BP}->result; # prints '120/80'

Note: We used the Test C<name> as the key for the Visit 'C<Tests>', as the
tests have unique names within any one Visit.
(See t/5.t)

=head1 DESCRIPTION

As shown in the above examples, the general usage is:

  package MyClass;
  use Moose;
  (define Moose object(s))
  ...
  use Array::To::Moose;
  ...
  my $data_ref = selectall_arrayref($sql); # for example

  my $object_ref =  array_to_moose(
                        data => $data_ref
                        desc => {
                          class    => 'MyClass',
                          key      => K,   # only for HashRefs
                          attrib_1 => N1,
                          attrib_2 => N2,
                          ...
                          attrib_m => [ M ],
                          ...
                          SubObject => {
                            class => 'MySubClass',
                            ...
                          }
                        }
  );

Where:

C<array_to_moose()> returns an array- or hash reference of C<MyClass>
Moose objects.
All Moose classes (C<MyClass>, C<MySubClass>, etc) must
already have been defined by the user.

C<$data_ref> is a reference to an array containing references to arrays of
scalars of the kind returned by, e.g.,
L<DBI::selectall_arrayref()|DBI/selectall_arrayref>

C<desc> (descriptor) is a reference to a hash which contains several types
of data:

C<class =E<gt>> 'MyObj' is I<required> and defines the Moose class or
package which will contain the data. The user should have defined this class
already.

C<key =E<gt> N > is required
if the Moose object being constructed is to be a hashref, either at
the top-level Moose object returned from C<array_to_moose()> or as a
"C<isa =E<gt> 'HashRef[...]'>" sub-object.

C<attrib =E<gt> N > where C<attrib> is the name of a Moose attribute
("C<has 'attrib' =E<gt>> ...") 

C<attrib =E<gt> [ N ] > where C<attrib> is the name of a Moose "simple" sub-attribute
("C<has =E<gt> 'attrib' ( isa =E<gt> 'ArrayRef[Type]' ...)> "), where C<Type>
is a "simple" Moose type, e.g., C<'Str', 'Int'>, etc.

In the above cases, C<N> is a positive integer containing the
the corresponding zero-indexed
column number in the data array where that attribute's data is to be found.

=head2 Sub-Objects

C<array_to_moose()> can handle three types of Moose sub-objects, i.e.:

an array of sub-objects:

  has => 'Sub_Obj' ( isa => 'ArrayRef[MyObj]' );

a hash of sub-objects:

  has => 'Sub_Obj' ( isa => 'HashRef[MyObj]'  );

or a single sub-object:

  has => 'Sub_Obj' ( isa => 'MyObj'           );

the descriptor entry for C<Sub_Obj> in each of these cases is (almost) the same:

  desc => {
    class => ...
    ...
    Sub_Obj => {
      class    => 'MyObj',
      key      => <keycol> # HashRef['] only
      attrib_a => <N>,
      ...
    } # end SubObj
    ...
  } # end desc

(A C<HashRef[']> sub-object will also I<require> a
C<key =E<gt> N> entry in the descriptor).

In addition, C<array_to_moose()> can also handle C<ArrayRef>s of "simple"
types:

  has => 'Sub_Obj' ( isa => 'ArrayRef[Type]' );

where C<Type> is a "simple" Moose type, e.g., C<'Str', 'Int, 'Bool'>, etc.

=head2 Ordering the data

C<array_to_moose()> does not sort the input data array, and does all
processing in a single pass through the data. This means that the data in the
array must be sorted properly for the algorithm to work.

For example, in the previous Patient/Visit/Test example, in which there are
many I<Test>s per I<Visit> and many I<Visit>s per I<Patient>, the data in the
I<Test> column(s) must change the fastest, the I<Visit> data slower, and the
I<Patient> data the slowest:

  Patient  Visit  Test
  ------   -----  ----
    P1      V1     T1
    P1      V1     T2
    P1      V1     T3
    P1      V2     T4
    P1      V2     T5
    P2      V3     T6
    P2      V3     T7
    P2      V4     T8

In SQL this would be accomplished by a C<SORT BY> clause, e.g.:

  SORT BY Patient.Key, Visit.Key, Test.Key

=head2 throw_nonunique_keys ()

By default, C<array_to_moose()> does not check the uniqueness of hash key
values within the data. If the key values in the data are not unique,
existing hash entries will get overwritten, and
the sub-object will contain the value from the last data row which
contained that key value. For example:

  package Employer;
  use Moose;
  has 'year'    => (is => 'rw', isa => 'Str');
  has 'name'    => (is => 'rw', isa => 'Str');

  package Person;
  use Moose;
  has 'name'        => (is => 'rw', isa => 'Str'              );
  has 'Employers'   => (is => 'rw', isa => 'HashRef[Employer]');

  ...

  my $data = [
    [ 'Anne Miller', '2005', 'Acme Corp'    ],
    [ 'Anne Miller', '2006', 'Acme Corp'    ],
    [ 'Anne Miller', '2007', 'Widgets, Inc' ],
    ...
  ];

The call:

  my $obj = array_to_moose(
                  data => $data,
                  desc => {
                    class     => 'Person',
                    name      => 0,
                    Employers => {
                      class => 'Employer',
                      key   => 2,   # using employer name as key
                      year  => 1,
                    } # Employer
                  } # Person
  );

Because the employer was C<'Acme Corp'> in years 2005 & 2006,
C<array_to_moose>
will silently overwrite the 2005 Employer object with the data for the
2006 Employer object:

  print $obj->[0]->Employers->{'Acme Corp'}->year, "\n"; # prints '2006'

Calling C<throw_uniq_keys()> (either with no argument, or with a non-zero
argument) enables reporting of non-unique keys. In the above example,
C<array_to_moose()> would exit with warning:

 Non-unique key 'Acme Corp' in 'Employer' class ...

Calling C<throw_uniq_keys(0)>, i.e. with an argument of zero will disable
subsequent reporting of non-unique keys.
(See t/8c.t)

=head2 throw_multiple_rows ()

For single-occurence sub-objects (i.e. C<( isa =E<gt> 'MyObj' )>),
if the data contains more than one row of data for the sub-object,
only the first row will be used to construct the single sub-object and
C<array_to_moose()> will not report the fact. E.g.:

  package Salary;
  use Moose;
  has 'year'    => (is => 'rw', isa => 'Str');
  has 'amount'  => (is => 'rw', isa => 'Int');

  package Person;
  use Moose;
  has 'name'     => (is => 'rw', isa => 'Str'   );
  has 'Salary'   => (is => 'rw', isa => 'Salary'); # a single object

  ...

  my $data = [
    [ 'John Smith', '2005', 23_350 ],
    [ 'John Smith', '2006', 24_000 ],
    [ 'John Smith', '2007', 26_830 ],
    ...
  ];

The call:

  my $obj = array_to_moose(
                  data => $data,
                  desc => {
                    class  => 'Person'
                    name   => 0,
                    Salary => {
                      class  => 'Salary',
                      year   => 1,
                      amount => 2
                    } # Salary
                  } # Person
  );

would silently assign to C<Salary>, the first row of the three Salary
data rows, i.e. for year 2005:

  print $object->[0]->Salary->year, "\n"; # prints '2005'

Calling C<throw_multiple_rows()>
(either with no argument, or with a non-zero argument)
enables reporting of this situation. In the
above example, C<array_to_moose()> will exit with error:

  Expected a single 'Salary' object, but got 3 of them ...

Calling C<throw_multiple_rows(0)>, i.e. with an argument of zero will disable
subsequent reporting of this error.
(See t/8d.t)

=head2 set_class_ind (), set_key_ind ()

Problems arise if the Moose objects being constructed contain attributes
called I<class> or I<key>, causing ambiguities in the descriptor. (Does
C<key =E<gt> 5> mean the I<attribute> C<key> or the I<hash key> C<key> is in
the 5th column?)

In these cases, C<set_class_ind()> and
C<set_key_ind()> can be used to change the keywords for C<class
=E<gt> ...> and C<key =E<gt> ...> descriptor entries.

For example:

  package Letter;
  use Moose;

  has 'address' => ( is => 'ro', isa => 'Str'         );
  has 'class'   => ( is => 'ro', isa => 'PostalClass' );
  ...

  set_key_ind('package'); # use "package =>" in place of "class =>"

  my $letters = array_to_moose(
                        data => $data,
                        desc => {
                          package => 'Letter',  # the Moose class
                          address => 0,
                          class   => 1,         # the attribute 'class'
                          ...
                        }
  );


=head2 Read-only Attributes

One of the recommendations of L<Moose::Manual::BestPractices>
is to make attributes read-only (C<isa =E<gt> 'ro'>) wherever
possible. C<Array::To::Moose> supports this by evaluating all the
attributes for a given object given in the descriptor, then including
them all in the call to C<new(...)> when constructing the object.

For Moose objects with attributes which are
sub-objects, i.e.  references to a Moose object, or references to an array or hash of
Moose objects, it means that the sub-objects must be evaluated before the
C<new()> call. The effect of this for multi-leveled Moose objects is that
object evaluations are carried out depth-first.

=head2 Treatment of C<NULL>s

C<array_to_moose()> uses
L<Array::GroupBy::igroup_by|Array::GroupBy.pm/DESCRIPTION>
to compare the rows in
the data given in C<data =E<gt> ...>, using function
L<Array::GroupBy::str_row_equal()|Array::GroupBy.pm/Routines_str_row_equal()_and_num_row_equal()>
which compares the data as I<strings>.

If the data contains C<undef> values, typically returned from
database SQL queries in which L<DBI> maps NULL values to C<undef>, when
C<str_row_equal()> encounters C<undef> elements in I<corresponding> column
positions, it will consider the elements C<equal>.  When I<corresponding>
column elements are defined and C<undef> respectively, the elements are
considered C<unequal>.

This truth table demonstrates the various combinations:

  -------+------------+--------------+--------------+--------------
  row 1  | ('a', 'b') | ('a', undef) | ('a', undef) | ('a', 'b'  )
  row 2  | ('a', 'b') | ('a', undef) | ('a', 'b'  ) | ('a', undef)
  -------+------------+--------------+--------------+--------------
  equal? |    yes     |     yes      |      no      |      no

=head1 EXPORT

C<array_to_moose> by default; C<throw_nonunique_keys>, C<throw_multiple_rows>,
C<set_class_ind> and C<set_key_ind> if requested.

=head1 DIAGNOSTICS

Errors in the call of C<array-to-moose()> will be caught by
L<Params::Validate::Array>, q.v.

<array-to-moose> does a lot of error checking, and is probably annoyingly
chatty. Most of the errors generated are, of course, self-explanatory :-)

=head1 DEPENDENCIES

  Carp
  Params::Validate::Array
  Array::GroupBy

=head1 SEE ALSO

L<DBI>, L<Moose>, L<Array::GroupBy>

=head1 BUGS

The handling of Moose type constraints is primitive.

=head1 AUTHOR

Sam Brain <samb@stanford.edu>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Stanford University. June 6th, 2010.
All rights reserved.
Author: Sam Brain <samb@stanford.edu>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

# TODO
#
# test for non-square data array?
#
# - allow argument "compare => sub {...}" in array_to_moose() call to
# allow a user-defined row-comparison routine to be passed to
# Array::GroupBy::igroup_by()
#
# - make it Mouse-compatible? (All meta->... stuff would break?)

##### SUBROUTINE INDEX #####
#                          #
#   gen by index_subs.pl   #
#   on 24 Apr 2014 21:11   #
#                          #
############################


####### Packages ###########

# Array::To::Moose ......................... 1
#   array_to_moose ......................... 2
#   set_class_ind .......................... 2
#   set_key_ind ............................ 2
#   throw_multiple_rows .................... 2
#   throw_nonunique_keys ................... 2
#   _check_descriptor ...................... 4
#   _check_non_ref_attribs ................. 9
#   _check_ref_attribs ..................... 8
#   _check_subobj .......................... 6


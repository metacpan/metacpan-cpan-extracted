package Data::Nested::Multiele;
# Copyright (c) 2007-2010 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################
# GLOBAL VARIABLES
###############################################################################

###############################################################################
# TODO
###############################################################################

###############################################################################

require 5.000;
use strict;
use warnings;
use YAML::Syck;
use Data::Nested;
use Storable qw(dclone);

use vars qw($VERSION);
$VERSION = '3.12';

###############################################################################
# BASE METHODS
###############################################################################
#
# $NDS   always refers to a Data::Nested object
# $nds   always refers to an actual NDS
# $ele   always refers to an element name/index
# $self  always refers to a Data::Nested::Multiele object

sub new {
   my(@args) = @_;

   # Get the Data::Nested object (if any).

   my $class = 'Data::Nested::Multiele';
   my $NDS   = undef;

   if (@args  &&  ref($args[0]) eq $class) {
      # $obj = $self->new;

      my $self = shift(@args);
      $NDS     = $self->nds();

   } elsif (@args  &&  $args[0] eq $class) {
      # $obj = new Data::Nested::Multiele [NDS];

      shift(@args);
      if (@args  &&  ref($args[0]) eq 'Data::Nested') {
         $NDS = shift(@args);
      } else {
         $NDS = new Data::Nested;
      }

   } else {
      warn "ERROR: [new] first argument must be a $class class/object\n";
      return undef;
   }

   # Get the file (if any)

   my $file = '';
   if (@args) {
      $file = shift(@args);
   }

   # Get the ordered argument (if any).

   my $ordered = 0;
   if ($file) {
      if (@args  &&  $args[0] eq '1') {
         $ordered = shift(@args);
      }
   }

   # Unknown arguments

   if (@args) {
      warn "ERROR: [new] unknown arguments: @args\n";
      return undef;
   }

   my $self = {
               'nds'       => $NDS,  # Data::Nested object
               'file'      => '',    # Path to YAML file
               'list'      => '',    # 1 if the data is a list.
               'ordered'   => 0,     # 1 if it is an ordered list.
               'def'       => [],    # List of default elements.
                                     #   [ [ [NAME] ELE1 RULESET COND... ]
                                     #     [ [NAME] ELE2 RULESET COND... ] ]
                                     # NAME is used only for hashes
               'raw'       => undef, # hash/list of elements
               'data'      => undef, # hash/list of full elements
               'err'       => '',
               'errmsg'    => '',
               'elesx'     => undef, # A list of all existing elements
               'elesn'     => undef, # A list of all non-empty elements
               'elesxh'    => {},    # A hash of { ELE => 1 } for existing elements
                                     # Exactly equivalent to 'elesx'.
               'elesnh'    => undef, # A hash of { ELE => 0/1 } for empty/not


               'eles'      => {},    # A hash of all elements. The value is:
                                     #   0  : exists
                                     #   1  : constructed
                                     #   2  : constructed, known empty
                                     #   3  : constructed, known non-empty
               'status'    => 0,     # Status of data
                                     #   0  : no checks
                                     #   1  : existance checked
                                     #   2  : all element constructed
                                     #   3  : empty checked
              };
   bless $self, $class;

   if ($ordered) {
      $$self{'ordered'} = 1;
   }

   if ($file) {
      $self->file($file);
      if ($self->err()) {
         return undef;
      }
   }

   return $self;
}

sub version {
   my($self) = @_;

   return $VERSION;
}

sub nds {
   my($self) = @_;

   return $$self{'nds'};
}

sub err {
   my($self) = @_;

   return $$self{'err'};
}

sub errmsg {
   my($self) = @_;

   return $$self{'errmsg'};
}

sub ordered_list {
   my($self) = @_;

   if ($$self{'file'}) {
      $$self{'err'}    = 'ndserr02';
      $$self{'errmsg'} = 'Cannot call ordered_list after a file is read.';
      return;
   }
   $$self{'ordered'} = 1;
}

###############################################################################
# FILE METHODS
###############################################################################

sub file {
   my($self,$file,$nostruct) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';
   my $ordered      = $$self{'ordered'};
   my $new          = ($nostruct ? 0 : 1);

   #
   # Read the YAML data source
   #

   if ($$self{'file'}) {
      $$self{'err'}    = 'nmefil01';
      $$self{'errmsg'} = "File already set for this object: $$self{file}";
      return;
   }

   if (! -f $file) {
      $$self{'err'}    = 'nmefil02';
      $$self{'errmsg'} = "File not found: $file";
      return;
   }

   if (! -r $file) {
      $$self{'err'}    = 'nmefil03';
      $$self{'errmsg'} = "File not readable: $file";
      return;
   }

   my $ref = YAML::Syck::LoadFile($file);
   if (ref($ref) eq 'HASH') {
      $$self{'list'}    = 0;
      $$self{'ordered'} = 0;
      $$self{'data'}    = {};
      if ($ordered) {
         $$self{'err'}    = 'nmefil09';
         $$self{'errmsg'} = "Ordered not valid for a file containing a hash: $file";
         return;
      }
   } elsif (ref($ref) eq 'ARRAY') {
      $$self{'list'}    = 1;
      $$self{'data'}    = [];
   } else {
      $$self{'err'}    = 'nmefil04';
      $$self{'errmsg'} = "File must contain a list or hash: $file";
      return;
   }

   #
   # Check the structure of each element
   #

   my $NDS = $$self{'nds'};
   my $err = 0;

   if ($$self{'list'}) {
      for (my $i=0; $i<=$#$ref; $i++) {
         $NDS->check_structure($$ref[$i],$new);
         my $e = $NDS->err();
         if ($e) {
            if ($err) {
               $$self{'errmsg'} .= " $i [$e]";
            } else {
               $$self{'errmsg'} = "Invalid element: $i [$e]";
            }
            $err = 1;
         }
      }

   } else {
      foreach my $ele (CORE::keys %$ref) {
         $NDS->check_structure($$ref{$ele},$new);
         my $e = $NDS->err();
         if ($e) {
            if ($err) {
               $$self{'errmsg'} .= " $ele [$e]";
            } else {
               $$self{'errmsg'} = "Invalid element: $ele [$e]";
            }
            $err = 1;
         }
      }

   }

   if ($err) {
      $$self{'err'} = 'nmefil05';
      return;
   }

   #
   # Store the data.
   #

   $$self{'raw'}   = $ref;
   $$self{'file'}  = $file;
   $$self{'def'}   = [];
   return;
}

###############################################################################
# ELEMENT METHODS
###############################################################################

# Set a list of all existing or non-empty elements.
#
sub _eles {
   my($self,$exists) = @_;

   if ($exists) {
      my @ele;
      if ($$self{'list'}) {
         my $n = $#{ $$self{'raw'} };
         @ele = (0..$n);

         if ($#ele != $#{ $$self{'elesx'} }) {
            $$self{'elesx'} = [ @ele ];
            %{ $$self{'elesxh'} } = map { $_,1 } @ele;
         }

      } else {
         if (! defined($$self{'elesx'})) {
            my @tmp = CORE::keys %{ $$self{'raw'} };
            @tmp    = sort @tmp;
            $$self{'elesx'} = [ @tmp ];
            %{ $$self{'elesxh'} } = map { $_,1 } @tmp;
         }
         @ele = @{ $$self{'elesx'} };
      }

      return;
   }

   _eles($self,'construct');
   my(@non);

   foreach my $ele (@{ $$self{'elesx'} }) {
      push(@non,$ele)  if (! _ele_empty($self,$ele));
   }

   if ($$self{'list'}) {
      $$self{'elesn'} = [ sort { $a <=> $b } @non ];
   } else {
      $$self{'elesn'} = [ sort @non ];
   }
}

# Construct a data element from a raw element and all default elements.
#
sub _ele {
   my($self,$ele) = @_;

   # Test to see if the element has been constructed.
   if ($$self{'list'}) {
      return  if (defined $$self{'data'}[$ele]);
   } else {
      return  if (exists $$self{'data'}{$ele});
   }

   # Initialize the data element using the raw data

   if ($$self{'list'}) {
      $$self{'data'}[$ele] = undef;
      $$self{'data'}[$ele] = dclone($$self{'raw'}[$ele])
        if (defined $$self{'raw'}[$ele]);
   } else {
      $$self{'data'}{$ele} = undef;
      $$self{'data'}{$ele} = dclone($$self{'raw'}{$ele})
        if (defined $$self{'raw'}{$ele});
   }

   # Merge in each default.

   my $NDS = $self->nds();
   foreach my $def (@{ $$self{'def'} }) {
      if ($$self{'list'}) {
         my($defele,$ruleset,@cond) = @$def;
         my $nds  = _ele_nds($self,$ele);
         if ($NDS->test_conditions($nds,@cond)) {
            my $tmp = $$self{'data'}[$ele];
            if (defined($tmp)) {
               $NDS->merge($tmp,dclone($defele),$ruleset);
            } else {
               $tmp = dclone($defele);
            }
            $$self{'data'}[$ele] = $tmp;
         }

      } else {
         my($e,$defele,$ruleset,@cond) = @$def;
         my $nds  = _ele_nds($self,$ele);
         if ($NDS->test_conditions($nds,@cond)) {
            my $tmp = $$self{'data'}{$ele};
            if (defined($tmp)) {
               $NDS->merge($tmp,dclone($defele),$ruleset);
            } else {
               $tmp = dclone($defele);
            }
            $$self{'data'}{$ele} = $tmp;
         }
      }
   }
}

# Test to see if an element is empty (construct it if necessary).
#
sub _ele_nonempty {
   my($self,$ele) = @_;

   my $NDS = $self->nds();
   my $nds = _ele_nds($self,$ele);
   my $val = $NDS->empty($nds);

   if (! defined $val) {
      return undef;
   }
   $val = 1-$val;
   $$self{'elesnh'}{$ele} = $val;
   return $val;
}

# Return the full NDS of an element.
#
# If $raw is 1, returns the raw element.
# If $noconstruct is 1, returns the current data element without constructing.
# Otherwise, returns the full element.
#
sub _ele_nds {
   my($self,$ele,$raw,$noconstruct) = @_;

   if ($raw) {
      if ($$self{'list'}) {
         return $$self{'raw'}[$ele];
      } else {
         return $$self{'raw'}{$ele};
      }
   }

   # $noconstruct is useful so that this can be called while in
   # the process of merging in each of the defaults.
   if (! $noconstruct) {
      _ele($self,$ele);
      return undef  if ($self->err());
   }

   if ($$self{'list'}) {
      return $$self{'data'}[$ele];
   } else {
      return $$self{'data'}{$ele};
   }
}

sub _ele_exists {
   my($self,$ele) = @_;
   _eles($self,'construct');
   return 1  if (exists $$self{'elesxh'}{$ele});
   return 0;
}

sub _ele_empty {
   my($self,$ele) = @_;
   return 1  if (! _ele_exists($self,$ele));
   _ele($self,$ele);
   _ele_nonempty($self,$ele);
   return 1-$$self{'elesnh'}{$ele};
}

###############################################################################
# DEFAULT METHODS
###############################################################################

sub default_element {
   my($self,@args)  = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   # For hashes, get the element

   my $ele;
   if (! $$self{'list'}) {
      if (! @args) {
         $$self{'err'}    = 'nmedef01';
         $$self{'errmsg'} = 'Element name required for hashes';
         return;
      }
      $ele = shift(@args);

      if (! exists $$self{'raw'}{$ele}) {
         $$self{'err'}    = 'nmedef02';
         $$self{'errmsg'} = "The named element does not exist: $ele";
         return;
      }
   }

   # Ruleset, conditions

   my $ruleset = 'default';
   my @cond;

   if ( ($#args % 2) == 0) {
      # odd number of arguments
      $ruleset = shift(@args);
      @cond    = @args;
   } else {
      @cond    = @args;
   }

   my $NDS = $self->nds();
   if (! $NDS->ruleset_valid($ruleset)) {
      $$self{'err'}    = 'nmedef03';
      $$self{'errmsg'} = 'An invalid ruleset specified for merging ' .
        "defaults: $ruleset";
      return;
   }

   my @tmp = @cond;
   while (@tmp) {
      my $path = shift(@tmp);
      my $val  = shift(@tmp);
      if (! $NDS->get_structure($path,'valid')) {
         $$self{'err'}    = 'nmedef04';
         $$self{'errmsg'} = 'An invalid path specified in a default ' .
           "condition: $path";
         return;
      }
   }

   # Move the default element into the list of defaults.

   my @def;
   if ($$self{'list'}) {
      if (! defined $$self{'raw'}[0]  ||
          $NDS->empty($$self{'raw'}[0])) {
         $$self{'err'}    = 'ndsdef06';
         $$self{'errmsg'} = 'An undefined/empty element may not be used as ' .
           'a default.';
         return;
      }
      push(@def,splice(@{ $$self{'raw'} },0,1));

   } else {
      push(@def,$ele);
      push(@def,$$self{'raw'}{$ele});
      delete $$self{'raw'}{$ele};
   }
   $$self{'elesx'} = undef;
   push(@def,$ruleset,@cond);
   push(@{ $$self{'def'} },[@def]);
   return;
}

sub is_default_value {
   my($self,$ele,$path) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   if (! $self->ele($ele,1)) {
      $$self{'err'}    = 'nmeele01';
      $$self{'errmsg'} = "The specified element does not exist: $ele";
      return;
   }

   if (! $self->path_valid($path)) {
      $$self{'err'}    = 'nmeacc03';
      $$self{'errmsg'} = "Attempt to access data with an invalid path: $path";
      return undef;
   }

   # Get the current value at the path. If it's not defined, it didn't
   # come from a default.

   my $val = $self->value($ele,$path);
   if ($self->err()  ||
       ! defined $val) {
      $$self{'err'}    = '';
      $$self{'errmsg'} = '';
      return 0;
   }

   # Get the raw value at the path. If it's not defined, the value had
   # to come from a default.

   my $NDS = $self->nds();
   my $nds = _ele_nds($self,$ele,1);
   my $raw = $NDS->value($nds,$path);
   if ($NDS->err()  ||
       ! defined $raw) {
      $$NDS{'err'}    = '';
      $$NDS{'errmsg'} = '';
      return 1;
   }

   # Compare the current value to the raw value. If they are different,
   # it came from a default.

   if (ref($val)) {
      # Compare data structures (use the Data::Nested::identical method)
      return 0  if ($NDS->identical($val,$raw));
      return 1;

   } else {
      # Compare scalars
      return 1  if ($raw ne $val);
      return 0;
   }
}

###############################################################################
# ELEMENT EXISTANCE METHODS
###############################################################################

sub eles {
   my($self,$exists) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';

   if ($exists) {
      _eles($self,'construct');
      return undef  if ($self->err());
      return @{ $$self{'elesx'} };
   } else {
      _eles($self);
      return undef  if ($self->err());
      return @{ $$self{'elesn'} };
   }
}

sub ele {
   my($self,$ele,$exists) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   # Return 0 if it doesn't exist
   if ($$self{'list'}) {
      return 0  if (! defined $$self{'raw'}[$ele]);
   } else {
      return 0  if (! exists $$self{'raw'}{$ele});
   }

   if ($exists) {
      return 1;

   } else {
      return $$self{'elesnh'}{$ele}  if (exists $$self{'elesnh'}{$ele});
      _ele_nonempty($self,$ele);
      return $$self{'elesnh'}{$ele};
   }
}

###############################################################################
# WHICH METHOD
###############################################################################

sub which {
   my($self,@cond)  = @_;
   my $NDS          = nds($self);
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   # Test to make sure that all paths are valid, and that there are
   # an even number of values.

   if (($#cond % 2) == 0) {
      $$self{'err'}    = 'nmeacc01';
      $$self{'errmsg'} = 'When specifying conditions, an even number of ' .
        'arguments is required.';
      return ();
   }

   my @tmp = @cond;
   while (@tmp) {
      my $path = shift(@tmp);
      shift(@tmp);
      if (! $NDS->get_structure($path,'valid')) {
         $$self{'err'}    = 'nmeacc02';
         $$self{'errmsg'} = 'When specifying conditions, a valid path is ' .
           "required: $path";
         return ();
      }
   }

   # Test every element

   _eles($self);
   return ()  if ($self->err());

   my @eles = $self->eles(1);
   my @ret;

   foreach my $ele (@eles) {
      # Test it.
      my $nds  = _ele_nds($self,$ele);
      my $pass = $NDS->test_conditions($nds,@cond);
      return ()  if ($self->err());
      push(@ret,$ele)  if ($pass);
   }

   return @ret;
}

###############################################################################
# PATH_VALID METHOD
###############################################################################

sub path_valid {
   my($self,$path) = @_;
   my $NDS = $$self{'nds'};

   return $NDS->get_structure($path,'valid');
}

###############################################################################
# VALUE, KEYS, VALUES METHODS
###############################################################################

sub value {
   my($self,$ele,$path,$copy,$raw) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';
   $copy            = 0  if (! $copy);
   $raw             = 0  if (! $raw);

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   if (! $self->ele($ele,1)) {
      $$self{'err'}    = 'nmeele01';
      $$self{'errmsg'} = "The specified element does not exist: $ele";
      return;
   }

   my $NDS = $$self{'nds'};
   if (! $NDS->get_structure($path,'valid')) {
      $$self{'err'}    = 'nmeacc03';
      $$self{'errmsg'} = "Attempt to access data with an invalid path: $path";
      return undef;
   }

   my $nds = _ele_nds($self,$ele,$raw);
   my $val = $NDS->value($nds,$path);
   if ($NDS->err()) {
      $$NDS{'err'}     = '';
      $$NDS{'errmsg'}  = '';
      $$self{'err'}    = 'nmeacc04';
      $$self{'errmsg'} = "The path does not exist in this element: $ele: $path";
      return undef;
   }

   if ($copy) {
      $val = dclone($val);
   }

   return $val;
}

sub keys {
   my($self,$ele,$path,$empty,$raw) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';
   $empty           = 0  if (! $empty);
   $raw             = 0  if (! $raw);

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   my $NDS = $$self{'nds'};
   if (! $NDS->get_structure($path,'valid')) {
      $$self{'err'}    = 'nmeacc03';
      $$self{'errmsg'} = "Attempt to access data with an invalid path: $path";
      return undef;
   }

   my $nds = _ele_nds($self,$ele,$raw);
   my $val = $NDS->value($nds,$path);
   if ($NDS->err()) {
      $$NDS{'err'}     = '';
      $$NDS{'errmsg'}  = '';
      $$self{'err'}    = 'nmeacc04';
      $$self{'errmsg'} = "The path does not exist in this element: $ele: $path";
      return undef;
   }

   my @val;
   if      (ref($val) eq 'HASH') {
      foreach my $k (sort keys %$val) {
         my $v  = $$val{$k};
         my $v2 = $v;
         $v2    = [$v2]  if (! ref($v2));
         push(@val,$k)  if ( (! $empty  &&  ! $NDS->empty($v2)) ||
                             $empty );
      }

   } elsif (ref($val) eq 'ARRAY') {
      for (my $i=0; $i<=$#$val; $i++) {
         my $v  = $$val[$i];
         my $v2 = $v;
         $v2    = [$v2]  if (! ref($v2));
         push(@val,$i)  if ( (! $empty  &&  ! $NDS->empty($v2))  ||
                             $empty );
      }

   } elsif (! defined($val)) {

   } else {
      $$self{'err'}    = 'nmeacc05';
      $$self{'errmsg'} = 'Keys method may not be used with a scalar path: ' .
        "$path";
   }

   return @val;
}

sub values {
   my($self,$ele,$path,$empty,$copy,$raw) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';
   $empty           = 0  if (! $empty);
   $copy            = 0  if (! $copy);
   $raw             = 0  if (! $raw);

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   my $NDS = $$self{'nds'};
   if (! $NDS->get_structure($path,'valid')) {
      $$self{'err'}    = 'nmeacc03';
      $$self{'errmsg'} = "Attempt to access data with an invalid path: $path";
      return undef;
   }

   my $nds = _ele_nds($self,$ele,$raw);
   my $val = $NDS->value($nds,$path);
   if ($NDS->err()) {
      $$NDS{'err'}     = '';
      $$NDS{'errmsg'}  = '';
      $$self{'err'}    = 'nmeacc04';
      $$self{'errmsg'} = "The path does not exist in this element: $ele: $path";
      return undef;
   }

   my @val;
   if      (ref($val) eq 'HASH') {
      foreach my $k (sort (CORE::keys %$val)) {
         my $v  = $$val{$k};
         my $v2 = $v;
         $v2    = [$v2]  if (! ref($v2));
         if ( (! $empty  &&  ! $NDS->empty($v2)) ||
              $empty ) {
            if ($copy  &&  ref($v)) {
               push(@val,dclone($v));
            } else {
               push(@val,$v);
            }
         }
      }

   } elsif (ref($val) eq 'ARRAY') {
      for (my $i=0; $i<=$#$val; $i++) {
         my $v  = $$val[$i];
         my $v2 = $v;
         $v2    = [$v2]  if (! ref($v2));
         if ( (! $empty  &&  ! $NDS->empty($v2)) ||
              $empty ) {
            if ($copy  &&  ref($v)) {
               push(@val,dclone($v));
            } else {
               push(@val,$v);
            }
         }
      }

   } elsif (! defined($val)) {

   } else {
      $$self{'err'}    = 'nmeacc06';
      $$self{'errmsg'} = 'Values method may not be used with a scalar path: ' .
        "$path";
   }

   return @val;
}

###############################################################################
# PATH_VALUES METHOD
###############################################################################

sub path_values {
   my($self,$path,$empty,$copy) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';
   my $NDS          = $$self{'nds'};

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   if (! $NDS->get_structure($path,'valid')) {
      $$self{'err'}    = 'nmeacc03';
      $$self{'errmsg'} = "Attempt to access data with an invalid path: $path";
      return;
   }

   my @eles;
   if ($empty) {
      @eles = $self->eles(1);
   } else {
      @eles = $self->eles();
   }

   my %ret;
   foreach my $ele (@eles) {

      my $nds = _ele_nds($self,$ele);
      my $val = $NDS->value($nds,$path,0,1);
      if ($NDS->err()) {
         $$NDS{'err'}     = '';
         $$NDS{'errmsg'}  = '';
         next;
      }

      $val = dclone($val)  if (ref($val)  &&  $copy);
      $ret{$ele} = $val;
   }

   return %ret;
}

###############################################################################
# PATH_IN_USE METHOD
###############################################################################

sub path_in_use {
   my($self,$path,$empty) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';
   my $NDS          = $$self{'nds'};

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   if (! $NDS->get_structure($path,'valid')) {
      $$self{'err'}    = 'nmeacc03';
      $$self{'errmsg'} = "Attempt to access data with an invalid path: $path";
      return undef;
   }

   my @eles;
   if ($empty) {
      @eles = $self->eles(1);
   } else {
      @eles = $self->eles();
   }

   foreach my $ele (@eles) {

      my $nds = _ele_nds($self,$ele);
      my $val = $NDS->value($nds,$path,0,1);
      if ($NDS->err()) {
         $$NDS{'err'}     = '';
         $$NDS{'errmsg'}  = '';
         next;
      }

      return 1  if (defined $val);
   }

   return 0;
}

###############################################################################
# DELETE_ELE METHOD
###############################################################################

sub delete_ele {
   my($self,$ele) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   # Test to see if the element exists.

   if (! _ele_exists($self,$ele)) {
      $$self{'err'}    = 'nmeele01';
      $$self{'errmsg'} = "The specified element does not exist: $ele";
      return;
   }

   #
   # Delete both the raw element and the full element.
   #

   _delete_ele($self,$ele);
   return;
}

# Deletes an element. By default, deletes it fully. If $leaveraw is
# passed in, it deletes only the constructed element.
#
sub _delete_ele {
   my($self,$ele,$leaveraw) = @_;

   if ($$self{'list'}  &&  $$self{'ordered'}) {

      #
      # Delete an ordered list element (leaves an undef placeholder).
      #

      $$self{'data'}[$ele] = undef  if (defined $$self{'data'}[$ele]);
      $$self{'raw'}[$ele]  = undef  if (defined $$self{'raw'}[$ele]  &&
                                        ! $leaveraw);

   } elsif ($$self{'list'}) {

      #
      # Delete an unordered list element (removes it entirely)
      #

      if ($#{ $$self{'data'} } >= $ele) {
         splice( @{ $$self{'data'} },$ele,1);
      }

      if (! $leaveraw) {
         splice( @{ $$self{'raw'} },$ele,1);
      }

   } else {

      #
      # Delete a hash element
      #

      delete $$self{'data'}{$ele};
      if (! $leaveraw) {
         delete $$self{'raw'}{$ele};
      }
   }

   $$self{'elesx'}      = undef;
   $$self{'elesxh'}     = {};
   $$self{'elesn'}      = undef;
   $$self{'elesnh'}     = undef;
}

###############################################################################
# RENAME_ELE METHOD
###############################################################################

sub rename_ele {
   my($self,$ele,$newele) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';
   return  if ($$self{'list'}  &&  ! $$self{'ordered'});

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   # Test to see if the element exists and new element doesn't (or is empty).

   if (! _ele_exists($self,$ele)) {
      $$self{'err'}    = 'nmeele01';
      $$self{'errmsg'} = "The specified element does not exist: $ele";
      return;
   }

   if (_ele_exists($self,$newele)  &&
       ! _ele_empty($self,$newele)) {
      $$self{'err'}    = 'nmeele02';
      $$self{'errmsg'} = "Attempt to overwrite an existing element: $newele";
      return;
   }

   #
   # Rename the raw and combined data elements, and the element list.
   #

   _rename_ele($self,$ele,$newele);
   return;
}

# Move an element from one name to another.  This will never be done
# with a list.
#
sub _rename_ele {
   my($self,$ele,$newele) = @_;

   # Move both the data and raw elements.

   if ($$self{'list'}) {
      if (defined $$self{'data'}[$ele]) {
         $$self{'data'}[$newele] = $$self{'data'}[$ele];
         $$self{'data'}[$ele]    = undef;
      }
      $$self{'raw'}[$newele]  = $$self{'raw'}[$ele];
      $$self{'raw'}[$ele]     = undef;

   } else {
      if (exists $$self{'data'}{$ele}) {
         $$self{'data'}{$newele} = $$self{'data'}{$ele};
         delete $$self{'data'}{$ele};
      }
      $$self{'raw'}{$newele}  = $$self{'raw'}{$ele};
      delete $$self{'raw'}{$ele};
   }

   $$self{'elesx'}      = undef;
   $$self{'elesxh'}     = {};
   $$self{'elesn'}      = undef;
   $$self{'elesnh'}     = undef;
}

###############################################################################
# ADD_ELE METHOD
###############################################################################

sub add_ele {
   my($self,@args) = @_;
   $$self{'err'}    = '';
   $$self{'errmsg'} = '';

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   # Parse arguments

   my($ele,$nds,$new);
   $ele = '';

   if ($$self{'list'}) {
      if ($args[0] =~ /^\d+$/) {
         ($ele,$nds,$new) = @args;
      } else {
         ($nds,$new) = @args;
      }

   } else {
      ($ele,$nds,$new) = @args;
   }

   # Check the structure

   my $NDS = $self->nds();
   $NDS->check_structure($nds,$new);
   if ($NDS->err()) {
      $$NDS{'err'}     = '';
      $$NDS{'errmsg'}  = '';
      $$self{'err'}    = 'nmends01';
      $$self{'errmsg'} = 'The NDS has an invalid structure.';
      return;
   }

   # Store the element

   _add_ele($self,$ele,$nds);
   return;
}

sub _add_ele {
   my($self,$ele,$nds) = @_;

   if ($$self{'list'}  &&  ! $$self{'ordered'}) {

      # For an unordered list
      #    If $ele is given
      #       It must refer to an existing element. Insert before it.
      #    Else
      #       Push onto the end.

      if ($ele) {

         if (! _ele_exists($self,$ele)) {
            $$self{'err'}    = 'nmeele04';
            $$self{'errmsg'} = 'Attempt to add element to an unordered list ' .
              "using a non-existant element: $ele";
            return;
         }
         _add_element_insert($self,$ele,$nds);

      } else {
         _add_element_push($self,$nds);
      }

   } elsif ($$self{'list'}) {

      # For an ordered list
      #    If $ele is given
      #       If the element exists
      #          If it is empty
      #             Put the new element there
      #          Else
      #             Insert it before that element
      #       Else
      #          Put the new element there
      #    Else
      #       Push onto the end.

      if ($ele) {

         if (_ele_exists($self,$ele)) {

            if (_ele_empty($self,$ele)) {
               _add_element_setlist($self,$ele,$nds);
            } else {
               _add_element_insert($self,$ele,$nds);
            }

         } else {
            _add_element_setlist($self,$ele,$nds);
         }

      } else {
         _add_element_push($self,$nds);
      }

   } else {

      # For a hash
      #    If $ele is given and it is empty
      #       Put the new element there
      #    Elsif $ele is given and it doesn't exist
      #       Put it there
      #    Else
      #       Error

      if ($ele  &&  _ele_empty($self,$ele)) {
         _add_element_sethash($self,$ele,$nds);
      } elsif ($ele  &&  ! _ele_exists($self,$ele)) {
         _add_element_sethash($self,$ele,$nds);
      } else {
         $$self{'err'}    = 'nmeele02';
         $$self{'errmsg'} = "Attempt to overwrite an existing element: $ele";
         return;
      }
   }

   $$self{'elesx'}      = undef;
   $$self{'elesxh'}     = {};
   $$self{'elesn'}      = undef;
   $$self{'elesnh'}     = undef;
}

sub _add_element_setlist {
   my($self,$ele,$nds) = @_;

   $$self{'raw'}[$ele] = $nds;
}

sub _add_element_insert {
   my($self,$ele,$nds) = @_;

   splice(@{ $$self{'raw'} },$ele,0,$nds);
   if ($#{ $$self{'data'} } >= $ele) {
      splice(@{ $$self{'data'} },$ele,0,undef);
   }
}

sub _add_element_push {
   my($self,$nds) = @_;

   my $n = $#{ $$self{'raw'} };
   $n++;
   _add_element_setlist($self,$n,$nds);
}

sub _add_element_sethash {
   my($self,$ele,$nds) = @_;

   $$self{'raw'}{$ele}  = $nds;
}

###############################################################################
# UPDATE_ELE METHOD
###############################################################################

sub update_ele {
   my($self,$ele,$path,$val,$new,$ruleset) = @_;

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   # Check to make sure $ele is valid (it need only exist)

   if (! _ele_exists($self,$ele)) {
      $$self{'err'}    = 'nmeele01';
      $$self{'errmsg'} = "The specified element does not exist: $ele";
      return;
   }

   # If $val is not passed in, erase the path.

   my $NDS = $self->nds();
   my $nds = $$self{'raw'}{$ele};

   if (! defined $val) {
      $NDS->erase($nds,$path);
      if ($NDS->err()) {
         $$NDS{'err'}     = '';
         $$NDS{'errmsg'}  = '';
         $$self{'err'}    = 'nmends02';
         $$self{'errmsg'} = "Problem encountered while erasing a path: $path";
      }

   } else {

      # Check new/ruleset values

      if (! defined $ruleset  &&
          defined $new  &&
          $NDS->ruleset_valid($new)) {
         $ruleset = $new;
         $new = '';
      }

      $ruleset = 'replace'  if (! $ruleset);

      # Merge in the new value

      if (! $NDS->ruleset_valid($ruleset)) {
         $$self{'err'}    = 'ndserr01';
         $$self{'errmsg'} = "An invalid ruleset was passed in: $ruleset";
         return;
      }

      $NDS->merge_path($nds,$val,$path,$ruleset,$new);

      if ($NDS->err()) {
         $$NDS{'err'}     = '';
         $$NDS{'errmsg'}  = '';
         $$self{'err'}    = 'nmends03';
         $$self{'errmsg'} = 'The value had an invalid structure.';
         return;
      }
   }

   # Update status information

   $$self{'elesx'}      = undef;
   $$self{'elesxh'}     = {};
   $$self{'elesn'}      = undef;
   $$self{'elesnh'}     = undef;

   if ($$self{'list'}) {
      $$self{'data'}[$ele] = undef;
   } else {
      delete $$self{'data'}{$ele};
   }
}

###############################################################################
# COPY_ELE METHOD
###############################################################################

sub copy_ele {
   my($self,$ele,$newele) = @_;

   if (! $$self{'file'}) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   # Check to make sure $ele is valid (it need only exist)

   if (! _ele_exists($self,$ele)) {
      $$self{'err'}    = 'nmeele01';
      $$self{'errmsg'} = "The specified element does not exist: $ele";
      return;
   }

   # Get the structure there.

   my $nds = dclone(_ele_nds($self,$ele,1));
   _add_ele($self,$newele,$nds);
}

###############################################################################
# DUMP METHOD
###############################################################################

sub dump {
   my($self,$ele,$path,%opts) = @_;

   my $NDS = $$self{'nds'};
   my $nds = _ele_nds($self,$ele);
   if ($path) {
      $nds = $NDS->value($nds,$path);
   }
   return $NDS->print($nds,%opts);
}

###############################################################################
# SAVE METHOD
###############################################################################

sub save {
   my($self,$nobackup) = @_;
   my $file            = $$self{'file'};
   if (! $file) {
      $$self{'err'}    = 'nmefil06';
      $$self{'errmsg'} = 'No file set.';
      return;
   }

   # Backup file

   if (! $nobackup) {
      if (! rename($file,"$file.bak")) {
         $$self{'err'}    = 'nmefil07';
         $$self{'errmsg'} = "Unable to backup data file: $!";
         return undef;
      }
   }

   # The data that must be stored consists of the defaults and
   # the current raw data.

   my $data;
   if ($$self{'list'}) {
      my(@ele);
      foreach my $def (@{ $$self{'def'} }) {
         push(@ele,$$def[0]);
      }
      push(@ele,@{ $$self{'raw'} });
      $data   = \@ele;

   } else {
      my(%ele);
      foreach my $def (@{ $$self{'def'} }) {
         $ele{$$def[0]} = $$def[1];
      }
      foreach my $key (CORE::keys %{ $$self{'raw'} }) {
         $ele{$key} = $$self{'raw'}{$key};
      }
      $data = \%ele;
   }

   # Write data

   my $out = new IO::File;
   if (! $out->open(">$file")) {
      $$self{'err'}    = 'nmefil08';
      $$self{'errmsg'} = "Unable to write data file: $!";
      return undef;
   }

   print $out Dump($data);
   $out->close();
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

package Data::Nested::Multifile;
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
use Data::Nested::Multiele;
use Storable qw(dclone);

use vars qw($VERSION);
$VERSION = "3.12";

###############################################################################
# BASE METHODS
###############################################################################
#
# $NDS   always refers to a Data::Nested object
# $NME   always refers to a Data::Nested::Multiele object
# $nds   always refers to an actual NDS
# $ele   always refers to an element name/index
# $self  always refers to a Data::Nested::Multiele object

sub new {
   my(@args) = @_;

   # Get the Data::Nested object (if any).

   my $class = "Data::Nested::Multifile";
   my $NDS   = undef;

   if (@args  &&  ref($args[0]) eq $class) {
      # $obj = $self->new;

      my $self = shift(@args);
      $NDS     = $self->nds();

   } elsif (@args  &&  $args[0] eq $class) {
      # $obj = new Data::Nested::Multifile [NDS];

      shift(@args);
      if (@args &&  ref($args[0]) eq "Data::Nested") {
         $NDS  = shift(@args);
      } else {
         $NDS  = new Data::Nested;
      }

   } else {
      warn "ERROR: [new] first argument must be a $class class/object\n";
      return undef;
   }

   # Get the label/file args (if any)

   my @file = @args;

   my $self = {
               "nds"       => $NDS,  # Data::Nested object
               "file"      => undef, # LABEL => Data::Nested::Multiele
               "labels"    => [],    # The order the labels are read in
               "list"      => "",    # 1 if data is a list
               "err"       => "",
               "errmsg"    => "",
               "elesx"     => undef, # Existing elements
               "elesn"     => undef, # Non-empty elements
               "eles"      => {},    # [ LABEL, FILE_ELE ]
                                     # Which file an element is in, and
                                     # the element in that file (this
                                     # differs for lists)
              };
   bless $self, $class;

   if (@file) {
      $self->file(@file);
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

   return $$self{"nds"};
}

sub err {
   my($self) = @_;

   return $$self{"err"};
}

sub errmsg {
   my($self) = @_;

   return $$self{"errmsg"};
}

sub nme {
   my($self,$label) = @_;

   return $$self{"file"}{$label}  if (exists $$self{"file"}{$label});
   return undef;
}

###############################################################################
# FILE METHODS
###############################################################################

sub file {
   my($self,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (defined $$self{"elesx"}) {
      $$self{"err"}    = "nmffil07";
      $$self{"errmsg"} = "An attempt to read in a file after element operations " .
        "have been done";
      return;
   }

   $$self{"file"} = {}  if (! defined $$self{"file"});

   if ($#args == 0  ||
       $#args % 2 == 0) {
      $$self{"err"}    = "nmffil01";
      $$self{"errmsg"} = "An even number of arguments required to specify " .
        "files";
      return;
   }

   my $NDS = $self->nds();

   while (@args) {
      my $label = shift(@args);
      my $file  = shift(@args);

      # Check the label

      if (exists $$self{"file"}{$label}) {
         $$self{"err"}    = "nmffil02";
         $$self{"errmsg"} = "An attempt to reuse a file label already in " .
           "use: $label";
         return;
      }

      # Create a Data::Nested::Multiele object for the file

      my $obj   = new Data::Nested::Multiele($NDS,$file);

      if (! defined $obj) {
         $$self{"err"}    = "nmffil03";
         $$self{"errmsg"} = "An error occurred reading the data file: $file";
         return;
      }

      # Check to see that all files contain either lists or hashes

      if ($$self{"list"} eq "") {
         $$self{"list"} = $$obj{"list"};
      } elsif ($$self{"list"} != $$obj{"list"}) {
         $$self{"err"}    = "nmffil04";
         $$self{"errmsg"} = "All files must contain the same type of data: " .
           "$file";
         return;
      }

      # Save the label

      $$self{"file"}{$label} = $obj;
      push(@{ $$self{"labels"} },$label);

      my $err = _eles_label($self,$label);
      return  if ($err);
   }
}

###############################################################################
# ELEMENT EXISTANCE METHODS
###############################################################################

# Get the elements that are in a given label (that is being read in).
#
sub _eles_label {
   my($self,$label) = @_;

   my $NME = $$self{"file"}{$label};

   my @elesx = $NME->eles(1);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg() . ": $label";
      return 1;
   }

   my $i0;
   if ($$self{"list"}) {
      my @tmp = CORE::keys %{ $$self{"eles"} };
      if (@tmp) {
         @tmp = sort { $a <=> $b } @tmp;
         $i0  = pop(@tmp) + 1;
      } else {
         $i0 = 0;
      }
   }

   foreach my $ele (@elesx) {
      my $e = $ele;
      $e = $ele + $i0  if ($$self{"list"});

      if (exists $$self{"eles"}{$e}) {
         my $other        = $$self{"eles"}{$e}[0];
         $$self{"err"}    = "nmffil05";
         $$self{"errmsg"} = "A data element is duplicated in 2 files: " .
           "$ele [$other, $label]";
         return 1;
      }

      if ($$self{"list"}) {
         $$self{"eles"}{$e} = [$label,$ele];
      } else {
         $$self{"eles"}{$e} = [ $label,$ele ];
      }
   }
}

# If $op is:
#   ""       Get all the elements from all the labels.
#   exists   Get all elements that exist
#   nonempty Get all nonempty elements
#
sub _eles {
   my($self,$op) = @_;
   $op = ""  if (! $op);

   if ($op eq "exists") {
      return  if (defined $$self{"elesx"});
      my @tmp = CORE::keys %{ $$self{"eles"} };
      if ($$self{"list"}) {
         $$self{"elesx"} = [ sort { $a <=> $b } @tmp ];
      } else {
         $$self{"elesx"} = [ sort @tmp ];
      }

   } elsif ($op eq "nonempty") {

      if ($$self{"list"}) {
         my @tmp;
         my $n = 0;
         foreach my $label (@{ $$self{"labels"} }) {
            my $NME  = $$self{"file"}{$label};
            my @tmp2 = $NME->eles();
            push(@tmp,map { $_+$n } @tmp2);
            @tmp2    = $NME->eles(1);
            $n      += $#tmp2 + 1;
         }
         $$self{"elesn"} = [ @tmp ];

      } else {
         my @tmp;
         foreach my $label (@{ $$self{"labels"} }) {
            my $NME = $$self{"file"}{$label};
            push(@tmp,$NME->eles());
         }
         $$self{"elesn"} = [ sort @tmp ];
      }

   } else {
      $$self{"elesx"} = undef;
      $$self{"elesn"} = undef;
      $$self{"eles"}  = {};
      foreach my $label (@{ $$self{"labels"} }) {
         my $err = _eles_label($self,$label);
         return  if ($err);
      }
   }
}

sub eles {
   my($self,$exists) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   if ($exists) {
      _eles($self,"exists");
      return @{ $$self{"elesx"} };
   } else {
      _eles($self,"nonempty");
      return @{ $$self{"elesn"} };
   }
}

sub ele {
   my($self,$ele,$exists) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   return 0  if (! exists $$self{"eles"}{$ele});
   return 1  if ($exists);

   my($label,$fele) = @{ $$self{"eles"}{$ele} };
   my $NME          = $$self{"file"}{$label};

   my $ret          = $NME->ele($fele,$exists);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg() . ": $label";
      return undef;
   }

   return $ret;
}

sub ele_file {
   my($self,$ele) = @_;

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   if (! $self->ele($ele)) {
      $$self{"err"}    = "nmfele01";
      $$self{"errmsg"} = "The specified element does not exist: $ele";
      return "";
   }

   return $$self{"eles"}{$ele}[0];
}

sub _ele_nme {
   my($self,$ele) = @_;

   if (! $self->ele($ele)) {
      $$self{"err"}    = "nmfele01";
      $$self{"errmsg"} = "The specified element does not exist: $ele";
      return "";
   }

   my $label = $$self{"eles"}{$ele}[0];
   my $fele  = $$self{"eles"}{$ele}[1];
   return ($$self{"file"}{$label},$fele);
}

###############################################################################
# DEFAULT METHODS
###############################################################################

sub default_element {
   my($self,@args)  = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   # Any element which works with the data will have set "elesx", so if
   # it is set, the operation fails.

   if (defined $$self{"elesx"}) {
      $$self{"err"}    = "nmedef09";
      $$self{"errmsg"} = "Defaults must be set immediately after the filef " .
                         "are read in.";
      return;
   }

   # Get the Multiele object containing the default.

   my $label;
   if ($$self{"list"}) {
      #
      # Lists = (LABEL [RULESET] [PATH,VAL,...])
      #
      $label = shift(@args);
      if (! exists $$self{"file"}{$label}) {
         $$self{"err"}    = "nmffil06";
         $$self{"errmsg"} = "An invalid file label was used: $label";
         return undef;
      }

   } else {
      #
      # Hashes = (ELE [RULESET] [PATH,VAL,...])
      #
      my $ele = $args[0];
      if (! exists $$self{"eles"}{$ele}) {
         $$self{"err"}    = "nmfele01";
         $$self{"errmsg"} = "Attempt to access an undefined element: $ele";
         return undef;
      }
      $label = $$self{"eles"}{$ele}[0];
   }

   my $NME = $$self{"file"}{$label};

   # Handle the default.

   $NME->default_element(@args);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg() . ": $label";
      return undef;
   }

   _eles($self);
}

sub is_default_value {
   my($self,$ele,$path) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   if (! $self->ele($ele,1)) {
      $$self{"err"}    = "nmfele01";
      $$self{"errmsg"} = "The specified element does not exist: $ele";
      return;
   }

   if (! $self->path_valid($path)) {
      $$self{"err"}    = "nmeacc03";
      $$self{"errmsg"} = "Attempt to access data with an invalid path: $path";
      return undef;
   }

   my($label,$fele) = @{ $$self{"eles"}{$ele} };
   my $NME          = $$self{"file"}{$label};

   my $ret          = $NME->is_default_value($fele,$path);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg() . ": $label";
      return undef;
   }

   return $ret;
}

###############################################################################
# WHICH METHOD
###############################################################################

sub which {
   my($self,@cond)  = @_;

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   if ($$self{"list"}) {
      return _which_list($self,@cond);
   } else {
      return _which_hash($self,@cond);
   }
}

sub _which_list {
   my($self,@cond)  = @_;

   my @ele = ();
   my $n   = 0;
   foreach my $label (@{ $$self{"labels"} }) {
      my $NME = $$self{"file"}{$label};

      my @tmp = $NME->which(@cond);
      if ($NME->err()) {
         $$self{"err"}    = $NME->err();
         $$self{"errmsg"} = $NME->errmsg() . ": $label";
         return ();
      }

      push @ele, map { $_ + $n } @tmp;

      @tmp = $NME->eles(1);
      $n  += $#tmp + 1;
   }

   return @ele;
}

sub _which_hash {
   my($self,@cond)  = @_;

   my @ele = ();
   while (my($label,$NME) = each %{ $$self{"file"} }) {
      my @tmp = $NME->which(@cond);
      if ($NME->err()) {
         $$self{"err"}    = $NME->err();
         $$self{"errmsg"} = $NME->errmsg() . ": $label";
         return ();
      }
      push(@ele,@tmp);
   }
   @ele = sort @ele;
   return @ele;
}

###############################################################################
# PATH_VALID METHOD
###############################################################################

sub path_valid {
   my($self,$path) = @_;
   my $NDS = $$self{"nds"};

   return $NDS->get_structure($path,"valid");
}

###############################################################################
# VALUE, KEYS, VALUES METHODS
###############################################################################

sub value {
   my($self,$ele,$path,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   my $NME;
   ($NME,$ele) = _ele_nme($self,$ele);
   return undef  if ($self->err());

   my $val = $NME->value($ele,$path,@args);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg();
      return undef;
   }

   return $val;
}

sub keys {
   my($self,$ele,$path,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   my $NME;
   ($NME,$ele) = _ele_nme($self,$ele);
   return undef  if ($self->err());

   my @val = $NME->keys($ele,$path,@args);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg();
      return undef;
   }

   return @val;
}

sub values {
   my($self,$ele,$path,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   my $NME;
   ($NME,$ele) = _ele_nme($self,$ele);
   return undef  if ($self->err());

   my @val = $NME->values($ele,$path,@args);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg();
      return undef;
   }

   return @val;
}

###############################################################################
# PATH_VALUES METHOD
###############################################################################

sub path_values {
   my($self,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   my @ret;

   my $prev         = 0;
   foreach my $label (@{ $$self{"labels"} }) {
      my $NME = $$self{"file"}{$label};

      my @tmp = $NME->path_values(@args);
      if ($NME->err()) {
         $$self{"err"}    = $NME->err();
         $$self{"errmsg"} = $NME->errmsg() . ": $label";
         return ();
      }

      if ($$self{"list"}) {
         while (@tmp) {
            my $e = shift(@tmp);
            my $v = shift(@tmp);
            push(@ret,$e+$prev,$v);
         }
         my @ele = $NME->eles(1);
         $prev += $#ele + 1;
      } else {
         push(@ret,@tmp);
      }
   }

   return @ret;
}

###############################################################################
# PATH_IN_USE METHOD
###############################################################################

sub path_in_use {
   my($self,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   my @ret;

   my $prev         = 0;
   foreach my $label (@{ $$self{"labels"} }) {
      my $NME  = $$self{"file"}{$label};

      my $flag = $NME->path_in_use(@args);
      if ($NME->err()) {
         $$self{"err"}    = $NME->err();
         $$self{"errmsg"} = $NME->errmsg() . ": $label";
         return undef;
      }

      return 1  if ($flag);
   }

   return 0;
}

###############################################################################
# DELETE_ELE METHOD
###############################################################################

sub delete_ele {
   my($self,$ele) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   my $NME;
   ($NME,$ele) = _ele_nme($self,$ele);
   return undef  if ($self->err());

   $NME->delete_ele($ele);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg();
      return undef;
   }

   _eles($self);
   return;
}

###############################################################################
# RENAME_ELE METHOD
###############################################################################

sub rename_ele {
   my($self,$ele,$newele) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   my $NME;
   ($NME,$ele) = _ele_nme($self,$ele);
   return undef  if ($self->err());

   $NME->rename_ele($ele,$newele);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg();
      return undef;
   }

   _eles($self);
   return;
}

###############################################################################
# ADD_ELE METHOD
###############################################################################

sub add_ele {
   my($self,@args) = @_;

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   if ($$self{"list"}) {
      return _add_ele_list($self,@args);
   } else {
      return _add_ele_hash($self,@args);
   }
}

sub _add_ele_list {
   my($self,@args) = @_;

   # Parse arguments

   my($label,$ele,$nds,$new);
   $ele = "";

   if ($#args == 0) {
      # $nds
      ($nds) = @args;

   } elsif ($#args == 1) {
      # $nds,$new
      # $ele,$nds
      # $label,$nds

      if (exists $$self{"file"}{$args[0]}) {
         ($label,$nds) = @args;
      } elsif (ref($args[0])) {
         ($nds,$new) = @args;
      } else {
         ($ele,$nds) = @args;
      }

   } elsif ($#args == 2) {
      # $ele,$nds,$new
      # $label,$nds,$new
      if (exists $$self{"file"}{$args[0]}) {
         ($label,$nds,$new) = @args;
      } else {
         ($ele,$nds,$new) = @args;
      }

   } else {
      die "ERROR: add_ele: unknown arguments: @args\n";
   }

   # Check each argument

   if ($label  &&  ! exists $$self{"file"}{$label}) {
      $$self{"err"}    = "nmffil06";
      $$self{"errmsg"} = "An invalid file label was used: $label";
      return undef;
   }

   if ($ele ne ""  &&  ! exists $$self{"eles"}{$ele}) {
      $$self{"err"}    = "nmfele01";
      $$self{"errmsg"} = "Attempt to access an undefined element: $ele";
      return undef;
   }

   # Add the element

   my $NME;
   my @a;
   if ($label) {
      # Push onto list of the given file
      @a = ($nds);

   } elsif ($ele ne "") {
      # Insert into the list at $ele

      my($fele);
      ($label,$fele) = @{ $$self{"eles"}{$ele} };
      @a = ($fele,$nds);

   } else {
      # Push onto the last file.
      $label = $$self{"labels"}[ $#{ $$self{"labels"} } ];
      @a = ($nds);
   }

   $NME = $$self{"file"}{$label};
   $NME->add_ele(@a);

   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg();
      return undef;
   }

   _eles($self);
   return;
}

sub _add_ele_hash {
   my($self,@args) = @_;

   # Parse arguments

   my($label,$ele,$nds,$new);
   if (exists $$self{"file"}{$args[0]}) {
      ($label,$ele,$nds,$new) = @args;
   } else {
      ($ele,$nds,$new) = @args;
      $label = $$self{"labels"}[ $#{ $$self{"labels"} } ];
   }

   # Check each argument

   if (ref($ele)) {
      $$self{"err"}    = "nmfele04";
      $$self{"errmsg"} = "When adding an element, a name must be given.";
      return undef;
   }

   if (! exists $$self{"file"}{$label}) {
      $$self{"err"}    = "nmffil06";
      $$self{"errmsg"} = "An invalid file label was used: $label";
      return undef;
   }

   if ($ele eq "") {
      $$self{"err"}    = "nmfele03";
      $$self{"errmsg"} = "When accessing a hash element, a name must be given.";
      return undef;
   }

   if (exists $$self{"eles"}{$ele}) {
      $$self{"err"}    = "nmfele02";
      $$self{"errmsg"} = "Attempt to overwrite an existing element: $ele";
      return undef;
   }

   # Add the element

   my $NME = $$self{"file"}{$label};
   $NME->add_ele($ele,$nds);

   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg();
      return undef;
   }

   _eles($self);
   return;
}

###############################################################################
# COPY_ELE METHOD
###############################################################################

sub copy_ele {
   my($self,$ele,@args) = @_;

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   # Check to make sure $ele is valid (it need only exist)

   if (! $self->ele($ele)) {
      $$self{"err"}    = "nmfele01";
      $$self{"errmsg"} = "The specified element does not exist: $ele";
      return "";
   }

   # Get the structure there.

   my $file = $self->ele_file($ele);
   my $NME  = (_ele_nme($self,$ele))[0];
   my $nds  = dclone($NME->_ele_nds($ele,1));

   if (! @args  ||  ! exists $$self{"file"}{$args[0]}) {
      # The first argument is not a label, so prepend the label of the
      # original element.
      unshift(@args,$file);
   }

   add_ele($self,@args,$nds);
}

###############################################################################
# UPDATE_ELE METHOD
###############################################################################

sub update_ele {
   my($self,$ele,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   my $NME;
   ($NME,$ele) = _ele_nme($self,$ele);
   return undef  if ($self->err());

   $NME->update_ele($ele,@args);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg();
      return undef;
   }

   _eles($self);
   return;
}

###############################################################################
# DUMP METHOD
###############################################################################

sub dump {
   my($self,$ele,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   my $NME;
   ($NME,$ele) = _ele_nme($self,$ele);
   return undef  if ($self->err());

   my $ret = $NME->dump($ele,@args);
   if ($NME->err()) {
      $$self{"err"}    = $NME->err();
      $$self{"errmsg"} = $NME->errmsg();
      return undef;
   }
   return $ret;
}

###############################################################################
# SAVE METHOD
###############################################################################

sub save {
   my($self,$nobackup) = @_;

   if (! defined $$self{"file"}) {
      $$self{"err"}    = "nmffil08";
      $$self{"errmsg"} = "No file set.";
   }

   while (my($label,$NME) = each %{ $$self{"file"} }) {
      $NME->save($nobackup);
      if ($NME->err()) {
         $$self{"err"}    = $NME->err();
         $$self{"errmsg"} = $NME->errmsg() . ": $label";
         return undef;
      }
   }
   return;
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

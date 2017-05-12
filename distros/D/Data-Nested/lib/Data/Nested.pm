package Data::Nested;
# Copyright (c) 2008-2010 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################
# TODO
########################################################################

# If no structural information is kept, merge methods can only
# keep/replace/append for lists but unordered non-uniform lists
# are allowed.

# When specifying structure, /foo/* forces uniform if it is not
# already specified as non-uniform. If a structure is uniform,
# then applying structure to /foo/1 is equivalent to /foo/* (but
# a warning may be issued).

# Add validity tests for data
# see Data::Domain, Data::Validator

# Add subtract (to remove items in one NDS from another)
# see Data::Validate::XSD
# treats all lists as ordered... it's simply too complicated
# otherwise

# Add clean (to remove empty paths)
#    a hash key with a value of undef should be deleted
#    a list element with a value of undef should be deleted if unordered
#    a list consisting of only undefs should be deleted (and fix parent)
#    a hash with no keys should be deleted (and fix parent)

########################################################################

require 5.000;
use strict;
use Storable qw(dclone);
use Algorithm::Permute;
use IO::File;
use warnings;

use vars qw($VERSION);
$VERSION = "3.12";

use vars qw($_DBG $_DBG_INDENT $_DBG_OUTPUT $_DBG_FH $_DBG_POINT);
$_DBG        = 0;
$_DBG_INDENT = 0;
$_DBG_OUTPUT = "dbg.out";
$_DBG_FH     = ();
$_DBG_POINT  = 0;

###############################################################################
# BASE METHODS
###############################################################################
#
# The Data::Nested object is a hash of the form:
#
# { warn      => FLAG                                    whether to warn
#   delim     => DELIMITER                               the path delimiter
#   nds       => { NAME       => NDS }                   named NDSes
#   structure => FLAG                                    whether to do structure
#   blank     => FLAG                                    whether the empty
#                                                        string is treated as
#                                                        a keepable value when
#                                                        merging
#   struct    => { PATH       => { ITEM => VAL } }       structural information
#   defstruct => { ITEM       => VAL }                   default structure
#   ruleset   => { RULESET    => { def  => { ITEM => VAL },
#                                  path => { PATH => VAL } } }
#                                                        default and path
#                                                        specific ruleset
#                                                        merge methods
#   cache     => {...}                                   cached information
# }

sub new {
   my($class) = @_;

   my $self = {
               "warn"      => 0,
               "delim"     => "/",
               "nds"       => {},
               "structure" => 1,
               "blank"     => 0,
               "struct"    => {},
               "defstruct" => {},
               "ruleset"   => {},
               "err"       => "",
               "errmsg"    => "",
              };
   bless $self, $class;
   _structure_defaults($self);
   _merge_defaults($self);

   return $self;
}

sub version {
   my($self) = @_;

   return $VERSION;
}

sub no_structure {
   my($self) = @_;

   $$self{"structure"} = 0;
}

sub blank {
   my($self,$val) = @_;

   $$self{"blank"} = $val;
}

sub err {
   my($self) = @_;

   return $$self{"err"};
}

sub errmsg {
   my($self) = @_;

   return $$self{"errmsg"};
}

###############################################################################
# PATH METHODS
###############################################################################

sub delim {
   my($self,$delim) = @_;
   if (! defined $delim) {
      return $$self{"delim"};
   }
   $$self{"delim"} = $delim;
}

{
   my %path = ();

   sub path {
      my($self,$path) = @_;
      my $array       = wantarray;

      if ($array) {
         return @$path            if (ref($path));
         return ()                if (! $path);
         return @{ $path{$path} } if (exists $path{$path});

         my($delim)   = $self->delim();
         my @tmp      = split(/\Q$delim\E/,$path);
         shift(@tmp)  if (! defined($tmp[0])  ||  $tmp[0] eq "");
         $path{$path} = [ @tmp ];
         return @tmp;

      } else {
         my($delim)   = $self->delim();
         if (! ref($path)) {
            return $delim    if (! $path);
            return $path;
         }
         return $delim . join($delim,@$path);
      }
   }
}

###############################################################################
# RULESET METHODS
###############################################################################

sub ruleset {
   my($self,$name) = @_;
   $$self{"err"}   = "";

   if ($name eq "keep"     ||
       $name eq "replace"  ||
       $name eq "default"  ||
       $name eq "override") {
      $$self{"err"}    = "ndsrul03";
      $$self{"errmsg"} = "Unable to create a ruleset using a reserved name " .
        "[$name]";
      return;
   }

   if ($name !~ /^[a-zA-Z0-9]+$/) {
      $$self{"err"}    = "ndsrul01";
      $$self{"errmsg"} = "A non-alphanumeric character used in a ruleset name" .
        "[$name]";
      return;
   }

   if (exists $$self{"ruleset"}{$name}) {
      $$self{"err"}    = "ndsrul02";
      $$self{"errmsg"} = "Attempt to create ruleset for a name already in use" .
        " [$name].";
      return;
   }

   $$self{"ruleset"}{$name} = { "def"  => {},
                                "path" => {} };
   return;
}

sub ruleset_valid {
   my($self,$name) = @_;
   return 1  if (exists $$self{"ruleset"}{$name});
   return 0;
}

###############################################################################
# NDS METHODS
###############################################################################

# This takes $nds (which may be an NDS, or the name of a stored NDS)
# and it returns the actual NDS referred to, or undef if there is a
# problem.
#
# If $new is passed in, new structure is allowed.
# If $copy is passed in, a copy of the NDS is returned.
# If $nocheck is passed in, no structural check is done.
#
sub _nds {
   my($self,$nds,$new,$copy,$nocheck) = @_;

   if (! defined($nds)) {
      return undef;

   } elsif (ref($nds)) {
      if ($$self{"structure"}  &&  ! $nocheck) {
         _check_structure($self,$nds,$new,());
         return undef if ($self->err());
      }
      if ($copy) {
         return dclone($nds);
      } else {
         return $nds;
      }

   } elsif (exists $$self{"nds"}{$nds}) {
      if ($copy) {
         return dclone($$self{"nds"}{$nds});
      } else {
         return $$self{"nds"}{$nds};
      }
   } else {
      $$self{"err"}    = "ndsnam01";
      $$self{"errmsg"} = "No NDS stored under the name [$nds]";
      return undef;
   }
}

sub nds {
   my($self,$name,$nds,$new) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   #
   # $obj->nds($name);
   # $obj->nds($name,"_copy");
   #

   if (! defined $nds  ||  $nds eq "_copy") {
      if (exists $$self{"nds"}{$name}) {
         if (defined $nds  &&  $nds eq "_copy") {
            return dclone($$self{"nds"}{$name});
         } else {
            return $$self{"nds"}{$name};
         }
      } else {
         return undef;
      }
   }

   #
   # $obj->nds($name,"_delete");
   #

   if ($nds eq "_delete") {
      delete $$self{"nds"}{$name}, return 1
        if (exists $$self{"nds"}{$name});
      return 0;
   }

   #
   # $obj->nds($name,"_exists");
   #

   if ($nds eq "_exists") {
      return 1  if (exists $$self{"nds"}{$name});
      return 0;
   }

   #
   # $obj->nds($name,$nds);
   # $obj->nds($name,$nds,$new);
   #

   if (exists $$self{"nds"}{$name}) {
      $$self{"err"}    = "ndsnam02";
      $$self{"errmsg"} = "Attempt to copy NDS to a name already in use [$name]";
      return undef;
   }

   if (ref($nds)) {
      $self->check_structure($nds,$new);
      return undef if ($self->err());
      $$self{"nds"}{$name} = $nds;
      return undef;

   } elsif (exists $$self{"nds"}{$nds}) {
      $$self{"nds"}{$name} = dclone($$self{"nds"}{$nds});
      return undef;

   } else {
      $$self{"err"}    = "ndsnam01";
      $$self{"errmsg"} = "No NDS stored under the name [$nds]";
      return undef;
   }
}

sub empty {
   my($self,$nds) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";
   return 1  if (! defined $nds);

   $nds = _nds($self,$nds,0,0,1);
   return undef  if ($self->err());

   return _empty($self,$nds);
}

sub _empty {
   my($self,$nds) = @_;

   if (! defined $nds) {
      return 1;

   } elsif (ref($nds) eq "ARRAY") {
      foreach my $ele (@$nds) {
         return 0  if (! _empty($self,$ele));
      }
      return 1;

   } elsif (ref($nds) eq "HASH") {
      foreach my $key (keys %$nds) {
         return 0  if (! _empty($self,$$nds{$key}));
      }
      return 1;

   } elsif ($nds eq "") {
      return 0  if ($$self{"blank"});
      return 1;

   } else {
      return 0;
   }
}

###############################################################################
# GET_STRUCTURE
###############################################################################
# Retrieve structural information for a path. Makes use of the default
# structural information.

sub get_structure {
   my($self,$path,$info) = @_;
   $$self{"err"}         = "";
   $$self{"errmsg"}      = "";
   $info                 = "type"  if (! defined $info  ||  ! $info);

   if (exists $$self{"cache"}{"get_structure"}{$path}  &&
       exists $$self{"cache"}{"get_structure"}{$path}{$info}) {
      return $$self{"cache"}{"get_structure"}{$path}{$info};
   }

   # Split the path so that we can convert all elements into "*" when
   # appropriate.

   my @path = $self->path($path);
   my @p    = ();
   my $p    = "/";
   if (! exists $$self{"struct"}{$p}) {
      $$self{"err"}         = "ndschk03";
      $$self{"errmsg"}      = "No structural information available at all.";
      return "";
   }

   while (@path) {
      my $ele = shift(@path);
      my $p1  = $self->path([@p,"*"]);
      my $p2  = $self->path([@p,$ele]);
      if (exists $$self{"struct"}{$p1}) {
         push(@p,"*");
         $p = $p1;
      } elsif (exists $$self{"struct"}{$p2}) {
         push(@p,$ele);
         $p = $p2;
      } else {
         return 0  if ($info eq "valid");
         $$self{"err"}    = "ndschk04";
         $$self{"errmsg"} = "Invalid path: $p2";
         return "";
      }
   }

   # Return the information about the path.

   if ($info eq "valid") {
      $$self{"cache"}{"get_structure"}{$path}{$info} = 1;
      return 1;
   }

   if (exists $$self{"struct"}{$p}{$info}) {
      my $val = $$self{"struct"}{$p}{$info};
      $$self{"cache"}{"get_structure"}{$path}{$info} = $val
        if ( ($info eq "type"  &&  $val =~ /^(hash|list|scalar|other)$/)  ||
             $info eq "uniform"  ||
             $info eq "ordered");
      return $val;
   }

   if (! exists $$self{"struct"}{$p}{"type"}) {
      $$self{"err"}    = "ndschk05";
      $$self{"errmsg"} = "It is not known what type of data is stored at " .
        "path: $p";
      return ""
   }

   my $type = $$self{"struct"}{$p}{"type"};

   if      ($info eq "ordered") {
      if ($type ne "list") {
         $$self{"err"}    = "ndschk06";
         $$self{"errmsg"} = "Ordered information requested for a non-list " .
           "structure: $p";
         return "";
      }
      return $$self{"defstruct"}{"ordered"};

   } elsif ($info eq "uniform") {
      if      ($type eq "hash") {
         return $$self{"defstruct"}{"uniform_hash"};
      } elsif ($type eq "list") {
         my $ordered = $self->get_structure($p,"ordered");
         if ($ordered) {
            return $$self{"defstruct"}{"uniform_ol"};
         } else {
            return 1;
         }

      } else {
         $$self{"err"}    = "ndschk07";
         $$self{"errmsg"} = "Uniform information requested for a scalar " .
           "structure: $p";
         return "";
      }

   } elsif ($info eq "merge") {
      if ($type eq "list") {
         my $ordered = $self->get_structure($p,"ordered");
         if ($ordered) {
            return $$self{"defstruct"}{"merge_ol"};
         } else {
            return $$self{"defstruct"}{"merge_ul"};
         }

      } elsif ($type eq "hash") {
         return $$self{"defstruct"}{"merge_hash"};

      } else {
         return $$self{"defstruct"}{"merge_scalar"};
      }

   } elsif ($info eq "keys") {
      if ($type ne "hash") {
         $$self{"err"}    = "ndschk08";
         $$self{"errmsg"} = "Keys requested for a non-hash structure: $p";
         return "";
      }

      if (exists $$self{"struct"}{$p}{"uniform"}  &&
          $$self{"struct"}{$p}{"uniform"}) {
         $$self{"err"}    = "ndschk09";
         $$self{"errmsg"} = "Keys requested for a uniform hash structure: $p";
         return "";
      }

      my @keys = ();
    PP: foreach my $pp (CORE::keys %{ $$self{"struct"} }) {
         # Look for paths of the form: $p/KEY
         my @pp = $self->path($pp);
         next  if ($#pp != $#p + 1);
         my $key = pop(@pp);
         my $tmp = $self->path(\@pp);
         next  if ($tmp ne $p);
         push(@keys,$key);
      }
      return sort @keys;

   } else {
      $$self{"err"}    = "ndschk99";
      $$self{"errmsg"} = "Unknown structural information requested: $info";
      return "";
   }
}

###############################################################################
# SET_STRUCTURE
###############################################################################
# This sets a piece of structural information (and does all error checking
# on it).

sub set_structure {
   my($self,$item,$val,$path) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if ($path) {
      _set_structure_path($self,$item,$val,$path);
   } else {
      _set_structure_default($self,$item,$val);
   }
}

# Set a structural item for a path.
#
sub _set_structure_path {
   my($self,$item,$val,$path) = @_;

   my @path = $self->path($path);
   $path    = $self->path(\@path);
   _structure_valid($self,$item,$val,$path,@path);
}

# Rules for a valid structure:
#
# If parent is not valid
#    INVALID
# End
#
# If we're not setting an item
#    VALID
# End
#
# If type is not set
#    set it to unknown
# End
#
# INVALID  if incompatible with any other options already set
# INVALID  if path incompatible with type
# INVALID  if path incompatible with parent
# INVALID  if any direct childres incompatible
#
# Set item
#
sub _structure_valid {
   my($self,$item,$val,$path,@path) = @_;

   #
   # Check for an invalid parent
   #

   my (@parent,$parent);
   if (@path) {
      @parent = @path;
      pop(@parent);
      $parent = $self->path([@parent]);
      _structure_valid($self,"","",$parent,@parent);
      return  if ($self->err());
   }

   #
   # If we're not setting a value, then the most we've done is
   # set defaults (which we know we've done correct), so it's valid
   # to the extent that we're able to check.
   #

   return  unless ($item);

   #
   # Make sure type is set. If it's not, set it to "unknown".
   #

   $$self{"struct"}{$path}{"type"} = "unknown"
     if (! exists $$self{"struct"}{$path}{"type"});
   my $type = $$self{"struct"}{$path}{"type"};

   #
   # Check to make sure that $item and $val are valid and that
   # they don't conflict with other structural settings for
   # this path.
   #

   my $set_ordered    = 0;
   my $set_uniform    = 0;
   my $valid          = 0;

   # Type checks
   if ($item eq "type") {
      $valid = 1;
      if ($val ne "scalar"  &&
          $val ne "list"    &&
          $val ne "hash"    &&
          $val ne "other") {
         $$self{"err"}    = "ndsstr01";
         $$self{"errmsg"} = "Attempt to set type to an invalid value: $val";
         return;
      }
      if ($type ne "unknown"  &&
          $type ne "list/hash") {
         $$self{"err"}    = "ndsstr02";
         $$self{"errmsg"} = "Once type is set, it may not be reset: $path";
         return;
      }
      if ($type eq "list/hash"  &&
          $val ne "list"        &&
          $val ne "hash") {
         $$self{"err"}    = "ndsstr03";
         $$self{"errmsg"} = "Attempt to set type to scalar when a list/hash " .
           "type is required: $path";
         return;
      }
   }

   # Ordered checks
   if ($item eq "ordered") {
      $valid = 1;
      if (exists $$self{"struct"}{$path}{"ordered"}) {
         $$self{"err"}    = "ndsstr04";
         $$self{"errmsg"} = "Attempt to reset ordered: $path";
         return;
      }

      # only allowed for lists
      if ($type eq "unknown"  ||
          $type eq "list/hash") {
         _structure_valid($self,"type","list",$path,@path);
         return  if ($self->err());
         $type = "list";
      }
      if ($type ne "list") {
         $$self{"err"}    = "ndsstr05";
         $$self{"errmsg"} = "Attempt to set ordered on a non-list structure: " .
           "$path";
         return;
      }
      if ($val ne "0"  &&
          $val ne "1") {
         $$self{"err"}    = "ndsstr06";
         $$self{"errmsg"} = "Ordered value must be 0 or 1: $path";
         return;
      }

      # check conflicts with "uniform"
      if (! exists $$self{"struct"}{$path}{"uniform"}) {
         if ($val) {
            # We're making an unknown list ordered. This can
            # apply to uniform or non-uniform lists, so nothing
            # is required.
         } else {
            # We're making an unknown list unordered. The
            # list must be uniform.
            $set_uniform = 1;
         }
      } elsif ($$self{"struct"}{$path}{"uniform"}) {
         # We're making an uniform list ordered or non-ordered.
         # Both are allowed.
      } else {
         if ($val) {
            # We're making an non-uniform list ordered. This is
            # allowed.
         } else {
            # We're trying to make an non-uniform list unordered.
            # This is NOT allowed.

            # NOTE: This will never occur. Any time we set a list to
            # non-uniform, it will automatically set the ordered flag
            # appropriately, so trying to set it here will result in an
            # ndsstr04 error.
            return;
         }
      }
   }

   # Uniform checks
   if ($item eq "uniform") {
      $valid = 1;
      if (exists $$self{"struct"}{$path}{"uniform"}) {
         $$self{"err"}    = "ndsstr07";
         $$self{"errmsg"} = "Attempt to reset uniform: $path";
         return;
      }

      # only applies to lists and hashes
      if ($type eq "unknown") {
         _structure_valid($self,"type","list/hash",$path,@path);
         return  if ($self->err());
      }
      if ($type ne "list"  &&
          $type ne "hash"   &&
          $type ne "list/hash") {
         $$self{"err"}    = "ndsstr08";
         $$self{"errmsg"} = "Attempt to set uniform on a scalar structure: " .
           "$path";
         return;
      }
      if ($val ne "0"  &&
          $val ne "1") {
         $$self{"err"}    = "ndsstr09";
         $$self{"errmsg"} = "Uniform value must be 0 or 1: $path";
         return;
      }

      # check conflicts with "ordered"
      if (exists $$self{"struct"}{$path}{"type"}  &&
          $$self{"struct"}{$path}{"type"} eq "list") {
         if (! exists $$self{"struct"}{$path}{"ordered"}) {
            if ($val) {
               # We're making an unknown list uniform. This can
               # apply to ordered or unorderd lists, so nothing
               # is required.
            } else {
               # We're making an unknown list non-uniform. The
               # list must be ordered.
               $set_ordered = 1;
            }
         } elsif ($$self{"struct"}{$path}{"ordered"}) {
            # We're making an ordered list uniform or non-uniform.
            # Both are allowed.
         } else {
            if ($val) {
               # We're making an unordered list uniform. This is
               # allowed.
            } else {
               # We're trying to make an unordered list non-uniform.
               # This is NOT allowed.

               # NOTE: This error will never occur. Any time we set a
               # list to unordered, it will automatically set the
               # uniform flag appropriately, so trying to set it here
               # will result in a ndsstr07 error.
               return;
            }
         }
      }
   }

   # $item is invalid
   if (! $valid) {
      $$self{"err"}    = "ndsstr98";
      $$self{"errmsg"} = "Invalid default structural item: $item";
      return;
   }

   #
   # Check to make sure that the current path is valid with
   # respect to the type of structure we're currently in (this
   # is defined in the parent element).
   #

   if (@path) {
      my $curr_ele    = $path[$#path];
      if (exists $$self{"struct"}{$parent}{"type"}) {
         my $parent_type = $$self{"struct"}{$parent}{"type"};

         if ($parent_type eq "unknown") {
            _structure_valid($self,"type","list/hash",$parent,@parent);
            return  if ($self->err());
         }

         if ($parent_type eq "scalar"  ||
             $parent_type eq "other") {
            $$self{"err"}    = "ndsstr10";
            $$self{"errmsg"} = "Trying to set structural information for a " .
              "child with a scalar parent: $path";
            return;

         } elsif ($parent_type eq "list"  &&
             $curr_ele =~ /^\d+$/) {
            if (exists $$self{"struct"}{$parent}{"uniform"}) {
               if ($$self{"struct"}{$parent}{"uniform"}) {
                  # Parent = list,uniform  Curr = 2
                  $$self{"err"}    = "ndsstr11";
                  $$self{"errmsg"} = "Attempt to set structural information " .
                    "for a specific element in a uniform list: $path";
                  return;
               }
            } else {
               # Parent = list, unknown  Curr = 2
               #    => force parent to be non-uniform
               _structure_valid($self,"uniform","0",$parent,@parent);
               return  if ($self->err());
            }

         } elsif ($parent_type eq "list"  &&
                  $curr_ele eq "*") {
            if (exists $$self{"struct"}{$parent}{"uniform"}) {
               if (! $$self{"struct"}{$parent}{"uniform"}) {
                  # Parent = list,nonuniform  Curr = *
                  $$self{"err"}    = "ndsstr12";
                  $$self{"errmsg"} = "Attempt to set structural information " .
                    "for all elements in a non-uniform list: $path";
                  return;
               }
            } else {
               # Parent = list,unknown  Curr = *
               #    => force parent to be uniform
               _structure_valid($self,"uniform","1",$parent,@parent);
               return  if ($self->err());
            }

         } elsif ($parent_type eq "list") {
            $$self{"err"}    = "ndsstr13";
            $$self{"errmsg"} = "Attempt to access a list with a non-integer " .
              "index.: $path";
            return;

         } elsif (($parent_type eq "hash"  ||  $parent_type eq "list/hash")  &&
                  $curr_ele eq "*") {
            if (exists $$self{"struct"}{$parent}{"uniform"}) {
               if (! $$self{"struct"}{$parent}{"uniform"}) {
                  # Parent = list/hash,non-uniform  Curr = *
                  $$self{"err"}    = "ndsstr15";
                  $$self{"errmsg"} = "Attempt to set structural information " .
                    "for all elements in a non-uniform structure: $path";
                  return;
               }
            } else {
               # Parent = hash,unknown  Curr = *
               #    => force parent to be uniform
               _structure_valid($self,"uniform","1",$parent,@parent);
               return  if ($self->err());
            }

         } elsif ($parent_type eq "hash"  ||  $parent_type eq "list/hash") {
            if (exists $$self{"struct"}{$parent}{"uniform"}) {
               if ($$self{"struct"}{$parent}{"uniform"}) {
                  # Parent = list/hash,uniform  Curr = foo
                  $$self{"err"}    = "ndsstr14";
                  $$self{"errmsg"} = "Attempt to set structural information " .
                    "for a specific element in a uniform structure: $path";
                  return;
               }
            } else {
               # Parent = hash,unknown  Curr = foo
               #    => force parent to be non-uniform
               _structure_valid($self,"uniform","0",$parent,@parent);
               return  if ($self->err());
            }
         }

      } else {
         # Parent is not type'd yet.

         if ($curr_ele eq "*"  ||
             $curr_ele =~ /^\d+$/) {
            _structure_valid($self,"type","list/hash",$parent,@parent);
            return  if ($self->err());
         } else {
            _structure_valid($self,"type","hash",$parent,@parent);
            return  if ($self->err());
         }
      }
   }

   #
   # Set the item
   #

   $$self{"struct"}{$path}{$item} = $val;
   if ($set_ordered) {
      _structure_valid($self,"ordered","1",$path,@path);
      return  if ($self->err());
   }
   if ($set_uniform) {
      _structure_valid($self,"uniform","1",$path,@path);
      return  if ($self->err());
   }
}

{
   # Values for the default structural information. First value in the
   # list is the error code for this item. Second value is the default
   # for this item.

   my %def = ( "ordered"        => [ "ndsstr16",
                                     "Attempt to set the default ordered " .
                                     "value to something other than 0/1",
                                     qw(0 1) ],
               "uniform_hash"   => [ "ndsstr17",
                                     "Attempt to set the default uniform_hash" .
                                     " value to something other than 0/1",
                                     qw(0 1) ],
               "uniform_ol"     => [ "ndsstr18",
                                     "Attempt to set the default uniform_ol " .
                                     "value to something other than 0/1",
                                     qw(1 0) ],
             );

   sub _set_structure_default {
      my($self,$item,$val) = @_;

      if (! exists $def{$item}) {
         $$self{"err"}    = "ndsstr99";
         $$self{"errmsg"} = "Invalid structural item for a path: $item";
         return;
      }
      my @tmp = @{ $def{$item} };
      my $err = shift(@tmp);
      my $msg = shift(@tmp);
      my %tmp = map { $_,1 } @tmp;
      if (! exists $tmp{$val}) {
         $$self{"err"} = $err;
         $$self{"errmsg"} = "$msg: $item = $val";
         return;
      }
      $$self{"defstruct"}{$item} = $val;
      return;
   }

   # Set up the default structure:
   sub _structure_defaults {
      my($self) = @_;
      my($d) = "defstruct";

      $$self{$d} = {}  if (! exists $$self{$d});
      foreach my $key (CORE::keys %def) {
         $$self{$d}{$key} = $def{$key}[2];
      }
   }
}

###############################################################################
# CHECK_STRUCTURE/CHECK_VALUE
###############################################################################
# This checks the structure of an NDS (and may update the structural
# information if appropriate).

sub check_structure {
   my($self,$nds,$new) = @_;
   $$self{"err"}       = "";
   $$self{"errmsg"}    = "";

   return  if (! ref($nds));
   return  if (! $$self{"structure"});

   $new = 0  if (! $new);

   _check_structure($self,$nds,$new,());
}

sub check_value {
   my($self,$path,$val,$new) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";
   my(@path) = $self->path($path);
   _check_structure($self,$val,$new,@path);
}

sub _check_structure {
   my($self,$nds,$new,@path) = @_;
   return  if (! defined $nds);

   my $path = $self->path([@path]);

   # Check to make sure that it's the correct type of data.

   my $type = $self->get_structure($path,"type");

   if ($type) {
      my $ref = lc(ref($nds));
      $ref    = "scalar"  if (! $ref);
      $ref    = "list"    if ($ref eq "array");

      if      ($type eq "hash"  ||  $type eq "list"  ||  $type eq "scalar") {
         if ($ref ne $type) {
            $$self{"err"}    = "ndschk01";
            $$self{"errmsg"} = "Invalid type: $path (expected $type, got $ref)";
            return;
         }

      } elsif ($type eq "list/hash") {
         if ($ref ne "list"  &&  $ref ne "hash") {
            $$self{"err"}    = "ndschk01";
            $$self{"errmsg"} = "Invalid type: $path (expected $type, got $ref)";
            return;
         }
         $type = "";

      } elsif ($type eq "other") {
         if ($ref eq "scalar"  ||
             $ref eq "hash"    ||
             $ref eq "list") {
            $$self{"err"}    = "ndschk01";
            $$self{"errmsg"} = "Invalid type: $path (expected $type, got $ref)";
            return;
         }

      } elsif ($type eq "unknown") {
         $type = "";

      } else {
         die "[check_structure] Impossible error: $type";
      }
   }

   if (! $type) {
      # If the structure is not previously defined, it will set an
      # error code. Erase that one (it's not interesting) and then
      # set the structure based on the new value (if allowed).
      $$self{"err"}    = "";
      $$self{"errmsg"} = "";
      if ($new) {
         $type = lc(ref($nds));
         $type = "list"  if ($type eq "array");
         if (! $type) {
            _set_structure_path($self,"type","scalar",$path);
         } elsif ($type eq "hash"  ||
                  $type eq "list") {
            _set_structure_path($self,"type",$type,$path);
         } else {
            _set_structure_path($self,"type","other",$path);
         }

      } else {
         $$self{"err"}    = "ndschk02";
         $$self{"errmsg"} = "New structure not allowed";
         return;
      }
   }

   return  unless ($type eq "list"  ||  $type eq "hash");

   # Recurse into hashes.

   my $uniform = $self->get_structure($path,"uniform");
   if ($type eq "hash") {
      foreach my $key (CORE::keys %$nds) {
         my $val = $$nds{$key};
         if ($uniform) {
            _check_structure($self,$val,$new,@path,"*");
            return  if ($self->err());
         } else {
            _check_structure($self,$val,$new,@path,$key);
            return  if ($self->err());
         }
      }
      return;
   }

   # Recurse into lists

   for (my $i=0; $i<=$#$nds; $i++) {
      my $val = $$nds[$i];
      if ($uniform) {
         _check_structure($self,$val,$new,@path,"*");
         return  if ($self->err());
      } else {
         _check_structure($self,$val,$new,@path,$i);
         return  if ($self->err());
      }
   }

   return;
}

###############################################################################
# VALID/VALUE
###############################################################################

sub value {
   my($self,$nds,$path,$copy,$nocheck) = @_;
   $nocheck=0  if (! $nocheck);
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";
   $nds = _nds($self,$nds,1,0,$nocheck);
   return undef  if ($self->err());

   my($delim) = $self->delim();
   my @path   = $self->path($path);

   my $val    = _value($self,$nds,$delim,"",@path);
   return undef  if ($self->err());

   if ($copy  &&  ref($val)) {
      return dclone($val);
   } else {
      return $val;
   }
}

sub _value {
   my($self,$nds,$delim,$path,@path) = @_;

   #
   # We've traversed as far as @path goes
   #

   if (! @path) {
      return $nds;
   }

   #
   # Get the next path element.
   #

   my $p = shift(@path);
   $path = ($path ? join($delim,$path,$p) : "$delim$p");

   #
   # Handle the case where $nds is a scalar, or not
   # a known data type.
   #

   if      (! defined($nds)) {
      # $nds doesn't contain the path
      $$self{"err"}    = "ndsdat01";
      $$self{"errmsg"} = "A path does not exist in the NDS: $path";
      return undef;

   } elsif (! ref($nds)) {
      # $nds is a scalar
      $$self{"err"}    = "ndsdat04";
      $$self{"errmsg"} = "The NDS has a scalar at a point where a hash or " .
        "list should be: $path";
      return undef;

   } elsif (ref($nds) ne "HASH"  &&  ref($nds) ne "ARRAY") {
      # $nds is an unsupported data type
      $$self{"err"}    = "ndsdat05";
      $$self{"errmsg"} = "The NDS has a reference to an unsupported data " .
        "type where a hash or list should be: $path";
      return undef;
   }

   #
   # Handle hash references.
   #

   if      (ref($nds) eq "HASH") {
      if (exists $$nds{$p}) {
         return _value($self,$$nds{$p},$delim,$path,@path);
      } else {
         $$self{"err"}    = "ndsdat02";
         $$self{"errmsg"} = "A hash key does not exist in the NDS: $path";
         return undef;
      }
   }

   #
   # Handle lists.
   #

   if ($p !~ /^\d+$/) {
      # A non-integer list reference
      $$self{"err"}    = "ndsdat06";
      $$self{"errmsg"} = "A non-integer index used to access a list: $path";
      return undef;
   } elsif ($#$nds < $p) {
      $$self{"err"}    = "ndsdat03";
      $$self{"errmsg"} = "A list element does not exist in the NDS: $path";
      return undef;
   } else {
      return _value($self,$$nds[$p],$delim,$path,@path);
   }
}

###############################################################################
# KEYS, VALUES
###############################################################################

sub keys {
   my($self,$nds,$path) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";
   $nds = _nds($self,$nds,1,0,0);
   my $val = $self->value($nds,$path);
   return undef  if ($self->err());

   if (! ref($val)) {
      return ();

   } elsif (ref($val) eq "ARRAY") {
      my(@ret);
      foreach my $i (0..$#$val) {
         push(@ret,$i)  if (! _empty($self,$$val[$i]));
      }
      return @ret;

   } elsif (ref($val) eq "HASH") {
      my(@ret);
      foreach my $key (sort(CORE::keys %$val)) {
         push(@ret,$key)  if (! _empty($self,$$val{$key}));
      }
      return @ret;

   } else {
      return undef;
   }
}

sub values {
   my($self,$nds,$path) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";
   $nds = _nds($self,$nds,1,0,0);
   my $val = $self->value($nds,$path);
   return undef  if ($self->err());

   if (! ref($val)) {
      return ($val);

   } elsif (ref($val) eq "ARRAY") {
      my(@ret);
      foreach my $i (0..$#$val) {
         push(@ret,$$val[$i])  if (! _empty($self,$$val[$i]));
      }
      return @ret;

   } elsif (ref($val) eq "HASH") {
      my(@ret);
      foreach my $key (sort(CORE::keys %$val)) {
         push(@ret,$$val{$key})  if (! _empty($self,$$val{$key}));
      }
      return @ret;

   } else {
      return undef;
   }
}

###############################################################################
# SET_MERGE
###############################################################################

sub set_merge {
   my($self,$item,$val,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   if (_merge_default($self,$item)) {
      _set_merge_default($self,$item,$val,@args);

   } elsif ($item eq "merge") {
      _set_merge_path($self,$val,@args);

   } else {
      $$self{"err"}    = "ndsmer01";
      $$self{"errmsg"} = "Attempt to set a merge setting to an unknown " .
        "value: $item";
      return;
   }
}

# Set a merge item for a path.
#
sub _set_merge_path {
   my($self,$path,$method,$ruleset) = @_;
   $ruleset = "*"  if (! $ruleset);

   my @path = $self->path($path);
   $path    = $self->path(\@path);

   if (exists $$self{"ruleset"}{$ruleset}{"path"}{$path}) {
      $$self{"err"}    = "ndsmer06";
      $$self{"errmsg"} = "Attempt to reset merge value for a path: $path";
      return;
   }

   # Check type vs. method

   my $type = $self->get_structure($path,"type");

   if      ($type eq "list") {
      my $ordered = $self->get_structure($path,"ordered");

      if (! _merge_allowed($type,$ordered,$method)) {
         if ($ordered) {
            $$self{"err"}    = "ndsmer08";
            $$self{"errmsg"} = "Invalid merge method for ordered list " .
              "merging: $path";
            return;
         } else {
            $$self{"err"}    = "ndsmer09";
            $$self{"errmsg"} = "Invalid merge method for unordered list " .
              "merging: $path";
            return;
         }
      }

   } elsif ($type eq "hash") {
      if (! _merge_allowed($type,0,$method)) {
         $$self{"err"}    = "ndsmer10";
         $$self{"errmsg"} = "Invalid merge method for hash merging: $path";
         return;
      }

   } elsif ($type eq "scalar"  ||  $type eq "other") {
      if (! _merge_allowed($type,0,$method)) {
         $$self{"err"}    = "ndsmer11";
         $$self{"errmsg"} = "Invalid merge method for scalar merging: $path";
         return;
      }

   } else {
      $$self{"err"}    = "ndsmer07";
      $$self{"errmsg"} = "Attempt to set merge for a path with no " .
        "known type: $path";
      return;
   }

   # Set the method

   $$self{"ruleset"}{$ruleset}{"path"}{$path} = $method;
   return;
}

{
   # Values for the default structural information. First value in the
   # list is the error code for this item. Second value is the default
   # for this item.

   my %def = ( "merge_hash"     => [ "ndsmer02",
                                     "Attempt to set merge_hash to an " .
                                     "invalid value",
                                     qw(merge
                                        keep keep_warn
                                        replace replace_warn
                                        error) ],
               "merge_ol"       => [ "ndsmer03",
                                     "Attempt to set merge_ol to an invalid " .
                                     "value",
                                     qw(merge
                                        keep keep_warn
                                        replace replace_warn
                                        error) ],
               "merge_ul"       => [ "ndsmer04",
                                     "Attempt to set merge_ul to an invalid " .
                                     "value",
                                     qw(append
                                        keep keep_warn
                                        replace replace_warn
                                        error) ],
               "merge_scalar"   => [ "ndsmer05",
                                     "Attempt to set merge_scalar to an " .
                                     "invalid value",
                                     qw(keep keep_warn
                                        replace replace_warn
                                        error) ],
             );

   sub _merge_default {
      my($self,$item) = @_;
      return 1  if (exists $def{$item});
      return 0;
   }

   sub _set_merge_default {
      my($self,$item,$val,$ruleset) = @_;
      $ruleset = "*"  if (! $ruleset);

      my @tmp = @{ $def{$item} };
      my $err = shift(@tmp);
      my $msg = shift(@tmp);
      my %tmp = map { $_,1 } @tmp;
      if (! exists $tmp{$val}) {
         $$self{"err"}    = $err;
         $$self{"errmsg"} = "$msg: $item = $val";
         return;
      }
      $$self{"ruleset"}{$ruleset}{"def"}{$item} = $val;
      return;
   }

   # Set up the default merge:
   sub _merge_defaults {
      my($self) = @_;

      foreach my $key (CORE::keys %def) {
         $$self{"ruleset"}{"*"}{"def"}{$key} = $def{$key}[2];
      }

      $$self{"ruleset"}{"keep"}{"def"} =
        { "merge_hash"   => "keep",
          "merge_ol"     => "keep",
          "merge_ul"     => "keep",
          "merge_scalar" => "keep" };

      $$self{"ruleset"}{"replace"}{"def"} =
        { "merge_hash"   => "replace",
          "merge_ol"     => "replace",
          "merge_ul"     => "replace",
          "merge_scalar" => "replace" };

      $$self{"ruleset"}{"default"}{"def"} =
        { "merge_hash"   => "merge",
          "merge_ol"     => "merge",
          "merge_ul"     => "keep",
          "merge_scalar" => "keep" };

      $$self{"ruleset"}{"override"}{"def"} =
        { "merge_hash"   => "merge",
          "merge_ol"     => "merge",
          "merge_ul"     => "replace",
          "merge_scalar" => "replace" };

   }

   sub _merge_allowed {
      my($type,$ordered,$val) = @_;

      my @tmp;
      if ($type eq "hash") {
         @tmp = @{ $def{"merge_hash"} };
      } elsif ($type eq "list") {
         if ($ordered) {
            @tmp = @{ $def{"merge_ol"} };
         } else {
            @tmp = @{ $def{"merge_ul"} };
         }
      } else {
         @tmp = @{ $def{"merge_scalar"} };
      }

      my $err = shift(@tmp);
      my $msg = shift(@tmp);
      my %tmp = map { $_,1 } @tmp;
      return 0  if (! exists $tmp{$val});
      return 1;
   }
}

###############################################################################
# GET_MERGE
###############################################################################

sub get_merge {
   my($self,$path,$ruleset) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";
   $ruleset = "*"  if (! $ruleset);
   my @path = $self->path($path);
   $path    = $self->path(\@path);

   # Check ruleset

   return $$self{"ruleset"}{$ruleset}{"path"}{$path}
     if (exists $$self{"ruleset"}{$ruleset}{"path"}{$path});

   my $type    = $self->get_structure($path,"type");
   my $ordered;
   if ($type eq "list") {
      $ordered = $self->get_structure($path,"ordered");
   }

   if ($type eq "hash") {
      return $$self{"ruleset"}{$ruleset}{"def"}{"merge_hash"}
        if (exists $$self{"ruleset"}{$ruleset}{"def"}{"merge_hash"});

   } elsif ($type eq "list"  &&  $ordered) {
      return $$self{"ruleset"}{$ruleset}{"def"}{"merge_ol"}
        if (exists $$self{"ruleset"}{$ruleset}{"def"}{"merge_ol"});

   } elsif ($type eq "list") {
      return $$self{"ruleset"}{$ruleset}{"def"}{"merge_ul"}
        if (exists $$self{"ruleset"}{$ruleset}{"def"}{"merge_ul"});

   } elsif ($type eq "scalar"  ||  $type eq "other") {
      return $$self{"ruleset"}{$ruleset}{"def"}{"merge_scalar"}
        if (exists $$self{"ruleset"}{$ruleset}{"def"}{"merge_scalar"});

   } else {
      return "";
   }

   # Check "*" (this should always find something)

   $ruleset = "*";

   return $$self{"ruleset"}{$ruleset}{"path"}{$path}
     if (exists $$self{"ruleset"}{$ruleset}{"path"}{$path});

   if ($type eq "hash") {
      return $$self{"ruleset"}{$ruleset}{"def"}{"merge_hash"};

   } elsif ($type eq "list"  &&  $ordered) {
      return $$self{"ruleset"}{$ruleset}{"def"}{"merge_ol"};

   } elsif ($type eq "list") {
      return $$self{"ruleset"}{$ruleset}{"def"}{"merge_ul"};

   } elsif ($type eq "scalar"  ||  $type eq "other") {
      return $$self{"ruleset"}{$ruleset}{"def"}{"merge_scalar"};
   }
}

###############################################################################
# MERGE
###############################################################################
# This merges two NDSes into a single one.

sub merge {
   my($self,$nds1,$nds2,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";
   return  if (! defined $nds2);

   #
   # Parse ruleset and new arguments
   #

   my ($ruleset,$new);
   if (! @args) {
      $ruleset = "*";
      $new     = 0;

   } elsif ($#args == 0) {
      if ($args[0] eq "0"  ||  $args[0] eq "1") {
         $ruleset = "*";
         $new     = $args[0];
      } else {
         $ruleset = $args[0];
         $new     = 0;
      }

   } elsif ($#args == 1) {
      $ruleset = $args[0];
      $new     = $args[1];

   } else {
      die "[merge] Unknown argument list";
   }

   #
   # Get nds1 and nds2 by reference or name
   #

   $nds1 = _nds($self,$nds1,$new);
   if (! defined($nds1)) {
      $$self{"err"}    = "ndsmer12";
      $$self{"errmsg"} = "While merging, the first NDS is not defined: $nds1";
      return;
   }

   $nds2 = _nds($self,$nds2,$new);
   if (! defined($nds2)) {
      $$self{"err"}    = "ndsmer13";
      $$self{"errmsg"} = "While merging, the second NDS is not defined: $nds2";
      return;
   }

   #
   # Check structure
   #

   $self->check_structure($nds1,$new);
   if ($$self{"err"}) {
      $$self{"err"}    = "ndsmer14";
      $$self{"errmsg"} = "The first NDS has an invalid structure.";
      return;
   }
   $self->check_structure($nds2,$new);
   if ($$self{"err"}) {
      $$self{"err"}    = "ndsmer15";
      $$self{"errmsg"} = "The second NDS has an invalid structure.";
      return;
   }

   #
   # Merge
   #

   my $tmp = _merge($self,$nds1,$nds2,[],$ruleset);
   if (ref($nds1) eq "HASH") {
      %$nds1 = %$tmp;
   } elsif (ref($nds1) eq "ARRAY") {
      @$nds1 = @$tmp;
   } else {
      $$self{"err"}    = "ndsmer16";
      $$self{"errmsg"} = "The NDS must be a list or hash.";
      return;
   }
   return;
}

sub _merge {
   my($self,$nds1,$nds2,$pathref,$ruleset) = @_;
   my $path = $self->path($pathref);

   #
   # If $nds2 is empty, we'll always return whatever $nds1 is.
   # If $nds1 is empty or "", we'll always return whatever $nds2 is.
   #

   return $nds1  if ($self->empty($nds2));
   if ($self->empty($nds1)  ||
       (! ref($nds1)  &&  $nds1 eq "")) {
      return $nds2;
   }

   #
   # $method can be merge, keep, keep_warn, replace, replace_warn,
   # error, append
   #
   # handle keep*, replace*, and error
   #

   my $type   = $self->get_structure($path);
   my $method = $self->get_merge($path,$ruleset);

   if      ($method eq "keep"  ||  $method eq "keep_warn") {
      warn($self,"[merge] keeping initial value\n" .
                  "        path: $path",1)  if ($method eq "keep_warn");
      return $nds1;

   } elsif ($method eq "replace"  ||  $method eq "replace_warn") {
      warn($self,"[merge] replacing initial value\n" .
                  "        path: $path",1)  if ($method eq "replace_warn");
      if (ref($nds2)) {
         return $nds2;
      }
      return $nds2;

   } elsif ($method eq "error") {
      if (ref($nds1)) {
         warn($self,"[merge] multiply defined value\n" .
                     "        path: $path",1);
         exit;
      } elsif ($nds1 eq $nds2) {
         return $nds1;
      } else {
         warn($self,"[merge] nonidentical values\n" .
                     "        path: $path",1);
         exit;
      }
   }

   #
   # Merge two lists
   #

   if (ref($nds1) eq "ARRAY") {
      return _merge_lists($self,$method,$nds1,$nds2,$pathref,$ruleset);
   }

   #
   # Merge two hashes
   #

   if (ref($nds1) eq "HASH") {
      return _merge_hashes($self,$method,$nds1,$nds2,$pathref,$ruleset);
   }
}

# Method is: merge
#
sub _merge_hashes {
   my($self,$method,$val1,$val2,$pathref,$ruleset) = @_;

   foreach my $key (CORE::keys %$val2) {

      #
      # If $val2 is empty, we'll keep $val1
      # If $val1 is empty or "", we'll always set it to $val2
      #

      next  if ($self->empty($$val2{$key}));

      if (! exists $$val1{$key}  ||
          $self->empty($$val1{$key})  ||
          (! ref($$val1{$key})  &&  $$val1{$key} eq "")) {
         $$val1{$key} = $$val2{$key};

      } else {
         $$val1{$key} =
           _merge($self,$$val1{$key},$$val2{$key},[@$pathref,$key],$ruleset);
      }
   }

   return $val1;
}

# Method is: append, merge
#
sub _merge_lists {
   my($self,$method,$val1,$val2,$pathref,$ruleset) = @_;

   # Handle append unordered

   if ($method eq "append") {
      push(@$val1,@$val2);
      return $val1;
   }

   # Handle merge ordered (merge each i'th element)

   my($i);
   for ($i=0; $i<=$#$val2; $i++) {

      # val1[i]  val2[i]
      # -------  -------
      # *        empty      do nothing
      # empty/'' *          val1[i] = val2[i]
      # *        *          recurse into (including scalars)

      if ($self->empty($$val2[$i])) {
         next;

      } elsif ($self->empty($$val1[$i])  ||
               (! ref($$val1[$i])  &&  $$val1[$i] eq "")) {
         $$val1[$i] = $$val2[$i];

      } else {
         $$val1[$i] =
           _merge($self,$$val1[$i],$$val2[$i],[@$pathref,$i],$ruleset);
      }
   }

   return $val1;
}

###############################################################################
# MERGE_PATH
###############################################################################

sub merge_path {
   my($self,$nds,$val,$path,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   my @path  = $self->path($path);
   $path     = $self->path(\@path);

   return merge($self,$nds,$val,@args)  if (! @path);

   #
   # Parse ruleset and new arguments
   #

   my ($ruleset,$new);
   if (! @args) {
      $ruleset = "*";
      $new     = 0;

   } elsif ($#args == 0) {
      if ($args[0] eq "0"  ||  $args[0] eq "1") {
         $ruleset = "*";
         $new     = $args[0];
      } else {
         $ruleset = $args[0];
         $new     = 0;
      }

   } elsif ($#args == 1) {
      $ruleset = $args[0];
      $new     = $args[1];

   } else {
      die "[merge_path] Unknown argument list";
   }

   #
   # Get nds by reference or name
   #

   $nds = _nds($self,$nds,0,0,1);
   if (! defined($nds)) {
      $$self{"err"}    = "ndsmer17";
      $$self{"errmsg"} = "Attempt to merge a value into an undefined NDS: $nds";
      return;
   }

   #
   # Check structure
   #

   $self->check_structure($nds,$new);
   if ($self->err()) {
      $$self{"err"}    = "ndsmer18";
      $$self{"errmsg"} = "The NDS has an invalid structure: $path";
      return;
   }

   _check_structure($self,$val,$new,@path);
   if ($self->err()) {
      $$self{"err"}    = "ndsmer19";
      $$self{"errmsg"} = "The value has an invalid structure: $path";
      return;
   }

   #
   # Get the NDS stored at the path.
   #

   my $ele     = pop(@path);
   $nds        = _merge_path_nds($self,$nds,[],@path);

   #
   # Merge in the value
   #

   if (ref($nds) eq "HASH") {
      $$nds{$ele} = _merge($self,$$nds{$ele},$val,[@path,$ele],$ruleset);

   } elsif (ref($nds) eq "ARRAY") {
      $$nds[$ele] = _merge($self,$$nds[$ele],$val,[@path,$ele],$ruleset);
   }
   return;
}

# This returns the NDS stored at @path in $nds. $pathref is the path
# of $nds with respect to the main NDS structure.
#
# Since we removed the last element of the path in the merge_path
# method, this can ONLY be called with hash/list structures.
#
sub _merge_path_nds {
   my($self,$nds,$pathref,@path) = @_;
   return $nds  if (! @path);
   my($ele) = shift(@path);

   # Easy case: return an existing element

   if (ref($nds) eq "HASH") {
      if (exists $$nds{$ele}) {
         return _merge_path_nds($self,$$nds{$ele},[@$pathref,$ele],@path);
      }

   } else {
      if (defined $$nds[$ele]) {
         return _merge_path_nds($self,$$nds[$ele],[@$pathref,$ele],@path);
      }
   }

   # Hard case: create new structure

   my $type = $self->get_structure([@$pathref,$ele]);
   my $new;
   if ($type eq "hash") {
      $new = {};
   } else {
      $new = [];
   }

   if (ref($nds) eq "HASH") {
      $$nds{$ele} = $new;
      return _merge_path_nds($self,$$nds{$ele},[@$pathref,$ele],@path);

   } else {
      $$nds[$ele] = $new;
      return _merge_path_nds($self,$$nds[$ele],[@$pathref,$ele],@path);
   }
}

###############################################################################
# ERASE
###############################################################################
# This removes a path from an NDS based on the structural information.
# Hash elements are deleted, ordered elements are cleared, unordered
# elements are deleted.

sub erase {
   my($self,$nds,$path) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   #
   # Get the NDS
   #

   $nds = _nds($self,$nds,1,0,0);
   return undef  if ($self->err());

   #
   # If $path not passed in, clear the entire NDS
   #

   my(@path) = $self->path($path);
   if (! @path) {
      if (ref($nds) eq "HASH") {
         %$nds = ();
      } elsif (ref($nds) eq "ARRAY") {
         @$nds = ();
      }
      return 1;
   }

   #
   # Get the parent of $path
   #

   my $ele = pop(@path);
   $nds    = $self->value($nds,[@path]);
   return undef  if ($self->err());

   #
   # Delete the element
   #

   if (ref($nds) eq "HASH") {
      if (exists $$nds{$ele}) {
         delete $$nds{$ele};
      } else {
         return 0;
      }

   } else {
      my $ordered = $self->get_structure([@path],"ordered");
      if ($ordered) {
         if (defined $$nds[$ele]) {
            $$nds[$ele] = undef;
         } else {
            return 0;
         }
      } else {
         if (defined $$nds[$ele]) {
            splice(@$nds,$ele,1);
         } else {
            return 0;
         }
      }
   }

   return 1;
}

###############################################################################
# WHICH
###############################################################################

sub which {
   my($self,$nds,@crit) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   $nds = _nds($self,$nds,1,0,0);

   if (! @crit) {
      my %ret;
      _which_scalar($self,$nds,\%ret,{},[]);
      return %ret;
   } else {
      my(@re,%vals,%ret);
      foreach my $crit (@crit) {
         if (ref($crit) eq "Regexp") {
            push(@re,$crit);
         } else {
            $vals{$crit} = 1;
         }
      }
      _which_scalar($self,$nds,\%ret,\%vals,\@re);
      return %ret;
   }
}

# Sets %ret to be a hash of PATH => VAL for every path which
# passes one of the criteria.
#
# If %vals is not empty, a path passes if it's value is any of
# the keys in %vals.
#
# If @re is not empty, a path passes if it matches any of the
# regular expressions in @re.
#
sub _which_scalar {
   my($self,$nds,$ret,$vals,$re,@path) = @_;

   if (ref($nds) eq "HASH") {
      foreach my $key (CORE::keys %$nds) {
         _which_scalar($self,$$nds{$key},$ret,$vals,$re,@path,$key);
      }

   } elsif (ref($nds) eq "ARRAY") {
      foreach (my $i = 0; $i <= $#$nds; $i++) {
         _which_scalar($self,$$nds[$i],$ret,$vals,$re,@path,$i);
      }

   } else {
      my $path = $self->path([@path]);
      my $crit = 0;

      if (CORE::keys %$vals) {
         $crit = 1;
         if (exists $$vals{$nds}) {
            $$ret{$path} = $nds;
            return;
         }
      }

      if (@$re) {
         $crit = 1;
         foreach my $re (@$re) {
            if ($nds =~ $re) {
               $$ret{$path} = $nds;
               return;
            }
         }
      }

      return  if ($crit);

      # No criteria passed in
      $$ret{$path} = $nds   if (defined $nds);
      return;
   }
}

###############################################################################
# PATHS
###############################################################################

sub paths {
   my($self,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";
   @args = ("scalar")  if (! @args);

   # Parse parameters

   my %tmp;
   foreach my $arg (@args) {
      if ($arg eq "scalar"  ||
          $arg eq "list"    ||
          $arg eq "hash") {
         if (exists $tmp{"scalar"}  ||
             exists $tmp{"list"}    ||
             exists $tmp{"hash"}) {
            $$self{"err"}    = "ndsdat07";
            $$self{"errmsg"} = "Invalid parameter combination in paths " .
              "method: @args";
            return undef;
         }
      } elsif ($arg eq "uniform"  ||
               $arg eq "nonuniform") {
         if (exists $tmp{"uniform"}  ||
             exists $tmp{"nonuniform"}) {
            $$self{"err"}    = "ndsdat07";
            $$self{"errmsg"} = "Invalid parameter combination in paths " .
              "method: @args";
            return undef;
         }
      } elsif ($arg eq "ordered"  ||
               $arg eq "unordered") {
         if (exists $tmp{"ordered"}  ||
             exists $tmp{"unordered"}) {
            $$self{"err"}    = "ndsdat07";
            $$self{"errmsg"} = "Invalid parameter combination in paths " .
              "method: @args";
            return undef;
         }
      } else {
         $$self{"err"}    = "ndsdat08";
         $$self{"errmsg"} = "Invalid parameter in paths method: $arg";
         return undef;
      }
      $tmp{$arg} = 1;
   }

   if (exists $tmp{"scalar"}  &&
       (exists $tmp{"uniform"}     ||
        exists $tmp{"nonuniform"}  ||
        exists $tmp{"ordered"}     ||
        exists $tmp{"unordered"})) {
      $$self{"err"}    = "ndsdat07";
      $$self{"errmsg"} = "Invalid parameter combination in paths " .
        "method: @args";
      return undef;
   }

   if (exists $tmp{"hash"}  &&
       (exists $tmp{"ordered"}     ||
        exists $tmp{"unordered"})) {
      $$self{"err"}    = "ndsdat07";
      $$self{"errmsg"} = "Invalid parameter combination in paths " .
        "method: @args";
      return undef;
   }

   if (exists $tmp{"list"}       &&
       exists $tmp{"unordered"}  &&
       exists $tmp{"nonuniform"}) {
      $$self{"err"}    = "ndsdat07";
      $$self{"errmsg"} = "Invalid parameter combination in paths " .
        "method: @args";
      return undef;
   }

   # Check which paths fit


   my @ret = sort(CORE::keys %{ $$self{"struct"} });

   my $type = "";
   if      (exists $tmp{"scalar"}) {
      $type = "scalar";
   } elsif (exists $tmp{"list"}) {
      $type = "list";
   } elsif (exists $tmp{"hash"}) {
      $type = "hash";
   }
   if ($type) {
      my @tmp;
      foreach my $path (@ret) {
         push(@tmp,$path)  if ($$self{"struct"}{$path}{"type"} eq $type);
      }
      @ret = @tmp;
   }

   my $ordered = "";
   if      (exists $tmp{"ordered"}) {
      $ordered = 1;
   } elsif (exists $tmp{"unordered"}) {
      $ordered = 0;
   }
   if ($ordered ne "") {
      my @tmp;
      foreach my $path (@ret) {
         push(@tmp,$path)  if (exists $$self{"struct"}{$path}{"ordered"}  &&
                               $$self{"struct"}{$path}{"ordered"} == $ordered);
      }
      @ret = @tmp;
   }

   my $uniform = "";
   if      (exists $tmp{"uniform"}) {
      $uniform = 1;
   } elsif (exists $tmp{"nonuniform"}) {
      $uniform = 0;
   }
   if ($uniform ne "") {
      my @tmp;
      foreach my $path (@ret) {
         push(@tmp,$path)  if (exists $$self{"struct"}{$path}{"uniform"}  &&
                               $$self{"struct"}{$path}{"uniform"} == $uniform);
      }
      @ret = @tmp;
   }

   return @ret;
}

###############################################################################
# TEST_CONDITIONS
###############################################################################

sub test_conditions {
   my($self,$nds,@cond) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";
   return 1  if (! @cond);

 COND: while (@cond) {
      my $path = shift(@cond);
      my $cond = shift(@cond);

      # Get the value at the path. An error code means that the path
      # is not defined (but the path is valid in the sense that it COULD
      # be there... it just doesn't exist in this NDS).

      my $v    = $self->value($nds,$path,0,1);
      if ($self->err()) {
         $$self{"err"}    = "";
         $$self{"errmsg"} = "";
         $v               = undef;
      }

      if (! defined $v) {
         # no path does NOT automatically mean failure... worse, we
         # can't tell whether it should be tested as a hash, list, or
         # scalar
         my($valid,$pass) = _test_hash_condition($self,$v,$cond);
         if ($valid) {
            return 0  if (! $pass);
         } else {
            return 0  if (! _test_list_condition($self,$v,$cond)  &&
                          ! _test_scalar_condition($self,$v,$cond));
         }

      } elsif (ref($v) eq "HASH") {
         my($valid,$pass) = _test_hash_condition($self,$v,$cond);
         if ($valid) {
            return 0  if (! $pass);
         } else {
            # Set error (invalid condition)
            $$self{"err"}    = "ndscon01";
            $$self{"errmsg"} = "Invalid test condition used: $path: $cond";
            return undef;
         }

      } elsif (ref($v) eq "ARRAY") {
         return 0  if (! _test_list_condition($self,$v,$cond));

      } else {
         return 0  if (! _test_scalar_condition($self,$v,$cond));
      }
   }

   return 1;
}

# If $nds contains a hash, condition can be any of the following:
#
#    exists:VAL   : true if a key named VAL exists in the hash
#    empty:VAL    : true if a key named VAL is empty in the hash (it
#                   doesn't exist, or has an empty value)
#    empty        : true if the hash is empty
#
sub _test_hash_condition {
   my($self,$nds,$cond) = @_;

   # Make sure it's a valid condition for this data type.

   if ($cond !~ /^\!?empty(:.+)?$/i  &&
       $cond !~ /^\!?exists:.+$/i) {
      return (0,0);
   }

   # An undefined value:
   #    passes empty
   #    passes empty:VAL
   #    passes !exists:VAL
   #    fails  all others

   if (! defined $nds) {
      return (1,1)  if ($cond =~ /^empty/i  ||
                    $cond =~ /^\!exists/i);
      return (1,0);
   }

   # A non-hash element should not even be passed in.

   if (ref($nds) ne "HASH") {
     die "ERROR: [_test_hash_condition] impossible: non-hash passed in\n";
   }

   # Test for existance of a key or an empty key

   if ($cond =~ /^(\!?)(exists|empty):(.+)$/) {
      my ($not,$op,$key) = ($1,$2,$3);
      my $exists = (exists $$nds{$key});

      if (lc($op) eq "exists") {
         return (1,1)  if ( ($exists  &&  ! $not) ||
                        (! $exists  &&  $not) );
         return (1,0);
      }

      my $empty = 1;
      $empty    = $self->empty([ $$nds{$key} ])  if ($exists);

      return (1,1)  if ( ($empty  &&  ! $not) ||
                     (! $empty  &&  $not) );
      return (1,0);
   }

   # An empty value:
   #    passes empty
   #    fails  !empty
   # A non-empty value:
   #    fails  empty
   #    passes !empty

   $cond = lc($cond);
   if ($self->empty($nds)) {
      return (1,1)  if ($cond eq "empty");
      return (1,0)  if ($cond eq "!empty");
   } else {
      return (1,0)  if ($cond eq "empty");
      return (1,1)  if ($cond eq "!empty");
   }
}

# If $path refers to a list, conditions may be any of the following:
#
#    empty        : true if the list is empty
#    defined:VAL  : true if the VAL'th (VAL is an integer) element
#                   is defined
#    empty:VAL    : true if the VAL'th (VAL is an integer) element
#                   is empty (or not defined)
#    contains:VAL : true if the list contains the element VAL
#    <:VAL        : true if the list has fewer than VAL (an integer)
#                   non-empty elements
#    <=:VAL
#    =:VAL
#    >:VAL
#    >=:VAL
#    VAL          : equivalent to contains:VAL
#
sub _test_list_condition {
   my($self,$nds,$cond) = @_;

   # An undefined value:
   #    passes empty
   #    passes empty:VAL
   #    passes !defined:VAL
   #    passes !contains:VAL
   #    passes =:0
   #    passes !=:*  (not zero)
   #    passes <:*
   #    passes <=:*
   #    passes >=:0
   #    fails  all others

   if (! defined($nds)) {
      return 1  if ($cond =~ /^empty(:.+)?$/i      ||
                    $cond =~ /^\!defined:(.+)$/i   ||
                    $cond =~ /^\!contains:(.+)$/i  ||
                    $cond eq "=:0"                 ||
                    $cond =~ /^\!=:(\d*[1-9]\d*)$/ ||
                    $cond =~ /^<:(\d+)$/           ||
                    $cond =~ /^<=:(\d+)$/          ||
                    $cond eq ">=:0");
      return 0;
   }

   # A non-list element should not even be passed in.

   if (ref($nds) ne "ARRAY") {
      die "ERROR: [_test_list_condition] impossible: non-list passed in\n";
   }

   # Test for defined/empty keys

   if ($cond =~ /^(\!?)(defined|empty):(\d+)$/i) {
      my ($not,$op,$i) = ($1,$2,$3);
      my $def = (defined $$nds[$i]);

      if (lc($op) eq "defined") {
         return 1  if ( ($def  &&  ! $not) ||
                        (! $def  &&  $not) );
         return 0;
      }

      my $empty = 1;
      $empty    = $self->empty([ $$nds[$i] ])  if ($def);

      return 1  if ( ($empty  &&  ! $not) ||
                     (! $empty  &&  $not) );
      return 0;
   }

   # < <= = > >= tests

   if ($cond =~ /^(\!?)(<=|<|=|>=|>):(\d+)$/) {
      my($not,$op,$val) = ($1,$2,$3);
      my $n = 0;
      foreach my $v (@$nds) {
         $n++  if (! $self->empty([ $v ]));
      }

      if      ($op eq "<") {
         return 1  if ( ($n < $val  &&  ! $not) ||
                        ($n >= $val  &&  $not) );
         return 0;

      } elsif ($op eq "<=") {
         return 1  if ( ($n <= $val  &&  ! $not) ||
                        ($n > $val  &&  $not) );
         return 0;

      } elsif ($op eq "=") {
         return 1  if ( ($n == $val  &&  ! $not) ||
                        ($n != $val  &&  $not) );
         return 0;

      } elsif ($op eq ">=") {
         return 1  if ( ($n >= $val  &&  ! $not) ||
                        ($n < $val  &&  $not) );
         return 0;

      } else {
         return 1  if ( ($n > $val  &&  ! $not) ||
                        ($n <= $val  &&  $not) );
         return 0;
      }
   }

   # contains condition

   if ($cond =~ /^(\!?)contains:(.*)$/i) {
      my($not,$val) = ($1,$2);
      $val          = ""  if (! defined $val);
      foreach my $v (@$nds) {
         next  if (! defined $v);
         if ($v eq $val) {
            return 1  if (! $not);
            return 0  if ($not);
         }
      }
      return 0  if (! $not);
      return 1;
   }

   # An empty list:
   #   passes empty
   #   fails  !empty
   # A non-empty list:
   #   fails  empty
   #   passes !empty

   my $c = lc($cond);
   if ($self->empty([ $nds ])) {
      return 1  if ($c eq "empty");
      return 0  if ($c eq "!empty");
   } else {
      return 0  if ($c eq "empty");
      return 1  if ($c eq "!empty");
   }

   # VAL test

   my $not = 0;
   $not    = 1 if ($cond =~ s/^\!//);

   foreach my $v (@$nds) {
      next  if (! defined $v);
      if ($v eq $cond) {
         return 1  if (! $not);
         return 0  if ($not);
      }
   }
   return 0  if (! $not);
   return 1;
}

# If $path refers to a scalar, conditions may be any of the following:
#
#    defined      : true if the value is not defined
#    empty        : true if the value is empty
#    zero         : true if the value defined and evaluates to 0
#    true         : true if the value defined and evaluates to true
#    =:VAL        : true if the the value is VAL
#    member:VAL:VAL:...
#                 : true if the value is any of the values given (in
#                   this case, ALL of the colons (including the first
#                   one) can be replace by any other single character
#                   separator
#    VAL          : true if the value is equal to VAL
#
sub _test_scalar_condition {
   my($self,$nds,$cond) = @_;

   # An undefined value
   #    passes !defined
   #    passes !zero
   #    passes !true
   #    passes empty
   #    passes !=:*
   #    passes !member:*
   #    fails  all others

   if (! defined $nds) {
      return 1  if ($cond =~ /^!defined$/i  ||
                    $cond =~ /^empty$/i     ||
                    $cond =~ /^\!zero$/i    ||
                    $cond =~ /^\!true$/i    ||
                    $cond =~ /^\!=:/        ||
                    $cond =~ /^\!member/i);
      return 0;
   }

   # A non-scalar element should not even be passed in.

   if (ref($nds)) {
      die "ERROR: [_test_scalar_condition] impossible: non-scalar passed in\n";
   }

   # A defined value
   #    passes defined
   #    fails  ! defined

   my($c) = lc($cond);
   return 1  if ($c eq "defined");
   return 0  if ($c eq "!defined");

   # An empty value (must pass it as a structure, NOT a scalar)
   #    passes empty
   #    fails  !empty
   # A non-empty value
   #    passes !empty
   #    fails  empty

   if ($self->empty([$nds])) {
      return 1  if ($c eq "empty");
      return 0  if ($c eq "!empty");
   } else {
      return 0  if ($c eq "empty");
      return 1  if ($c eq "!empty");
   }

   $nds = ""  if (! defined $nds);

   # zero and true tests

   if      ($c eq "zero") {
      return 1  if ($nds eq ""  ||  $nds == 0);
      return 0;
   } elsif ($c eq "!zero") {
      return 0  if ($nds eq ""  ||  $nds == 0);
      return 1;
   } elsif ($c eq "true") {
      return 1  if ($nds);
      return 0;
   } elsif ($c eq "!true") {
      return 0  if ($nds);
      return 1;
   }

   # = test

   if ($cond =~ /^(\!?)=:(.*)/) {
      my($not,$val) = ($1,$2);
      $val = ""  if (! defined $val);
      return 1  if ( ($nds eq $val  &&  ! $not)  ||
                     ($nds ne $val  &&  $not) );
      return 0;
   }

   # member test

   if ($cond =~ /^(\!?)member(.)(.+)$/) {
      my($not,$sep,$vals) = ($1,$2,$3);
      my %tmp = map { (defined $_ ? $_ : ""),1 } split(/\Q$sep\E/,$vals);
      return 1  if ( (exists $tmp{$nds}  &&  ! $not)  ||
                     (! exists $tmp{$nds}  &&  $not) );
      return 0;
   }

   # VAL test

   if ($cond =~ s/^\!//) {
      return 0  if ($nds eq $cond);
      return 1;
   }

   return 1  if ($nds eq $cond);
   return 0;
}

###############################################################################
# IDENTICAL, CONTAINS
###############################################################################

sub identical {
   my($self,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   my($nds1,$nds2,$path) = _ic_args($self,@args);
   return  if ($self->err());

   _DBG_begin("Identical");

   my $flag = _identical_contains($self,$nds1,$nds2,1,$path);

   _DBG_end($flag);
   return $flag;
}

sub contains {
   my($self,@args) = @_;
   $$self{"err"}    = "";
   $$self{"errmsg"} = "";

   my($nds1,$nds2,$path) = _ic_args($self,@args);
   return  if ($self->err());

   _DBG_begin("Contains");

   my $flag = _identical_contains($self,$nds1,$nds2,0,$path);

   _DBG_end($flag);
   return $flag;
}

sub _ic_args {
   my($self,$nds1,$nds2,@args) = @_;

   #
   # Parse $new and $path
   #

   my($new,$path);
   if (! @args) {
      $new  = 0;
      $path = "";
   } elsif ($#args == 0) {
      if ($args[0] eq "0"  ||  $args[0] eq "1") {
         $new  = $args[0];
         $path = "";
      } else {
         $new  = 0;
         $path = $args[0];
      }
   } elsif ($#args == 1) {
      $new  = $args[0];
      $path = $args[1];
   } else {
      die "[identical/contains] invalid arguments";
   }

   #
   # Check the two NDSes for validity, and return them as refs.
   #

   $nds1 = _nds($self,$nds1,$new,0,0);
   if ($self->err()) {
      $$self{"err"}    = "ndside01";
      $$self{"errmsg"} = "The first NDS is invalid: $nds1";
      return;
   }
   $nds2 = _nds($self,$nds2,$new,0,0);
   if ($self->err()) {
      $$self{"err"}    = "ndside02";
      $$self{"errmsg"} = "The first NDS is invalid: $nds2";
      return;
   }

   return ($nds1,$nds2,$path);
}

sub _identical_contains {
   my($self,$nds1,$nds2,$identical,$path) = @_;
   _DBG_enter("_identical_contains");

   #
   # Handle $path
   #

   $path    = $self->path($path);
   my @path = $self->path($path);

   #
   # We will now recurse through the data structure and get an
   # mpath description.
   #
   # An mpath description will be stored as:
   #   %desc = ( MPATH  => DESC )
   #
   # An MPATH is related to a PATH, except that every path element that
   # contains an index for an unordered list is transformed to illustrate
   # this. For example, for the path:
   #   /foo/1/bar/2
   # the mpath is:
   #   /foo/_ul_1/bar/_ul_2
   # (assuming that the 2nd and 4th elements are indices in unorderd
   # lists).
   #

   my(%desc1,%desc2);
   if ($path ne "/") {
      $nds1 = $self->value($nds1,$path);
      $nds2 = $self->value($nds2,$path);
   }
   _ic_desc($self,$nds1,\%desc1,[@path],[@path],0,$self->delim());
   _ic_desc($self,$nds2,\%desc2,[@path],[@path],0,$self->delim());

   #
   # Now check these description hashes to see if they are identical
   # (or contained). This is done recusively.
   #

   my $flag = _ic_compare($self,\%desc1,\%desc2,$identical,$self->delim());
   _DBG_leave($flag);
   return $flag;
}

# This compares all elements of two description hashes to see if
# they are identical, or if the second is contained in the first.
#
sub _ic_compare {
   my($self,$desc1,$desc2,$identical,$delim) = @_;
   _DBG_enter("_ic_compare");
   if ($_DBG) {
      _DBG_line("DESC1 =");
      foreach my $mpath (sort(CORE::keys %$desc1)) {
         my $val = $$desc1{$mpath}{"val"} .
           "  [" . join(" ",@{ $$desc1{$mpath}{"meles"} }) . "]";
         _DBG_line("   $mpath\t= $val");
      }
      _DBG_line("DESC2 =");
      foreach my $mpath (sort(CORE::keys %$desc2)) {
         my $val = $$desc2{$mpath}{"val"} .
           "  [" . join(" ",@{ $$desc2{$mpath}{"meles"} }) . "]";
         _DBG_line("   $mpath\t= $val");
      }
   }

   #
   # Separate %desc into two sections. Move everything containing any
   # unordered list induces to %ul.  %desc will end up containing
   # everything else (which is handled very simply).
   #

   my(%ul1,%ul2);
   _ic_ul($desc1,\%ul1);
   _ic_ul($desc2,\%ul2);

   #
   # One trivial case... if %desc2 is bigger than %desc1, (or %ul2
   # is bigger than %ul1) it isn't contained in it. If they are not
   # equal in size, they can't be identical.
   #

   my @d1 = CORE::keys %$desc1;
   my @d2 = CORE::keys %$desc2;
   my @u1 = CORE::keys %ul1;
   my @u2 = CORE::keys %ul2;
   if ($identical) {
      _DBG_leave("Not equal"), return 0  if ($#d1 != $#d2  ||
                                            $#u1 != $#u2);
   } else {
      _DBG_leave("Bigger"),    return 0  if ($#d1 < $#d2  ||
                                            $#u1 < $#u2);
   }

   #
   # Do the easy part... elements with no unordered lists. All in
   # %desc2 must be in %desc1. For identical tests, nothing else
   # can exist.
   #

   foreach my $mpath (@d2) {
      if (exists $$desc1{$mpath}  &&
          $$desc1{$mpath}{"val"} eq $$desc2{$mpath}{"val"}) {
         delete $$desc1{$mpath};
         delete $$desc2{$mpath};
         next;
      } else {
         _DBG_leave("Desc differs");
         return 0;
      }
   }

   @d1 = CORE::keys %$desc1;
   _DBG_leave("Desc not equal"), return 0  if ($identical  &&  @d1);

   #
   # Now do elements containing unordered lists.
   #

   if ($#u2 == -1) {
      _DBG_leave("UL not identical"), return 0  if ($identical  &&  $#u1 > -1);
      _DBG_leave(1);
      return 1;
   }
   my $flag = _ic_compare_ul($self,\%ul1,\%ul2,$identical,$delim);
   _DBG_leave($flag);
   return $flag;
}

# This recurses through %ul1 and %ul2 to try all possible combinations
# of indices for unordered elements. At every level of recusion, we do
# the left-most set of indices.
#
sub _ic_compare_ul {
   my($self,$ul1,$ul2,$identical,$delim) = @_;
   _DBG_enter("_ic_compare_ul");
   if ($_DBG) {
      _DBG_line("UL1 =");
      foreach my $mpath (sort(CORE::keys %$ul1)) {
         my $val = $$ul1{$mpath}{"val"} .
           "  [" . join(" ",@{ $$ul1{$mpath}{"meles"} }) . "]";
         _DBG_line("   $mpath\t= $val");
      }
      _DBG_line("UL2 =");
      foreach my $mpath (sort(CORE::keys %$ul2)) {
         my $val = $$ul2{$mpath}{"val"} .
           "  [" . join(" ",@{ $$ul2{$mpath}{"meles"} }) . "]";
         _DBG_line("   $mpath\t= $val");
      }
   }

   #
   # We need to get a list of all similar mpaths up to this level.
   # To determine if two mpaths are similar, look at the first element
   # in @meles in each.
   #
   # If both are unordered list indices (not necessarily identical) or
   # both are NOT unordered list indices and are identical, then they
   # are similar.
   #

 COMPARE: while (1) {
      my @mpath2 = CORE::keys %$ul2;
      last COMPARE  if (! @mpath2);

      #
      # Look at the first element in @meles in one of the $ul entries.
      # It will either be an unordered list index or a set of 1 or more
      # path elements which do NOT contain unordered list indices.
      #

      my $mpath = $mpath2[0];
      my $mele  = $$ul2{$mpath}{"meles"}[0];

      if ($mele =~ /^_ul_/) {

         # Get a list of all elements with a first $mele an _ul_ and
         # move them to a temporary description hash.

         my(%tmp1,%tmp2);
         _ic_ul2desc($ul1,\%tmp1,$mele,1);
         _ic_ul2desc($ul2,\%tmp2,$mele,1);

         # Find the number of unique $mele in %ul1 and %ul2 .  If
         # the number in %ul2 is greater, it can't be contained. It
         # can't be identical unless the two numbers are the same.

         my $max1 = _ic_max_idx(\%tmp1);
         my $max2 = _ic_max_idx(\%tmp2);

         _DBG_leave("Bigger"),    return 0  if ($max2 > $max1);
         _DBG_leave("Not equal"), return 0  if ($identical  &&  $max1 != $max2);

         # Copy all elements from %ul1 to %desc1, but change them
         # from _ul_I to J (where J is 0..MAX)
         #
         # After we set a combination, we need to reset MELES.

         my $desc1 = {};
         _ic_permutation(\%tmp1,$desc1,(0..$max1));
         foreach my $mp (CORE::keys %$desc1) {
            $$desc1{$mp}{"meles"} = _ic_mpath2meles($self,$mp,$delim);
         }

         # Try every combination of the elements in %ul2 setting
         # _ul_I to J (where J is 1..MAX and MAX comes from %ul1)

         my $p = new Algorithm::Permute([0..$max1],$max2+1);

         while (my(@idx) = $p->next) {

            my $d1 = {};
            my $d2 = {};
            $d1 = dclone($desc1);
            _ic_permutation(\%tmp2,$d2,@idx);
            foreach my $mp (CORE::keys %$d2) {
               $$d2{$mp}{"meles"} = _ic_mpath2meles($self,$mp,$delim);
            }

            next COMPARE
              if (_ic_compare($self,$d1,$d2,$identical,$delim));
         }

         _DBG_leave("Unordered list fails");
         return 0;

      } else {

         #
         # Not an unordered list.
         #
         # Go through all %ul mpaths and take all elements which
         # have the same leading $mele and move them to a new
         # %desc hash. Then compare the two %desc hashes.
         #

         my(%desc1,%desc2);
         _ic_ul2desc($ul1,\%desc1,$mele,0);
         _ic_ul2desc($ul2,\%desc2,$mele,0);

         _DBG_leave("Desc fails"), return 0
           if (! _ic_compare($self,\%desc1,\%desc2,$identical,$delim));

      }
   }

   my @mpath1 = CORE::keys %$ul1;
   _DBG_leave("Remaining items fail"), return 0  if (@mpath1  &&  $identical);
   _DBG_leave(1);
   return 1;
}

# This recurses through a data structure and creates a description of
# every path containing a scalar. The description is a hash of the
# form:
#
# %desc =
#    ( MPATH =>
#       { val    => VAL           the scalar at the path
#         path   => PATH          the actual path         /a/1
#         mpath  => MPATH         the modified path       /a/_ul_1
#         ul     => N             the number of unordered indices in mpath
#         meles  => MELES         a list of modified elements (see below)
#         mele   => MELE          the part of MELES currently being examined
#       }
#    )
#
# Ths MELES list is a list of "elements" where can be combined to form the
# mpath (using the delimiter). Each element of MELES is either an index of
# an unordered list or all adjacent path elements which are not unordered
# list indices. For example, the mpath:
#     /a/_ul_1/b/c/_ul_3/_ul_4
# would become the following MELES
#     [ a, _ul_1, b/c, _ul_3, _ul_4 ]
#
# We'll pass both the path and mpath (as listrefs) as arguments as well
# as a flag whether or not we've had any unordered elements in the path
# to this point.
#
sub _ic_desc {
   my($self,$nds,$desc,$mpath,$path,$ul,$delim) = @_;

   if (ref($nds) eq "HASH") {
      foreach my $key (CORE::keys %$nds) {
         _ic_desc($self,$$nds{$key},$desc,[@$mpath,$key],[@$path,$key],$ul,
                  $delim);
      }

   } elsif (ref($nds) eq "ARRAY") {
      my $ordered = $self->get_structure([@$path,0],"ordered");

      if ($ordered) {
         for (my $i=0; $i<=$#$nds; $i++) {
            _ic_desc($self,$$nds[$i],$desc,[@$mpath,$i],[@$path,$i],$ul,$delim);
         }

      } else {
         for (my $i=0; $i<=$#$nds; $i++) {
            _ic_desc($self,$$nds[$i],$desc,[@$mpath,"_ul_$i"],[@$path,$i],$ul+1,
                     $delim);
         }
      }

   } elsif (! $self->empty($nds)) {
      my $p     = $self->path($path);
      my $mp    = $self->path($mpath);

      $$desc{$mp} = { "val"   => $nds,
                      "path"  => $p,
                      "mpath" => $mp,
                      "meles" => _ic_mpath2meles($self,$mpath,$delim),
                      "ul"    => $ul
                    };
   }
}

# Move all elements from %desc to %ul which have unordered list elements
# in them.
#
sub _ic_ul {
   my($desc,$ul) = @_;

   foreach my $mpath (CORE::keys %$desc) {
      if ($$desc{$mpath}{"ul"}) {
         $$ul{$mpath} = $$desc{$mpath};
         delete $$desc{$mpath};
      }
   }
}

# This moves moves all elements from %ul to %desc which have the given
# first element in @meles.
#
# $mele can be an unordered list element (in which case all elements
# with unordered list elements are moved) or not (in which case, all
# elements with the same first $mele are moved).
#
sub _ic_ul2desc {
   my($ul,$desc,$mele,$isul) = @_;

   foreach my $mpath (CORE::keys %$ul) {
      if ( ($isul    &&  $$ul{$mpath}{"meles"}[0] =~ /^_ul_/)  ||
           (! $isul  &&  $$ul{$mpath}{"meles"}[0] eq $mele) ) {

         # Move the element to %desc

         $$desc{$mpath} = $$ul{$mpath};
         delete $$ul{$mpath};

         # Fix @meles accordingly

         my @meles = @{ $$desc{$mpath}{"meles"} };
         my $m = shift(@meles);

         $$desc{$mpath}{"meles"} = [ @meles ];
         $$desc{$mpath}{"mele"} = $m;
      }
   }
}

# This goes through a description hash (%desc) and sets the "meles" value
# for each element.
#
sub _ic_mpath2meles {
   my($self,$mpath,$delim) = @_;
   my(@mpath) = $self->path($mpath);

   my @meles  = ();
   my $tmp    = "";
   foreach my $mele (@mpath) {
      if ($mele =~ /^_ul_/) {
         if ($tmp) {
            push(@meles,$tmp);
            $tmp = "";
         }
         push(@meles,$mele);
      } else {
         if ($tmp) {
            $tmp .= "$delim$mele";
         } else {
            $tmp = $mele;
         }
      }
   }
   if ($tmp) {
      push(@meles,$tmp);
   }
   return [ @meles ];
}

# This goes through all of the elements in a %desc hash. All of them should
# have a descriptor "mele" which is an unordered list index in the form
# _ul_I . Find out how many unique ones there are.
#
sub _ic_max_idx {
   my($desc) = @_;

   my %tmp;
   foreach my $mpath (CORE::keys %$desc) {
      my $mele = $$desc{$mpath}{"mele"};
      $tmp{$mele} = 1;
   }

   my @tmp = CORE::keys %tmp;
   return $#tmp;
}

# This copies all elements from one description hash (%tmpdesc) to a final
# description hash (%desc). Along the way, it substitutes all leading
# unordered list indices (_ul_i) with the current permutation index.
#
# So if the list of indices (@idx) is (0,2,1) and the current list of
# unorderd indices is (_ul_0, _ul_1, _ul_2), then every element containing
# a leading _ul_1 in the mpath will be modified and that element will be
# replaced by "2".
#
sub _ic_permutation {
   my($tmpdesc,$desc,@idx) = @_;

   # Get a sorted list of all unordered indices:
   #   (_ul_0, _ul_1, _ul_2)

   my(%tmp);
   foreach my $mpath (CORE::keys %$tmpdesc) {
      my $mele    = $$tmpdesc{$mpath}{"mele"};
      $tmp{$mele} = 1;
   }
   my @tmp = sort(CORE::keys %tmp);

   # Create a hash of unordered list indices and their
   # replacement:
   #   _ul_0  => 0
   #   _ul_1  => 2
   #   _ul_2  => 1

   %tmp = ();
   while (@tmp) {
      my($ul)  = shift(@tmp);
      my($idx) = shift(@idx);
      $tmp{$ul} = $idx;
   }

   # Copy the element from %tmpdesc to %desc
   #    Substitute the unordered list index with the permutation index
   #    Clear "mele" value
   #    Decrement "ul" value

   foreach my $mpath (CORE::keys %$tmpdesc) {
      my $mele  = $$tmpdesc{$mpath}{"mele"};
      my $idx   = $tmp{$mele};
      my $newmp = $mpath;
      $newmp    =~ s/$mele/$idx/;

      $$desc{$newmp}          = dclone($$tmpdesc{$mpath});
      $$desc{$newmp}{"mpath"} = $newmp;
      $$desc{$newmp}{"mele"}  = "";
      $$desc{$newmp}{"ul"}--;
   }
}

###############################################################################
# PRINT
###############################################################################

sub print {
   my($self,$nds,%opts) = @_;
   $nds = _nds($self,$nds,1,0,1);

   if (exists $opts{"indent"}) {
      my $opt = $opts{"indent"};
      if ($opt !~ /^\d+$/  ||
          $opt < 1) {
         warn($self,"Invalid option: indent: $opt",1);
         return;
      }
   } else {
      $opts{"indent"} = 3;
   }

   if (exists $opts{"width"}) {
      my $opt = $opts{"width"};
      if ($opt !~ /^\d+$/  ||
          ($opt > 0  &&  $opt < 20)) {
         warn($self,"Invalid option: width: $opt",1);
         return;
      }
   } else {
      $opts{"width"} = 79;
   }

   my $maxlevel = ($opts{"width"} == 0 ? 0 : int( ($opts{"width"} - 10)/
                                                  $opts{"indent"} ) + 1);
   if (exists $opts{"maxlevel"}) {
      my $opt = $opts{"maxlevel"};
      if ($maxlevel != 0  &&  $opt > $maxlevel) {
         warn($self,"Maxlevel exceeded: $opt > $maxlevel",1);
         $opts{"maxlevel"} = $maxlevel;
      }
   } else {
      $opts{"maxlevel"} = $maxlevel;
   }

   return _print($nds,0,1,%opts);
}

sub _print {
   my($nds,$indent,$level,%opts) = @_;

   my $string;
   my $indentstr  = " "x$indent;
   my $nextindent = $indent + $opts{"indent"};
   my $currwidth  = ($opts{"width"} == 0 ? 0 : $opts{"width"} - $indent);

   if (ref($nds) eq "HASH") {
      # Print
      #     key  : val      val is a scalar, and it fits
      #     key  : ...      we're at maxlevel, val is a ref, and ... fits
      #     key  :          otherwise
      #        val

      # Find the length of the longest key
      my @keys = CORE::keys %$nds;
      @keys    = sort _sortByLength(@keys);
      my $maxl = length($keys[0]);
      my $keyl = 0;
      my $vall = 0;

      # Find the length that we'll allocate for keys (the rest if
      # for values).
      if ( $currwidth  &&  ($maxl+1) > $currwidth ) {
         # keys won't all fit on the line, so truncate them
         $keyl = $currwidth - 1;
      } else {
         $keyl = $maxl;
         if ($currwidth == 0) {
            $vall = -1;
         } else {
            $vall = $currwidth - ($keyl + 2);  # key:_ (include a space)
            $vall = 0  if ($vall < 0);
         }
      }

      # Print each key
      foreach my $key (sort @keys) {
         my $val = $$nds{$key};
         $val    = "undef"  if (! defined $val);
         $val    = "''"     if (! ref($val)  &&  $val eq "");
         my $k   = $key;
         if (length($k) > $keyl) {
            $k   = substr($k,0,$keyl);
         } elsif (length($k) < $keyl) {
            $k   = $k . " "x($keyl - length($k));
         }
         $string .= "$indentstr$k" . ":";

         if (! ref($val)  &&  ($vall == -1  ||  length($val) <= $vall)) {
            $string .= " $val\n";

         } elsif (ref($val)  &&
                  $opts{"maxlevel"} == $level  &&
                  ($vall == -1  ||  $vall > 3)) {
            $string .= " ...\n";

         } else {
            $string .= "\n";
            $string .= _print($val,$nextindent,$level+1,%opts);
         }
      }

   } elsif (ref($nds) eq "ARRAY") {
      # Print each element as:
      #     0  = val      val is a scalar, and it fits
      #     0  = ...      we're at maxlevel, val is a ref, and ... fits
      #     0  =          otherwise
      #        val

      # Find the length of the longest index
      my $maxl = length($#$nds + 1);
      my $keyl = 0;
      my $vall = 0;

      # Find the length allocated for indices and the rest for values.
      if ( ($maxl + 1) > $currwidth ) {
         # keys won't all fit on the line, so truncate them
         $keyl = $currwidth - 1;
      } else {
         $keyl = $maxl;
         if ($currwidth == 0) {
            $vall = -1;
         } else {
            $vall = $currwidth - ($keyl + 2);  # key:_ (include a space)
            $vall = 0  if ($vall < 0);
         }
      }

      # Print each index
      for (my $key=0; $key <= $#$nds; $key++) {
         my $val = $$nds[$key];
         $val    = "undef"  if (! defined $val);
         $val    = "''"     if (! ref($val)  &&  $val eq "");
         my $k   = $key;
         if (length($k) > $keyl) {
            $k   = substr($k,0,$keyl);
         } elsif (length($k) < $keyl) {
            $k   = " "x($keyl - length($k)) . $k;
         }
         $string .= "$indentstr$k" . "=";

         if (! ref($val)  &&  ($vall == -1  ||  length($val) <= $vall)) {
            $string .= " $val\n";

         } elsif (ref($val)  &&
                  $opts{"maxlevel"} == $level  &&
                  ($vall == -1  ||  $vall > 3)) {
            $string .= " ...\n";

         } else {
            $string .= "\n";
            $string .= _print($val,$nextindent,$level+1,%opts);
         }
      }

   } else {
      $nds    = "undef"  if (! defined $nds);
      $nds    = "''"     if (! ref($nds)  &&  $nds eq "");

      if (length($nds) > $currwidth) {
         $nds = substr($nds,0,$currwidth-3) . "...";
      }
      $string = "$indentstr$nds\n";
   }

   return $string;
}

no strict "vars";
# This sorts from longest to shortest element
sub _sortByLength {
  return (length $b <=> length $a);
}
use strict "vars";

###############################################################################
# DEBUG ROUTINES
###############################################################################

# Begin a new debugging session.
sub _DBG_begin {
   my($function) = @_;
   return  unless ($_DBG);

   $_DBG_FH = new IO::File;
   $_DBG_FH->open(">>$_DBG_OUTPUT");
   $_DBG_INDENT = 0;
   $_DBG_POINT  = 0;

   _DBG_line("#"x70);
   _DBG_line("# $function");
   _DBG_line("#"x70);
}

# End a debugging session.
sub _DBG_end {
   my($value) = @_;
   return  unless ($_DBG);

   _DBG_line("# Ending: $value");
   $_DBG_FH->close();
}

# Enter a routine.
sub _DBG_enter {
   my($routine) = @_;
   return  unless ($_DBG);
   $_DBG_POINT++;
   $_DBG_INDENT += 3;

   _DBG_line("### Entering[$_DBG_POINT]: $routine");
}

# Leave a routine.
sub _DBG_leave {
   my($value) = @_;
   return  unless ($_DBG);
   $_DBG_POINT++;

   _DBG_line("### Leaving[$_DBG_POINT]: $value");
   $_DBG_INDENT -= 3;
}

# Print a debugging line.
sub _DBG_line {
   my($line) = @_;
   print $_DBG_FH " "x$_DBG_INDENT,$line,"\n";
}

###############################################################################
###############################################################################

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

package Array::AsObject;
# Copyright (c) 2009-2010 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

require 5.004;

use warnings;
use strict;
use Sort::DataTypes qw(sort_by_method sort_valid_method);

use vars qw($VERSION);
$VERSION = "1.02";

###############################################################################
# BASE METHODS
###############################################################################

sub new {
   my($class,@array) = @_;

   my $self = {
               "set"  => [],
               "err"  => "",
              };
   bless $self, $class;

   $self->list(@array)  if (@array);
   return $self;
}

sub version {
   my($self) = @_;

   return $VERSION;
}

sub err {
   my($self) = @_;

   return 1  if ($$self{"err"});
   return 0;
}

sub errmsg {
   my($self) = @_;

   return $$self{"err"};
}

###############################################################################
# LIST EXAMINATION METHODS
###############################################################################

sub as_hash {
   my($self,$full) = @_;
   $$self{"err"} = "";

   if ($full) {

      my %count;
      my %vals;
      my %refs;
      my %scal;
      my $undef;
      my $label = 1;
      foreach my $ele (@{ $$self{"set"} }) {
         if (! defined $ele) {
            if ($undef) {
               $count{$undef}++;
            } else {
               $undef         = $label++;
               $vals{$undef}  = undef;
               $count{$undef} = 1;
            }
         } elsif (ref($ele)) {
            my $s = scalar($ele);
            my $l;
            if (exists $refs{$s}) {
               $l         = $refs{$s};
               $count{$l}++;
            } else {
               $l         = $label++;
               $refs{$s}  = $l;
               $vals{$l}  = $ele;
               $count{$l} = 1;
            }
         } else {
            my $l;
            if (exists $scal{$ele}) {
               $l         = $scal{$ele};
               $count{$l}++;
            } else {
               $l          = $label++;
               $scal{$ele} = $l;
               $vals{$l}   = $ele;
               $count{$l}  = 1;
            }
         }
      }

      return (\%count, \%vals);

   } else {

      my %tmp;
      foreach my $ele (@{ $$self{"set"} }) {
         next  if (! defined $ele  ||  ref($ele));
         if (exists $tmp{$ele}) {
            $tmp{$ele}++;
         } else {
            $tmp{$ele} = 1;
         }
      }

      return %tmp;

   }
}

sub at {
   my($self,@n) = @_;
   $$self{"err"} = "";

   if      (! @n) {
      $$self{"err"} = "Index required";
      return undef;
   } elsif ($#n > 0  &&  ! wantarray) {
      $$self{"err"} = "In scalar context, only a single index allowed";
      return undef;
   }

   my @list = @{ $$self{"set"} };
   if (! @list) {
      $$self{"err"} = "Operation (at) invalid with empty list";
      return undef;
   }

   my(@ret);
   my $len = $#list + 1;

   foreach my $n (@n) {
      if ($n =~ /^[+-]?\d+$/) {
         if ($n < -$len  ||  $n > $len-1) {
            $$self{"err"} = "Index out of range";
            return undef;
         }
         CORE::push(@ret,$list[$n]);
      } else {
         $$self{"err"} = "Index must be an integer";
         return undef;
      }
   }

   if (wantarray) {
      return @ret;
   } else {
      return $ret[0];
   }
}

sub count {
   my($self,$val) = @_;
   my @idx = $self->index($val);
   return undef  if ($self->err());

   return $#idx + 1;
}

sub exists {
   my($self,@val) = @_;
   @val = (undef)  if (! @val);

   foreach my $val (@val) {
      my @idx = $self->index($val);
      return undef  if ($self->err());
      return 0  if (! @idx);
   }
   return 1;
}

sub first {
   my($self) = @_;
   $$self{"err"} = "";

   my @list = @{ $$self{"set"} };
   if (! @list) {
      $$self{"err"} = "Operation (first) invalid with empty list";
      return undef;
   }

   return $list[0];
}

sub last {
   my($self) = @_;
   $$self{"err"} = "";

   my @list = @{ $$self{"set"} };
   if (! @list) {
      $$self{"err"} = "Operation (first) invalid with empty list";
      return undef;
   }

   return $list[$#list];
}

sub index {
   my($self,$val) = @_;
   $$self{"err"} = "";

   my @idx  = ();
   my @list = @{ $$self{"set"} };

   for (my $i=0; $i<=$#list; $i++) {
      my $ele = $list[$i];
      CORE::push(@idx,$i)  if (_eq($self,$val,$ele));
   }

   if (wantarray) {
      return @idx;
   } elsif (@idx) {
      return $idx[0];
   } else {
      return -1;
   }
}

sub rindex {
   my($self,$val) = @_;
   my @idx = $self->index($val);

   if (wantarray) {
      return CORE::reverse(@idx);
   } elsif (@idx) {
      return $idx[$#idx];
   } else {
      return -1;
   }
}

sub is_empty {
   my($self,$undef) = @_;
   $$self{"err"} = "";

   my @list = @{ $$self{"set"} };
   return 1  if ($#list == -1);

   foreach my $ele (@list) {
      next  if ($undef  &&  ! defined $ele);
      return 0;
   }

   return 1;
}

sub length {
   my($self) = @_;
   $$self{"err"} = "";

   return $#{ $$self{"set"} } + 1;
}

sub list {
   my($self,@list) = @_;
   $$self{"err"}   = "";

   if (@list) {
      $$self{"set"} = [@list];
      return;
   } else {
      return @{ $$self{"set"} };
   }
}

sub _eq {
   my($self,$val1,$val2) = @_;

   if (! defined $val1  &&  ! defined $val2) {
      return 1;
   } elsif (! defined $val1  ||  ! defined $val2) {
      return 0;

   } elsif (ref($val1)  &&  ref($val2)  &&  scalar($val1) eq scalar($val2)) {
      return 1;
   } elsif (ref($val1)  ||  ref($val2)) {
      return 0;

   } elsif ($val1 eq $val2) {
      return 1;
   } else {
      return 0;
   }
}

###############################################################################
# SIMPLE LIST MODIFICATION METHODS
###############################################################################

sub clear {
   my($self,$undef) = @_;
   $$self{"err"}   = "";

   if ($undef) {
      foreach my $ele (@{ $$self{"set"} }) {
         $ele = undef;
      }

   } else {
      $$self{"set"} = [];
   }

   return;
}

sub compact {
   my($self) = @_;
   $$self{"err"} = "";

   my @list = ();
   foreach my $ele (@{ $$self{"set"} }) {
      CORE::push(@list,$ele)  if (defined $ele);
   }
   $$self{"set"} = [@list];
   return;
}

sub delete {
   my($self,$all,$undef,@val) = @_;
   $$self{"err"} = "";

   foreach my $val (@val) {
      my(@idx);
      if ($all) {
         @idx = $self->rindex($val);
         next  if (! @idx);
      } else {
         my $idx = $self->index($val);
         next  if ($idx == -1);
         @idx = ($idx);
      }

      if ($undef) {
         foreach my $idx (@idx) {
            $$self{"set"}[$idx] = undef;
         }
      } else {
         foreach my $idx (@idx) {
            CORE::splice(@{ $$self{"set"} },$idx,1);
         }
      }
   }
   return;
}

sub delete_at {
   my($self,$undef,@idx) = @_;
   $$self{"err"} = "";

   my @list = @{ $$self{"set"} };
   foreach my $idx (@idx) {
      if ($idx !~ /^[+-]?\d+$/) {
         $$self{"err"} = "Index must be an integer";
         return undef;
      }
      if ($idx < -($#list + 1)  ||
          $idx > $#list) {
         $$self{"err"} = "Index out of bounds";
         return undef;
      }
      if ($idx < 0) {
         $idx = $#list + 1 + $idx;
      }
   }
   @idx = sort { $b <=> $a } @idx;

   if ($undef) {
      foreach my $idx (@idx) {
         $$self{"set"}[$idx] = undef;
      }
   } else {
      foreach my $idx (@idx) {
         CORE::splice(@{ $$self{"set"} },$idx,1);
      }
   }
   return;
}

sub fill {
   my($self,$val,$start,$length) = @_;
   $$self{"err"} = "";

   my @list = @{ $$self{"set"} };

   $start = 0  if (! $start);
   if ($start !~ /^[+-]?\d+$/) {
      $$self{"err"} = "Start must be an integer";
      return undef;
   }
   if ($start < -($#list + 1)  ||
       $start > $#list + 1) {
      $$self{"err"} = "Start out of bounds";
      return undef;
   }
   if ($start < 0) {
      $start = $#list + 1 + $start;
   }

   if (! defined $length) {
      if ($start > $#list) {
         $length = 1;
      } else {
         $length = ($#list + 1 - $start);
      }
   }

   if ($length !~ /^\d+$/) {
      $$self{"err"} = "Length must be an unsigned integer";
      return undef;
   }
   my $end = $start + $length - 1;

   foreach my $i ($start..$end) {
      $list[$i] = $val;
   }

   $$self{"set"} = [@list];
   return;
}

sub min {
   my($self,$method,@args) = @_;

   if (! defined $method) {
      $method = "numerical";
   }

   my(@list) = _sort($self,$method,@args);
   return undef  if ($self->err());

   return $list[0];
}

sub max {
   my($self,$method,@args) = @_;

   if (! defined $method) {
      $method = "numerical";
   }

   my(@list) = _sort($self,$method,@args);
   return undef  if ($self->err());

   return $list[$#list];
}

sub pop {
   my($self) = @_;
   $$self{"err"}   = "";

   my $val = CORE::pop @{ $$self{"set"} };
   return $val;
}

sub shift {
   my($self) = @_;
   $$self{"err"}   = "";

   my $val = CORE::shift @{ $$self{"set"} };
   return $val;
}

sub push {
   my($self,@list) = @_;
   $$self{"err"}   = "";

   CORE::push(@{ $$self{"set"} },@list);
   return;
}

sub unshift {
   my($self,@list) = @_;
   $$self{"err"}   = "";

   CORE::unshift(@{ $$self{"set"} },@list);
   return;
}

sub randomize {
   my($self) = @_;
   $self->sort("random");
}

sub reverse {
   my($self) = @_;
   $$self{"err"}   = "";

   my @list = @{ $$self{"set"} };
   $$self{"set"} = [ CORE::reverse(@list) ];
   return;
}

sub rotate {
   my($self,$n) = @_;
   $n = 1  if (! defined $n);
   $$self{"err"} = "";

   if ($n !~ /^[+-]?\d+$/) {
      $$self{"err"} = "Rotation number must be an integer";
      return undef;
   }

   my @list = @{ $$self{"set"} };
   if ($n > 0) {
      for (my $i=1; $i<=$n; $i++) {
         CORE::push(@list,CORE::shift(@list));
      }
   } elsif ($n < 0) {
      $n *= -1;
      for (my $i=1; $i<=$n; $i++) {
         CORE::unshift(@list,CORE::pop(@list));
      }
   }

   $$self{"set"} = [@list];
   return;
}

sub set {
   my($self,$index,$val) = @_;
   $$self{"err"} = "";

   if (! defined $index) {
      $$self{"err"} = "Index required";
      return undef;
   }

   my @list = @{ $$self{"set"} };

   if ($index !~ /^[+-]?\d+$/) {
      $$self{"err"} = "Index must be an integer";
      return undef;
   }
   if ($index < -($#list + 1)  ||
       $index > $#list) {
      $$self{"err"} = "Index out of bounds";
      return undef;
   }

   $$self{"set"}[$index] = $val;
   return;
}

sub sort {
   my($self,$method,@args) = @_;

   if (! defined $method) {
      $method = "alphabetic";
   }

   my(@list) = _sort($self,$method,@args);
   return undef  if ($self->err());

   $$self{"set"} = [@list];
   return;
}

sub _sort {
   my($self,$method,@args) = @_;
   $$self{"err"} = "";

   if (! sort_valid_method($method)) {
      $$self{"err"} = "Invalid sort method";
      return undef;
   }

   my @list = @{ $$self{"set"} };
   sort_by_method($method,\@list,@args);
   return @list;
}

sub splice {
   my($self,$start,$length,@vals) = @_;
   $$self{"err"} = "";

   my @list = @{ $$self{"set"} };

   $start = 0  if (! $start);
   if ($start !~ /^[+-]?\d+$/) {
      $$self{"err"} = "Start must be an integer";
      return undef;
   }
   if ($start < -($#list + 1)  ||
       $start > $#list) {
      $$self{"err"} = "Start out of bounds";
      return undef;
   }
   if ($start < 0) {
      $start = $#list + 1 + $start;
   }

   if (! defined $length) {
      if ($start > $#list) {
         $length = 1;
      } else {
         $length = ($#list + 1 - $start);
      }
   }

   if ($length !~ /^\d+$/) {
      $$self{"err"} = "Length must be an unsigned integer";
      return undef;
   }
   my $end = $start + $length - 1;

   my @ret = CORE::splice(@list,$start,$length,@vals);

   $$self{"set"} = [@list];
   return @ret;
}

sub unique {
   my($self) = @_;
   $$self{"err"} = "";

   my @list = ();
   my %list = ();
   my $undef = 0;

   foreach my $ele (@{ $$self{"set"} }) {
      if (! defined($ele)) {
         if (! $undef) {
            CORE::push(@list,$ele);
            $undef = 1;
         }
      } elsif (! CORE::exists $list{$ele}) {
         CORE::push(@list,$ele);
         $list{$ele} = 1;
      }
   }
   $$self{"set"} = [@list];
   return;
}

###############################################################################
# SET METHODS
###############################################################################

sub difference {
   my($obj1,$obj2,$unique) = @_;

   my @list  = @{ $$obj1{"set"} };
   my $class = ref($obj1);
   my $ret   = new $class;

   if (ref($obj2) ne $class) {
      $$ret{"err"} = "Obj2 not of the right class";
      return $ret;
   }

   # $ret starts as identical to $obj1
   # remove every element in $obj2 from $ret

   $ret->list(@list);
   my $all = ($unique ? 1 : 0);
   foreach my $ele (@{ $$obj2{"set"} }) {
      $ret->delete($all,0,$ele);
   }

   return $ret;
}

sub intersection {
   my($obj1,$obj2,$unique) = @_;

   my $class = ref($obj1);
   my $ret   = new $class;

   if (ref($obj2) ne $class) {
      $$ret{"err"} = "Obj2 not of the right class";
      return $ret;
   }

   # $tmp is identical to $obj2
   # foreach element in $obj1
   #    if it's in $tmp
   #       add it to $ret
   #       remove it from $tmp

   my $tmp   = new $class;
   $tmp->list(@{ $$obj2{"set"} });
   my $all   = ($unique ? 1 : 0);

   my @list  = @{ $$obj1{"set"} };
   foreach my $ele (@list) {
      if ($tmp->exists($ele)) {
         $ret->push($ele);
         $tmp->delete($all,0,$ele);
      }
   }

   return $ret;
}

sub is_equal {
   my($obj1,$obj2,$unique) = @_;

   my $class = ref($obj1);

   if (ref($obj2) ne $class) {
      return undef;
   }

   my @list1  = @{ $$obj1{"set"} };
   my @list2  = @{ $$obj2{"set"} };

   if ($unique) {
      foreach my $ele (@list1) {
         return 0  if (! $obj2->exists($ele));
      }
      foreach my $ele (@list2) {
         return 0  if (! $obj1->exists($ele));
      }
      return 1;
   }

   foreach my $ele (@list1,@list2) {
      return 0  if ($obj1->count($ele) != $obj2->count($ele));
   }
   return 1;
}

sub not_equal {
   return 1 - is_equal(@_);
}

sub is_subset {
   my($obj1,$obj2,$unique) = @_;

   my $class = ref($obj1);

   if (ref($obj2) ne $class) {
      return undef;
   }

   my @list  = @{ $$obj2{"set"} };

   if ($unique) {
      foreach my $ele (@list) {
         return 0  if (! $obj1->exists($ele));
      }
      return 1;
   }

   foreach my $ele (@list) {
      return 0  if ($obj2->count($ele) > $obj1->count($ele));
   }
   return 1;
}

sub not_subset {
   return 1 - is_subset(@_);
}

sub symmetric_difference {
   my($obj1,$obj2,$unique) = @_;

   my $class = ref($obj1);
   my $ret   = new $class;

   if (ref($obj2) ne $class) {
      $$ret{"err"} = "Obj2 not of the right class";
      return $ret;
   }

   my $tmp1  = new $class;
   my @list1 = @{ $$obj1{"set"} };
   $tmp1->list(@list1);

   my $tmp2  = new $class;
   my @list2 = @{ $$obj2{"set"} };
   $tmp2->list(@list2);

   my $all   = ($unique ? 1 : 0);

   foreach my $ele (@list1,@list2) {
      if ($tmp1->exists($ele)  &&  $tmp2->exists($ele)) {
         $tmp1->delete($all,0,$ele);
         $tmp2->delete($all,0,$ele);
      } elsif ($tmp1->exists($ele)) {
         $ret->push($ele);
         $tmp1->delete(0,0,$ele);
      } elsif ($tmp2->exists($ele)) {
         $ret->push($ele);
         $tmp2->delete(0,0,$ele);
      }
   }

   return $ret;
}

sub union {
   my($obj1,$obj2,$unique) = @_;

   my $class = ref($obj1);
   my $ret   = new $class;

   if (ref($obj2) ne $class) {
      $$ret{"err"} = "Obj2 not of the right class";
      return $ret;
   }

   my @list1 = @{ $$obj1{"set"} };
   my @list2 = @{ $$obj2{"set"} };

   $ret->list(@list1,@list2);
   if ($unique) {
      $ret->unique();
   }

   return $ret;
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

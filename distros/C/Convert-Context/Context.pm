#
# $Id: Context.pm,v 1.77 1998/10/03 22:21:23 martin Exp $
#
# Convert::Context, an attributed text data type
#
# Copyright (C) 1996, 1997 Martin Schwartz
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, you should find it at:
#
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/COPYING
#

package Convert::Context;
use strict;
my $VERSION=do{my@R=('$Revision: 1.77 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};

sub CS () {"C"};
my $Debug = 0;
my $default_acmp = sub { $_[0] cmp $_[1] };

sub acmp       { shift->_member("A", @_) }
sub docmode    { shift->_mode(@_ ? ("DOC"):())  eq "DOC" }
sub textmode   { shift->_mode(@_ ? ("TEXT"):()) eq "TEXT" }

sub _attrib    { shift->_member("ATT", @_) }
sub _charsize  { shift->_member(CS, @_) }
sub _mode      { shift->_member("MOD", @_) }
sub _offset    { shift->_member("O", @_) }
sub _text      { shift->_member("T", @_) }

sub _member { my $S=shift; my $n=shift; $S->{$n}=shift if @_; $S->{$n} }

sub append {
#
# $Ct1 = $Ct1 -> append (($Ctn||$strn||$strRn)*)
#
   my $S = shift;
   my $acmp = $S->acmp();

   my ($Ct2, $o);
   while (@_) {
      $Ct2 = shift;
      if (!ref($Ct2)) {
         ${$S->_text} .= $Ct2;
         next;
      } elsif (ref ($Ct2) =~ /^SCALAR$/) {
         ${$S->_text} .= $$Ct2;
         next;
      }
      $o = $S->length();

      if (!$o) {
         ${$S->_text} .= ${$Ct2->_text};
         @{$S->_offset}=();
         @{$S->_attrib}=();
         push (@{$S->_offset}, @{$Ct2->_offset});
         push (@{$S->_attrib}, @{$Ct2->_attrib});
         next;
      }

      ${$S->_text} .= ${$Ct2->_text};
      next if $S->textmode;
      my $cs   = $S->_charsize;
      my $cs2  = $Ct2->_charsize;
      my $flag = ($cs==$cs2);

      if (! &$acmp ($S->_attrib->[$#{$S->_attrib}], $Ct2->_attrib->[0])) {
         my $end = $#{$Ct2->_offset};
         push (@{$S->_offset}, map 
            {$flag ? $_+$o : $o+$_/$cs2*$cs} @{$Ct2->_offset}[1..$end] 
         );
         push (@{$S->_attrib}, @{$Ct2->_attrib}[1..$end]);
      } else {
         push (@{$S->_offset}, map 
            {$flag ? $_+$o : $o+$_/$cs2*$cs} @{$Ct2->_offset} 
         );
         push (@{$S->_attrib}, @{$Ct2->_attrib});
      }
   } 
   $S;
}

sub attrib {
#
# (1)           $attrib = $Ct  -> attrib ($o, [$attrib])
# (2) ([@attrib], [@o]) = $Ct  -> attrib ($o, $l)
# (3)           $attrib = $Ct  -> attrib ($o, $l, $attrib)
# (4)        1 || undef = $Ct  -> attrib ($o1, $l1, [@attrib], [@o])
# (5)        1 || undef = $Ct  -> attrib ($o1, $l1, [@attrib], [@o], $o2, $l2)
# (6)        1 || undef = $Ct1 -> attrib ($o, $l, $Ct2)
# (7)        1 || undef = $Ct1 -> attrib ($o1, $l1, $Ct2, $o2, $l2)
#
   my $S = shift;
   return undef if $S->textmode;

   if (!$#_ || ($#_==1) && ref($_[1])) {
      # case (1)
      my $o = @_ ? shift : 0;
      $o += $S->length() if $o<0; 
      return undef if $o<0;

      my $i = $S->_index($o);
      $S->_attrib->[$i] = shift->[0] if @_;
      return $S->_attrib->[$i];
   }

   my $o1 = @_ ? shift : 0;
   $o1 += $S->length() if $o1<0; 
   return undef if $o1<0;
   my $l1 = @_ ? shift : 0;
   if (!@_) {
      # case (2)
      my $il = $S->_index($o1) || 0;
      my $ir = $S->_index($o1+$l1-1) || 0;
      return (
         [@{$S->_attrib}[$il, $il+1..$ir]],
         [0, map $_-$o1, @{$S->_offset}[$il+1..$ir]] 
      );
   } 

   my $ref = @_ ? ref($_[0]) : "";
   if (!$ref) {
      # case (3)
      my $attrib = @_ ? shift: 0;
      return $S->_subattr($o1, $l1, [$attrib], [0]) && $attrib;
   } elsif ($ref =~ /^ARRAY$/) {
      # case (4) and (5)
      return $S->_subattr($o1, $l1, @_);
   } else {
      # case (6) and (7)
      my $Ct2 = shift;
      push (@_, $_[2]) if $#_==2;
      return $S->_subattr($o1, $l1, $Ct2->_attrib, $Ct2->_offset, @_);
   }

   undef;
}

sub charsize { 
   my ($S, $cs) = @_;
   my $cs_orig = $S->_charsize();
   return $cs_orig if !$cs || $cs_orig==$cs;
   my $O = $S->_offset;
   for (@$O) { 
      $_*=$cs_orig; $_/=$cs;
   }
   $S->_charsize($cs);
}

sub chunks {
#
# [ [$str1, $attr1], [$str2, $attr2], [$str3, $attr3] ...] = $S->chunks
#
   my $S = shift;
   my $A = $S->_attrib;
   my $O = $S->_offset;
   my $T = $S->_text;
   my $n = $#{$S->_offset};
   my $left = 0;
   my $cs = $S->_charsize;
   [  map (
         [substr($$T, $O->[$_-1]*$cs, $O->[$_]*$cs-$O->[$_-1]*$cs), $A->[$_-1]],
         (1..$n)
      ), 
      [ substr($$T, $O->[$n]*$cs, $S->length()*$cs-$O->[$n]*$cs), $A->[$n] ]
   ];
}

sub clone {
   my $S = shift;
   my $N = $S->new(
      $S->_charsize,
      \(my $text = ${$S->_text}), 
      [@{$S->_attrib}], 
      [@{$S->_offset}], 
      1
   );
   $N->_mode($S->_mode);
   $N->acmp($S->acmp);
   $N;
}

sub dump {
   my ($S, $mode) = @_;
   print "Dumping (mode $mode), object ".
      (($S =~ /(^[^=]*)/) && $1).
      "\n" . ${$S->sdump($mode)} . "Done.\n\n\n"
   ;
   $S;
}

sub eq {
#
# 1||0 = $Ct1 -> eq ($Ct2)
#
   my ($S, $Ct2) = @_;
   return undef if !$Ct2;
   return 1 if $S eq $Ct2;
   return 0 if !ref($Ct2);
   return 0 if ref($S) ne ref($Ct2);
   return 0 if $S->_charsize != $Ct2->_charsize;
   return 0 if ${$S->_text} ne ${$Ct2->_text};
   $S->_cmp_attribs($Ct2);
}

sub index {
#
# $pos = $Ct -> index ($string [,$pos])
#
   my ($S, $str, $pos) = @_;
   my $cs = $S->charsize;
   my $i = ($pos||0) * $cs - $cs;
   while (1) {
      $i = index(${$S->_text}, $str, $i+(($i%$cs)||$cs));
      return $i if $cs == 1;
      return $i if $i == -1;
      if (!($i % $cs)) {
         return $i / $cs;
      }
   }
}

sub join {
#
# $Ct  = Convert::Context -> join ($expr, ($Ctn||$strn||$strRn)*)
#
# $Ct1 = $Ct1 -> join ($expr, ($Ctn||$strn||$strRn)*)
#
   my $S = shift;
   return undef if !@_;
   my $expr = shift;
   my @extra = ();

   if (!ref($S)) {
      $S = $S -> new (eval {$_[0]->charsize});
   } else {
      @extra = ($expr);
   }
   return $S if !@_;

   $S->append( @extra, shift, map {($expr, $_)} @_ );
}

sub lc      { shift->_apply_f_to_t("CORE::lc") }
sub lcfirst { shift->_apply_f_to_t("CORE::lcfirst") }

sub length {
#
# $len = $Ct -> length ()
#
   length(${$_[0]->_text}) / $_[0]->_charsize();
}

sub ne {
   !shift->eq(@_);
}

sub new {
   my $proto = shift;
   my $S = bless ({}, ref($proto) || $proto);
   $S->docmode (1);
   $S->acmp ($default_acmp);

   if (@_ && !ref($_[0])) {
      $S->_charsize(shift());
   } else {
      $S->_charsize(1);
   }

   if (@_ && ref($_[0])=~ /^ARRAY/) {
      $S->_entry(@{shift()});
      for (@_) { $S->append( $S->new(@{$_}) ) }
   } else {
      $S->_entry(@_);
   }

   # Offsets and Attribute pairs doesn't match
   return 0 if $#{$S->_offset} != $#{$S->_attrib};

   $S;
}

sub replace {
   my ($S, $pattern, $replace, $option) = @_;
   return 0      if !defined $pattern;
   $replace = "" if !defined $replace;
   $option  = "" if !defined $option;

   my @L = ();
   my %R_Context = ();
   my %R_scalar  = ();
   my $array = "";
   my $code = "";
   my $Ct = "";
   my $s_pattern = "";
   my $s_replace = "";

   if ($array = ref ($pattern) =~ /^ARRAY/) {
      for (0..$#{$pattern}) {
         if (ref($pattern->[$_])) {
            $R_Context {${$pattern->[$_]->_text}} = $_;
            $s_pattern .= ${$pattern->[$_]->_text};
         } else {
            $R_scalar {$pattern->[$_]} = $_;
            $s_pattern .= $pattern->[$_];
         }
         $s_pattern .= '|';
      };
      $s_pattern =~ s/\|$//;
   } elsif (ref ($pattern)) {
      $Ct = $pattern;
      $s_pattern = ${$pattern->_text};
      $code = (ref ($replace) =~ /^CODE/);
   } else {
      $s_pattern = $pattern;
      $code = (ref ($replace) =~ /^CODE/);
   }
   $s_replace=$replace;

   my ($i, $m, $n, $oc, $lc);
   my $cs = $S ->_charsize;
   $n = eval '${$S->text} =~ '.
      's#$s_pattern#{
         $oc=CORE::length($`); return $& if ($oc%$cs); $oc/=$cs; 
         $lc=CORE::length($&); 
         if ($lc%$cs) {
            $lc+=($lc%$cs); 
            $m = CORE::substr(${$S->_text}, $oc*$cs, $lc);
         } else {
            $m = $&;
         }
         $lc/=$cs;
         if ($array) {
            if (defined ($i = $R_Context{$&})) {
               $Ct = $pattern->[$i];
               $s_replace = $replace->[$i];
            } elsif (defined ($i = $R_scalar{$&})) {
               $Ct = "";
               $s_replace = $replace->[$i];
            } else {
               $Ct = "";
               $s_replace = "";
            }
            $code = (ref ($s_replace) =~ /^CODE/);
         } 
         if (!$Ct || $Ct->_cmp_attribs($S->attrib($oc, $lc))) {
            push (@L, [$oc, $lc, $code ? &$s_replace($m, $S, $oc):$s_replace]);
         }
         $&;
      }#e'.($option||"")
   ;
   while (@L) {
      $S->substr(@{pop(@L)});
   }
   $n;
}

sub sdump {
#
# \$buf = $S->sdump($mode)
#
   my ($S, $mode) = @_;
   my $n;
   my $buf="";

   if ($mode) {
      $buf .= "\"";
      for (@{$S->chunks}) {
         $buf .= sprintf ("<%s>", $_->[1]) if defined $_->[1];
         $buf .= $_->[0];
      }
      $buf .= "\"\n";
   } else {
      $buf .= "   text => \"" . ${$S->_text} . "\"\n";
   }
   if ($S->charsize()!=1) {
      $buf .= sprintf ("   charsize=%d, textlen=%d\n", 
         $S->charsize(), $S->length()
      );
   }
   $n = $#{$S->_attrib}+1;
   $buf .= sprintf ("   attrib => [ " . ("%3s " x $n) . "]\n", @{$S->_attrib});
   $n = $#{$S->_offset}+1;
   $buf .= sprintf ("   offset => [ " . ("%03x " x $n) . "]\n", @{$S->_offset});
   \$buf;
}

sub split {
#
# @Ct = $Ct -> split ($pattern, $option, $limit) 
#   
   my ($S, $pattern, $option, $limit) = @_;
   my @L = ();

   my $Ct = ref ($pattern) ? $pattern : "";
   $pattern = ${$Ct->_text} if $Ct;
   my $cs = $S->_charsize;

   my $o = 0;
   my ($l, $ml);
   eval '${$S->text} =~ '.
      's#$pattern#{
         $l = CORE::length($`);
         $ml = CORE::length($&); $ml+=($ml%$cs); $ml/=$cs;
         if (!($l % $cs) &&
            (!$Ct || 
               $Ct->_cmp_attribs($S->attrib($l/$cs, $ml))
            )
         ) {
            push (@L, $S->substr($o, $l/$cs-$o));
            $o = ($l/$cs+$ml);
         }
         $&;
      }#e'."g".($option||"")
   ;
   push (@L, $S->substr($o));
   if ($limit) {
      # no better idea, how to limit, sigh...
      @L[0..$limit-1];
   } else {
      # Split strips "trailing null fields", when no $limit given.
      while (@L) { last if $L[$#L]->length(); pop(@L) }
      @L;
   }
}

sub substr {
#
# $Context1 = $Context1 -> substr (
#    $o1||undef, $l1||undef, $Context2, $o2||undef, $l2||undef
# )
#
# Substitutes $Context1->substr($o1, $l1) with $Context2->substr($o2, $l2)
#
# o1|o2: undef => 0
# l1|l2: undef => length($Contextn)
#
   my ($S, $o1, $l1, $Ct2, $o2, $l2) = @_;

   my $len1 = $S->length();
   $o1 = 0 if !defined $o1;
   $o1 += $len1 if $o1<0; 
   return undef if $o1<0;
   my $cs = $S->_charsize;

   $l1 = $len1 - $o1 if !defined $l1;

   #
   # Case 1: Return a new partial Context 
   #
   if (!$Ct2) {
      return $S->new(
         $cs,
         \(my $text = substr(${$S->_text}, $o1*$cs, $l1*$cs)), 
         $S->attrib($o1, $l1),
         1
      );
   }

   my $len2;

   #
   # Case 2: Substitute argument is a simple string
   #
   if (!ref $Ct2) {
      $len2 = CORE::length($Ct2);
      $o2 = 0 if !defined $o2;
      $o2 += $len2 if $o2<0; 
      $l2 = $len2 - $o2 if !defined $l2;

      # Special case: same string lengths: change only string.
      if ($l1*$cs == $l2) {
         substr(${$S->_text}, $o1*$cs, $l1*$cs) = 
            substr($Ct2, $o2, $l2)
         ;
         return $S;
      } 
      # Normal case: different string lengths: create Context on the fly.
      $Ct2 = $S->new(
         $S->_charsize, \substr($Ct2, $o2, $l2), $S->attrib($o1, $l1)
      );
      $o2 = 0;
      $l2 /= $cs;
   }

   #
   # Case 3: Substitute argument is another Context
   #
   # 
   # Note: The following 3 lines could do a similar job like the messy
   # looking code afterwards. Everything would look fine and easy. 
   # The problem: That code would construct a new Context and would not 
   # change the old Context; further more I suspect it to be slower.
   #
   # return = $S->substr(0, $o1)
   #    ->join($Ct2)
   #    ->join($S->substr($o1+$l1))
   # ;
   #

   my $cs2 = $Ct2->_charsize;
   $len2 = $Ct2->length();
   $o2 = 0 if !defined $o2;
   $o2 += $len2 if $o2<0; 
   $l2 = $len2 - $o2 if !defined $l2;

   if (!$S->textmode) {
      $S->_subattr($o1, $l1, $Ct2->_attrib, $Ct2->_offset, $o2, $l2, $l2);
   }

   substr(${$S->_text}, $o1*$cs, $l1*$cs) = 
      substr(${$Ct2->_text}, $o2*$cs2, $l2*$cs2)
   ;

   $S;
}

sub rindex {
#
# $pos = $Ct -> rindex ($string [,$pos])
#
   my ($S, $str, $pos) = @_;
   $pos = $S->length() if !defined $pos;
   my $cs = $S->charsize;
   my $i = $pos * $cs + $cs;
   while (1) {
      $i = rindex(${$S->_text}, $str, $i-(($i%$cs)||$cs));
      return $i if $cs == 1;
      return $i if $i == -1;
      if (!($i % $cs)) {
         return $i / $cs;
      }
   }
}

sub text {
   shift->_text();
}

sub tr      { goto &y }
sub uc      { shift->_apply_f_to_t("CORE::uc") }
sub ucfirst { shift->_apply_f_to_t("CORE::ucfirst") }

sub y {
#
# $Ct -> y ($search_str, $replace_str, $mode)
# $Ct -> y (\@search[0..n], \@replace[0..n], $mode)
#
   my ($S, $search, $replace, $mode) = @_;
   $search  = "" if !defined $search;
   $replace = "" if !defined $replace;
   $mode    = "" if !defined $mode;
   my $cs = $S->_charsize;
   if (ref($search)) {
      $S->replace($search, $replace, "g$mode");
   } elsif ($cs==1) {
      $mode =~ s/g//g;
      eval '${$S->_text} =~ y/'.
         ($search||"")."/".($replace||"")."/".($mode||"")
      ;
   } else {
      $S->replace(
         [map CORE::substr($search, $_*$cs, $cs), (0..(CORE::length($search)/$cs-1))],
         [map CORE::substr($replace, $_*$cs, $cs), (0..(CORE::length($replace)/$cs-1))],
         "g$mode"
      );
   }
   $S;
}
sub _dl { my ($lR,$str)=@_; 
   print "$str: " if $str; printf "(".("'%s', "x($#{$lR}+1)).")\n", @{$lR};
}

sub _apply_f_to_t {
#
# lc, lcfirst, uc, ucfirst
#
   my ($S, $apply) = @_;
   $S->new (
      $S->_charsize,
      \(eval "$apply".'(${$S->_text})'), 
      [@{$S->_attrib}], [@{$S->_offset}], 
      1
   );
}

sub _cmp_attribs {
#
# 1||0 = $Ct1 -> _cmp_attribs ($Ct2)
# 1||0 = $Ct1 -> _cmp_attribs ([@attrib], [@offset])
#
   my ($S, $a2R, $o2R) = @_;
   if (!defined $o2R) {
      my $Ct2 = $a2R;
      $a2R = $Ct2->_attrib;
      $o2R = $Ct2->_offset;
   }
   return 0 if !$S->_cmp_slist($S->_attrib, $a2R);
   return 0 if !$S->_cmp_nlist($S->_offset, $o2R);
1}

sub _cmp_nlist {
#
# 1||0 = _cmp_nlist ([@list1], [@list2])
#
   my ($S, $aR, $bR) = @_;
   return 0 unless @$aR == @$bR;
   for (0..$#$aR) { return 0 if $aR->[$_] != $bR->[$_] }
1}
sub _cmp_slist {
#
# 1||0 = _cmp_slist ([@list1], [@list2])
#
   my ($S, $aR, $bR) = @_;
   my $acmp = $S->acmp();
   return 0 unless @$aR == @$bR;
   for (0..$#$aR) { return 0 if &$acmp ($aR->[$_], $bR->[$_]) }
1}

sub _entry {
#
# 1 = $S -> entry (\$text, [@attrib], [@offset], $mode)
#
# mode = 0: make copies of text, attrib and offset (store values)
#        1: use given references                   (store references)
#
   my ($S, $textR, $attribR, $offsetR, $mode) = @_;
   
   if (!$mode) {
      $S->_text   (\(my $text = $textR ? $$textR : ""));
      $S->_attrib ($attribR ? [@$attribR] : [0]);
      $S->_offset ($offsetR ? [@$offsetR] : [0]);
   } else {
      $S->_text   ($textR   ? $textR : \(""));
      $S->_attrib ($attribR ? $attribR : [0]);
      $S->_offset ($offsetR ? $offsetR : [0]);
   }
1}

sub _index {
#
# $context_index = -> _index ($position [,[@offset]])
#
   my ($S, $pos, $oR) = @_;
   return 0     if !$pos;
   return undef if $pos < 0;
   $oR = $S->_offset if !defined $oR;

   my $og = $#{$oR};
   return $og if $pos >= ($oR->[$og]);
   my $ug = 0;
   my $step;

   while ($step = ($og-$ug) >> 1) {
      if ($oR->[$ug+$step] <= $pos) {
         $ug += $step;
      } else {
         $og -= $step;
      }
   }

   $ug;
}

sub _subattr {
#
# ([@attrib], [@o]) = 
#    $Ct -> _subattr ($o1, $l1, [@attrib], [@o] [,$o2, $al2 [,$tl2]])
#
# Substitutes $Ct's attributes from position o1 and length l1 with
# @attrib and @o. The substituted textlength will stay l1, unless tl2 given.
#
   my ($S, $o1, $l1, $aR2, $oR2, $o2, $al2, $tl2) = @_;
   return undef if !defined $oR2;

   my $len1 = $S->length();
   $o1 += $len1 if $o1<0; 
   return undef if $o1<0;
   return undef if ($o1+$l1) > $len1;
   return 1 if ($o1 && ($o1==$len1));

   $al2 = $l1 if !defined $al2;
   $tl2 = $l1 if !defined $tl2;
   $o2 = 0 if !defined $o2;
   return undef if $o2<0;
 
   my $i1_right = $o1 ? $S->_index($o1-1) : 0;
   my $i2_left  = $S->_index($o2, $oR2);
   my $i2_right = ($o2+$al2-1) ? $S->_index($o2+$al2-1, $oR2) : 0;
   my $i3_left  = $S->_index($o1+$l1);

   my $a1_right = $S->_attrib->[$i1_right];
   my $a2_left  = $aR2->[$i2_left];
   my $a2_right = $aR2->[$i2_right];
   my $a3_left  = $S->_attrib->[$i3_left];

   my $o1_right = $S->_offset->[$i1_right];
   my $o2_left  = $oR2->[$i2_left];

   my @a_left=();  my @o_left=();
   my @a_right=(); my @o_right=();

   my $diff_middle = $tl2 - $l1;
   my $diff_right = $o1 - $o2;

   my $acmp = $S->acmp();

   if ($o1) {
      push (@a_left, $a1_right);         
      push (@o_left, $o1_right);
   }

   if ((!$o1) || &$acmp($a1_right, $a2_left)) { 
      push (@a_left, $a2_left);
      push (@o_left, $o1);
   }

   if ( (($o1+$l1) < $len1) &&
      &$acmp ($a2_right, $a3_left)
   ) {
      push (@a_right, $a3_left);
      push (@o_right, $o1+$tl2);
   }
#print "a1r=$a1_right a2l=$a2_left a2r=$a2_right a3l=$a3_left\n";
#print "i1r=$i1_right i2l=$i2_left i2r=$i2_right i3l=$i3_left\n";
#print "o1=$o1 l1=$l1  o2=$o2 al2=$al2 tl2=$tl2  o1r=$o1_right o2l=$o2_left\n";
#print "len1=$len1\n";
#print "al=(@a_left) ar=(@a_right)  ol=(@o_left) or=(@o_right)\n\n";

   splice (@{$S->_attrib}, 
      $i1_right, 
      $i3_left-$i1_right+1, 
      (@a_left, 
       @{$aR2}[$i2_left+1..$i2_right], 
       @a_right
      )
   );

   for (@{$S->_offset}[$i3_left+1 .. $#{$S->_offset}]) { 
      $_ += $diff_middle
   }
  
   splice (@{$S->_offset},
      $i1_right,
      $i3_left-$i1_right+1,
      (@o_left, 
       (map {$_+$diff_right} @{$oR2}[$i2_left+1..$i2_right]),
       @o_right
      )
   );
1}

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

Convert::Context - an Attributed Text data type

- ALPHA - release

$Revision: 1.77 $ $Date: 1998/10/03 22:21:23 $

=head1 SYNOPSIS

See below.

=head1 DESCRIPTION

Convert::Context maintains attributed strings. It allows you to access
those strings similar to perl's normal strings. 

An attributed string is a string to that attributes are connected at
certain string positions. An attribute can be everything scalar: numbers, 
strings, references are welcome. Attributes are not part of the string. 
Semantics of the attributes have to be done by the applying code.

What does this mean?

A basic work for a text system is to localize a certain text part. This is
trivial if you have only plain text to look at. It is no longer trivial, if 
you have attributes or entries among your text like: bold, italic, bookmarks 
and so on. One has two strategies to mingle attributes with a string:

=over 4

=item 1.

You can enrich the text by inserting control codes. E.g., if you have a line 
with two bold words: 

(A) "The word B<bold> is always B<bold>" 

it would look (here with HTML controls) like: 

(B) "The word <b>bold</b> is always <b>bold</b>" 

If you would look for the text "bold is" in (B) with perls m// operator, 
you'd fail. You would have to strip the HTML control sequences first. This 
is an ok method, but not used here.

=item 2.

You can maintain separate lists, holding at which position of the text 
which control codes are stored. This is, what Convert::Context does. 
The example from above would look like:

   offset    0---------1---------2-------
   text      The word bold is always bold
   attrib   (0        1   0          1   )

Internally this is stored as:

  $Context = {
     "T" => \("The word bold is always bold"),
     "A" => [0, 1,  0,  1]
     "O" => [0, 9, 13, 24],
  }

The maintainance of these lists is a little bit tricky, so what a luck,
that you don't need to care about this. 

=back

Do not rely on this internal representation, as it might change. E.g. it could 
happen, that "O" in future stores relative offsets instead of absolute.

B<Available Methods>

=over 4

=item acmp

I<sub { $Code }> = I<$Ct> -> acmp (I<sub { $Code }>)

When two attribs shall be compared, this normally is done stringwise, using
function "cmp". If this is not practical for you, with acmp you could provide 
a new compare function, similar to the way you do when using sort. 

The standard behavior is implemented this way:

   $Ct -> acmp (sub { $_[0] cmp $_[1] })

B<Note:> The code provided via acmp is not used when comparing identity. 
That means: I<$Ct1> -> eq (I<$Ct1>) is always true.

=item append

I<$Ct1> = I<$Ct1> -> append (I<$Ct2>||I<$str2>||I<$strR2>, ...)

Appends all strings, string references or Contexts to the end of Context1.

=item attrib

Attrib is used to yield and change the attributes of a Context. It can
be called several ways. 

(1) I<$attrib> = I<$Ct> -> attrib (I<$pos> [,I<[$attrib]>])

When called in a scalar context with only I<$pos> as parameter, attrib
returns the attribute of Context at character position I<$pos>. You can
can set the attribute by specifying the new one as a list reference (not 
recommended).

(2) (I<[@attrib]>, I<[@offset]>) = I<$Ct> -> attrib (I<$pos>, I<$len>)

When called in an array context, a list with references to a free usable
attrib array and a free usable offset array is returned. 

(3) I<$attrib> = I<$Ct> -> attrib (I<$pos>, I<$len>, I<$attrib>)

When called in a scalar context with three parameters and I<$attrib> is
scalar, the attributes of Context Ct starting at position I<$pos> with 
length I<$len> will be set to I<$attrib>.

(4) C<1>||C<undef> = I<$Ct> -> attrib (I<$o1>, I<$l1>, I<[@attrib]>, I<[@offset]>)

Substitutes attributes of Context Ct from position o1 and length l1 with
attributes I<[@attrib]> according to offsets I<[@offset]>. 

(5) C<1>||C<undef> = I<$Ct> -> attrib (I<$o1>, I<$l1>, I<[@attrib]>, I<[@offset]>, I<$o2>, I<$l2>)

Like (4), but I<@attrib> and I<@offset> are reduced according to offset
I<$o2> and length I<$l2>.

(6) C<1>||C<undef> = I<$Ct1> -> attrib (I<$o1>, I<$l1>, I<$Ct2>)

Substitutes attributes of Context I<$Ct1> from position I<$o1> and length
I<$l1> with attributes of Context I<Ct2> from position C<0> to position
I<$l1>.

B<Note:> Attrib does not care for the length of I<$Ct2>!

(7) C<1>||C<undef> = I<$Ct1> -> attrib (I<$o1>, I<$l1>, I<$Ct2> [,I<$o2>, I<$l2>])

Like (6), but only the part of I<$Ct2> from position I<$o2> with a length
I<$l2> is used. 

=item charsize

I<$Ct> = I<$Ct> -> charsize ([I<$bytesize_of_one_char>])

Returns the character size of Context Ct. The character size is the size of
one character measured in bytes. If parameter bytesize is given, Context Ct 
additionally is converted to a Context with the new character size bytesize. 

=item chunks

[ [I<$str1>, I<$attr1>], [I<$str2>, I<$attr2>], ... ] = I<$Ct> -> chunks ()

Until now this is the only way to traverse a Context by it's different
attributes. You would use it like:

   for ( @{$Ct1->chunks()} ) {
      my ($text, $attrib) = @{$_};
      if ($attrib) {
         # do something (text has attribute $attrib)
      } else {
         # do something (text has default attribute)
      }
   }

=item clone

I<$Ct2> = I<$Ct1> -> clone

Returns a 1:1 copy of Context Ct1 as new Context Ct2.

=item dump

I<$Ct> = I<$Ct> -> dump

For debugging purposes. Dumps the Context structure to stdout.

=item eq

C<1>||C<0> = I<$Ct1> -> eq (I<$Ct2>)

Returns 1, if Context1 is equal to Context2, returns 0 otherwise.

=item index

I<$pos> = I<$Ct> -> index (I<$string> [,I<$pos>])

Analogue to perls index. (see "man perlfunc")

=item join

I<$Ct> = Convert::Context -> join ($expr, I<$Ct1>||I<$str1>||I<$strR1>, ...)

Concatenates all strings (scalar or reference) or Contexts with delimitor
$expr, returns a new build Context.

I<$Ct1> = I<$Ct1> -> join (I<$Ct2>||I<$str2>||I<$strR2>, ...)

Like above, but modifies I<$Ct1> instead of creating a new Context.

=item lc

I<$Ct2> = I<$Ct1> -> lc

Like perls lc. Returns a lowercased version of Context1 as Context2.

=item lcfirst

I<$Ct2> = I<$Ct1> -> lcfirst

Like perls lcfirst. Returns a version of Context1 with a lowercased first
character as Context2.

=item length

I<$length> = I<$Ct> -> length

Returns the length of Context Ct. This is the length of the text part of 
Ct, measured in characters.

=item ne

C<1>||C<0> = I<$Ct1> -> ne (I<$Ct2>)

Returns 1, if Context1 is different from Context2, returns 0 otherwise.

=item new

I<$Ct> = Convert::Context -> new ([I<$cs>])

I<$Ct> = Convert::Context -> new ([I<$cs>,] I<\$txt> [,I<[@a]>, I<[@o]>])

I<$Ct> = Convert::Context -> new ([I<$cs>,] I<[>I<\$txt> [,I<[@a]>, I<[@o]>]I<]>, 
I<[>...I<]>, ...)

Returns a new Context string. It can be initialized three ways:
(1) Without parameters, (2) with a reference to a text string, an attrib 
list reference and an offset list reference, or (3) with a list of
references of (2). 

Optionally it can be initialized with a leading parameter I<$cs>. This
stands for "character length" and specifies the byte size of one character.
One needs this when using e.g. UTF16 (Unicode) characters.

Example:

 (1) 
   $Empty = Convert::Context -> new;

 (2) 
   $Plain = Convert::Context -> new (\("Plain text\n"));
   $Bold  = Convert::Context -> new (\("Attribute 1 text"), [1]);

 (3)
   Special (but useful) case:
   $Mixed = Convert::Context -> new (
      [\("This is an "),                         [0] ],
      [\("all bold"),                          [122] ],
      [\(", short and sometimes ")                   ],
      [\("italic"),       ["Strange text attribute"] ],
      [\(" text."                                    ]
   ;

Attribute C<0> and Offset C<0> is used as default value, if none is 
explicitly given. The meaning of all attributes (here 0, 122 and 
"Strange text attribute") has to be defined 100% by the applying code. 
In this example one would assume, that a text processor was connoting 
the attributes 0, 122 and "Strange text attribute" to the semantics: plain, 
bold and italic.

=item replace

I<$n> = I<$Ct> -> replace (I<$pattern>, I<$replace>, C<egimosx>)

Replaces one or all occurrances matching to I<$pattern> with I<$replace>.
Returns the number of replacements, or false if pattern is not found.
Implemented mainly via perls replace operator: 

   s/$pattern/$replace/egimosx

I<$replace> here can be a string, a Context or a code reference. In the 
latter case this routine will be called at each match, passing the matched 
string as parameter. The matched text will then be replaced with the return 
value of the routine.

I<$n> = I<$Ct> -> replace (I<[@pattern]>, I<[@replace]>, C<egimosx>)

You can call replace with list references holding corresponding sets of
patterns and replacements. pattern and replace can be strings or Contexts, 
and replace additionally code references. The patterns will be glued 
together to a single pattern match, using pattern match or operator C<|>. 

Examples:

   (1) $Ct -> replace ("krims", "kram", "g")

Option g says, that not only one, but all occurrances of string "krims" shall 
be substituted by string "kram".  "kram" will get the attributes of
"krims" (see method "substr"). If you want to have more control about the 
attributes of "kram", you can pass the replacement string as a Context.

   (2) $Ct -> replace ("krims", $Ct, "g")

Replaces all occurrances of string "krims" with the Context $Ct. This is
useful, if you want to have $Ct special attributes.

   (3) $Ct -> replace (" asta tu ", " AStA TU ", "ig")

Option i says, that the characters case shall be ignored. So example (3)
would replace " asta tu ", " ASTA TU ", " Asta Tu " ... with " AStA TU ". 
(AStA stands for Allgemeiner Studierendenausschuß. Students governments are 
called like this in Germany and quite cool).

   (4) $Ct -> replace ("\02", \&footnote, "g")

This would call a function "footnote". The function will be called with 
three parameters:  

   &function($match, $Ct, $pos)

   1. The matched string (here "\02")
   2. The Context        (here $Ct)
   3. The match position 

   (5) $Ct -> replace ("krims", sub {allow (@_, "kram")}, "ig")

This notation would call a function "allow" for each match, quite like 
(4). But further more here the string "kram" would be passed as additional 
parameter.

   (6) $Ct -> replace (["a", "o"], ["o", "a"], "g")

Substitutes a's with o's and o's with a's.

=item rindex

I<$pos> = I<$Ct> -> rindex (I<$string> [,I<$pos>])

Analogue to perls rindex. (try "man perlfunc")

=item split

I<@Ct> = I<$Ct> -> split (I<$pattern> [I<$option> [,I<$limit>]])

Similar to perls split. Splits a Context according to string or Context 
delimitor I<$pattern>. Returns an array of Contexts. If I<$limit> is given,
returns only that many elements. I<$pattern> and I<$option> are to be used
according to perls s/I<$pattern>/something/C<egimosx> operator (but option
"g" here is always set).

=item substr

I<$Ct2> = I<$Ct1> -> substr (I<$o1>, I<$l1>)

Returns a partial Context of Ct1 as new Context Ct2. Ct2 will be copied
from Ct1 starting at position o1 and with the length l1.

I<$Ct>  = I<$Ct>  -> substr (I<$o1>, I<$l1>, I<$str> [,I<$o2>, I<$l2>])

If a string is given as argument, the partial Context starting at offset 
o1 with length l1 is substituted by string. String gets the attributes 
of the partial Context. If e.g. the string to be replaced would be 
"<0>di<1>n<2>g<0>s", after the replacement it might look like 
"<0>bu<1>m<2>s". 

I<$Ct1> = I<$Ct1> -> substr (I<$o1>, I<$l1>, I<$Ct2> [,I<$o2>, I<$l2>])

The partial Context of Ct1 starting at offset o1 with length l2 is 
substituted by Context Ct2. 

If o<n> is C<undef>, o<n> is set to 0.

If l<n> is C<undef>, l<n> is set according to end of Ct<n>

=item text

I<\$text> = I<$Ct> -> text

Returns a reference to the text section of Context Ct.

=item tr

Synonyme for y. (see below)

=item uc

I<$Ct2> = I<$Ct1> -> uc

Like perls uc. Returns an uppercased version of Context Ct1 as Context Ct2.

=item ucfirst

I<$Ct2> = I<$Ct1> -> ucfirst

Like perls ucfirst. Returns a version of Context Ct1 with an uppercased 
first character as Context Ct2.

=item y

y can be called three ways.

(1) I<$Ct> -> y (I<$search>, I<$replace>, C<cds>)

If charsize of I<$Ct> is 1, y behaves quite like perls y. Each character of 
string I<$search> is replaced by the corresponding character of I<$replace>.

(2) I<$Ct> -> y (I<$search>, I<$replace>, C<egimosx>)

If charsize of I<$Ct> is bigger than 1, y breaks the strings I<$search> and 
I<$replace> into substrings, each charsize bytes long. These corresponding
strings are then passed to method replace, automatically with option "g".
Note, that thus internally perls tr operator is not used.

(3) I<$Ct> -> y (I<[@search]>, I<[@replace]>, C<egimosx>)

This actually just calls method replace with option "g". I<@search> and
I<@replace> can be Contexts or strings, just like you want. I<@replace>
can also be code references.

=back

=head1 ERRORS

- I just found that split with parameter I<$limit> behaves not like perls
  split. Will be done.

=head1 TO DO

- Speeding up

- When programming this a long time ago I was very fond of references.
  Today this seems quite odd to me sometimes. So there might happen a
  major redesign sooner or later.

- The only real way to traverse a Context is still method "chunks()".
  There need to be some enhancements.

- Support for a hash parameter style for calling methods?

- Support for overloaded operators?

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>. 

=cut


#
# bibliography package for Perl
#
# Character set common variables and routines
#
# Dana Jacobsen (dana@acm.org)
# 18 November 1995 (last modified 17 March 1996)

# for bib'nocharset which calls fromcanon:
require "bp-cs-none.pl";

######
#
# Return canonical character for a unicode hex string.
#
sub unicode_to_canon {
  local($hex) = @_;

  $hex =~ tr/a-f/A-F/;

  # XXXXX Should we prepend '0' characters if we don't have 4 digits?
  if ($hex !~ /^[\dA-F]{4}$/) {
    &bib'gotwarn("Invalid Unicode character: $hex");
    return '';
  }
  if ($hex =~ /00(..)/) {
    return pack("C", hex($1));
  }
  return $bib'cs_ext . $hex;
}

sub canon_to_unicode {
  local($can) = @_;
  local($hex);

  if (length($can) == 1) {
    $hex = sprintf("%2lx", ord($can));
    $hex =~ tr/a-f /A-F0/;
    return( '00' . $hex );
  }
  if ($can =~ /$bib'cs_ext(....)/) {
    $hex = $1;
    $hex =~ tr/a-f/A-F/;
    return $hex;
  }
  if ($can eq $bib'cs_char_escape) {
    return &bib'canon_to_unicode($bib'cs_escape);
  }
  return &bib'gotwarn("Can't convert $can to Unicode");
}

sub decimal_to_unicode {
  local($num) = @_;
  local($hex);

  if ($num < 256) {
    $hex = sprintf("00%2lx", $num);
  } elsif ($num < 65536) {
    local($div) = $num / 256;
    local($high) = int($div);
    local($low) = 256 * ($div - $high);
    $hex = sprintf("%2lx%2lx", $high, $low);
  } else {
    return &bib'gotwarn("Illegal number $num given to decimal_to_unicode");
  }
  $hex =~ tr/a-f /A-F0/;
  $hex;
}

sub unicode_to_decimal {
  local($uni) = @_;

  return &bib'gotwarn("Illegal unicode length: $uni") unless length($uni) == 4;
  return &bib'gotwarn("Illegal unicode string: $uni") if $uni =~ /[^\da-fA-F]/;

  hex($uni);
}

sub unicode_name {
  local($hex) = @_;
  local($name);

  # For now, just print hex value
  $name = "Unicode '$hex'";
  $name;
}

sub meta_name {
  local($hex) = @_;
  local($name);

  # For now, just print hex value
  $name = "Meta '$hex'";
  $name;
}

# Oh boy, this is getting really complicated.
#
# We have an approx table set up, which says that one can approximate XXXX
# by YYYY, where presumably YYYY is easier.  There shouldn't be any loops,
# so programs can recurse through the table.
#
# That's for the meta codes.  For the unicode approx, we just have a
# string.  This allows multiple character approximations.
#
# XXXXX Think about C3's idea of multiple approximations.
#
# A map of 0000 means that it maps to the null string -- our "approximation"
# is to get rid of it.  This is what we can do if it isn't terribly harmful
# to remove it.

sub meta_approx {
  local($orig) = @_;

  require "${glb_bpprefix}p-cstab.pl" unless defined %bib'mapprox_tab;

  if (defined $mapprox_tab{$orig}) {
    return '' if $mapprox_tab{$orig} eq '0000';
    return "${bib'cs_meta}$mapprox_tab{$orig}";
  }
  undef;
}

sub unicode_approx {
  local($orig) = @_;

  # XXXXX Should we warn them that they're getting an approx?

  require "${glb_bpprefix}p-cstab.pl" unless defined %bib'uapprox_tab;

  $uapprox_tab{$orig};
}

######
#
# Font change checker.  Verifies and tries to correct font changes.
#
# After fonts are converted in your tocanon routine, call this.  In your
# fromcanon routine, you can assume this has been called.
#
# XXXXX Should we call this in bp.pl's conversion routines?  That would
#       guarantee that it has been run.  Right now, we let each module
#       decide when and if it needs to be run.
#
# It takes a string that has font changes in it and makes sure they always
# match up and that there isn't an odd number (more starts than ends, more
# ends than starts).
#

sub font_check {
  local($_) = @_;

  # XXXXX Ought to read meta information from 00 or as input.
  return $_ unless /${bib'cs_meta}01[01]/;

  local(@fontstack) = ();
  local($fontsmatch, $font, $pfont);

  # Check for this special occurance:  They don't have end fonts (or don't
  # use them).  They just make everything a begin font (troff often does this).
  # Solution: Try to fix it up by replacing each begin after the first with
  #           an endprevious / begin pair.  Then remove the last begin.
  if (!/${bib'cs_meta}011/) {
    local($pos) = $[;
    local($lpos) = 0;
    local($distance) = length($bib'cs_meta) + 3;
    local($n) = 0;
    while (($pos = index($_, "${bib'cs_meta}010", $pos)) >= $[) {
      $n++;
      if ($n == 1) {
        $lpos = $pos;
        $pfont = substr($_, $pos + $distance, 1);
        $pos++;
        next;
      }
      $lpos = $pos;
      $font = substr($_, $pos + $distance, 1);
      substr($_, $pos, 0) = "${bib'cs_meta}0110";
      $pos += ($distance*2); # need to skip over the one we just put in.
    }
    if ($n > 1) {
      # now remove the last begin
      substr($_, $lpos + $distance + 1, $distance + 1) = '';
    } elsif ($n == 1) {
      # only one begin?  Add a previous to the end.
      $_ .= "${bib'cs_meta}0110";
    } else {
      &panic("Bug in font_check, file bp-p-cs.");
    }
#print STDERR "F: end of troff: $_\n";
    # XXXXX XXF return $_;
  }
      
  do {
    # We assume that everything is ok until something goes wrong.
    $fontsmatch = 1;
    while (/${bib'cs_meta}01(.)(.)/g) {
      $font = $2;
      if ($1 eq '0') {                   # font begin
#print STDERR "F: check begin font $font\n";
        if ($font eq '0') {
          &bib'gotwarn("Someone used default font begin.  Naughty.");
          s/${bib'cs_meta}0100/${bib'cs_meta}0110/go;
          $fontsmatch = 0;
          last;
        }
        push(@fontstack, $font);
      } else {                           # font end
#print STDERR "F: check end   font $font\n";
        if (@fontstack) {
          $pfont = pop(@fontstack);
          next if $font eq '0';  # previous font.  We don't care what it was.
          if ($pfont ne $font) {
            # _____ ended font that wasn't equal to the last begin
            &bib'gotwarn("Nesting problem.  Ended $font after $pfont");
            # just make it end the previous one.
            if ($] >= 5.000) {
              s/(${bib'cs_meta}010$pfont)(.*?)${bib'cs_meta}011$font/$1$2{bib'cs_meta}011$pfont/;
            } else {
              s/(${bib'cs_meta}010$pfont)(.*)${bib'cs_meta}011$font/$1$2{bib'cs_meta}011$pfont/;
            }
            $fontsmatch = 0;
            last;
          }
        } else {
          # _____ end font used without a begin
          &bib'gotwarn("Ended font $font before begin seen");
          # This is really lousy, but without pulling the whole string apart,
          # I can't do it properly.
          # XXXXX  Perhaps we should be pulling it apart with split?
          s/${bib'cs_meta}011$font//;
          $fontsmatch = 0;
          last;
        }
      }
      # .last statement of while
    }
    if ( $fontsmatch && (@fontstack != 0) ) {
      # _____ too many begins

      # XXXXX Is this loop needed, since we did this above?
      # Try the simple case: They think roman is the default font, and begin
      # it instead of ending their own.  We'll treat this as a misunderstanding
      # and won't create a warning.
      while (    (@fontstack != 0)
              && (@fontstack % 2 == 0)
              && ($fontstack[$#fontstack] eq '1') ) {
        $pfont = pop(@fontstack);
        $pfont = pop(@fontstack);
#print STDERR "F: Too many begins found roman & replacing with $pfont\n";
        if ($] >= 5.000) {
          s/(${bib'cs_meta}010$pfont)(.*?)${bib'cs_meta}0111/$1$2{bib'cs_meta}011$pfont/;
        } else {
          s/(${bib'cs_meta}010$pfont)(.*)${bib'cs_meta}0111/$1$2{bib'cs_meta}011$pfont/;
        }
      }
      while (@fontstack != 0) {
        $pfont = pop(@fontstack);
        &bib'gotwarn("Began font $pfont, but never ended it!");
        # just end them in order.
        # XXXXX Should we use previous?  Doesn't seem to matter.
        $_ .= "${bib'cs_meta}011$pfont";
      }
      # Yes, $fontsmatch should be 0 at the end.  We want one more pass through
      # to validate the ordering.  Our search and replace routines very well
      # may find the wrong item!
      $fontsmatch = 0;
      # .last statement of if too many begins
    }
  } until $fontsmatch;

  $_;
}

######
#
# This routine removes references to "font-previous" for those routines
# that don't support that notation.  For instance, while troff has the
# \fP command, and TeX uses {\it foo}, HTML doesn't understand this.  It
# needs a matching </I> for every <I>.  So this routine will turn all
# references to the previous font into a "font-xxx-off" command.
#
# We assume that the string has been run through font_check already.
# Since this is called in a cs's fromcanon routine, that should be true.
#
sub font_noprev {
  local($val) = @_;
  local(@sval, @fontstack);
  local($font, $pfont);
  local($ret) = '';

  return $val unless $val =~ /${bib'cs_meta}01/;

  @sval = split(/${bib'cs_meta}01([01].)/, $val);
  while (@sval) {
    $ret .= shift @sval;
    if (@sval) {
      $font = shift @sval;
      if ($font =~ /^0/) {
        # font begin
        push(@fontstack, $font);
      } else {
        $pfont = pop @fontstack;
        if ($font =~ /^10/) {
          $font = $pfont;
          $font =~ s/^0/1/;
        } else {
          if (substr($font, 1, 1) ne substr($pfont, 1, 1)) {
           &bib'gotwarn("Nesting problem in noprev.  Ended $font after $pfont");
          }
        }
      }
      $ret .= "${bib'cs_meta}01$font";
    }
  }
  $ret;
}


######
#
# This should strip off any special characters and replace them with either
# a simple form, or delete them.  This will return ASCII text only, which
# is also equivilant to the 7 bit subset of ISO-8859-1.
#
# XXXXX I've tentatively decided that the actual code for this belongs in
#       cs-none.  The problem is that we then must load that file before
#       running anything.  It's a small file though.
#       It should be required at the top of this file, so it's always loaded.
#
sub nocharset {
  &bp_cs_none'fromcanon(@_);
}

1;

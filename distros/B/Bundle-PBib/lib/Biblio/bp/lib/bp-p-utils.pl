#
# bibliography package for Perl
#
# utility subroutines
#
# Dana Jacobsen (dana@acm.org)
# 11 January 1995
#

package bp_util;

######

$opt_complex = 1;

# The global key registry.
%glb_keyreg = ();

#
# mname_to_canon takes a name string and returns it back as a Canonical name.
#
# Example input:
#
#       John von Jones, Jr., Ed Krol, Ludwig von Beethoven
#
# output:
#
#       Jones,von,John,Jr./Krol,Ed,/Beethoven,von,Ludwig,
#
# (the actual seperators are $cs_sep for '/' and $cs_sep2 for ',')
#
# This is a total heuristic hack, and if you know where names are split,
# use multiple calls to name_to_canon instead.  Use this routine if you
# expect the input to be some sort of free-form such that you can't
# easily seperate the names yourself.
#
# This routine assumes there can be multiple authors per line, seperated by
# "and" or commas, and it's going to try to guess how to break them up,
# given that it can get "name1, name2, jr, name3" as a 3 name string with
# "name2, jr" as the second name.  This method precludes the ability to
# also correctly parse "last, first" format strings.  If that is the format
# your string is in, call the function with a "1" as the second argument.
#
# Note that no-break-space ("tie", ~ in TeX, \0 in troff) is \240.
#
sub mname_to_canon {
  local($allnames, $revauthor) = @_;
  local($firstn, $vonn, $lastn, $jrn);
  local(@names, $name, $oname, $nname, $rest);
  local(@cnames) = ();
 
  # Squeeze all spaces into one space.
  $allnames =~ s/\s+/ /g;
  # remove any beginning and trailing ands.
  $allnames =~ s/^and //;
  $allnames =~ s/ and$//;

  @names = split(/,? and /, $allnames);
  while (@names) {
    $oname = $name = shift @names;
    $firstn = $vonn = $lastn = $jrn = '';
    # name has no spaces at beginning or end

    # squeeze all spaces around commas.  They aren't telling us anything that
    # we can rely on, and it simplifies matching.  Also combine them.
    $name =~ s/,+/,/g;
    $name =~ s/ ,/,/g;
    $name =~ s/, /,/g;

    if ( $revauthor && ($name =~ /,/) ) {
      if ($name =~ s/[, ]+([sj]r\.?|I+)$//i) {
        $jrn = ",$1";
      }
      $name =~ s/^(.*),(.*)/$2 $1$jrn/g;
      # name has no spaces at beg or end
    }

    $name =~ s/[ \240]+([sj]r\.?|\(?edi?t?o?r?s?\.?\)?|I+)(,|$)/,$1/i;
    ($nname, $rest, $jrn) = split(/,([^\240])/, $name, 2);
    $jrn = (defined $jrn)  ? "$rest$jrn"  :  '';
    #$jrn =~ s/,+$//;
    # nname has no spaces at beg or end.
    # jrn   has no spaces at beg or end.
    if ($jrn =~ / /) {
      ($jrn, $rest) = $jrn =~ /([sj]r\.?|\(?edi?t?o?r?s?\.?\)?|I+)?,?(.*)$/i;
      unshift(@names, $rest) if defined $rest;
      $jrn = '' unless defined $jrn;
    }
    ($firstn) = $nname =~ /^((\S* )*)/;
    $nname = substr($nname, length($firstn));
    # nname has no spaces at beg or end.
    $lastn = $nname;
    $lastn  =~ s/\240+/ /g;
    $firstn =~ s/\240+/ /g;
    $jrn    =~ s/\240+/ /g;
    while ($firstn =~ / ([a-z]+ )$/) {
      $rest = $1;
      substr($vonn, 0, 0) = $rest;
      # XXXXX removed " - 1" from position argument
      substr($firstn, length($firstn) - length($rest)) = '';
    }
    while ($lastn =~ /^([a-z]+ )/) {
      $rest = $1;
      $vonn .= $rest;
      $lastn = substr($lastn, length($rest));
    }
    $vonn   =~ s/\s+$//;
    $firstn =~ s/\s+$//;
#print STDERR ":$vonn:$lastn:$firstn:$jrn:\n";

    if ($jrn) {
      if ($jrn =~ /^(et\.? ?al\.?)|(others)$/i) {
        $jrn = '';
        unshift(@names, "et al.");
      }
      if ($jrn =~ /^inc[\.]?$/i) {
        $lastn .= ", " . $jrn;
        $jrn = '';
      }
    }
    if ($lastn =~ /^(et ?al)|(others)$/i) {
      $lastn = "et al.";
    }

    push( @cnames, join($bib'cs_sep2, $lastn, $vonn, $firstn, $jrn) );
  }

  $name = join( $bib'cs_sep, @cnames );
  $name =~ s/\s+$//;
  $name =~ s/\s+/ /g;

  # remove any spaces before and after parts of names.
  1 while $name =~ s/ ${bib'cs_sep2}/${bib'cs_sep2}/go;
  1 while $name =~ s/${bib'cs_sep2} /${bib'cs_sep2}/go;

  $name;
}

#########

#
# name_to_canon takes a _single_ name and returns it back as a Canonical name.
#
# This will be faster than mname_to_canon.  I also wrote it for bp, and
# mname_to_canon is full of weird TeX things from r2b.
#
# Note that there are a few differences between the two.  Notably, that
# we only break out a von if it is space seperated -- a nbsp (tie) will
# prevent us from breaking it.  Note that nbsp => \240.
#

sub name_to_canon {
  local($name, $revauthor) = @_;
  local($first, $last, $von, $jrn);

  &bib'panic("name_to_canon called with no arguments") unless defined $name;

  $name =~ s/\s+/ /g;
  $name =~ s/ $//;
  $von = ''; $jrn = '';

  if ($name =~ s/[, ]+([sj]r\.?|I+)$//i) {
    $jrn = $1;
  }
  # name has no space at end
  # jrn  has no space at beg or end
  if ( $revauthor && ($name =~ /,/) ) {
    $name =~ s/^(.*)\s*,\s*(.*)/$2 $1/g;
  }
  # strip off Jr., but leave "Hunt,\0Jr." alone.
  if (($name =~ /,/) && ($name !~ /,\240/) ) {
    # XXXXX Check the logic here
    if (!$revauthor) {
      if ($jrn) {
        # possibly reversed?
        local($newname) = &name_to_canon($name, 'reverse');
        if (defined $newname) {
          &bib'gotwarn("Names are in reverse order?");
          return $newname;
        } else {
          &bib'goterror("name_to_canon already got jr!");
        }
      } else {
        &bib'goterror("Names seem to be reversed!") if $jrn;
      }
    }
    ($name, $jrn) = split(/ ?, ?/, $name, 2);
  }
  if ($name =~ / /) {
    ($first, $last) = $name =~ /(.*) (\S*)$/;
  } else {
    $first = '';
    $last = $name;
  }
  if ($first =~ / ([a-z].*)$/) {
    $von = $1;
    $von =~ s/\240/ /g;
    substr($first, length($first)-length($von)-1) = '';
    #$first =~ s/ $von//;
  }
  while ($last =~ /^([a-z]+)\240/) {
    $von .= " $1";
    substr($last, 0, length($1)+1) = '';
  }
  $von   =~ s/^ //;
  $last  =~ s/\240/ /g;

#print STDERR ":$last:$von:$first:$jrn:\n";

  $name = join( $bib'cs_sep2, $last, $von, $first, $jrn);

  $name =~ s/\s+$//;
  $name =~ s/\s+/ /g;
  # remove spaces before and after seperators.
  1 while $name =~ s/ ${bib'cs_sep2}/${bib'cs_sep2}/go;
  1 while $name =~ s/${bib'cs_sep2} /${bib'cs_sep2}/go;

  if ($opt_complex > 1) {
    ($last, $von, $first, $jrn) = split($bib'cs_sep2, $name);
    # Look for corporations
    if ($jrn =~ /^Inc\.$/i) {
      $jrn = '';
      $last = $last . ", Inc.";
    }
    # put it back together
    $name = join( $bib'cs_sep2,  $last, $von, $first, $jrn);
  }

  $name;
}

# This routine turns a name string (possibly containing multiple names) in
# canon format into a string suitable for output.
#
# The styles supported are:
#
#    bibtex      First von Last [or] von Last, First [or] von Last, Jr, First
#
#    plain       First von Last, Jr
#
#    reverse     von Last, First, Jr
#
#    reverse2    Last, First von, Jr
#
#    lname1      von Last, Jr, First  [for first author]
#                First von Last       [for subsequesent authors]
#
# XXXXX
#
# What we should do instead is have a more general solution.  We could specify
# names in the above sort of format, and have it parse that.  But then how do
# we handle BibTeX, which will make decisions based on what fields exist?  But
# for most of these, something like "FvL,J" or "vL,F,J" or "L,Fv,J" would work.
#
# Also, we really need a generic output form, that handles more subtle
# variations, like when to put "et al." in place of 150 names, and a different
# separator for the last name (", and " instead of ", "), initials, and so on.
#
# XXXXX Check out bibtex parsing.  We look for a space, but we've tied all
#       spaces already!

sub canon_to_name {
  local($cname, $how) = @_;
  local(@names);
  local($name);
  local($n, $von, $last, $jr, $first);
  local($namenum) = 0;

  &bib'panic("canon_to_name called with no arguments") unless defined $cname;
  $how = 'bibtex' unless defined $how;

  foreach $name ( split(/$bib'cs_sep/o, $cname) ) {
    $namenum++;
    ($last, $von, $first, $jr) = split(/$bib'cs_sep2/o, $name, 4);
    $last =~ s/ /\240/g;
    $von  =~ s/ /\240/g;
    if ($how =~ /^bibtex/) {
      # Turn ties back into spaces.
      $last =~ s/([^,])\240/$1 /g;
      $von  =~ s/\240([a-z])/ $1/g;
      # Do the minimal amount of commas
      if ($jr) {
        $n = $von . ' ' . $last . ', ' . $jr . ', ' . $first;
      } elsif ( ($last =~ /\S\s+\S/) && ($last !~ /^{.*}$/) ) {
        $n = $von . ' ' . $last . ', ' . $first;
      } else {
        $n = join(' ', $first, $von, $last);
      }
    } elsif ($how =~ /^plain/) {
      # plain: "First von Last, Jr" for each name
      $n = $first;
      $n .= " $von "   if $von;
      $n .= " $last"   if $last;
      $n .= ", $jr"    if $jr;
    } elsif ($how =~ /^reverse2/) {
      # This is "Last, First von, Jr." order.
      $n = "$last";
      $n .= ","        if ($first || $von || $jr);
      $n .= " $first"  if $first;
      $n .= " $von"    if $von;
      $n .= ", $jr"    if $jr;
    } elsif ($how =~ /^reverse/) {
      # This is "von Last, First, Jr." order.
      $n = "$von $last";
      $n .= ", $first"  if ($first || $jr);
      $n .= ", $jr"     if $jr;
    } elsif ($how =~ /^lname1/) {
      # lname1 : First author has last name first, the rest are in normal order.
      #          Personally I hate this style, but its common in ecology.
      $last .= ", $jr"  if $jr;
      if ($namenum == 1) {
        $last = join(' ', $von, $last)  if ($von);
        if ($first) {
          $n = join(', ', $last, $first);
        } else {
          $n = $last;
        }
      } else {
        $n = join(' ', $first, $von, $last);
      }
   # unknown name style
    } else {
      return &bib'goterror("canon_to_name doesn't know form: $how");
    }
    $n =~ s/ \240/ /g;
    $n =~ s/^\s+//;
    $n =~ s/\s+$//;
    $n =~ s/\s+/ /g;
    push(@names, $n);
  }

  if (wantarray) {
    @names;
  } else {
    # They want the complete string accoring to the style they asked for.
    if ($how =~ /lname1|plain/) {
      if (@names <= 2) {
        $n = join(' and ', @names);
      } else {
        $lname = pop(@names);
        $n = join(', ', @names) . ', and ' . $lname;
      }
    } else {
      $n = join(' and ', @names);
    }
    $n;
  }
}

# XXXXX Obsolete?

sub parsename {
  local($name, $how) = @_;

  &canon_to_name( &mname_to_canon($name), $how);
}


#########

#
# parsedate takes a date and returns a list of month, year.
#
# taken from r2b
#
# date looks like                   month                dec  year           
# --------------------------------  -------------------  --  ---------------
# 1984                                                   84  1984           
# 1974-1975                                              74  1974-1975      
# August 1984                       aug                  84  1984           
# May 1984 May 1984                 may                  84  1984           
# 1976 November                     nov                  76  1976           
# 1976 November 1976                nov                  76  1976           
# 21 August 1984                    {21 August}          84  1984           
# August 18-21, 1984                {August 18-21}       84  1984           
# 18-21 August 1991                 {18-21 August}       91  1991           
# July 31-August 4, 1984 1984       {July 31-August 4}   84  1984           
# July-August 1980                  {July-August}        80  1980           
# February 1984 (revised May 1991)  feb                  84  1984           
# Winter 1990                       {Winter}             90  1990           
# 1988 (in press)                                        88  1988 (in press)
# to appear                                              ??  to appear

sub parsedate {
  local($date) = @_;
  local($year)  = undef;
  local($month);
  local($old_date) = $date;

  return (undef, undef) unless defined $date;

  $date =~ s/(\S+)\s+(\d+)\s+\1\s+\2/$1 $2/;   # handle duplicate dates
  $date =~ s/^\s*(\d\d\d+)\s+(\S+)/$2 $1/;     # handle 1976 November
  while ($date =~ /\s*[(]?((\d\d\d\d[-\/])?\d\d\d\d)[).]?\s*(\(.*\))?$/) {
    $year = $1;
    $date =~ s/,?\s*[(]?(\d\d\d\d[-\/])?\d\d\d\d[).]?\s*(\(.*\))?$//;
  }

  $month = &canon_month($date);

  if ($month !~ /\S/) {
    undef $month;
  } elsif ( (!defined $year) && ($month eq $date) ) {
    $year = $old_date;
    undef $month;
  }
  ($month, $year);
}

%month_table = (
'apr',	'April',
'aug',	'August',
'dec',	'December',
'feb',	'February',
'jan',	'January',
'jul',	'July',
'jun',	'June',
'mar',	'March',
'may',	'May',
'nov',	'November',
'oct',	'October',
'sep',	'September',
);

sub canon_month {
  local($month) = @_;

  return $month if $month =~ /[\d\/\-]/;

  local($canm) = substr($month, 0, 3);

  $canm =~ tr/A-Z/a-z/;

  return $month unless defined $month_table{$canm};

  $canm;
}

sub output_month {
  local($canm, $how) = @_;
  local($outm) = $month_table{$canm};

  # we don't know what they have
  return $canm unless defined $outm;

  if ( ($how eq 'short') && (length($outm) > 4) ) {
    substr($outm, 3) = '.';
  }

  # 'long' format
  $outm;
}

sub output_date {
  local($mo, $yr, $how) = @_;
  local($date);

  $how = 'short' unless defined $how;

  if (defined $mo) {
    $mo = &bp_util'output_month($mo, $how);
    if (defined $yr) {
      $date = "$mo $yr";
    } else {
      $date = $mo;
    }
  } else {
    $date = $yr if defined $yr;
  }

  $date;
}

#
# Generates a key for a canonical record.
#
# XXXXX This should take an option string and parse it to generate a key.
#

sub genkey {
  local(%cent) = @_;
  local($key, $keytype, $sy);

  # first pick out the field we're going to use
  GETKEY: {
    defined $cent{'Authors'} && do
       { $keytype = 'author';  $key = $cent{'Authors'};      last GETKEY; };
    defined $cent{'CorpAuthor'} && do
       { $keytype = 'org';     $key = $cent{'CorpAuthor'};   last GETKEY; };
    defined $cent{'Editors'} && do
       { $keytype = 'author';  $key = $cent{'Editors'};      last GETKEY; };
    defined $cent{'Publisher'} && do
       { $keytype = 'org';     $key = $cent{'Publisher'};    last GETKEY; };
    defined $cent{'Organization'} && do
       { $keytype = 'org';     $key = $cent{'Organization'}; last GETKEY; };
    # nothing defined
         $keytype = 'text';    $key = "Anonymous";
  }

  # next we want to reduce the name to a reasonable key

#print STDERR "$key -> ";

  if ($keytype eq 'author') {
    #    # turn "Stephen van Rensselaer, Jr." into "vanRensselaerJr".
    #    #$key =~ s/^([^\/]*)\/([^\/]*)\/([^\/]*)\/([^\|]*).*/$2$1$4/;
    #    # turn "Stephen van Rensselaer, Jr." into "Rensselaer"
    #    #$key =~ s/^([^\/]*)\/.*/$1/;
    # Remove everything past the first seperator
    local($split_sep) = index($key, $bib'cs_sep2);
    substr($key, $split_sep) = ''  if $split_sep >= $[;
  } elsif ($keytype eq 'org') {
    $key =~ s/^(\S*).*/$1/;
  } else {
    # text
  }
#print STDERR "$key -> ";
  $key = &bib'nocharset($key);
#print STDERR "$key -> ";
  $key =~ tr/A-Za-z0-9\/\-//cd;

  # reduce it to fit normal lengths
  substr($key, 14) = '' if length($key) > 14;

  # Now find the year
  if ( (defined $cent{'Year'})  &&  ($cent{'Year'} =~ /(\d\d\d\d)/) ) {
    $sy = $1;
  } elsif ( (defined $cent{'Month'})  &&  ($cent{'Month'} =~ /(\d\d\d\d)/) ) {
    $sy = $1;
  } else {
    $sy = "????";
  }
  # We lop off the century part
  substr($sy, 0, 2) = '';

  # and add on the shortyear to the end of our key
  $key .= $sy;

  $key;
}

#
# Register a key in our global key registry, returning the possibly changed
# key.  All this does is maintain a registry of keys, and if there is already
# a key that matches, it adds letters from a -> z -> aa -> az -> ba -> bz -> ...
# to the end of the key.  A format uses these routines with something like:
#
#    $can{'CiteKey'} = &bp_util'genkey(%can) unless defined $can{'CiteKey'};
#    $can{'CiteKey'} = &bp_util'regkey($can{'CiteKey'});
#
# in it's fromcanon routines.  This generates a key if necessary, and then
# registers it.  A format may wish to do its own key generation, or even
# throw out the citekey it was given and make a new one, so generation and
# registration are seperate routines.
#
# It is recommended that keys be registered here rather than in the format, as
# we would like one registry even for multiple formats.
#
# XXXXX is this necessary?  This goes to an output routine after all.  As long
#       as they register them all, or none, do we care?
#

sub regkey {
  local($key) = @_;
  local($rkey, $nextkey, $rkeylen);

  $rkey = $key;
  $rkey =~ tr/A-Z/a-z/;
  $rkeylen = length($rkey);

  if (defined $glb_keyreg{$rkey}) {
    $nextkey = $key . 'a';
    while (defined $glb_keyreg{$nextkey}) {
      # increment the characters after the key, 'z'+1 -> 'aa'.
      substr($nextkey, $rkeylen)++;
    }
    # going to put ourselves in $nextkey
    $glb_keyreg{$nextkey} = 1;
    # key has changed, so update it for the output.
    $key .= substr($nextkey, $rkeylen);
  } else {
    $glb_keyreg{$rkey} = 1;
    # key is unchanged
  }

  $key;
}

#######################
# end of package
#######################

1;

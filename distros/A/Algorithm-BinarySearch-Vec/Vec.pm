package Algorithm::BinarySearch::Vec;

use Exporter;
use Carp;
use AutoLoader;
use Config qw();
use strict;
use bytes;

our @ISA = qw(Exporter);
our $VERSION = '0.08';

our ($HAVE_XS);
eval {
  require XSLoader;
  $HAVE_XS = XSLoader::load('Algorithm::BinarySearch::Vec', $VERSION);
} or do {
  $HAVE_XS = 0;
};

# Preloaded methods go here.
#require Algorithm::BinarySearch::Vec::XS::Whatever;

# Autoload methods go after =cut, and are processed by the autosplit program.

##======================================================================
## Exports
##======================================================================

no warnings 'portable'; ##-- avoid "Bit vector size > 32 non-portable" errors for native quads
our $HAVE_QUAD     = ($Config::Config{use64bitint} ##-- avoid errors with xs U64TYPE but no perl-side 64bit ints (e.g. freebsd w/o -use64bitint perl config option)
		      &&
		      ($HAVE_XS ? Algorithm::BinarySearch::Vec::XS::HAVE_QUAD()     : $Config::Config{d_quad})
		     );
our $KEY_NOT_FOUND =   $HAVE_XS ? Algorithm::BinarySearch::Vec::XS::KEY_NOT_FOUND() : 0xffffffff;
#our $KEY_NOT_FOUND =  $HAVE_XS ? Algorithm::BinarySearch::Vec::XS::KEY_NOT_FOUND() : ($HAVE_QUAD ? 0xffffffffffffffff : 0xffffffff);

our (%EXPORT_TAGS, @EXPORT_OK, @EXPORT);
BEGIN {
  %EXPORT_TAGS =
    (
     api   => [qw( vbsearch  vbsearch_lb  vbsearch_ub),
	       qw(vabsearch vabsearch_lb vabsearch_ub),
	       qw(vvbsearch vvbsearch_lb vvbsearch_ub),
	       qw(vunion vintersect vsetdiff),
	      ],
     const => [qw($HAVE_QUAD $KEY_NOT_FOUND)],
     debug => [qw(vget vset vec2array)],
    );
  $EXPORT_TAGS{all}     = [map {@$_} @EXPORT_TAGS{qw(api const debug)}];
  $EXPORT_TAGS{default} = [map {@$_} @EXPORT_TAGS{qw(api const)}];
  @EXPORT_OK            = @{$EXPORT_TAGS{all}};
  @EXPORT               = @{$EXPORT_TAGS{default}};
}

##======================================================================
## Debug wrappers

##--------------------------------------------------------------
## $val = vget($vec,$i,$nbits)
sub _vget {
  return vec($_[0],$_[1],$_[2]);
}

##--------------------------------------------------------------
## undef = vset($vec,$i,$nbits,$val)
sub _vset {
  return vec($_[0],$_[1],$_[2])=$_[3];
}


##======================================================================
## API: Search: element-wise

##--------------------------------------------------------------
## $index = vbsearch($v,$key,$nbits)
## $index = vbsearch($v,$key,$nbits,$ilo,$ihi)
sub _vbsearch {
  my ($vr,$key,$nbits,$ilo,$ihi) = (\$_[0],@_[1..$#_]);
  $ilo = 0 if (!defined($ilo));
  $ihi = 8*length($$vr)/$nbits if (!defined($ihi));
  my ($imid);
  while ($ilo < $ihi) {
    $imid = ($ihi+$ilo) >> 1;
    if (vec($$vr,$imid,$nbits) < $key) {
      $ilo = $imid + 1;
    } else {
      $ihi = $imid;
    }
  }
  return ($ilo==$ihi) && vec($$vr,$ilo,$nbits)==$key ? $ilo : $KEY_NOT_FOUND;
}

##--------------------------------------------------------------
## $index = vbsearch_lb($v,$key,$nbits)
## $index = vbsearch_lb($v,$key,$nbits,$ilo,$ihi)
sub _vbsearch_lb {
  my ($vr,$key,$nbits,$ilo,$ihi) = (\$_[0],@_[1..$#_]);
  $ilo = 0 if (!defined($ilo));
  $ihi = 8*length($$vr)/$nbits if (!defined($ihi));
  my ($imin,$imax,$imid) = ($ilo,$ihi);
  while ($ihi-$ilo > 1) {
    $imid = ($ihi+$ilo) >> 1;
    if (vec($$vr,$imid,$nbits) < $key) {
      $ilo = $imid;
    } else {
      $ihi = $imid;
    }
  }
  return $ilo if (                vec($$vr,$ilo,$nbits)==$key);
  return $ihi if ($ihi < $imax && vec($$vr,$ihi,$nbits)==$key);
  return $ilo if ($ilo > $imin || vec($$vr,$ilo,$nbits) <$key);
  return $KEY_NOT_FOUND;
}

##--------------------------------------------------------------
## $index = vbsearch_ub($v,$key,$nbits)
## $index = vbsearch_ub($v,$key,$nbits,$ilo,$ihi)
sub _vbsearch_ub {
  my ($vr,$key,$nbits,$ilo,$ihi) = (\$_[0],@_[1..$#_]);
  $ilo = 0 if (!defined($ilo));
  $ihi = 8*length($$vr)/$nbits if (!defined($ihi));
  my ($imin,$imax,$imid) = ($ilo,$ihi);
  while ($ihi-$ilo > 1) {
    $imid = ($ihi+$ilo) >> 1;
    if (vec($$vr,$imid,$nbits) > $key) {
      $ihi = $imid;
    } else {
      $ilo = $imid;
    }
  }
  return $ihi if ($ihi < $imax && vec($$vr,$ihi,$nbits)==$key);
  return $ilo if (                vec($$vr,$ilo,$nbits)>=$key);
  return $ihi>=$imax ? $KEY_NOT_FOUND : $ihi;
}

##======================================================================
## API: Search: array-wise

##--------------------------------------------------------------
## \@indices = vabsearch($v,\@keys,$nbits)
## \@indices = vabsearch($v,\@keys,$nbits,$ilo,$ihi)
sub _vabsearch {
  return [map {vbsearch($_[0],$_,@_[2..$#_])} @{$_[1]}];
}


##--------------------------------------------------------------
## \@indices = vabsearch_lb($v,\@keys,$nbits)
## \@indices = vabsearch_lb($v,\@keys,$nbits,$ilo,$ihi)
sub _vabsearch_lb {
  return [map {vbsearch_lb($_[0],$_,@_[2..$#_])} @{$_[1]}];
}

##--------------------------------------------------------------
## \@indices = vabsearch_ub($v,\@keys,$nbits)
## \@indices = vabsearch_ub($v,\@keys,$nbits,$ilo,$ihi)
sub _vabsearch_ub {
  return [map {vbsearch_ub($_[0],$_,@_[2..$#_])} @{$_[1]}];
}

##======================================================================
## API: Search: vec-wise

## \@a = vec2array($vec,$nbits)
sub vec2array {
  return [map {vec($_[0],$_,$_[1])} (0..(length($_[0])*8/$_[1]-1))];
}

##--------------------------------------------------------------
## $indices = vvbsearch($v,$keys,$nbits)
## $indices = vvbsearch($v,$keys,$nbits,$ilo,$ihi)
sub _vvbsearch {
  return pack('N*', @{vabsearch($_[0],vec2array(@_[1,2]),@_[2..$#_])});
}

##--------------------------------------------------------------
## $indices = vvbsearch_lb($v,$keys,$nbits)
## $indices = vvbsearch_lb($v,$keys,$nbits,$ilo,$ihi)
sub _vvbsearch_lb {
  return pack('N*', @{vabsearch_lb($_[0],vec2array(@_[1,2]),@_[2..$#_])});
}

##--------------------------------------------------------------
## $indices = vvbsearch_ub($v,$keys,$nbits)
## $indices = vvbsearch_ub($v,$keys,$nbits,$ilo,$ihi)
sub _vvbsearch_ub {
  return pack('N*', @{vabsearch_ub($_[0],vec2array(@_[1,2]),@_[2..$#_])});
}

##======================================================================
## API: set operations

##--------------------------------------------------------------
## $vunion = vunion($av,$bv,$nbits)
sub _vunion {
  my ($avr,$bvr,$nbits) = (\$_[0],\$_[1],$_[2]);
  die(__PACKAGE__ , "::_vunion(): cannot handle nbits < 8, but you requested $nbits") if ($nbits < 8);
  my $na = length($$avr)*8/$nbits;
  my $nb = length($$bvr)*8/$nbits;
  my $cv = '';
  my ($ai,$bi,$ci, $aval,$bval);
  for ($ai=0,$bi=0,$ci=0; $ai < $na && $bi < $nb; ++$ci) {
    $aval = vec($$avr,$ai,$nbits);
    $bval = vec($$bvr,$bi,$nbits);
    if ($aval <= $bval) {
      vec($cv,$ci,$nbits) = $aval;
      ++$ai;
      ++$bi if ($aval == $bval);
    } else { ##-- $aval == $bval
      vec($cv,$ci,$nbits) = $bval;
      ++$bi;
    }
  }
  $cv .= substr($$avr, $ai*$nbits/8);
  $cv .= substr($$bvr, $bi*$nbits/8);
  return $cv;
}

##--------------------------------------------------------------
## $vintersect = vintersect($av,$bv,$nbits)
sub _vintersect {
  my ($avr,$bvr,$nbits) = (\$_[0],\$_[1],$_[2]);
  die(__PACKAGE__ , "::_vintersect(): cannot handle nbits < 8, but you requested $nbits") if ($nbits < 8);

  ##-- ensure smaller set is "a"
  ($$avr,$$bvr) = ($$bvr,$$avr) if (length($$bvr) < length($$avr));

  my $na = length($$avr)*8/$nbits;
  my $nb = length($$bvr)*8/$nbits;
  my $cv = '';
  my ($ai,$bi,$ci, $blo,$aval,$bval);
  for ($ai=0,$blo=0,$ci=0; $ai < $na; ++$ai) {
    $aval = vec($$avr,$ai,$nbits);
    $bi   = _vbsearch_ub($$bvr,$aval,$nbits,$blo,$nb);
    last if ($bi == $KEY_NOT_FOUND);
    vec($cv,$ci++,$nbits) = $aval if ($aval == vec($$bvr,$bi,$nbits));
    $blo = $bi;
  }
  return $cv;
}

##--------------------------------------------------------------
## $vsetdiff = vsetdiff($av,$bv,$nbits)
sub _vsetdiff {
  my ($avr,$bvr,$nbits) = (\$_[0],\$_[1],$_[2]);
  die(__PACKAGE__ , "::_vintersect(): cannot handle nbits < 8, but you requested $nbits") if ($nbits < 8);

  my $na = length($$avr)*8/$nbits;
  my $nb = length($$bvr)*8/$nbits;
  my $cv = '';
  my ($ai,$bi,$ci, $blo,$aval,$bval);
  for ($ai=0,$blo=0,$ci=0; $ai < $na; ++$ai) {
    $aval = vec($$avr,$ai,$nbits);
    $bi   = _vbsearch_ub($$bvr,$aval,$nbits,$blo,$nb);
    last if ($bi == $KEY_NOT_FOUND);
    vec($cv,$ci++,$nbits) = $aval if ($aval != vec($$bvr,$bi,$nbits));
    $blo = $bi;
  }
  $cv .= substr($$avr, $ai*$nbits/8);
  return $cv;
}


##======================================================================
## delegate: attempt to delegate to XS module
foreach my $func (map {@$_} @EXPORT_TAGS{qw(api debug)}) {
  no warnings 'redefine';
  if ($HAVE_XS && Algorithm::BinarySearch::Vec::XS->can($func)) {
    eval "\*$func = \\&Algorithm::BinarySearch::Vec::XS::$func;";
  } elsif (__PACKAGE__->can("_$func")) {
    eval "\*$func = \\&_$func;";
  }
}


1; ##-- be happy

__END__

=pod

=head1 NAME

Algorithm::BinarySearch::Vec - binary search functions and basic set operations for vec()-vectors with fast XS implementations

=head1 SYNOPSIS

 use Algorithm::BinarySearch::Vec;
 
 ##-------------------------------------------------------------
 ## Constants
 my $NOKEY   = $Algorithm::BinarySearch::Vec::KEY_NOT_FOUND;
 my $is_fast = $Algorithm::BinarySearch::Vec::HAVE_XS;
 
 ##-------------------------------------------------------------
 ## Search: element-wise
 $index = vbsearch   ($v,$key,$nbits,$lo,$hi);	##-- match only
 $index = vbsearch_lb($v,$key,$nbits,$lo,$hi);	##-- lower bound
 $index = vbsearch_ub($v,$key,$nbits,$lo,$hi);	##-- upper bound
 
 ##-------------------------------------------------------------
 ## Search: array-wise
 $indices = vabsearch   ($v,\@keys,$nbits,$lo,$hi); ##-- match only
 $indices = vabsearch_lb($v,\@keys,$nbits,$lo,$hi); ##-- lower bound
 $indices = vabsearch_ub($v,\@keys,$nbits,$lo,$hi); ##-- upper bound
 
 ##-------------------------------------------------------------
 ## Search: vector-wise
 $ixvec = vvbsearch   ($v,$keyvec,$nbits,$lo,$hi); ##-- match only
 $ixvec = vvbsearch_lb($v,$keyvec,$nbits,$lo,$hi); ##-- lower bound
 $ixvec = vvbsearch_ub($v,$keyvec,$nbits,$lo,$hi); ##-- upper bound
 
 ##-------------------------------------------------------------
 ## Set Operations
 $cv = vunion($av,$bv,$nbits);          ##-- set union
 $cv = vintersect($av,$bv,$nbits);      ##-- set intersection
 $cv = vsetdiff($av,$bv,$nbits);        ##-- set difference
 
 ##-------------------------------------------------------------
 ## Debugging
 $val  = vget($vec,$i,$nbits);
 undef = vset($vec,$i,$nbits, $newval);
 $vals = vec2array($vec,$nbits);


=head1 DESCRIPTION

The Algorithm::BinarySearch::Vec perl module provides binary search functions and
basic set operations for L<vec()|perlfunc/vec-EXPR-OFFSET-BITS>-vectors,
including fast XS implementations in the package C<Algorithm::BinarySearch::Vec::XS>.
The XS implementations are used by default if available, otherwise pure-perl fallbacks are provided.
You can check whether the XS implementations are available on your system by examining the
boolean scalar C<$Algorithm::BinarySearch::Vec::HAVE_XS>.

=cut

##======================================================================
## Data Conventions
=pod

=head2 Data Conventions

All API functions provided by this module assume that the elements of the vec()-style vector arguments
are sorted in strictly ascending order.  The user is responsible for assuring that this is the case,
since no additional checking is done by this module.

=cut

##======================================================================
## Exports
=pod

=head2 Exports

This module support the following export tags:

=over 4

=item :api

Exports all API functions (default).

=item :const

Exports the following constant(s):

=over 4

=item $KEY_NOT_FOUND

Constant returned by search functions indicating that the requested key
was not found, or the requested bound is not within the data vector.

=back

=item :debug

Exports debugging subs for the XS module (vget(), vset()).

=item :all

Exports everything available.

=back

=cut

##======================================================================
## API: Search: element-wise
=pod

=head2 Search: element-wise

=over 4

=item vbsearch($v,$key,$nbits,?$ilo,?$ihi)

Binary search for $key in the vec()-style vector $v, which contains elements
of $nbits bits each, sorted in ascending order.  $ilo and $ihi if specified are
indices to limit the search.  $ilo defaults to 0, $ihi defaults to (8*$nbits/bytes::length($v)),
i.e. the entire vector is to be searched.
Returns the index $i of an element in $v matching $key (C<vec($v,$i,$nbits)==$key>,
with ($ilo E<lt>= $i E<lt> $ihi)),
or $KEY_NOT_FOUND if no such element exists.

=item vbsearch_lb($v,$key,$nbits,?$ilo,?$ihi)

Binary search for the lower-bound of $key in the vec()-style vector $v.
Arguments are as for L<vbsearch()|vbsearch>.

Returns the maximum index $i such that
C<vec($v,$i,$nbits) E<lt>= $key>
and
C<vec($v,$j,$nbits) E<lt> $key> for all $j with $ilo E<lt>= $j E<lt> $i,
or $KEY_NOT_FOUND if no such $i exists (i.e. if C<vec($v,$ilo,$nbits) E<gt> $key>).
In other words,
returns the least index of a match for $key in $v whenever a match exists,
otherwise the greatest index whose value in $v is strictly less than $key if that exists,
and $KEY_NOT_FOUND if all values in $v are strictly greater than $key.

This is equivalent to (but usually much faster than):

 return $KEY_NOT_FOUND if (vec($v,$ilo,$nbits) > $key);
 for (my $i=$ilo; $i < $ihi; $i++) {
   return $i   if (vec($v,$i,$nbits) == $key);
   return $i-1 if (vec($v,$i,$nbits) >  $key);
 }
 return ($ihi-1);

Note that the semantics of this function differ substantially from
the C++ STL function lower_bound().


=item vbsearch_ub($v,$key,$nbits,?$ilo,?$ihi)

Binary search for the upper-bound of $key in the vec()-style vector $v.
Arguments are as for L<vbsearch()|vbsearch>.

Returns the minimum index $i such that
C<vec($v,$i,$nbits) E<gt>= $key>
and
C<vec($v,$j,$nbits) E<gt> $key> for all $j with $i E<lt> $j E<lt> $ihi,
or $KEY_NOT_FOUND if no such $i exists (i.e. if C<vec($v,$ihi-1,$nbits) E<lt> $key>).
In other words,
returns the greatest index of a match for $key in $v whenever a match exists,
otherwise the least index whose value in $v is strictly greater than $key if that exists,
and $KEY_NOT_FOUND if all values in $v are strictly less than $key.

This is equivalent to (but usually much faster than):

 return $KEY_NOT_FOUND if (vec($v,$ihi-1,$nbits) < $key);
 for ($i=$ihi-1; $i >= 0; $i--) {
   return $i   if (vec($v,$i,$nbits) == $key)
   return $i+1 if (vec($v,$i,$nbits) <  $key)
 }
 return $ilo;

Note that the semantics of this function differ substantially from
the C++ STL function upper_bound().

=back

=cut

##======================================================================
## API: Search: array-wise
=pod

=head2 Search: array-wise

=over 4

=item vabsearch($v,\@keys,$nbits,?$ilo,?$ihi)

Binary search for each value in the ARRAY-ref \@keys in the vec()-style vector $v.
Other arguments are as for L<vbsearch()|vbsearch>.
Returns an ARRAY-ref of indices.
This is equivalent to (but usually much faster than):

 $indices = [map {vbsearch($v,$_,$nbits,$ilo,$ihi)} @keys];


=item vabsearch_lb($v,\@keys,$nbits,?$ilo,?$ihi)

Binary search for the lower-bound of each value in the ARRAY-ref \@keys in the vec()-style vector $v.
Other arguments are as for L<vbsearch()|vbsearch>.
Returns an ARRAY-ref of indices.
This is equivalent to (but usually much faster than):

 $indices = [map {vbsearch_lb($v,$_,$nbits,$ilo,$ihi)} @keys];

=item vabsearch_ub($v,\@keys,$nbits,?$ilo,?$ihi)

Binary search for the upper-bound of each value in the ARRAY-ref \@keys in the vec()-style vector $v.
Other arguments are as for L<vbsearch()|vbsearch>.
Returns an ARRAY-ref of indices.
This is equivalent to (but usually much faster than):

 $indices = [map {vbsearch_ub($v,$_,$nbits,$ilo,$ihi)} @keys];

=back

=cut

##======================================================================
## API: Search: vec-wise
=pod

=head2 Search: vec-wise

=over 4

=item vvbsearch($v,$keyvec,$nbits,?$ilo,?$ihi)

Binary search for each key in the key-vector $keyvec in the "haystack"-vector $v.
Other arguments are as for L<vbsearch()|vbsearch>.
Returns a vec()-vector of 32-bit indices.
This is equivalent to (but usually faster than):

 $ixvec = pack('N*', @{vabsearch($v,vec2array($keyvec,$nbits),$nbits,$ilo,$ihi)});

=item vvbsearch_lb($v,$keyvec,$nbits,?$ilo,?$ihi)

Binary lower-bound search for each key in the key-vector $keyvec in the "haystack"-vector $v.
Other arguments are as for L<vbsearch()|vbsearch>.
Returns a vec()-vector of 32-bit indices.
This is equivalent to (but usually faster than):

 $ixvec = pack('N*', @{vabsearch_lb($v,vec2array($keyvec,$nbits),$nbits,$ilo,$ihi)});

=item vvbsearch_ub($v,$keyvec,$nbits,?$ilo,?$ihi)

Binary upper-bound search for each key in the key-vector $keyvec in the "haystack"-vector $v.
Other arguments are as for L<vbsearch()|vbsearch>.
Returns a vec()-vector of 32-bit indices.
This is equivalent to (but usually faster than):

 $ixvec = pack('N*', @{vabsearch_ub($v,vec2array($keyvec,$nbits),$nbits,$ilo,$ihi)});

=back

=cut

##======================================================================
## API: Set Opterations
=pod

=head2 Set Operations

The set operations supported by this module assume that the vec()-style vector sets
are sorted in ascending order, contain no duplicates, and are encoded with
C<$nbits E<gt>= 8>; i.e. every element-boundary must lie on a byte-boundary.
The vector-sets returned by these API functions should also conform to these
conventions whenever the parameters do.

=over 4

=item vunion($av,$bv,$nbits)

Computes the union of two sorted vec()-style sets C<$av> and C<$bv>
and returns the result as a sorted vector-set.  Complexity is I<O>(C<$a> + C<$b>)>.

=item vintersect($av,$bv,$nbits)

Computes the intersection of two sorted vec()-style sets C<$av> and C<$bv>
and returns the result as a sorted vector-set.  Complexity is I<O>(C<$A> * log C<$B>),
where C<$A> is the shorter and C<$B> the longer of the argument vectors C<$a> and C<$b>.

=item vsetdiff($av,$bv,$nbits)

Computes the difference of two sorted vec()-style sets C<$av> and C<$bv>
and returns the result as a sorted vector-set.  Complexity is I<O>(C<$A> * log C<$B>),
where C<$A> is the shorter and C<$B> the longer of the argument vectors C<$a> and C<$b>.

=back

=cut

##======================================================================
## Debugging
=pod

=head2 Debugging and Miscellaneous

=over 4

=item vget($vec,$i,$nbits)

Debugging XS-wrapper equivalent to C<vec($vec,$i,$nbits)>.

=item vset($vec,$i,$nbits,$newval)

Debugging XS-wrapper equivalent to C<vec($vec,$i,$nbits)=$newval>.

=item vec2array($vec,$nbits)

Debugging utility, equivalent to

 [map {vec($vec,$_,$nbits)} (0..(length($vec)*8/$nbits-1))]

=back

=cut

##======================================================================
## Footer
=pod

=head1 SEE ALSO

L<vec() in perlfunc(1)|perlfunc/vec-EXPR-OFFSET-BITS>,
PDL(3perl),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2016 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

#############################################################################
## Name:        InlineC.pm
## Purpose:     Class::HPLOO::InlineC
## Author:      Graciliano M. P.
## Modified by:
## Created:     23/02/2005
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Class::HPLOO::InlineC ;

use strict qw(vars) ;

use vars qw($VERSION @ISA) ;

$VERSION = '0.2';

##########
# REGEXP #
##########

  my $re_attr = qr/
    ->
    (?:
      \{.*?\}
    |
      \[.*?\]
    )
  /xsi ;
  
  my $re_ret_type = qr/
    ->
    (?:
      int\w*|iv|
      double|flout\w*|nv|
      char|str\w*|pv|pvx|
      hash|hv|
      array|av|
      ref|rv|
      sv
    )
  /xsi ;

  my $re_fetch = qr/
    (?:
      $re_attr
    |
      $re_ret_type
    )
  /xsi ;

###############
# CODE_HEADER #
###############

sub code_header {
return q`
STRLEN SVPVLEN_CONST ;

#ifndef CLASSHPLOO_CPL_HEADER
#define CLASSHPLOO_CPL_HEADER

SV* CPL_HV_FETCH( HV* hv , char* k ) {
  if ( !hv_exists(hv , k , strlen(k)) ) {
    hv_store( hv , k , strlen(k) , newSV(0) , 0 ) ;  
  }
  return *hv_fetch(hv , k , strlen(k) , 0) ;
}

SV* CPL_AV_FETCH( AV* av , long i ) {
  av_fill(av , i) ;
  if ( !av_exists(av , i) ) {
    av_store(av , i , newSV(0));
  }
  return *av_fetch(av, i ,0) ;
}

SV* CPL_RV_FETCH( SV* sv ) {
  if ( SvROK(sv) ) {
    return (SV*) SvRV(sv) ;
  }
  return sv ;
}


SV* bool2sv( bool b ) { return( b ? newSViv(1) : newSV(0) ) ;}
SV* bool2svTMP( bool b ) { return bool2sv(b) ;}

SV* int2sv( long n ) { return newSViv(n) ;}
SV* int2svTMP( long n ) { return sv_2mortal(newSViv(n)) ;}
SV* long2sv( long n ) { return newSViv(n) ;}
SV* long2svTMP( long n ) { return sv_2mortal(newSViv(n)) ;}

SV* float2sv( float n ) { return newSVnv(n) ;}
SV* float2svTMP( float n ) { return sv_2mortal(newSVnv(n)) ;}
SV* double2sv( double n ) { return newSVnv(n) ;}
SV* doublesvTMP( double n ) { return sv_2mortal(newSVnv(n)) ;}

SV* str2sv( char* s ) { return newSVpv(s , strlen(s) ) ;}
SV* str2svTMP( char* s ) { return sv_2mortal( newSVpv(s , strlen(s) ) ) ;}

bool sv2bool( SV* s ) { return SvTRUE(s) ;}

int sv2int( SV* s ) { return SvIV(s) ;}
long sv2long( SV* s ) { return SvIV(s) ;}

float sv2float( SV* s ) { return SvNV(s) ;}
double sv2double( SV* s ) { return SvNV(s) ;}

char* sv2str( SV* s ) { return SvPV_nolen(s) ;}

SV* newSVnull() { return newSV(0) ;}
SV* newSVnullTMP() { return sv_2mortal(newSV(0)) ;}

SV* newSVivTMP( long n ) {
  return sv_2mortal( newSViv(n) ) ;
}

SV* newSVnvTMP( double n ) {
  return sv_2mortal( newSVnv(n) ) ;
}

SV* newSVpvTMP( char* s ) {
  return sv_2mortal( newSVpv(s , strlen(s) ) ) ;
}

SV* newSVTMP() {
  return sv_2mortal( newSV(0) ) ;
}

AV* newAVTMP() {
  return sv_2mortal( newAV() ) ;
}

HV* newHVTMP() {
  return sv_2mortal( newHV() ) ;
}

#endif
` ;
}

#############
# APPLY_CPL #
#############

sub apply_CPL {
  my $body = shift ;
  
  my $syntax ;
  
  ## FETCH
  
  while( $body =~ /(.*?\W)(\w+$re_fetch+)(\s*=\s*.*?;|\W)(.*)/gxsi ) {
    $syntax .= $1 ;
    my ( $fetch_attr , $op ) = ($2 , $3) ;
    $body = $4 ;
    
    if ( $op =~ /^\s*=\s*(.*?)\s*;/s ) {
      my $fetch = fetch_attr($fetch_attr) ;
      $syntax .= "sv_setsv_mg( $fetch , ". _val_to_sv(fetch_attr($1)) ." ) ;" ;
    }
    else {
      $syntax .= fetch_attr($fetch_attr) ;
      $syntax .= $op ;
    }

  }
  
  $syntax .= substr($body , pos($body)) ;
  
  ## REF
  
  my %PH ;

  $syntax =~ s/\\{([^\r\n]+?)}/newRV_inc( $1 )/gs ;
  
  $syntax =~ s/\%{([^\r\n]+?)}\{(.*?)\}/ $PH{++$PH{i}} = qq`CPL_HV_FETCH((HV*) $1 , `. _auto_quote($2) .q`)` ; "%CLASSHPLOO_PH_REF_$PH{i}%"/gse ;
  $syntax =~ s/\@{([^\r\n]+?)}\[(.*?)\]/ $PH{++$PH{i}} = qq`CPL_AV_FETCH((AV*) $1 , $2)` ; "%CLASSHPLOO_PH_REF_$PH{i}%"/gse ;
    
  $syntax =~ s/\%{([^\r\n]+?)}/(HV*)CPL_RV_FETCH( $1 )/gs ;
  $syntax =~ s/\@{([^\r\n]+?)}/(AV*)CPL_RV_FETCH( $1 )/gs ;
  $syntax =~ s/\${([^\r\n]+?)}/ $PH{++$PH{i}} = "CPL_RV_FETCH( $1 )" ; "%CLASSHPLOO_PH_REF_$PH{i}%" /gse ;
  
  ## PH
  
  $syntax =~ s/%CLASSHPLOO_PH_REF_(\d+)%\s*=\s*(.*?);/ "sv_setsv_mg( $PH{$1} , ". _val_to_sv($2) ." ) ;" /gse ;
  
  ## return
  
  return $syntax ;
}

##############
# FETCH_ATTR #
##############

sub fetch_attr {
  my $fetch = shift ;

  return $fetch if $fetch !~ /^\w+$re_attr+$re_ret_type?$/ ;

  my (@attrs) = ( $fetch =~ /^(\w+)/s , $fetch =~ /($re_fetch)/gs );
  
  my $i = -1 ;
  foreach my $attrs_i ( @attrs ) {
    ++$i ;

    my $next_tp = $attrs[$i+1] =~ /^->\{.*?\}/ ? 'HV' : ( $attrs[$i+1] =~ /^->\[.*?\]/ ? 'AV' : undef ) ;
    
    if ( $attrs_i =~ /^->\{(.*)\}/ ) {
      ##$attrs_i = qq`FETCH_ATTR($attrs[$i-1] , `. _auto_quote($1) .q`)` ;
      $attrs_i = qq`CPL_HV_FETCH($attrs[$i-1] , `. _auto_quote($1) .q`)` ;
    }
    elsif ( $attrs_i =~ /^->\[(.*)\]/ ) {
      ##$attrs_i = qq`FETCH_ELEM($attrs[$i-1] , $1)` ;
      $attrs_i = qq`CPL_AV_FETCH($attrs[$i-1], $1)` ;
    }
    
    if ( $next_tp ) {
      $attrs_i = qq`($next_tp*)CPL_RV_FETCH( $attrs_i )` ;
    }
    elsif ( $attrs_i =~ /^->(\w+)$/s ) {
      if ( $1 =~ /^(?:int\w*|iv)$/i ) {
        $attrs_i = qq`SvIV( $attrs[$i-1] )` ;
      }
      elsif ( $1 =~ /^(?:double|flout\w*|nv)$/i ) {
        $attrs_i = qq`SvNV( $attrs[$i-1] )` ;
      }
      elsif ( $1 =~ /^(?:char|str\w*|pv)$/i ) {
        $attrs_i = qq`SvPV_nolen( $attrs[$i-1] )` ;
      }
      elsif ( $1 =~ /^(?:pvx)$/i ) {
        $attrs_i = qq`SvPVX( $attrs[$i-1] )` ;
      }
      elsif ( $1 =~ /^(?:hash|hv)$/i ) {
        $attrs_i = qq`(HV*)CPL_RV_FETCH( $attrs[$i-1] )` ;
      }
      elsif ( $1 =~ /^(?:array|av)$/i ) {
        $attrs_i = qq`(AV*)CPL_RV_FETCH( $attrs[$i-1] )` ;
      }
      elsif ( $1 =~ /^(?:sv)$/i ) {
        $attrs_i = qq`(SV*) $attrs[$i-1]` ;
      }
      elsif ( $1 =~ /^(?:ref|rv)$/i ) {
        $attrs_i = qq`newRV_inc((SV*) $attrs[$i-1] )` ;
      }
    }
  }
    
  return $attrs[-1] ;
}

##############
# _VAL_TO_SV #
##############

sub _val_to_sv {
  my $val = shift ;
  if    ( $val =~ /^\s*([0-9]+)\s*$/s ) { return "newSViv($1)" ;}
  elsif ( $val =~ /^\s*([0-9]+\.[0-9]+)\s*$/s ) { return "newSVnv($1)" ;}
  elsif ( $val =~ /^\s*(".*?")\s*$/s ) { return "newSVpv($1 , 0)" ;}
  return $val ;
}

###############
# _AUTO_QUOTE #
###############

sub _auto_quote {
  my $val = shift ;
  if ( $val !~ /^".*?"$/s && $val !~ /^\WHPL_PH\d+\W$/s ) { return "\"$val\"" ;}
  return $val ;
}

#######
# END #
#######

1;


__END__

=head1 NAME

Class::HPLOO::InlineC - Add a pseudo syntax over C to work easier with SV*, AV*, HV* and RV*.

=head1 DESCRIPTION

Who have worked with XS and L<perlapi> knows that to access values from AV* and HV*, and work
with references is not very friendly. To work arounf that I have added a pseudo syntax over the C
syntax, that helps to work easily with SV*, AV*, HV* and RV*.

=head1 USAGE

  use Class::HPLOO ;
  
  class Point {
    
    sub Point ($x , $y) {
      $this->{x} = $x ;
      $this->{y} = $y ;
    }
    
    sub move_x( $mv_x ) {
      $this->{x} += $mv_x ;
    }
    
    sub[C] void move_y( SV* self , int mv_y ) {
      int y = self->{y}->int + mv_y ;
      self->{y} = int2sv(y) ;
    }
    
    sub[C] SV* get_xy_ref( SV* self ) {
      AV* ret = newAV() ;
      
      ret->[0] = self->{x} ;
      ret->[1] = self->{y} ;
      
      return \{ret} ;
    }
  
  }
  
  my $p = Point->new(10,20) ;
  
  $p->move_x(100) ;
  $p->move_y(100) ;
  
  my $xy = $p->get_xy_ref() ; ## returns an ARRAY reference.
  print "XY> @$xy\n" ; ## XY> 110 120

As you can see, is very easy to access and set an integer value from $Point->{y} (at self). Also
is simple to create an ARRAY and return a reference to it.

B<FETCH:>

  self->{y}->int
  ## Rewrited to:
  SvIV( *hv_fetch((HV*)SvRV( self ) , "y" , strlen("y") , 0) )
   
B<STORE:>

  self->{y} = int2sv(y) ;
  ## Rewrited to:
  sv_setsv_mg( *hv_fetch((HV*)SvRV( self ) , "y" , strlen("y") , newSViv(y) ) ;

=head1 THE PSEUDO SYNTAX

=over 4

=item FETCH HV:

  void foo(SV* self) {
    self->{y}->int ;    // $this->{y} as int.
    self->{y}->float ;  // $this->{y} as double.
    self->{list}->av ;  // @{$this->{list}} as AV*.
    self->{hash}->hv ;  // %{$this->{hash}} as HV*.
    self->{y}->sv;      // explicity $this->{y} as SV*.
    self->{hash}->rv ;  // New RV: \%{$this->{hash}}
    
    {
      HV* hv1 = %{ self->{hash} } ; // %{$this->{hash}}
      HV* hv2 = self->{hash}->hv ;  // same
    }
  }

=item FETCH AV:

  void foo(SV* self) {
    self->[0]->int ;    // $this->[0] as int.
    self->[1]->float ;  // $this->[1] as double.
    self->[2]->av ;     // @{$this->[2]} as AV*.
    self->[3]->hv ;     // %{$this->[3]} as HV*.
    self->[3]->sv;      // explicity $this->[3] as SV*.
    self->[4]->rv ;     // New RV: \%{$this->[4]}
    
    {
      AV* av1 = @{ self->{list} } ; // @{$this->{list}}
      AV* av2 = self->{list}->av ;  // same
    }
  }

=item FETCH SV:

  void foo(SV* val) {
    val->str ;    // $val as char*
    val->pvx ;    // return a pointer to the char* buffer inside the SCALAR.
    
    val->int ;    // $val as int.
    val->float ;  // $val as double.
    val->av ;     // @{$val} as AV*.
    val->hv ;     // %{$val} as HV*.
    val->sv ;     // explicity $val as SV*.
    val->rv ;     // New RV: \%{$val}
    
    {
      SV* sv = val ;     // make sv to point to val.
      SV* sv = val->sv ; // make sv to point to val but explicity declare val as (SV*)

      SV* sv = ${val} ;  // Access the SV that val points if val is a reference (RV) to another SV.
    }
  }

=item FETCH RV:

  void foo(SV* val) {
    SV* sv_ref = \{val} ;  // Create a reference to $val
    SV* sv = ${sv_ref}     // de-reference sv_ref:  ${$sv_ref} ;
    
    AV* array = newAV() ;    // Create a new AV.
    SV* av_ref = \{array} ;  // Create a reference to array ;
    AV* av = @{av_ref}       // Get the array that av_ref make reference.
    
    HV* hash = newHV() ;    // Create a new HV.
    SV* hv_ref = \{hash} ;  // Create a reference to hash ;
    HV* hv = %{hv_ref}      // Get the hash that hv_ref make reference.
  }

=item STORE

The STORE syntax is always an access to an SV = a new SV:

  self->{y} = int2sv(10) ;
  self->[0] = int2sv(10) ;

If you have a SV directly in a C variable you can use ->sv to explicity say that
it's an SV and enable the syntax:

  SV* y = self->{y} ;
  // ...
  y->sv = int2sv(10);

=item STORE and REFERENCES

Basically to store using a reference we just need to access the SV inside the reference:

    AV* array = newAV() ;    // Create a new AV.
    SV* av_ref = \{array} ;  // Create a reference to array ;
    AV* av = @{av_ref}       // Get the array that av_ref make reference.
    
    array->[0] = int2sv(10) ;
    array->[1] = int2sv(20) ;
    array->[2] = int2sv(30) ;
    
    // and with av will change the same array:

    av->[0] = int2sv(10) ;
    av->[1] = int2sv(20) ;
    av->[2] = int2sv(30) ;
    
    // with the reference is:
    
    @{av_ref}[0] = int2sv(10) ;
    @{av_ref}[1] = int2sv(20) ;
    @{av_ref}[2] = int2sv(30) ;

=item FETCH/STORE AV and HV elements

As a normal Perl code the pseudo syntax make the fetch and store to elements
that doesn't exists yet true. So, if you fetch an ARRAY position that doesn't exists,
a new undef SV will be created in the position before you fetch it. The same idea
works for HV, so you can fetch a key of a hash even if it wasn't created yet.
And since a STORE is done with a previous FETCH, you can store elements in positions/keys
that doesn't exists yet:

    AV* array = newAV() ;    // Create a new AV.
    array->[0] = int2sv(10) ; // Store 10 in the position 0 without need to FILL the array before.

Note that each FETCH to an array ensure that the array is filled with the element.
And each FETCH to a HASH will automatically create the key.

=back

=head1 EASILY RETURNING N ELEMENTS

The easier way to return a list of elements (SV*) is to return a reference to an ARRAY.
With this approach you don't need to work with the XS STACK:

  sub SV* foo() {
    AV* ret = newAV() ;      // Create a new AV.
    ret->[0] = int2sv(10) ;  // store 10 at $ret[0].
    
    AV* table = newHV() ;    // Create a new HV.
    
    table->{a} = int2sv(1) ;  // set the key a => 1.
    table->{b} = int2sv(2) ;  // set the key b => 2.
    
    ret->[0] = \{table}      // Store a reference to the hash table.
    
    return \{ret} ; // Return a reference to the array @ret.
  }

=head1 SV* CONVERTIONS

Here's the list of convertion functions:

  SV* bool2sv( bool b ) ;
  SV* int2sv( long n ) ;
  SV* long2sv( long n ) ;
  SV* float2sv( float n ) ;
  SV* double2sv( double n ) ;
  SV* str2sv( char* s ) ;
  
  bool sv2bool( SV* s ) ;
  int sv2int( SV* s ) ;
  long sv2long( SV* s ) ;
  float sv2float( SV* s ) ;
  double sv2double( SV* s ) ;
  char* sv2str( SV* s ) ;

=head1 SEE ALSO

L<Class::HPLOO>, L<Inline::C>.

=head1 AUTHOR

Graciliano M. P. <gmpassos@cpan.org>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


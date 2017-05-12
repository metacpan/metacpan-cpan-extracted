#############################################################################
## Name:        Base.pm
## Purpose:     Base class for HPLOO classes.
## Author:      Graciliano M. P.
## Modified by:
## Created:     30/10/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Class::HPLOO::Base ;

use 5.006 ;
use strict qw(vars) ;

use vars qw($VERSION $SYNTAX @ISA) ;

$VERSION = '0.17';

############
# EXPORTER #
############

require Exporter;
@ISA = qw(Exporter UNIVERSAL) ;

our @EXPORT = qw(SUPER new GET_CLASS_HPLOO_HASH CLASS_HPLOO_TIE_KEYS ATTRS CLASS_HPLOO_ATTR CLASS_HPLOO_ATTR_TYPE) ;

our @EXPORT_OK = @EXPORT ;
  
########################
# GET_CLASS_HPLOO_HASH #
########################

sub GET_CLASS_HPLOO_HASH {
  my $pack = ref($_[0]) || ($_[1] ? $_[1] : $_[0]) ;
  return \%{$pack . '::CLASS_HPLOO'} ;
}

#########
# SUPER #
#########

sub SUPER {
  my ($prev_pack , undef , undef , $sub0) = caller(1) ;
  $prev_pack = undef if $prev_pack eq 'Class::HPLOO::Base' ;
  
  my ($pack,$sub) = ( $sub0 =~ /^(?:(.*?)::|)(\w+)$/ );

  my $sub_is_new_hploo = $sub0 =~ /^(.*?(?:::)?$sub)\::$sub$/ ? 1 : undef ;
  
  ##print "SUPER[$sub_is_new_hploo]>> @_ >> $pack,$sub >> $prev_pack\n" ;

  unshift(@_ , $prev_pack) if ( $sub_is_new_hploo && $prev_pack && ((!ref($_[0]) && $_[0] ne $prev_pack && !UNIVERSAL::isa($_[0] , $prev_pack)) || (ref($_[0]) && !UNIVERSAL::isa($_[0] , $prev_pack)) ) ) ;

  if ( defined @{"$pack\::ISA"} ) {
    my $isa_sub = ISA_FIND_NEW($pack, ($sub_is_new_hploo?'new':$sub) ,1) ;

    my ($sub_name) = ( $isa_sub =~ /(\w+)$/gi );
    if ( $sub0 ne $isa_sub && !ref($_[0]) && $isa_sub =~ /^(.*?(?:::)?$sub_name)\::$sub_name$/ ) {
      @_ = ( bless({},$_[0]) , @_[1..$#_] ) ;
    }
    
    if ( $sub0 eq $isa_sub && UNIVERSAL::isa($_[0] , $pack) ) {
      my @isa = Class::HPLOO::Base::FIND_SUPER_WALK( ref($_[0]) , $pack ) ;
      my $pk = $isa[-1] ;
      if ( $sub_is_new_hploo ) {
        if ( UNIVERSAL::isa($pk , 'Class::HPLOO::Base') ) {
          ($sub) = ( $pk =~ /(\w+)$/gi );        
        }
        else { $sub = 'new' ;}
      }
      
      my $isa_sub = $pk->can($sub) ;
      ##print "SUPER WALK>> $pk , $sub >> $isa_sub\n" ;
      return &$isa_sub( ARGS_WRAPPER(@_) ) if $isa_sub ;
    }
    
    ##print "SUPER ISA>> $isa_sub >> $pack >> ". join(',',@{"$pack\::ISA"}) ."\n" ;
    return &$isa_sub(@_) if $isa_sub && defined &$isa_sub && $sub0 ne $isa_sub ;
  }
  
  $sub = $sub_is_new_hploo ? 'new' : $sub ;
  ##print "SUPER CALL>> $pack $sub >> @_\n" ;

  die("Can't find SUPER method for $sub0!") if "$pack\::$sub" eq $sub0 ;
  
  return &{"$pack\::$sub"}(@_) ;
}

###################
# FIND_SUPER_WALK #
###################

sub FIND_SUPER_WALK {
  my $class_main = shift ;
  my $class_end = shift ;
  my $only_stak = shift ;
  
  my (@stack) ;
  my $stack = $only_stak || {} ;
  
  ##print "FIND>> $class_main , $class_end\n" ;
  
  my $found ;
  foreach my $isa_i ( @{"$class_main\::ISA"} ) {
    next if $$stack{$isa_i}++ ;
    $found = 1 if $isa_i eq $class_end ;
    push(@stack , $isa_i , FIND_SUPER_WALK($isa_i , $class_end , $stack) );
  }
  
  return ($found ? @stack : ()) if $only_stak ;
  return @stack ;
}

################
# ISA_FIND_NEW #
################

sub ISA_FIND_NEW {
  my $pack = shift ;
  my $sub = shift ;
  my $look_deep = shift ;
  my $count = shift ;
  return if $count > 100 ;
  
  ##print "ISA_FIND_NEW>> $pack >> $sub\n" ;
    
  my ($sub_name) ;
  if ( UNIVERSAL::isa($pack , 'Class::HPLOO::Base') ) {
    ($sub_name) = $sub eq 'new' ? ( $pack =~ /(\w+)$/ ) : ($sub) ;
  }
  else { $sub_name = $sub ;}
  
  my $isa_sub = "$pack\::$sub_name" ;
  
  if ( $look_deep || !defined &$isa_sub ) {
    foreach my $isa_i ( @{"$pack\::ISA"} ) {
      next if $isa_i eq $pack || $isa_i eq 'Class::HPLOO::Base' ;
      last if $isa_i eq 'UNIVERSAL' ;
      $isa_sub = ISA_FIND_NEW($isa_i , $sub , 0 , $count+1) ;
      last if $isa_sub ;
    }
  }
  
  $isa_sub = undef if !defined &$isa_sub ; 
  
  ##print "%%> $pack >> $isa_sub\n" ;
  return $isa_sub ;
}

##################
# NEW_CALL_BEGIN #
##################

sub new_call_BEGIN {
  my $class = shift ; $class = ref($class) if ref($class) ;
  my $this = $class ;
    
  my @isas = \@{"$class\::ISA"} ;
  
  foreach my $isas_i ( @isas ) {
    foreach my $ISA_i ( @$isas_i ) {
      if ( defined @{"$ISA_i\::ISA"} && @{"$ISA_i\::ISA"} > 2 ) {
        push(@isas , \@{"$ISA_i\::ISA"}) ;
      }
      last if $ISA_i eq 'Class::HPLOO::Base' ;
      my $ret ;
      my ($sub) = ( $ISA_i =~ /(\w+)$/ );
      $sub = "$ISA_i\::$sub\_BEGIN" ;
      $ret = &$sub($this,@_) if defined &$sub ;
      $this = $ret if $ret && UNIVERSAL::isa($ret,$class) ;
    }
  }
  
  return $this ;
}

################
# NEW_CALL_END #
################

sub new_call_END {
  my $class = shift ; $class = ref($class) if ref($class) ;
  
  my @isas = \@{"$class\::ISA"} ;
  
  foreach my $isas_i ( @isas ) {
    foreach my $ISA_i ( @$isas_i ) {
      if ( defined @{"$ISA_i\::ISA"} && @{"$ISA_i\::ISA"} > 2 ) {
        push(@isas , \@{"$ISA_i\::ISA"}) ;
      }
      last if $ISA_i eq 'Class::HPLOO::Base' ;
      my ($sub) = ( $ISA_i =~ /(\w+)$/ );
      $sub = "$ISA_i\::$sub\_END" ;
      &$sub(@_) if defined &$sub ;
    }
  }
  
  return ;
}

#######
# NEW #
#######

my $NEW_REF  = \&new ;

sub new {
  my $class = shift ;
  my $this = ref($class) ? $class : undef ;
  
  my $class_bless = $class ;
  ($class,$class_bless,$this) = @$class if ref($class) eq 'ARRAY' ;

  $class = ref($class) if ref($class) ;
  $class_bless = ref($class_bless) if ref($class_bless) ;
  
  my ($class_end) = ( $class =~ /(\w+)$/ );
  
  ##print "BASE NEW>> $class,$class_bless,$this >> $class_end >> @_ >> [". join(" ", @{"$class\::ISA"}) ."]\n" ;
  
  if ( !defined &{"$class\::$class_end"} && @{"$class\::ISA"} > 1 ) {
    foreach my $ISA_i ( @{"$class\::ISA"} ) {
      last if $ISA_i eq 'Class::HPLOO::Base' ;
      my $sub = "$ISA_i\::new" ;
      if ( defined &$sub ) {
        my $new_ref = \&$sub ;
        return &$sub([$ISA_i,$class,$this],@_) if $new_ref == $NEW_REF || (defined &{"$ISA_i\::__CLASS__"} && defined &{"$ISA_i\::SUPER"} && defined &{"$ISA_i\::new_call_END"} ) ;
        return &$sub($class,@_) ;
      }
    }
  }

  $this ||= $class ;
  $this = new_call_BEGIN( $this , @_) ;
  $this = bless({} , $class_bless) if !ref($this) || !UNIVERSAL::isa($this,$class_bless) ;
  
  no warnings ;
  
  my $undef = \'' ;
  sub UNDEF {$undef} ;
  
  my $CLASS_HPLOO = GET_CLASS_HPLOO_HASH($this) ;
  
  if ( $$CLASS_HPLOO{ATTR} ) { CLASS_HPLOO_TIE_KEYS($this) }
  
  my $ret_this = defined &{"$class\::$class_end"} ? $this->$class_end(@_) : undef ;
  
  if ( ref($ret_this) && UNIVERSAL::isa($ret_this,$class_bless) ) {
    $this = $ret_this ;
    if ( $$CLASS_HPLOO{ATTR} && UNIVERSAL::isa($this,'HASH') ) { CLASS_HPLOO_TIE_KEYS($this) }
  }
  elsif ( $ret_this == $undef ) { $this = undef }
  
  new_call_END($class,$this,@_) ;

  return $this ;
}

########################
# CLASS_HPLOO_TIE_KEYS #
########################
    
sub CLASS_HPLOO_TIE_KEYS {
  my $this = shift ;
  my $CLASS_HPLOO = GET_CLASS_HPLOO_HASH($this) ;
  if ( $$CLASS_HPLOO{ATTR} ) {
    foreach my $Key ( keys %{$$CLASS_HPLOO{ATTR}} ) {
      tie( $this->{$Key} => 'Class::HPLOO::Base::HPLOO_TIESCALAR' , $this , $Key , $$CLASS_HPLOO{ATTR}{$Key}{tp} , $$CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} , \$this->{CLASS_HPLOO_CHANGED} , ref($this) ) if !exists $this->{$Key} ;
    }
  }
}

#########
# ATTRS #
#########

sub ATTRS { return @{[@{ GET_CLASS_HPLOO_HASH($_[0] , scalar caller)->{ATTR_ORDER} }]} } ;

####################
# CLASS_HPLOO_ATTR #
####################

sub CLASS_HPLOO_ATTR {
  my $class = caller ;

  my @attrs = split(/\s*,\s*/ , $_[0]) ;
  
  my $CLASS_HPLOO = GET_CLASS_HPLOO_HASH( undef , $class ) ;

  foreach my $attrs_i ( @attrs ) {
    $attrs_i =~ s/^\s+//s ;
    $attrs_i =~ s/\s+$//s ;
    my ($name) = ( $attrs_i =~ /(\w+)$/gi ) ;
    my ($type) = ( $attrs_i =~ /^((?:\w+\s+)*?&?\w+|(?:\w+\s+)*?\w+(?:(?:::|\.)\w+)*)\s+\w+$/gi ) ;
    
    my $type0 = $type ;
    $type0 =~ s/\s+/ /gs ;
    
    $type = lc($type) ;
    $type =~ s/(?:^|\s*)bool$/boolean/gs ;
    $type =~ s/(?:^|\s*)int$/integer/gs ;
    $type =~ s/(?:^|\s*)float$/floating/gs ;
    $type =~ s/(?:^|\s*)str$/string/gs ;
    $type =~ s/(?:^|\s*)sub$/sub_$name/gs ;
    $type =~ s/\s//gs ;
    
    $type = 'any' if $type !~ /^(?:(?:ref)|(?:ref)?(?:array|hash)(?:boolean|integer|floating|string|sub_\w+|any|&\w+)|(?:ref)?(?:array|hash)|(?:array|hash)?(?:boolean|integer|floating|string|sub_\w+|any|&\w+))$/ ;

    if ( $type eq 'any' && $type0 =~ /^((?:ref\s*)?(?:array|hash) )?(\w+(?:(?:::|\.)\w+)*)$/ ) {
      my ($tp1 , $tp2) = ($1 , $2) ;
      $tp1 =~ s/\s+//gs ;
      $tp2 = 'UNIVERSAL' if $tp2 =~ /^(?:obj|object)$/i ;
      $tp2 =~ s/\.+/::/gs ;
      $type = "$tp1$tp2" ;      
    }
    
    my $parse_ref = $type =~ /^(?:array|hash)/ ? 1 : 0 ;
    
    push(@{ $$CLASS_HPLOO{ATTR_ORDER} } , $name) if !$$CLASS_HPLOO{ATTR}{$name} ;
    
    $$CLASS_HPLOO{ATTR}{$name}{tp} = $type ;
    $$CLASS_HPLOO{ATTR}{$name}{pr} = $parse_ref ;

    my $return ;

    if ( $type =~ /^sub_(\w+)$/ ) {
      my $sub = $1 ;
      $return = qq~
        return (&$sub(\$this,\@_))[0] if defined &$sub ;
        return undef ;
      ~ ;
    }
    else {
       $return = $parse_ref ? qq~
                   ref(\$this->{CLASS_HPLOO_ATTR}{$name}) eq 'ARRAY' ? \@{\$this->{CLASS_HPLOO_ATTR}{$name}} :
                   ref(\$this->{CLASS_HPLOO_ATTR}{$name}) eq 'HASH' ? \%{\$this->{CLASS_HPLOO_ATTR}{$name}} :
                   \$this->{CLASS_HPLOO_ATTR}{$name}
                 ~ :
                 "\$this->{CLASS_HPLOO_ATTR}{$name}" ;
    }

    eval(qq~
    package $class ;
    sub set_$name {
      my \$this = shift ;
      if ( !defined \$this->{$name} ) {
        tie( \$this->{$name} => 'Class::HPLOO::Base::HPLOO_TIESCALAR' , \$this , '$name' , '$type' , $parse_ref , \\\$this->{CLASS_HPLOO_ATTR}{$name} , \\\$this->{CLASS_HPLOO_CHANGED} , ref(\$this) ) ;
      }
      
      \$this->{CLASS_HPLOO_CHANGED}{$name} = 1 ;
      \$this->{CLASS_HPLOO_ATTR}{$name} = CLASS_HPLOO_ATTR_TYPE( ref(\$this) , '$type',\@_) ;
    }
    ~) if !defined &{"$class\::set_$name"} ;
    
    eval(qq~
    package $class ;
    sub get_$name {
      my \$this = shift ;
      $return ;
    }
    ~) if !defined &{"$class\::get_$name"} ;
  }
}

#########################
# CLASS_HPLOO_ATTR_TYPE #
#########################

sub CLASS_HPLOO_ATTR_TYPE {
  my $class = shift ;
  my $type = shift ;
  
  if ($type eq 'any') { return $_[0] }
  elsif ($type eq 'string') {
    return "$_[0]" ;
  }
  elsif ($type eq 'boolean') {
    return if $_[0] =~ /^(?:false|null|undef)$/i ;
    return 1 if $_[0] ;
    return ;
  }
  elsif ($type eq 'integer') {
    my $val = $_[0] ;
    my ($sig) = ( $val =~ /^(-)/ );
    $val =~ s/[^0-9]//gs ;
    $val = "$sig$val" ;
    return $val ;
  }
  elsif ($type eq 'floating') {
    my $val = $_[0] ;
    $val =~ s/[\s_]+//gs ;
    if ( $val !~ /^\d+\.\d+$/ ) {
      ($val) = ( $val =~ /(\d+)/ ) ;
      $val .= '.0' ;
    }
    return $val ;
  }
  elsif ($type =~ /^sub_(\w+)$/) {
    my $sub = $1 ;
    return (&$sub(@_))[0] if defined &$sub ;
  }
  elsif ($type =~ /^&(\w+)$/) {
    my $sub = $1 ;
    return (&$sub(@_))[0] if defined &$sub ;
  }
  elsif ($type eq 'ref') {
    my $val = $_[0] ;
    return $val if ref($val) ;
  }
  elsif ($type eq 'array') {
    my @val = @_ ;
    return \@val ;
  }
  elsif ($type eq 'hash') {
    my %val = @_ ;
    return \%val ;
  }
  elsif ($type eq 'refarray') {
    my $val = $_[0] ;
    return $val if ref($val) eq 'ARRAY' ;
  }
  elsif ($type eq 'refhash') {
    my $val = $_[0] ;
    return $val if ref($val) eq 'HASH' ;
  }
  elsif ($type =~ /^array(&?[\w:]+)/ ) {
    my $tp = $1 ;
    my @val = @_ ;
    my $accept_undef = $tp =~ /^(?:any|string|boolean|integer|floating|sub_\w+|&\w+)$/ ? 1 : undef ;
    if ( $accept_undef ) {
      return [map { CLASS_HPLOO_ATTR_TYPE($class , $tp , $_) } @val] ;
    }
    else {
      return [map { CLASS_HPLOO_ATTR_TYPE($class , $tp , $_) || () } @val] ;
    }
  }
  elsif ($type =~ /^hash(&?[\w:]+)/ ) {
    my $tp = $1 ;
    my %val = @_ ;
    foreach my $Key ( keys %val ) {
      $val{$Key} = CLASS_HPLOO_ATTR_TYPE($class , $tp , $val{$Key}) ;
    }
    return \%val ;
  }
  elsif ($type =~ /^refarray(&?[\w:]+)/ ) {
    my $tp = $1 ;
    return undef if ref($_[0]) ne 'ARRAY' ;
    my $ref = CLASS_HPLOO_ATTR_TYPE($class , "array$tp" , @{$_[0]}) ;
    @{$_[0]} = @{$ref} ;
    return $_[0] ;
  }
  elsif ($type =~ /^refhash(&?[\w:]+)/ ) {
    my $tp = $1 ;
    return undef if ref($_[0]) ne 'HASH' ;
    my $ref = CLASS_HPLOO_ATTR_TYPE($class , "hash$tp" , %{$_[0]}) ;
    %{$_[0]} = %{$ref} ;
    return $_[0] ;
  }
  elsif ($type =~ /^\w+(?:::\w+)*$/ ) {
    return( UNIVERSAL::isa($_[0] , $type) ? $_[0] : undef ) ;
  }
  return undef ;
}

#######################################
# CLASS::HPLOO::BASE::HPLOO_TIESCALAR #
#######################################

package Class::HPLOO::Base::HPLOO_TIESCALAR ;

sub TIESCALAR {
  shift ;
  my $obj = shift ;
  my $this = bless( { nm => $_[0] , tp => $_[1] , pr => $_[2] , rf => $_[3] , rfcg => $_[4] , pk => ($_[5] || scalar caller) } , __PACKAGE__ ) ;
        
  if ( $this->{tp} =~ /^sub_(\w+)$/ ) {
    my $CLASS_HPLOO = Class::HPLOO::Base::GET_CLASS_HPLOO_HASH( undef , $this->{pk} ) ;
  
    if ( !ref($$CLASS_HPLOO{OBJ_TBL}) ) {
      eval { require Hash::NoRef } ;
      if ( !$@ ) {
        $$CLASS_HPLOO{OBJ_TBL} = {} ;
        tie( %{$$CLASS_HPLOO{OBJ_TBL}} , 'Hash::NoRef') ;
      }
      else { $@ = undef }
    }

    $$CLASS_HPLOO{OBJ_TBL}{ ++$$CLASS_HPLOO{OBJ_TBL}{x} } = $obj ;
    $this->{oid} = $$CLASS_HPLOO{OBJ_TBL}{x} ;
  }

  return $this ;
}

sub STORE {
  my $this = shift ;
  my $ref = $this->{rf} ;
  my $ref_changed = $this->{rfcg} ;

  if ( $ref_changed ) {
    if ( ref $$ref_changed ne 'HASH' ) { $$ref_changed = {} }
    $$ref_changed->{$this->{nm}} = 1 ;
  }

  if ( $this->{pr} ) {
    my $tp = $this->{tp} =~ /^ref/ ? $this->{tp} : 'ref' . $this->{tp} ;
    $$ref = &{"$this->{pk}::CLASS_HPLOO_ATTR_TYPE"}($this->{pk} , $tp , @_) ;
  }
  else {
    $$ref = &{"$this->{pk}::CLASS_HPLOO_ATTR_TYPE"}($this->{pk} , $this->{tp} , @_) ;  
  }
}

sub FETCH {
  my $this = shift ;
  my $ref = $this->{rf} ;
  
  if ( $this->{tp} =~ /^sub_(\w+)$/ ) {
    my $CLASS_HPLOO = Class::HPLOO::Base::GET_CLASS_HPLOO_HASH( undef , $this->{pk} ) ;
    my $sub = $this->{pk} . '::' . $1 ;
    my $obj = $$CLASS_HPLOO{OBJ_TBL}{ $this->{oid} } ;
    return (&$sub($obj,@_))[0] if defined &$sub ;
  }
  else {
    if ( $this->{tp} =~ /^(?:ref)?(?:array|hash)/ ) {
      my $ref_changed = $this->{rfcg} ;
      if ( $ref_changed ) {
        if ( ref $$ref_changed ne 'HASH' ) { $$ref_changed = {} }
        $$ref_changed->{$this->{nm}} = 1 ;
      }
    }
    return $$ref ;
  }
}

sub UNTIE {}
sub DESTROY {}


#######
# END #
#######

1;



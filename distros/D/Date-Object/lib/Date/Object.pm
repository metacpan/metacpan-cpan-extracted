#############################################################################
## This file was generated automatically by Class::HPLOO/0.18
##
## Original file:    ./lib/Date/Object.hploo
## Generation date:  2005-01-05 20:52:25
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        Object.pm
## Purpose:     Date::Object
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-03-19
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


sub Date::O       { Date::Object->new(@_) ;}
sub Date::O_gmt   { Date::Object->new_gmt(@_) ;}
sub Date::O_local { Date::Object->new_local(@_) ;}
sub Date::O_zone  { Date::Object->new_zone(@_) ;}
sub Date::check   { Date::Object::check(@_) ;}
sub Date::timelocal  { Date::Object::timelocal(@_) ;}

{ package Date::Object ;

  use strict qw(vars) ; no warnings ;

  use vars qw(%CLASS_HPLOO @ISA $VERSION) ;

  $VERSION = '0.06' ;

  @ISA = qw(Class::HPLOO::Base UNIVERSAL) ;

  my $CLASS = 'Date::Object' ; sub __CLASS__ { 'Date::Object' } ;
 
  sub new { 
    if ( !defined &Object && @ISA > 1 ) {
    foreach my $ISA_i ( @ISA ) {
    return &{"$ISA_i\::new"}(@_) if defined &{"$ISA_i\::new"} ;
    } }  my $class = shift ;
    $class = ref($class) if ref($class) ;
    my $this = new_call_BEGIN($class , @_) ;
    $this = bless({} , $class) if !ref($this) || !UNIVERSAL::isa($this,$class) ;
    no warnings ;
    my $undef = \'' ;
    sub UNDEF {$undef} ;
    if ( $CLASS_HPLOO{ATTR} ) {
    CLASS_HPLOO_TIE_KEYS($this) }  my $ret_this = defined &Object ? $this->Object(@_) : undef ;
    if ( ref($ret_this) && UNIVERSAL::isa($ret_this,$class) ) {
    $this = $ret_this ;
    if ( $CLASS_HPLOO{ATTR} && UNIVERSAL::isa($this,'HASH') ) {
    CLASS_HPLOO_TIE_KEYS($this) } } elsif ( $ret_this == $undef ) {
    $this = undef }  new_call_END($this,@_) ;
    return $this ;
    }  sub CLASS_HPLOO_TIE_KEYS {
    my $this = shift ;
    if ( $CLASS_HPLOO{ATTR} ) {
    foreach my $Key ( keys %{$CLASS_HPLOO{ATTR}} ) {
    tie( $this->{$Key} => 'Date::Object::HPLOO_TIESCALAR' , $this , $Key , $CLASS_HPLOO{ATTR}{$Key}{tp} , $CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} , \$this->{CLASS_HPLOO_CHANGED} , 'Date::Object' ) if !exists $this->{$Key} ;
    } } }   sub SUPER {
    eval('package Class::HPLOO::Base ;
    ') if !defined *{'Class::HPLOO::Base::'} ;
    my ($prev_pack , undef , undef , $sub0) = caller(1) ;
    $prev_pack = undef if $prev_pack eq 'Class::HPLOO::Base' ;
    my ($pack,$sub) = ( $sub0 =~ /^(?:(.*?)::|)(\w+)$/ );
    my $sub_is_new_hploo = $sub0 =~ /^(.*?(?:::)?$sub)\::$sub$/ ? 1 : undef ;
    unshift(@_ , $prev_pack) if ( $sub_is_new_hploo && $prev_pack && ((!ref($_[0]) && $_[0] ne $prev_pack && !UNIVERSAL::isa($_[0] , $prev_pack)) || (ref($_[0]) && !UNIVERSAL::isa($_[0] , $prev_pack)) ) ) ;
    if ( defined @{"$pack\::ISA"} ) {
    my $isa_sub = ISA_FIND_NEW($pack, ($sub_is_new_hploo?'new':$sub) ,1) ;
    my ($sub_name) = ( $isa_sub =~ /(\w+)$/gi );
    if ( $sub0 ne $isa_sub && !ref($_[0]) && $isa_sub =~ /^(.*?(?:::)?$sub_name)\::$sub_name$/ ) {
    @_ = ( bless({},$_[0]) , @_[1..$#_] ) ;
    } if ( $sub0 eq $isa_sub && UNIVERSAL::isa($_[0] , $pack) ) {
    my @isa = Class::HPLOO::Base::FIND_SUPER_WALK( ref($_[0]) , $pack ) ;
    my $pk = $isa[-1] ;
    if ( $sub_is_new_hploo ) {
    if ( UNIVERSAL::isa($pk , 'Class::HPLOO::Base') ) {
    ($sub) = ( $pk =~ /(\w+)$/gi );
    } else {
    $sub = 'new' ;
    } } my $isa_sub = $pk->can($sub) ;
    return &$isa_sub( ARGS_WRAPPER(@_) ) if $isa_sub ;
    } return &$isa_sub(@_) if $isa_sub && defined &$isa_sub && $sub0 ne $isa_sub ;
    } $sub = $sub_is_new_hploo ? 'new' : $sub ;
    die("Can't find SUPER method for $sub0!") if "$pack\::$sub" eq $sub0 ;
    return &{"$pack\::$sub"}(@_) ;
    }  sub FIND_SUPER_WALK {
    my $class_main = shift ;
    my $class_end = shift ;
    my $only_stak = shift ;
    my (@stack) ;
    my $stack = $only_stak || {} ;
    my $found ;
    foreach my $isa_i ( @{"$class_main\::ISA"} ) {
    next if $$stack{$isa_i}++ ;
    $found = 1 if $isa_i eq $class_end ;
    push(@stack , $isa_i , FIND_SUPER_WALK($isa_i , $class_end , $stack) );
    }  return ($found ? @stack : ()) if $only_stak ;
    return @stack ;
    }  sub ISA_FIND_NEW {
    my $pack = shift ;
    my $sub = shift ;
    my $look_deep = shift ;
    my $count = shift ;
    return if $count > 100 ;
    my ($sub_name) ;
    if ( UNIVERSAL::isa($pack , 'Class::HPLOO::Base') ) {
    ($sub_name) = $sub eq 'new' ? ( $pack =~ /(\w+)$/ ) : ($sub) ;
    } else {
    $sub_name = $sub ;
    }  my $isa_sub = "$pack\::$sub_name" ;
    if ( $look_deep || !defined &$isa_sub ) {
    foreach my $isa_i ( @{"$pack\::ISA"} ) {
    next if $isa_i eq $pack || $isa_i eq 'Class::HPLOO::Base' ;
    last if $isa_i eq 'UNIVERSAL' ;
    $isa_sub = ISA_FIND_NEW($isa_i , $sub , 0 , $count+1) ;
    last if $isa_sub ;
    } }  $isa_sub = undef if !defined &$isa_sub ;
    return $isa_sub ;
    }  sub new_call_BEGIN {
    my $class = shift ;
    my $this = $class ;
    foreach my $ISA_i ( @ISA ) {
    last if $ISA_i eq 'Class::HPLOO::Base' ;
    my $ret ;
    my ($sub) = ( $ISA_i =~ /(\w+)$/ );
    $sub = "$ISA_i\::$sub\_BEGIN" ;
    $ret = &$sub($this,@_) if defined &$sub ;
    $this = $ret if UNIVERSAL::isa($ret,$class) ;
    } return $this ;
    }  sub new_call_END {
    my $class = shift ;
    foreach my $ISA_i ( @ISA ) {
    last if $ISA_i eq 'Class::HPLOO::Base' ;
    my $ret ;
    my ($sub) = ( $ISA_i =~ /(\w+)$/ );
    $sub = "$ISA_i\::$sub\_END" ;
    &$sub(@_) if defined &$sub ;
    } return ;
  }

  
  sub GET_CLASS_HPLOO_HASH { 
    return \%CLASS_HPLOO } ;
    sub ATTRS {
    return @{[@{ $CLASS_HPLOO{ATTR_ORDER} }]} } ;
    sub CLASS_HPLOO_ATTR {
    my @attrs = split(/\s*,\s*/ , $_[0]) ;
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
    }  my $parse_ref = $type =~ /^(?:array|hash)/ ? 1 : 0 ;
    push(@{ $CLASS_HPLOO{ATTR_ORDER} } , $name) if !$CLASS_HPLOO{ATTR}{$name} ;
    $CLASS_HPLOO{ATTR}{$name}{tp} = $type ;
    $CLASS_HPLOO{ATTR}{$name}{pr} = $parse_ref ;
    my $return ;
    if ( $type =~ /^sub_(\w+)$/ ) {
    my $sub = $1 ;
    $return = qq~ return (&$sub(\$this,\@_))[0] if defined &$sub ;
    return undef ;
    ~ ;
    } else {
    $return = $parse_ref ? qq~ ref(\$this->{CLASS_HPLOO_ATTR}{$name}) eq 'ARRAY' ? \@{\$this->{CLASS_HPLOO_ATTR}{$name}} : ref(\$this->{CLASS_HPLOO_ATTR}{$name}) eq 'HASH' ? \%{\$this->{CLASS_HPLOO_ATTR}{$name}} : \$this->{CLASS_HPLOO_ATTR}{$name} ~ : "\$this->{CLASS_HPLOO_ATTR}{$name}" ;
    }  eval(qq~ sub set_$name {
    my \$this = shift ;
    if ( !defined \$this->{$name} ) {
    tie( \$this->{$name} => 'Date::Object::HPLOO_TIESCALAR' , \$this , '$name' , '$type' , $parse_ref , \\\$this->{CLASS_HPLOO_ATTR}{$name} , \\\$this->{CLASS_HPLOO_CHANGED} , 'Date::Object' ) ;
    }  \$this->{CLASS_HPLOO_CHANGED}{$name} = 1 ;
    \$this->{CLASS_HPLOO_ATTR}{$name} = CLASS_HPLOO_ATTR_TYPE( ref(\$this) , '$type',\@_) ;
    } ~) if !defined &{"set_$name"} ;
    eval(qq~ sub get_$name {
    my \$this = shift ;
    $return ;
    } ~) if !defined &{"get_$name"} ;
    } }  { package Date::Object::HPLOO_TIESCALAR ;
    sub TIESCALAR {
    shift ;
    my $obj = shift ;
    my $this = bless( {
    nm => $_[0] , tp => $_[1] , pr => $_[2] , rf => $_[3] , rfcg => $_[4] , pk => ($_[5] || scalar caller) } , __PACKAGE__ ) ;
    if ( $this->{tp} =~ /^sub_(\w+)$/ ) {
    my $CLASS_HPLOO = Date::Object::GET_CLASS_HPLOO_HASH() ;
    if ( !ref($$CLASS_HPLOO{OBJ_TBL}) ) {
    eval {
    require Hash::NoRef } ;
    if ( !$@ ) {
    $$CLASS_HPLOO{OBJ_TBL} = {} ;
    tie( %{$$CLASS_HPLOO{OBJ_TBL}} , 'Hash::NoRef') ;
    } else {
    $@ = undef } }  $$CLASS_HPLOO{OBJ_TBL}{ ++$$CLASS_HPLOO{OBJ_TBL}{x} } = $obj ;
    $this->{oid} = $$CLASS_HPLOO{OBJ_TBL}{x} ;
    }  return $this ;
    }  sub STORE {
    my $this = shift ;
    my $ref = $this->{rf} ;
    my $ref_changed = $this->{rfcg} ;
    if ( $ref_changed ) {
    if ( ref $$ref_changed ne 'HASH' ) {
    $$ref_changed = {} } $$ref_changed->{$this->{nm}} = 1 ;
    }  if ( $this->{pr} ) {
    my $tp = $this->{tp} =~ /^ref/ ? $this->{tp} : 'ref' . $this->{tp} ;
    $$ref = &{"$this->{pk}::CLASS_HPLOO_ATTR_TYPE"}($this->{pk} , $tp , @_) ;
    } else {
    $$ref = &{"$this->{pk}::CLASS_HPLOO_ATTR_TYPE"}($this->{pk} , $this->{tp} , @_) ;
    } }  sub FETCH {
    my $this = shift ;
    my $ref = $this->{rf} ;
    if ( $this->{tp} =~ /^sub_(\w+)$/ ) {
    my $CLASS_HPLOO = Date::Object::GET_CLASS_HPLOO_HASH() ;
    my $sub = $this->{pk} . '::' . $1 ;
    my $obj = $$CLASS_HPLOO{OBJ_TBL}{ $this->{oid} } ;
    return (&$sub($obj,@_))[0] if defined &$sub ;
    } else {
    if ( $this->{tp} =~ /^(?:ref)?(?:array|hash)/ ) {
    my $ref_changed = $this->{rfcg} ;
    if ( $ref_changed ) {
    if ( ref $$ref_changed ne 'HASH' ) {
    $$ref_changed = {} } $$ref_changed->{$this->{nm}} = 1 ;
    } } return $$ref ;
    } return undef ;
    } sub UNTIE {} sub DESTROY {} }  sub CLASS_HPLOO_ATTR_TYPE {
    my $class = shift ;
    my $type = shift ;
    if ($type eq 'any') {
    return $_[0] } elsif ($type eq 'string') {
    return "$_[0]" ;
    } elsif ($type eq 'boolean') {
    return if $_[0] =~ /^(?:false|null|undef)$/i ;
    return 1 if $_[0] ;
    return ;
    } elsif ($type eq 'integer') {
    my $val = $_[0] ;
    my ($sig) = ( $val =~ /^(-)/ );
    $val =~ s/[^0-9]//gs ;
    $val = "$sig$val" ;
    return $val ;
    } elsif ($type eq 'floating') {
    my $val = $_[0] ;
    $val =~ s/[\s_]+//gs ;
    if ( $val !~ /^\d+\.\d+$/ ) {
    ($val) = ( $val =~ /(\d+)/ ) ;
    $val .= '.0' ;
    } return $val ;
    } elsif ($type =~ /^sub_(\w+)$/) {
    my $sub = $1 ;
    return (&$sub(@_))[0] if defined &$sub ;
    } elsif ($type =~ /^&(\w+)$/) {
    my $sub = $1 ;
    return (&$sub(@_))[0] if defined &$sub ;
    } elsif ($type eq 'ref') {
    my $val = $_[0] ;
    return $val if ref($val) ;
    } elsif ($type eq 'array') {
    my @val = @_ ;
    return \@val ;
    } elsif ($type eq 'hash') {
    my %val = @_ ;
    return \%val ;
    } elsif ($type eq 'refarray') {
    my $val = $_[0] ;
    return $val if ref($val) eq 'ARRAY' ;
    } elsif ($type eq 'refhash') {
    my $val = $_[0] ;
    return $val if ref($val) eq 'HASH' ;
    } elsif ($type =~ /^array(&?[\w:]+)/ ) {
    my $tp = $1 ;
    my @val = @_ ;
    my $accept_undef = $tp =~ /^(?:any|string|boolean|integer|floating|sub_\w+|&\w+)$/ ? 1 : undef ;
    if ( $accept_undef ) {
    return [map {
    CLASS_HPLOO_ATTR_TYPE($class , $tp , $_) } @val] ;
    } else {
    return [map {
    CLASS_HPLOO_ATTR_TYPE($class , $tp , $_) || () } @val] ;
    } } elsif ($type =~ /^hash(&?[\w:]+)/ ) {
    my $tp = $1 ;
    my %val = @_ ;
    foreach my $Key ( keys %val ) {
    $val{$Key} = CLASS_HPLOO_ATTR_TYPE($class , $tp , $val{$Key}) ;
    } return \%val ;
    } elsif ($type =~ /^refarray(&?[\w:]+)/ ) {
    my $tp = $1 ;
    return undef if ref($_[0]) ne 'ARRAY' ;
    my $ref = CLASS_HPLOO_ATTR_TYPE($class , "array$tp" , @{$_[0]}) ;
    @{$_[0]} = @{$ref} ;
    return $_[0] ;
    } elsif ($type =~ /^refhash(&?[\w:]+)/ ) {
    my $tp = $1 ;
    return undef if ref($_[0]) ne 'HASH' ;
    my $ref = CLASS_HPLOO_ATTR_TYPE($class , "hash$tp" , %{$_[0]}) ;
    %{$_[0]} = %{$ref} ;
    return $_[0] ;
    } elsif ($type =~ /^\w+(?:::\w+)*$/ ) {
    return( UNIVERSAL::isa($_[0] , $type) ? $_[0] : undef ) ;
    } return undef ;
  }

  no warnings ;

  use overload (
  '""' => '_OVER_string' ,
  '0+'  => '_OVER_number' ,
  'fallback' => 1 ,
  ) ;
  
  sub _OVER_string { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->date ;}
  sub _OVER_number { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->time ;}

  CLASS_HPLOO_ATTR('
        int time , int sec , int min , int hour , int day , int month , int year , int wday , int yday , int isdst , int zone ,
        sub zone_gmt ,
        sub s , sub m , sub h , sub d , sub mo , sub y , sub z ,
        sub serial ,
        sub date , sub date_zone ,
        sub hms , sub ymd , sub mdy , sub dmy ') ;
  
  my @MONTHS_DAYS = ('',31,28,31,30,31,30,31,31,30,31,30,31) ;

  sub Object { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my ( $year , $month , $day , $hour , $min , $sec , $zone , $time ) ;
    
    if ( $#_ == 0 && ref($_[0]) eq 'ARRAY' ) {
      ($zone , @_) = @{$_[0]} ;
    }
    
    my $time ;
    if ( !@_ ) { $time = time ;}
    elsif ( $#_ == 0 || $#_ == 1 ) {
      if ( ref($_[0]) && UNIVERSAL::isa($_[0],'Date::Object') ) {
        $time = $_[0]->time ;
        $zone = $_[0]->zone if $zone eq '' ;
      }
      elsif ( length($_[0]) >= 14 && $_[0] =~ /^\d+$/ ) {
        return new_serial('Date::Object',$_[0]) ;
      }
      elsif ( $_[0] =~ /^\s*(\d+)\D+(\d+)\D+(\d+)(?:\s+(\d\d?)\D+(\d\d?)(?:\D+(\d\d?))?)?/ ) {
        my ( $d , $m , $y , $h , $min , $s ) ;
        my @match = ($1 , $2 , $3 , $4 , $5 , $6) ;

        if ( $_[1] =~ /mdy/i ) {
          ( $m , $d , $y , $h , $min , $s ) = @match ;
        }
        elsif ( $_[1] =~ /dmy/i ) {
          ( $d , $m , $y , $h , $min , $s ) = @match ;
        }
        elsif ( $_[1] =~ /ymd/i ) {
          ( $y , $m , $d , $h , $min , $s ) = @match ;
        }
        else {
          ( $y , $m , $d , $h , $min , $s ) = @match ;
        }
      
        $time = $this->timelocal($y , $m , $d , $h , $min , $s , 0 ) ;
      }
      elsif ( $_[0] >= 0 ) { $time = $_[0] ;}
      else { $time = 0 ;}
    }
    else {
      if ($zone eq '') { $zone = $#_ >= 6 ? $_[6] : 0 ;}
      $time = $this->timelocal(@_[0..5] , $zone) ;
    }

    return UNDEF if $time == undef ;
    
    $this->{time} = $time ;
    
    if ( $zone ne '' ) { $this->set_zone($zone) ;}
    else { $this->set_gmt($time) ;}
  }
  
  sub new_gmt { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $class = shift ;
    new($class , [0,@_]) ;
  }
  
  sub new_local { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $class = shift ;
    my $zone = _calc_timezone() ;
    my $obj = new($class , [$zone , @_]) ;
    return $obj ;
  }
  
  sub new_zone { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $class = shift ;
    my $zone = shift ;
    my $obj = new($class , [$zone , @_]) ;
    return $obj ;
  }
  
  sub new_serial { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $class = shift ;
    my $serial = shift ;
    
    my ($time , $zone) = ( $serial =~ /^(\d+)(\d{4})$/ );
    
    if ( $zone > 1200 ) { $zone -= 1200 ;}
    elsif ( $zone == 1200 ) { $zone = 0 ;}
    else { $zone *= -1 ;}
    
    $zone =~ s/(\d\d)$/\.$1/ ;
    $zone =~ s/\.00$// ;
    $zone *= 1 ;
    
    my $obj = new($class , [$zone , $time]) ;
    return $obj ;
  }

  sub clone { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $clone = Date::Object->new_zone($this->zone , $this) ;
    return $clone ;
  }
    
  sub set_gmt { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $time = shift(@_) ;
    
    ($this->{sec} , $this->{min} , $this->{hour} , $this->{day} , $this->{month} , $this->{year} , $this->{wday} , $this->{yday} , $this->{isdst} ) = $this->gmtime($time) ;
    $this->{zone} = 0 ;
    $this->{time} = $time ;
    return $this ;
  }
  
  sub set_local { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $time = shift(@_) ;
    my $local_zone = shift(@_) ;
    
    ($this->{sec} , $this->{min} , $this->{hour} , $this->{day} , $this->{month} , $this->{year} , $this->{wday} , $this->{yday} , $this->{isdst} ) = $this->localtime($time) ;
    $this->{zone} = $this->_calc_timezone if $local_zone eq '' ;
    $this->{time} = $this->timelocal($this->{year} , $this->{month} , $this->{day} , $this->{hour} , $this->{min} , $this->{sec} , $this->{zone} ) ;
    return $this ;
  }
  
  sub set_zone { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $zone = shift(@_) ;
    my $time = shift(@_) ;
    
    $zone = $this->_format_zone($zone) if $zone ;
    
    $zone ||= $this->zone || 0 ;
    $time ||= $this->time ;
    
    $this->{zone} = $zone ;
    
    my $time_gmt = $time + (60*60*$zone) ;
    
    ($this->{sec} , $this->{min} , $this->{hour} , $this->{day} , $this->{month} , $this->{year} , $this->{wday} , $this->{yday} , $this->{isdst} ) = $this->gmtime($time_gmt) ;
    
    if ( $zone ) {
      my $local_zone = $this->_calc_timezone ;
      if ( $zone == $local_zone ) {
        ( $this->{isdst} ) = ($this->localtime($time))[8] ;
      }
      else { $this->{isdst} = 0 ;}
    }
    
    $this->{time} = $time ;
    return $this ;
  }
  
  sub set_serial { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $serial = shift(@_) ;
    
    my ($time , $zone) = ( $serial =~ /^(\d+)(\d{4})$/ );
    
    if ( $zone > 1200 ) { $zone -= 1200 ;}
    elsif ( $zone == 1200 ) { $zone = 0 ;}
    else { $zone *= -1 ;}
    
    $zone =~ s/(\d\d)$/\.$1/ ;
    $zone =~ s/\.00$// ;
    $zone *= 1 ;
    
    $this->set_zone($zone , $time) ;
    
    return $this ;
  }
  
  sub set { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $y = shift(@_) ;
    my $mo = shift(@_) ;
    my $d = shift(@_) ;
    my $h = shift(@_) ;
    my $m = shift(@_) ;
    my $s = shift(@_) ;
    
    $y = $this->{y} if !defined $y ;
    $mo = $this->{mo} if !defined $mo ;
    $d = $this->{d} if !defined $d ;
    $h = $this->{h} if !defined $h ;
    $m = $this->{m} if !defined $m ;
    $s = $this->{s} if !defined $s ;
    
    if ( $d > $this->check($mo) ) { $d = $this->check($mo) ;}

    my $new_date = Date::Object->new_zone( $this->zone , $y , $mo , $d , $h , $m , $s ) ;
    $this->set_serial( $new_date->serial ) ;
    
    return $this ;
  }
  
  sub _format_zone { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $zone = shift(@_) ;
    
    $zone ||= 0 ;
    if ( $zone > 12 ) { $zone = 12 ;}
    if ( $zone < -12 ) { $zone = -12 ;}
    $zone =~ s/(\.\d{1,2})\d*/$1/ ;
    return $zone ;
  }
  
  sub _calc_timezone { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $d0 = Date::Object->new(time) ;
    
    my ($sec,$min,$hour,$mday,$mon,$year) = $d0->localtime ;
    my $d1 = Date::Object->new($year , $mon , $mday , $hour , $min ,$sec) ;
    
    my $zone = $d1->time - $d0->time ;
    $zone /= 60*60 ;
    
    $zone =~ s/(\.\d\d)\d*/$1/ ;

    return $zone ;
  }
  
  sub zone { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{zone} ;}
  
  sub zone_gmt { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my ($sign,$h,$m) = ( $this->{zone} =~ /^([\+\-]?)(\d{1,2})\d*(?:\.(\d{1,2})\d*)?$/ );
    
    $sign ||= '+' ;
    
    $h = "0$h" while length($h) < 2 ;
    $m = "0$m" while length($m) < 2 ;

    my $z = "$sign$h$m" ;
    return $z ;
  }
  
  sub time { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{time} ;}
  
  sub sec { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{sec} ;}
  sub min { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{min} ;}
  sub hour { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{hour} ;}
  sub day { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{day} ;}
  sub month { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{month} ;}
  sub year { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{year} ;}
  sub wday { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{wday} ;}
  sub yday { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{yday} ;}
  sub isdst { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{isdst} ;}
  
  sub s { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{sec} ;}
  sub m { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{min} ;}
  sub h { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{hour} ;}
  sub d { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{day} ;}
  sub mo { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{month} ;}
  sub y { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{year} ;}
  sub z { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->{zone} ;}
  
  sub serial { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $z = $this->zone_gmt ;
    if    ( $z =~ /^-(\d+)/ ) { $z = $1 ;}
    elsif ( $z =~ /^[\+]?(\d+)/ ) { $z = $1 + 1200 ;}
    my $serial = $this->time . $z ;
    while( length($serial) < 14 ) { $serial = "0$serial" ;}
    return $serial ;
  }
  
  sub add_sec { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $secs = shift(@_) ;
    
    $secs ||= 1 ;
    $this->{time} += $secs ;
    $this->set_zone ;
  }
  
  sub add_min { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $mins = shift(@_) ;
    
    $mins ||= 1 ;
    $this->{time} += 60*$mins ;
    $this->set_zone ;
  }
  
  sub add_hour { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $hours = shift(@_) ;
    
    $hours ||= 1 ;
    $this->{time} += 60*60*$hours ;
    $this->set_zone ;
  }
  
  sub add_day { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $days = shift(@_) ;
    
    $days ||= 1 ;
    $this->{time} += 60*60*24*$days ;
    $this->set_zone ;
  }
  
  sub add_week { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $weeks = shift(@_) ;
    
    $weeks ||= 1 ;
    $this->add_day(7*$weeks) ;
  }
  
  sub add_month { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $months = shift(@_) ;
    
    $months ||= 1 ;
    
    if ( $months < 0 ) { return $this->sub_month($months*-1) ;}
    
    my $y = $this->y ;
    my $mo = $this->mo ;
    
    for my $i (1..$months) {
      ++$mo ;
      if ( $mo > 12 ) { $mo = 1 ; ++$y ;}
    }
    
    $this->{time} = $this->timelocal( $y , $mo , $this->d , $this->h , $this->m , $this->s , $this->z ) ;
    $this->set_zone ;
  }
  
  sub sub_month { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $months = shift(@_) ;
    
    $months ||= 1 ;
    
    if ( $months < 0 ) { return $this->add_month($months*-1) ;}
    
    my $y = $this->y ;
    my $mo = $this->mo ;
    
    for my $i (1..$months) {
      --$mo ;
      if ( $mo < 1 ) { $mo = 12 ; --$y ;}
    }
    
    $this->{time} = $this->timelocal( $y , $mo , $this->d , $this->h , $this->m , $this->s , $this->z ) ;
    $this->set_zone ;
  }
  
  sub add_year { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $years = shift(@_) ;
    
    $years ||= 1 ;
    $this->add_month(12*$years) ;
  }
  
  sub sub_sec { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ;my $n = shift(@_) ; $n ||= 1 ; $this->add_sec(  $n*-1 ) ;}
  sub sub_min { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ;my $n = shift(@_) ; $n ||= 1 ; $this->add_min(  $n*-1 ) ;}
  sub sub_hour { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ;my $n = shift(@_) ; $n ||= 1 ; $this->add_hour( $n*-1 ) ;}
  sub sub_day { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ;my $n = shift(@_) ; $n ||= 1 ; $this->add_day(  $n*-1 ) ;}
  sub sub_week { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ;my $n = shift(@_) ; $n ||= 1 ; $this->add_week( $n*-1 ) ;}
  sub sub_year { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ;my $n = shift(@_) ; $n ||= 1 ; $this->add_year( $n*-1 ) ;}
  
  sub gmtime { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $time = shift(@_) ;
    
    $time ||= $this->{time} || time ;
    return _fix_vars_time( gmtime($time) ) ;
  }
  
  sub localtime { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $time = shift(@_) ;
    
    $time ||= $this->{time} || time ;
    return _fix_vars_time( localtime($time) ) ;
  }
  
  sub _fix_vars_time { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $sec = shift(@_) ;
    my $min = shift(@_) ;
    my $hour = shift(@_) ;
    my $mday = shift(@_) ;
    my $mon = shift(@_) ;
    my $year = shift(@_) ;
    my $wday = shift(@_) ;
    my $yday = shift(@_) ;
    my $isdst = shift(@_) ;
    
    ++$mon ;
    $year += 1900 ;
    ++$yday ;
    
    $sec  = "0$sec"  if $sec  < 10 ;
    $min  = "0$min"  if $min  < 10 ;
    $hour = "0$hour" if $hour < 10 ;
    $mday = "0$mday" if $mday < 10 ;
    $mon  = "0$mon"  if $mon  < 10 ;
    
    return ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) ;
  }
  
  sub timelocal { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $year = shift(@_) ;
    my $mon = shift(@_) ;
    my $day = shift(@_) ;
    my $hour = shift(@_) ;
    my $min = shift(@_) ;
    my $sec = shift(@_) ;
    my $zone = shift(@_) ;
    
    
    $zone = _format_zone($zone) ;
  
    my $year_0 = (gmtime(1))[5] + 1900 ;
    
    my ($now_sec,$now_min,$now_hour,$now_mday,$now_mon,$now_year) = $this->gmtime ;

    if (!$year || $year eq '*' || $year < $year_0) { $year = $now_year ;}
  
    my $year_bisexto = 0 ;
    if ( $this->is_leap_year($year) ) { $year_bisexto = 1 ;}

    if (!$mon || $mon eq '*') { $mon = $now_mon }
    elsif ($mon < 1 || $mon > 12 ) { return }

    elsif (!$day || $day eq '*') { $day = $now_mday }
    elsif ($day < 1 || $day > 31 ) { return }
    elsif ($mon == 2 && $day > 28) {
      $day = 28 if !$this->check($year,$mon,$day) ;
    }
    elsif ($day > $this->check($mon) ) { return }
  
    if    ($hour eq '') { $hour = 0 }
    elsif ($hour eq '*') { $hour = $now_hour }
    elsif ($hour == 24) { $hour = 0 }
    elsif ($hour < 0 || $hour > 24 ) { return }
    
    if    ($min eq '') { $min = 0 }
    elsif ($min eq '*') { $min = $now_min }
    elsif ($min == 60) { $min = 59 }
    elsif ($min < 0 || $min > 60 ) { return }
    
    if    ($sec eq '') { $sec = 0 }
    elsif ($sec eq '*') { $sec = $now_sec }
    elsif ($sec == 60) { $sec = 59 }
    elsif ($sec < 0 || $sec > 60 ) { return }
  
    my $timelocal ;
  
    my $time_day = 60*60*24 ;
    my $time_year = $time_day * 365 ;
        
    for my $y ($year_0..($year-1)) {
      $timelocal += $time_year ;
      if ( $this->is_leap_year($y) ) { $timelocal += $time_day ;}
    }
    
    for my $m (1..($mon-1)) {
      my $month_days = &check($m) ;
      $timelocal += $month_days * $time_day ;
    }
  
    if ($year_bisexto == 1 && $mon > 2) { $timelocal += $time_day ;}
      
    $timelocal += $time_day * ($day-1) ;
    
    $timelocal += 60*60 * $hour ;
    $timelocal += 60 * $min ;
    $timelocal += $sec ;
    
    $timelocal += 60*60*($zone*-1) if $zone ;
      
    return $timelocal ;
  }
  
  sub check { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    shift if $_[0] !~ /^\d+$/ ;

    my ( $year , $month , $day ) ;
    
    if ($#_ == 2) { ( $year , $month , $day ) = @_ ;}
    if ($#_ == 1) { ( $month , $day ) = @_ ;}
    if ($#_ == 0) { ( $month ) = @_ ;}
    
    if ($#_ > 0) {
      if ($year eq '')  { $year = 1970 }
      if ($month eq '') { $month = 1 }
      if ($day eq '')   { $day = 1 }
      
      my @months_days = @MONTHS_DAYS ;
      
      if ( $this->is_leap_year($year) ) { $months_days[2] = 29 ;}
      
      if ($day <= $months_days[$month]) { return 1 ;}
      else { return ;}
    }
    elsif ($#_ == 0) {
      if ($month eq '') { return ; }
      return $MONTHS_DAYS[$month] ;
    }
    
    return undef ;
  }
  
  # The Egyptians called it 365 and left it at that. But their calendar got out of step with the seasons, so that 
  # after around 750 years of this they were celebrating The Fourth of July in the middle of the winter.
  # 
  # The Romans wised up and added the leap day every four years to get the 365.25 day Julian year. Much better, 
  # but notice that this time the year is longer than it ought to be. The small difference between this and the 
  # true length of the year caused the seasons to creep through the calendar once again, only slower and in the 
  # other direction. After about 23000 years of this, July Fourth would once again fall in mid-winter.
  # 
  # Fortunately things never reached that sad state. By 1582 the calendar was about ten days out of whack, so 
  # Pope Gregory XIII included the correction that's still in use today. 
  # 
  # "If the year is divisible by 100, it's not a leap year UNLESS it is also divisible by 400."
  # 
  # More recently, proposals for fixes have gotten even better than that. One suggested change is to add on "if 
  # the year is also divisible by 4000, it's not a leap year."
  
  sub is_leap_year { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $year = shift(@_) ;
    
    $year = $this->{year} if $year eq '' ;

    if    ($year == 0) { return 1 ;}
    elsif (($year % 4000) == 0) { return 0 ;}
    elsif (($year % 400) == 0) { return 1 ;}
    elsif (($year % 100) == 0) { return 0 ;}
    elsif (($year % 4) == 0) { return 1 ;}
    return 0 ;
  }
  
  sub secs_from { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $time_0 = $this->time ;
    my $time_1 = Date::Object->new(@_)->time ;
    
    my $delay = $time_0 - $time_1 ;
    return $delay ;
  }
  
  sub min_from { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $delay = $this->secs_from(@_) ;
    my $min = int($delay / (60)) ;
    return $min ;
  }
  
  sub hours_from { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $delay = $this->secs_from(@_) ;
    my $hours = int($delay / (60*60)) ;
    return $hours ;
  }
  
  sub days_from { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $delay = $this->secs_from(@_) ;
    my $days = int($delay / (60*60*24)) ;
    return $days ;
  }
  
  sub weeks_from { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $days = $this->days_from(@_) ;
    my $weeks = int($days / 7) ;
    return $weeks ;
  }
  
  sub months_from { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $days = $this->days_from(@_) ;
    my $months = int($days / 30) ;
    return $months ;
  }
  
  sub years_from { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $days = $this->days_from(@_) ;
    my $years = int($days / 365) ;
    return $years ;
  }
  
  sub secs_until { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->secs_from(@_) * -1 ;}
  sub min_until { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->min_from(@_) * -1 ;}
  sub hours_until { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->hours_from(@_) * -1 ;}
  sub days_until { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->days_from(@_) * -1 ;}
  sub weeks_until { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->weeks_from(@_) * -1 ;}
  sub months_until { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->months_from(@_) * -1 ;}
  sub years_until { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->years_from(@_) * -1 ;}
  
  sub secs_between { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; my $r = $this->secs_from(@_) ; $r < 0 ? ($r*-1) : $r ;}
  sub min_between { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; my $r = $this->min_from(@_) ; $r < 0 ? ($r*-1) : $r ;}
  sub hours_between { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; my $r = $this->hours_from(@_) ; $r < 0 ? ($r*-1) : $r ;}
  sub days_between { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; my $r = $this->days_from(@_) ; $r < 0 ? ($r*-1) : $r ;}
  sub weeks_between { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; my $r = $this->weeks_from(@_) ; $r < 0 ? ($r*-1) : $r ;}
  sub months_between { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; my $r = $this->months_from(@_) ; $r < 0 ? ($r*-1) : $r ;}
  sub years_between { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; my $r = $this->years_from(@_) ; $r < 0 ? ($r*-1) : $r ;}
  
  sub date { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $date = "$this->{year}-$this->{month}-$this->{day} $this->{hour}:$this->{min}:$this->{sec}" ;
    return $date ;
  }
  
  sub date_zone { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $z = $this->zone_gmt ;
    my $date = "$this->{year}-$this->{month}-$this->{day} $this->{hour}:$this->{min}:$this->{sec} $z" ;
    return $date ;
  }
  
  sub hour { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $date = "$this->{hour}:$this->{min}:$this->{sec}" ;
    return $date ;
  }
  
  sub hms { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ; $this->hour }
  
  sub ymd { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $date = "$this->{year}-$this->{month}-$this->{day}" ;
    return $date ;
  }
  
  sub mdy { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $date = "$this->{month}-$this->{day}-$this->{year}" ;
    return $date ;
  }
  
  sub dmy { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $date = "$this->{day}-$this->{month}-$this->{year}" ;
    return $date ;
  }
  
  sub STORABLE_freeze { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $cloning = shift(@_) ;
    
    return $this->serial ;
  }
  
  sub STORABLE_thaw { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $cloning = shift(@_) ;
    my $serial = shift(@_) ;
    
    $this->set_serial($serial) ;
    return ;
  }


}



1;

__END__

=head1 NAME

Date::Object - Handles dates/calendars/timezones and it's representation/convertions using a single Date::Object.

=head1 DESCRIPTION

Date::Object is an alternative to the L<DateTime> modules, with the main pourpose
to handle dates using a single object or make multiple I<Date::Object>s work together
to calculate and handle dates.

Other main poupose of I<Date::Object> is to find a simple way to store dates
in a persistent enverioment (any database) using a simple INTEGER field.
The use of a INTEGER field for that make possible searches in the DB by ranges,
what is impossible with normal storages of dates, specially if they are saved as STRING,
generally in the comon format of "YYYY-MM-DD". Also an INTEGER field have all the informations
of a date, including I<year, month, day, hour, minute, second and timezone>. Other good
thing is that any DB supports INTEGER fields, what doesn't make our Perl code dependent
of the SQL nuances of each different way to handle dates of each DB.

See the method I<serial()> for DB usage.

=head1 USAGE

  use Date::Object ;

  ...
  
  my $date = new Date::Object( time() ) ;
  
  my $date2 = new Date::Object( $date ) ;

  ...

  my $date = new Date::Object( 2004 , 2 , 29 , 12 , 30 , 10 ) ;

  print $date->date ; ## 2004-02-29 12:30:10

  $date->set_local ;
  ...
  $date->set_zone(-3) ;

  print $date->date ; ## 2004-02-29 09:30:10
  
  ...
  
  print $date->year ;
  print $date->month ;
  print $date->day ;
  
  ...
  
  print "$date->{year}\n" ;
  print "$date->{month}\n" ;
  print "$date->{hour}\n" ;
  
  ...
  
  print $date->hour ; ## hh:mm:ss
  
  ...

  print $date->ymd ; ## yyyy-mm-dd
  print $date->mdy ; ## mm-dd-yyyy
  print $date->dmy ; ## dd-mm-yyyy
  print $date->hms ; ## hh:mm:ss
  
  ...
  
  if ( $date_0 == $date_1 ) {...}
  if ( $date_0 > $date_1 ) {...}

=head1 NEW

To create a I<Date::Object> you can use different types of arguments:

=over 4

=item TIME

  Date::Object->new( time() ) ;
  

=item YEAR , MONTH , DAY , HOUR , MIN , SEC , ZONE

  Date::Object->new( 2004 , 12 , 25 , 15 , 30 , 59 ) ;

=item YYYY/MM/DD HH:MM:SS formats:

  Date::Object->new( "2004/12/25 15:30:59" ) ;
  Date::Object->new( "2004/12/25 15:30:59" , 'ymd' ) ;
  
  Date::Object->new( "25/12/2004 15:30:59" , 'dmy' ) ;
  
  Date::Object->new( "12/25/2004 15:30:59" , 'mdy' ) ;

=item Date::Object

  Date::Object->new( $another_date_object ) ;

=item NULL

When arguments are not sent the actual time() will be used.

=back

B<You also can use this extra contructors to handle the timezone and the serial:>

=head2 new_gmt

Create a new Date::Object in the GMT timezone.

  my $d_gmt = Date::Object::new_gmt() ;

=head2 new_local

Create a new Date::Object in the local timezone.

  my $d_gmt = Date::Object::new_local() ;

=head2 new_zone(ZONE , ...)

Create a new Date::Object in the given ZONE (timezone).

Examples:

  my $d0 = Date::Object::new_zone(-3) ;
  my $d1 = Date::Object::new_zone(-3 , 2004 , 1 , 1 , 12 , 30 , 00) ;
  
  ...

  my $d_gmt = Date::Object::new_gmt() ;
  my $d_local = Date::Object::new_zone(-3 , $d_gmt) ;

=head2 new_serial(SERIAL)

Create a new Date::Object using a serial INTEGER. See I<serial()> for more.

=head1 METHODS

=head2 add_day (N)

Add N days in the date. I<By default N is 1>.

=head2 add_hour

Add N hours in the date. I<By default N is 1>.

=head2 add_min

Add N minutes in the date. I<By default N is 1>.

=head2 add_month

Add N months in the date. I<By default N is 1>.

Note that this is not the same to add 30 days! The function will make a plus only in the month,
and will incremente automatically the year and also will handle the month days if needed, like Feb-29.

=head2 add_sec

Add N seconds in the date. I<By default N is 1>.

=head2 add_week

Add N weeks in the date. I<By default N is 1>.

=head2 add_year

Add N years in the date. I<By default N is 1>.

=head2 check (YEAR , MONTH , DAY)

Check if a given date exists. Returns I<BOOLEAN>.

Also can be used as a static method/function.

=head2 clone

Return a copy of the previous object.

=head2 date

Return the date in the format:

  YYYY-MM-DD HH:MM:SS

Example:

  2004-03-20 23:20:34

=head2 date_zone

Return the date in the format:

  YYYY-MM-DD HH:MM:SS ZONE

Example:

  2004-03-20 23:20:34 -0300

=head2 day

Return the day of the date.

=head2 days_between (DATEOBJECT | DATE )

Return the number of days between 2 date objects.

Example of use:

  my $d0 = Date::O(2004 , 1 , 1) ;
  my $d1 = Date::O(2005 , 1 , 1) ;
  
  if ( $d0->days_between($d1) == 366 ) {...}

=head2 days_from

Return the number of days from a given date.

=head2 days_until

Return the number of days until a given date.

=head2 dmy

Return the date in the format:

  DD-MM-YYYY

=head2 gmtime(TIME)

Return the same values of the core function gmtime(), but the values will be formated,
soo, in the year 1900 will be added, to month 1 is added, and numbers less than 10 0 will be added in the begin:

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = Date::O()->gmtime ;
  print "$sec,$min,$hour , $mday,$mon,$year , $wday,$yday,$isdst\n" ;

The output:

  21,05,00 , 21,03,2004 , 0,80,0

=head2 hms

Return the date in the format:

  HH:MM:SS

=head2 hour

The hour of the date.

=head2 hours_between

See I<days_between()>.

=head2 hours_from

See I<days_from()>.

=head2 hours_until

See I<days_until()>.

=head2 isdst

Is true if the specified time occurs during daylight savings time.

=head2 localtime

Same as gmtime(), but fot the local timezone.

See I<gmtime()>.

=head2 mdy

Return the date in the format:

  MM-DD-YYYY

=head2 min

The minutes of the date.

=head2 min_between

See I<days_between()>.

=head2 min_from

See I<days_from()>.

=head2 min_until

See I<days_until()>.

=head2 month

The month of the date.

=head2 months_between

See I<days_between()>.

=head2 months_from

See I<days_from()>.

=head2 months_until

See I<days_until()>.

=head2 sec

The seconds of the date.

=head2 secs_between

See I<days_between()>.

=head2 secs_from

See I<days_from()>.

=head2 secs_until

See I<days_until()>.

=head2 serial

Return a serial number that can be used to serialize this date object.

Useful to save in some database, and to realod it in the future.

The serial is an INTEGER based in the time() of the date and the zone in the end.
Soo, you can make searches in the DB by ranges of dates:

  my $d_init = Date::Object::new(2004 , 1 , 1) ;
  my $d_end = Date::Object::new(2004 , 2 , 1) ;
  
  ...
  
  my $init = $d_init->serial ;
  my $end = $d_end->serial ;
  
  "SELECT * FROM foo WHERE (date >= $init && date <= $end)"

To save it in the DB:

  my $d_serial = $d_init->serial ;
  
  ...
  
  "INSERT INTO foo(date) values($d_serial)"

To load:

  my $d_serial = "SELECT date FROM foo WHERE (id == 1)" ;
  
  my $date = Date::Object::new_serial($d_serial) ;

=head2 set (YEAR , MONTH , DAY , HOUR , MIN , SEC)

Set the date of the object. If some argument is B<undef>, the previous value of
the pbject will be used as default.

=head2 set_gmt

Set the date to the GMT timezone (0).

=head2 set_local

Set the date to the local timezone.

=head2 set_zone (ZONE)

Set the date to a ginve ZONE (timezone).

=head2 sub_day

See I<add_day()>.

=head2 sub_hour

See I<add_hour()>.

=head2 sub_min

See I<add_min()>.

=head2 sub_month

See I<add_month()>.

=head2 sub_sec

See I<add_sec()>.

=head2 sub_week

See I<add_week()>.

=head2 sub_year

See I<add_year()>.

=head2 time

The time of the date, with all the seconds from 1970-1-1 until the date,
same format of the core function time().

=head2 timelocal (YEAR , MONTH , DAY , HOUR , MIN , SEC , ZONE)

Create a time() integer with the given arguments.

=head2 wday

The week day of the date, in the range of 0..6, where 0 is Sunday.

=head2 weeks_between

See I<days_between()>.

=head2 weeks_from

See I<days_from()>.

=head2 weeks_until

See I<days_until()>.

=head2 yday

The year day of the date, in the range of 1..365 (or 1..366).

=head2 year

The year day of the date. Example: 2004

=head2 years_between

See I<days_between()>.

=head2 years_from

See I<days_from()>.

=head2 years_until

See I<days_until()>.

=head2 ymd

Return the date in the format:

  YYYY-MM-DD

=head2 zone

Return the zone of the date. The format is a floating number.
Soo, for the timzone -0300, the number is -3, and for -0330 is -3.3

=head2 zone_gmt

The timezone from the GMT as a full string.

Format:

  [+-]HHMM

Examples:

  -0300
  +0000

=head1 ALIASES

=head2 Date::O

Date::Object->new

=head2 Date::O_gmt

Date::Object->new_gmt

=head2 Date::O_local

Date::Object->new_local

=head2 Date::O_zone

Date::Object->new_zone

=head2 Date::check

Date::Object::check

=head2 Date::timelocal

Date::Object::timelocal

=head2 y

$date->year

=head2 mo

$date->month

=head2 d

$date->day

=head2 h

$date->hour

=head2 m

$date->min

=head2 s

$date->sec

=head2 z

$date->zone

=head1 Key Access

You also can access the date attributes using the object/hash keys:

Day:

  $date->{d}
  $date->{day}

Hour:

  $date->{h}
  $date->{hour}

Minutes:

  $date->{m}
  $date->{min}

Seconds:

  $date->{s}
  $date->{sec}

Month:

  $date->{mo}
  $date->{month}

Year:

  $date->{y}
  $date->{year}

Week day:

  $date->{wday}


Year day:

  $date->{yday}

Daylight savings

  $date->{isdst}

This keys are the same of a method call:

  $date->{date}
  $date->{date_zone}

  $date->{ymd}
  $date->{dmy}
  $date->{mdy}
  $date->{hms}

  $date->{serial}
  $date->{time}

  $date->{z}
  $date->{zone}
  $date->{zone_gmt}

=head1 SEE ALSO

L<DateTime>, L<Class::HPLOO>, L<HPL>.

The Perl DateTime Project: L<http://datetime.perl.org>

=head1 Class::HPLOO

This module was built with L<Class::HPLOO>, that make Classes definition easier
and smaller in Perl.

When sending patches or any type of code for this module take a look in
the sources in the .hploo files, and not in the .pm, since the .pm files
are generated automatically from the .hploo files.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


#############################################################################
## Name:        File.pm
## Purpose:     AutoSession::Driver::File
## Author:      Graciliano M. P.
## Modified by:
## Created:     20/5/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package AutoSession::Driver::File ;
our $VERSION = '1.0' ;

use strict qw(vars) ;

no warnings ;

use vars qw(@ISA) ;
@ISA = qw(AutoSession::Driver) ;

#################
# LOAD_STORABLE #
#################

sub load_storable {
  $INC{'Log/Agent.pm'} = '#ignore#' ;
  eval(q`use Storable qw(thaw freeze) ;`) ;
}

#######
# NEW #
#######

sub new {
  &load_storable() ;
  
  my $class = shift ;
  my ( %args ) = @_ ;

  my $this = {} ;
  
  bless($this,$class) ;
  
  $this->{id} = $args{id} ;
  $this->{idsize} = $args{idsize} || $AutoSession::DEF_IDSIZE ;

  if (defined $args{directory} && !defined $args{dir}) { $args{dir} = $args{directory} ;}
  if (defined $args{dir} && $args{dir} eq '') { $args{dir} = '.' ;}
  
  $this->{dir} = $args{dir} ;
  if ($this->{dir} eq '' || !-d $this->{dir}) { $this->{dir} = '/tmp' ;}
  
  $this->{dir} =~ s/[\\\/]+$//gs ;
  
  if ($this->{id} eq '') {
    $this->{id} = $this->new_id ;
    $this->{file} = $this->filename( $this->{id} ) ;
  }
  else {
    $this->{file} = $this->exist_id( $this->{id} ) || $this->filename( $this->{id} ) ;
  }
  
  $this->{expire} = $args{expire} || $AutoSession::DEF_EXPIRE ;
  
  if (!defined $args{expire}) { $this->{defexpire} = 1 ;}
  
  $this->{expire} = $this->parse_expire($this->{expire}) ;

  $this->{base64} = $args{base64} ;
  
  $this->{nocreate} = $args{nocreate} ;
  
  ## Create file if needed:
  $this->create if !$this->{nocreate} ;
  
  if (!-e $this->{file}) { return( undef ) ;}

  return( $this ) ;
}

##########
# CREATE #
##########

sub create {
  my $this = shift ;
  
  if ($this->{nocreate}) { return ;}
  
  if (!-e $this->{file}) {
    my $fh ;
    open ($fh,">$this->{file}") ; binmode($fh) ;
    close($fh) ;
    return( 1 ) ;
  }

  return( undef ) ;
}

##########
# DELETE #
##########

sub delete {
  my $this = shift ;
  
  if (-e $this->{file}) {
    my $v = unlink($this->{file}) ;
    $this->{closed} = 1 ;
    return( 1 ) if (!-e $this->{file}) ;
  }
  return( undef ) ;
}

########
# TIME #
########

sub time {
  my $this = shift ;
  my @stats = stat($this->{file}) ;
  if (! $stats[7] ) { return( 0 ) ;}
  return( $stats[9] ) ;
}

########
# LOAD #
########

sub load {
  my $this = shift ;
  
  if ($this->{closed}) { return( undef ) ;}
  
  if (!-s $this->{file}) {
    $this->{tree} = {} ;
    $this->{time} = 0 ;
  }
  else {
    my ($data,$header,$hsz,$fh) ;

    open ($fh,$this->{file}) ; binmode($fh) ;
    
    while($hsz !~ />/s) { my $n = read($fh , $hsz , 1 , length($hsz) ) ; last if !$n ;}
    $hsz =~ s/\D//gs ;
    
    read($fh , $header , $hsz) ;
    
    1 while( read($fh , $data , 1024*8 , length($data) ) )  ;
    
    close($fh) ;

    my %headers = $this->parse_header($header) ;    

    if ( $this->{defexpire} ) {
      $this->{expire} = $headers{expire} if $headers{expire} ;
    }
    
    if ( $headers{base64} ) {
      require AutoSession::Base64 ;
      $data = &AutoSession::Base64::decode_base64($data) ;
    }
  
    $this->{tree} = Storable::thaw($data) ;

    $this->{time} = $this->time ;
  }

  return( $this->{tree} ) ;
}

########
# SAVE #
########

sub save {
  my $this = shift ;
  
  if (!$this->{tree} || $this->{closed}) { return( undef ) ;}
  
  if ($this->{nocreate} && !-e $this->{file}) { return ;}
  
  if ( !ref($this->{tree}) ) { $this->{tree} = {} ;}

  my $data = Storable::freeze($this->{tree}) ;
  
  if ( $this->{base64} ) {
    require AutoSession::Base64 ;
    $data = &AutoSession::Base64::encode_base64($data) ;
  }
  
  my $fh ;
  open ($fh,">$this->{file}") ; binmode($fh) ;
  
  print $fh $this->header ;
  print $fh $data ;
  
  close($fh) ;
  
  return( 1 ) ;
}

#########
# LOCAL #
#########

sub local {
  my $this = shift ;
  return( $this->{file} ) ;
}

############
# EXIST_ID #
############

sub exist_id {
  my $this = shift ;
  my ( $id ) = @_ ;
  
  if ($id eq '') { $id = $this->{id} ;}
  
  my @file = $this->filename($id) ;
  
  foreach my $file ( @file ) {
    if (-e $file) { return( $file ) ;}
  }
  
  return( undef ) ;
}

#################
# CHECK_EXPIRED #
#################

sub check_expired {
  my $this = shift ;

  my $dh ; opendir($dh, $this->{dir}) ;

  while (my $filename = readdir $dh) {
    if ($filename =~ /^SESSION-(\w+)\.(?:tmp|hpl)$/s) {
      my $id = $1 ;
      my $file = "$this->{dir}/$filename" ;
      
      my @stats = stat($file) ;
      my $size = @stats[7] ;
      my $mdtime = @stats[9] ;      
      
      if ($id ne $this->{id} && ($size || ($size == 0 && (time-$mdtime) > 60*60*24) ) ) {
        my %headers = $this->get_file_header($file) ;
        my $idle = time - $headers{time} ;
        if ($idle >= $headers{expire}) { unlink($file) ;}
      }
    }
  }

  closedir($dh) ;
}

###################
# GET_FILE_HEADER #
###################

sub get_file_header {
  my $this = shift ;
  my $file = $_[0] || $this->{file} ;
  
  if (-s $file) {
    my $fh ; open ($fh,$file) ; binmode($fh) ;
    
    my $sz ;
    while($sz !~ />/s) {
      my $n = read($fh , $sz , 1 , length($sz) ) ;
      last if !$n ;
    }
    $sz =~ s/\D//gs ;
    
    my $data ;
    read($fh , $data , $sz) ;
    
    close($fh);
    
    return $this->parse_header($data) ;
  }

  return() ;
}

############
# FILENAME #
############

sub filename {
  my $this = shift ;
  my ( $id ) = @_ ;
  
  my $file = $this->{dir} . "/SESSION-$id" ;
  
  if ( wantarray ) {
    return( "$file.tmp" , "$file.hpl" ) ;
  }
  
  if ( $AutoSession::WITH_HPL ) { $file .= '.hpl' ;}
  else { $file .= '.tmp' ;}

  return( $file ) ;
}

##########
# HEADER #
##########

sub header {
  my $this = shift ;
  
  my $time = time() ;
  my $id = $this->{id} ;
  my $expire = $this->{expire} ;
  my $version = $AutoSession::VERSION ;
  my $base64 = $this->{base64} ;
  
  my $header = "AutoSession:$version:$time:$expire:$base64:$id" ;
  $header = length($header) . ">$header" ;
  
  if ( $AutoSession::WITH_HPL ) { $header = "#!hidden\n" . $header ;}
  
  return($header) ;
}

################
# PARSE_HEADER #
################

sub parse_header {
  my $this = shift ;
  my ( $header ) = @_ ;
  
  my ($module , $ver , $time , $expire , $base64 , $id) = split(":" , $header , 6) ;
  
  if ($module eq 'AutoSession' && $ver == $AutoSession::VERSION) {
    my %header = (
    time => $time ,
    expire => $expire ,
    id => $id ,
    base64 => $base64 ,
    ) ;

    return( %header ) ;
  }

  return() ;
}

#######
# END #
#######

1;



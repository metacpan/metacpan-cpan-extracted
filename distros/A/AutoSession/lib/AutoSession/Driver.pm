#############################################################################
## Name:        Driver.pm
## Purpose:     AutoSession::Driver
## Author:      Graciliano M. P.
## Modified by:
## Created:     20/5/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package AutoSession::Driver ;
our $VERSION = '1.0' ;

use strict qw(vars) ;

no warnings ;

  my %DRIVERS = (
  'file' => 'AutoSession::Driver::File' ,
  ) ;
  
  my @LYB = qw(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) ;

#######
# NEW #
#######

sub new {
  my $class = shift ;
  my ( %args ) = @_ ;
  
  my $type = "\L$args{driver}\E" ;
  $type =~ s/\s//gs ;
  
  my $module = $DRIVERS{$type} ;
  
  eval(qq`use $module ;`) ;
  if ($@) { die $@ ;}
  
  my $this = $module->new(%args) ;
  if (!$this) { return undef ;}
  
  $this->{type} = $type ;

  return( $this ) ;
}

########
# OPEN #
########

sub open {
  my $this = shift ;
  
  delete $this->{closed} ;
  $this->refresh ;
  
  return( 1 ) ;
}

#########
# CLOSE #
#########

sub close {
  my $this = shift ;
  $this->save ;
  
  $this->{closed} = 1 ;
  
  delete $this->{tree} ;
  delete $this->{time} ;
  
  return( 1 ) ;
}

###########
# REFRESH #
###########

sub refresh {
  my $this = shift ;
  
  if ( $this->{closed} ) { return( undef ) ;}

  if ( !$this->{tree} || $this->time > $this->{time} ) {
    $this->load ;
    return( 1 ) ;
  }
  
  return( undef ) ;
}

#########
# CLEAR #
#########

sub clear {
  my $this = shift ;
  $this->{tree} = {} ;
  $this->save ;
  return( 1 ) ;
}

sub clean { &clear ;}

##########
# NEW_ID #
##########

sub new_id {
  my $this = shift ;
  
  my $id = $this->random_id() ;
  
  while( $this->exist_id($id) ) { $id = $this->random_id() ;}
  
  return( $id ) ;
}

#############
# RANDOM_ID #
#############

sub random_id {
  my $this = shift ;
  my $leng = $this->{idsize} || $_[0] || $AutoSession::DEF_IDSIZE ;
  
  my $id ;
  
  while( length($id) < $leng ) {
    $id .= @LYB[ rand(@LYB) ] ;
  }
  
  return( $id ) ;
}

################
# PARSE_EXPIRE #
################

sub parse_expire {
  my $this = shift ;
  my $expire = $_[0] || $this->{expire} ;
  $expire =~ s/[\W_]//gs ;
      
  if ($expire !~ /^\d+$/) {
    if    ($expire =~ /^(\d+)s/)  { $expire = $1 ;}
    elsif ($expire =~ /^(\d+)m/)  { $expire = $1 * 60 ;}
    elsif ($expire =~ /^(\d+)h/)  { $expire = $1 * 60*60 ;}
    elsif ($expire =~ /^(\d+)d/)  { $expire = $1 * 60*60*24 ;}
    elsif ($expire =~ /^(\d+)w/)  { $expire = $1 * 60*60*24*7 ;}
    elsif ($expire =~ /^(\d+)mo/) { $expire = $1 * 60*60*24*30 ;}
    elsif ($expire =~ /^(\d+)y/)  { $expire = $1 * 60*60*24*365 ;}
  }
  
  return( $expire ) ;
}

###########
# DESTROY #
###########

sub DESTROY {
  my $this = shift ;
  $this->save ;
}

#######
# END #
#######

1;



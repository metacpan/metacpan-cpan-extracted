#############################################################################
## Name:        TieHandle.pm
## Purpose:     AutoSession::TieHandle
## Author:      Graciliano M. P.
## Modified by:
## Created:     20/5/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package AutoSession::TieHandle ;
our $VERSION = '0.01' ;

use strict qw(vars) ;
no warnings ;

sub TIEHASH { #print STDOUT "TIEHASH>> @_\n" ;
  my $class = shift;
  return bless({ driver => $_[0] }, $class) ;
}

sub FETCH { #print STDOUT "FETCH>> @_\n" ;
  my $this = shift ;
  my $key = shift ;
  
  delete($this->{KEYS}) if $this->{driver}->refresh ;
  
  return( $this->{driver}{tree}{$key} ) ;
}  

sub STORE { #print STDOUT "STORE>> @_\n" ;
  my $this = shift ;
  my $key = shift ;

  my $notdef ;
  if (! defined $this->{driver}{tree}{$key}) { $notdef = 1 ;}

  $this->{driver}{tree}{$key} = $_[0] ;
  $this->{driver}->save ;
  
  delete $this->{KEYS} if !$notdef ;
  
  return $_[0] ;
}
 
sub DELETE   { #print STDOUT "DELETE>> @_\n" ;
  my $this = shift ;
  my $key = shift ;
  
  my $ret ;
  
  if ( defined $this->{driver}{tree}{$key} ) {
    $ret = delete $this->{driver}{tree}{$key} ;
    $this->{driver}->save ;
    delete $this->{KEYS} ;
  }
  
  return $ret ;
}

sub EXISTS   { #print STDOUT "EXISTS>> @_\n" ;
  my $this = shift ;
  my $key = shift ;
  
  delete($this->{KEYS}) if $this->{driver}->refresh ;
  
  if ( defined $this->{driver}{tree}{$key} ) { return( 1 ) ;}
  
  return undef ;
}

sub FIRSTKEY { #my @call = caller ; print STDOUT "FIRSTKEY>> $_[0]->{TYPE} >> @call\n" ;
  my $this = shift ;
  
  delete($this->{KEYS}) if $this->{driver}->refresh ;
  
  if (! $this->{KEYS} ) {
    my %keys = map { $_ => 1 } ( keys %{$this->{driver}{tree}} ) ;
    $this->{KEYS} = [sort keys %keys] ;
  }
  
  return @{$this->{KEYS}}[0] ;
}

sub NEXTKEY  { #print STDOUT "NEXTKEY>> @_\n" ;
  my $this = shift ;
  my $keylast = shift ;
  
  delete($this->{KEYS}) if $this->{driver}->refresh ;
  
  if (! $this->{KEYS} ) {
    my %keys = map { $_ => 1 } ( keys %{$this->{driver}{tree}} ) ;
    $this->{KEYS} = [sort keys %keys] ;
  }
  
  my $ret_next ;
  foreach my $keys_i ( @{ $this->{KEYS} } ) {
    #print STDOUT "  >> $keys_i ** $keylast\n" ;
    if ($ret_next) { return($keys_i) ;}
    if ($keys_i eq $keylast || ! defined $keylast) { $ret_next = 1 ;}
  }

  return undef ;
}

sub CLEAR { #print STDOUT "CLEAR>> @_\n" ;
  my $this = shift ;
  $this->{driver}{tree} = {} ;
  $this->{driver}->save ;
  delete $this->{KEYS} ;
  return ;
}

sub UNTIE {}
sub DESTROY {}

#######
# END #
#######

1;



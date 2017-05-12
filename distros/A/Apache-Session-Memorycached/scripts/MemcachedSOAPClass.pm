#!/usr/bin/perl
package MemcachedSOAPClass;
use Apache::Session::Memorycached;
#  This module comes with lemonldap frameworks project 
#use Data::Dumper;
use strict;

# IP adress and port of apache server  
our $machine;


#/////////////////////////////////////////////////////////////////////////////////////////////

sub status {
  my $resp = '...... MEMCACHED SOAP OK ......';
  return $resp;
}

#/////////////////////////////////////////////////////////////////////////////////////////////

sub getSession { 
  my $nil    = shift;
  my $id_ses = shift;
  my %Machine = ( 'servers' => [$machine] );
  my %session;

  tie( %session, 'Apache::Session::Memorycached', $id_ses, \%Machine );

  my %H = %session;
  
  untie( %session );

  return \%H;
}


#/////////////////////////////////////////////////////////////////////////////////////////////

sub setSession {
  my $nil = shift; 
  my %session_tmp =  @_ ; 
  my %session;
  my %Machine = ( 'servers' => [$machine] );

  tie( %session, 'Apache::Session::Memorycached', undef, \%Machine );

  for (keys %session_tmp) {
    $session{$_} = $session_tmp{$_} ;
  }
 
  my $numses = $session{ '_session_id' };

  untie( %session );

  return $numses;
}

#///////////////////////////////////////////////////////////////////////////////////////////// 

1;

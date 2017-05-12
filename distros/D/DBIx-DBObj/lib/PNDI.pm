package PNDI; 

# Copyright (C) 2003 Matt Knopp <mhat@cpan.org>
# This library is free software released under the GNU Lesser General Public
# License, Version 2.1.  Please read the important licensing and disclaimer
# information included in the LICENSE file included with this distribution.

use strict; 
use Error qw (:try);
use PNDI::Exception; 

$PNDI::REQUEST = 0; 
$PNDI::SERVICE = 1; 
$PNDI::SESSION = 2; 

sub new { 
  my ($class)  = @_; 
  $Global::PNDI = bless({}, $class) if (!defined($Global::PNDI)); 
  return($Global::PNDI); 
} 

sub register { 
  my ($class, %args) = @_;
  my $pndi_object     = new PNDI();  
  my $pndi_name       = $args{name}; 
  my $pndi_value      = $args{value}; 
  my $pndi_scope      = $args{scope} || $PNDI::REQUEST; 

  if (exists($pndi_object->{$pndi_name})) { 
    throw PNDI::NameCollisionException("PNDI: $pndi_name already in use."); 
  } 
  else {
    $pndi_object->{$pndi_name}{scope} = $pndi_scope;
    $pndi_object->{$pndi_name}{value} = $pndi_value; 
  }
  return(1); 
}

sub update { 
  my ($class, %args) = @_; 
  my $pndi_object    = new PNDI();  
  my $pndi_name      = $args{name}; 
  my $pndi_value     = $args{value}; 

  $pndi_object->lookup(name => $pndi_name); 
  $pndi_object->{$pndi_name}{value} = $pndi_value;
}

sub release { 
  my ($class, %args) = @_; 
  my $pndi_object     = new PNDI();  
  my $pndi_name       = $args{name}; 
  delete($pndi_object->{$pndi_name}) if (exists($pndi_object->{$pndi_name}));
  return(1); 
}

sub lookup {
  my ($class, %args) = @_; 
  my $pndi_object     = new PNDI();  
  my $pndi_name       = $args{name}; 
  
  if(!exists($pndi_object->{$pndi_name})) { 
    throw PNDI::NoSuchNameException(
      "PNDI: No entry matching name(". $args{name}. ").");
  } 

  return($pndi_object->{$pndi_name}{value}); 
}

sub cleanup { 
  my ($class)     = @_; 
  my $pndi_object = new PNDI(); 

  foreach my $key ( keys %{ $pndi_object } ) {
    if ($pndi_object->{$key}{scope} == $PNDI::REQUEST) {
      delete($pndi_object->{$key}); 
    }
  }
} 

##
1;

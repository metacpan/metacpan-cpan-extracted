# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

##################################
package DBR::Admin::Exception;

use strict;
use Error;
use Curses::UI;

use base 'Error';



sub new {

  my $package = shift;
  my %_in = @_;

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1;	# Enables storing of stacktrace

  $_{message} ||= 'No message specified';

  my $self = $package->SUPER::new(-text => $_in{message});

  $self->{message} = $_in{message};
  $self->{root_window} = $_in{root_window};

  return $self;
}

sub get_message {

  my $self = shift;
  return $self->{message};
}

sub stringify {

  my $self = shift;
  if ($self->{root_window}) {
      $self->{root_window}->error($self->{message});
      print STDERR $self->{-stacktrace};
    #   $self->{root_window}->error($self->{-stringify});
  }
  else {
      return $self->{-stacktrace};
  }

}




1;

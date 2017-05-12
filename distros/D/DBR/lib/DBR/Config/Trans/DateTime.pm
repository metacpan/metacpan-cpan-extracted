# the contents of this file are Copyright (c) 2009-2011 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::Trans::DateTime;
use strict;

use base 'DBR::Config::Trans';
use DBR::Config::Trans::UnixTime;
use POSIX qw(strftime);

sub init {
      my $self = shift;
      $self->{tzref} = $self->{session}->timezone_ref or return $self->_error('failed to get timezone ref');
      return 1;
}

sub forward{
      my $self  = shift;
      my $value = shift;
      
      my $unixtime = Time::ParseDate::parsedate($value);
      return bless( [$unixtime,$self->{tzref}] , 'DBR::_UXTIME');
}

sub backward{
    my $self = shift;
    my $value = shift;

    return undef unless defined($value) && length($value);

    my $unixtime;
  
    if(ref($value) eq 'DBR::_UXTIME'){ #ahh... I know what this is
        $unixtime = $value->unixtime;

    }elsif($value =~ /^\d+$/){         # smells like a unixtime
        $unixtime = $value;
        
    }else{
        $unixtime = Time::ParseDate::parsedate($value);

        unless($unixtime){
          $self->_error("Invalid time '$value'");
          return ();
        }

    }
    
    return strftime ( "%D %H:%M:%S UTC", gmtime( $unixtime ) );

}

1;
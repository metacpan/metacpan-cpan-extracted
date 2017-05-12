# the contents of this file are Copyright (c) 2009-2011 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::Trans::UnixTime;

use strict;
use base 'DBR::Config::Trans';
use strict;
#use Date::Parse ();
use Time::ParseDate ();
use POSIX qw(strftime tzset);

sub new { die "Should not get here" }

sub init {
      my $self = shift;
      $self->{tzref} = $self->{session}->timezone_ref or return $self->_error('failed to get timezone ref');
      return 1;
}

sub forward{
      my $self = shift;
      my $unixtime = shift;
      return bless( [$unixtime,$self->{tzref}] , 'DBR::_UXTIME');
}

sub backward{
      my $self = shift;
      my $value = shift;

      return undef unless defined($value) && length($value);

      if(ref($value) eq 'DBR::_UXTIME'){ #ahh... I know what this is
	    return $value->unixtime;

      }elsif($value =~ /^\d+$/){         # smells like a unixtime
	    return $value;

      }else{
	    local($ENV{TZ}) = ${$self->{tzref}}; tzset(); # Date::Parse doesn't accept timezone in the way we want to specify it. Lame.

	    # Ok... so Date::Parse is kinda cool and all, except for the fact that it breaks horribly on
	    # Non DST-specific timezone prefixes, like PT, MT, CT, ET. Treats them all like GMT.
	    # Even strptime freaks out on it. What gives Graham? 
	    # P.S. glass house here throwing stones, but try adding a comment or two.

	    #my $uxtime = Date::Parse::str2time($value);
	    my $uxtime = Time::ParseDate::parsedate($value);

	    unless($uxtime){
		  $self->_error("Invalid time '$value'");
		  return ();
	    }

	    return $uxtime;
      }

}

package DBR::_UXTIME;

use strict;
use POSIX qw(strftime tzset);
use Carp;
use overload 
#values
'""' => sub { $_[0]->datetime },
'0+' => sub { $_[0]->unixtime },

#operators
 '+'  => sub { $_[0]->_manip( $_[1], 'add' )      || croak "Invalid date manipulation '$_[1]'" },
 '-'  => sub { $_[0]->_manip( $_[1], 'subtract' ) || croak "Invalid date manipulation '$_[1]'" },

# Some ideas:
# 

'fallback' => 1,
#'nomethod' => sub {croak "UnixTime object: Invalid operation '$_[3]' The ways in which you can use UnixTime objects is restricted"}
;

*TO_JSON = \&datetime;

sub unixtime { $_[0][0] || '' };

# Using $ENV{TZ} and the posix functions is ugly... and about 60x faster than the alternative in benchmarks

sub date  {
      return '' unless defined($_[0][0]);
      local($ENV{TZ}) = ${$_[0][1]}; tzset();
      return strftime ("%D", localtime($_[0][0]));
}

sub time  {
      return '' unless defined($_[0][0]);
      local($ENV{TZ}) = ${$_[0][1]}; tzset();
      return strftime ("%H:%M:%S %Z", localtime($_[0][0]));
}

sub datetime  {
      return '' unless defined($_[0][0]);
      local($ENV{TZ}) = ${$_[0][1]}; tzset();
      return strftime ("%D %H:%M:%S %Z", localtime($_[0][0]));
}

sub fancytime  {
      return '' unless defined($_[0][0]);
      local($ENV{TZ}) = ${$_[0][1]}; tzset();
      return strftime ("%I:%M:%S %p %Z", localtime($_[0][0]));
}

sub fancydatetime  {
      return '' unless defined($_[0][0]);
      local($ENV{TZ}) = ${$_[0][1]}; tzset();
      my $v = strftime ("%A %B %e %l:%M%p %Y", localtime($_[0][0]));
      $v =~ s/\s+/ /g;
      $v =~ s/(AM|PM)/lc($1)/e;
      return $v;
}

sub fancydate  {
      return '' unless defined($_[0][0]);
      local($ENV{TZ}) = ${$_[0][1]}; tzset();
      return strftime ("%A %B %e, %Y", localtime($_[0][0]));
}

#format takes a strftime format string as an argument
sub format  {
      return '' unless defined($_[0][0]) && length($_[1]);
      local($ENV{TZ}) = ${$_[0][1]}; tzset();
      return strftime ($_[1], localtime($_[0][0]));
}

sub midnight{
      my $self = shift;

      return '' unless defined($self->[0]);
      local($ENV{TZ}) = ${$self->[1]}; tzset();
      my ($sec,$min,$hour) = localtime($self->[0]);

      my $midnight = $self->[0] - ($sec + ($min * 60) + ($hour * 3600) ); # rewind!
      return $self->new($midnight);

}

sub endofday{
      my $self = shift;

      return '' unless defined($self->[0]);

      local($ENV{TZ}) = ${$self->[1]}; tzset();
      my ($sec,$min,$hour) = localtime($self->[0]);

      my $endofday = $self->[0] + 86399 - ($sec + ($min * 60) + ($hour * 3600) ) ; # rewind!
      return $self->new($endofday);
}

sub _manip{
      my $self = shift;
      my $manip = shift;
      my $mode = shift;

      $manip =~ s/^\s+|\s+$//g;
      return undef unless $manip;

      my ($number, $unit) = $manip =~ /^(\d+)\s+([A-Za-z]+?)s?$/;
      $unit = lc($unit);

      my $unixtime = $self->unixtime;

      # This isn't actually the correct way to do this, on account of DST nd leap year and so on,
      # just a proof of concept. Should probably just farm it out to Date::Manip

      my $diff;
      if($unit eq 'second'){
	    $diff = $number
      }elsif($unit eq 'minute'){
	    $diff = $number * 60;
      }elsif($unit eq 'hour'){
	    $diff = $number * 3600;
      }elsif($unit eq 'day'){
	    $diff = $number * 86400;
      }elsif($unit eq 'year'){
	    $diff = $number * 31536000;
      }else{
	    return undef;
      }

      if ($mode eq 'add'){
	    return $self->new( $unixtime + $diff );
      }elsif($mode eq 'subtract'){
	    return $self->new( $unixtime - $diff );
      }

      return undef;

}

#              uxtime , tzref
sub new{ bless([ $_[1], $_[0][1] ],'DBR::_UXTIME') }

1;

# $Id: Log.pm 3 2009-03-03 19:13:39Z jo $
# Cindy::Profiling - (XPath)-Profiling for Cindy 
#
# Copyright (c) 2008 Joachim Zobel <jz-2008@heute-morgen.de>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#


package Cindy::Profile;

use strict;
use warnings;

use Time::HiRes('gettimeofday', 'tv_interval');

use Cindy::Log;

#
# Constructor
#
sub new ($)
{
  my $class = shift;
  return bless({}, $class);  
}

sub before() {
  my @rtn = gettimeofday();
  return \@rtn;  
}

sub after($$$)
{
  my ($self, $r_before, $name) = @_;
  my @now = gettimeofday();
  # Time difference
  my $delta = tv_interval($r_before, \@now);

  if (not exists($self->{$name})) {
    # An array [count, sum] is initialised
    $self->{$name} = [0, 0];
  }
  $self->{$name}[0]++;
  $self->{$name}[1] += $delta;  
}  

sub DESTROY($) {
  my ($self) = shift;

  # This is needed by apache (that loads the 
  # module at configuration time without a request).
  return if not (keys(%{$self}));

  INFO "Outputting profile:";
  my @top = sort {$self->{$b}[1] <=> $self->{$a}[1];}  
              keys(%{$self});
  foreach my $name (@top[0 .. 9]) {
    if (defined($name)) {
      my $cnt = $self->{$name}[0];
      my $tm = $self->{$name}[1];
      INFO "$name: $cnt calls, $tm seconds";
    }
  }
}

1;


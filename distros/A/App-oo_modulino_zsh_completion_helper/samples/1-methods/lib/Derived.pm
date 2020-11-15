#!/usr/bin/env perl
package
  Derived;

use strict;
use warnings;

use File::AddInc;
use parent qw(Greetings_oo_modulino);

unless (caller) {
  my $self = __PACKAGE__->new(name => "world");

  my $cmd = shift @ARGV
    or die "Usage: $0 COMMAND ARGS...\n";

  if (my $sub = $self->can("cmd_$cmd")) {
    $sub->($self, @ARGV)
  }
  elsif ($sub = $self->can("$cmd")) {
    print $self->$cmd(@ARGV), "\n";
  }
  else {
    die "Unknown command: $cmd\n";
  }
}

sub good_morning { my $self = shift; join(" ", "Good morning" => $self->{name}, @_)}

sub good_afternoon { my $self = shift; join(" ", "Good afternoon" => $self->{name}, @_)}

sub good_evening { my $self = shift; join(" ", "Good evening" => $self->{name}, @_)}

1;

#!/usr/bin/env perl
package
  Greetings_oo_modulino;
use strict;
use warnings;

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

sub new  { my $class = shift; bless +{@_}, $class }

sub hello { my $self = shift; join " ", "Hello", $self->{name} }

sub hi { my $self = shift; join " ", "Hi", $self->{name} }

1;

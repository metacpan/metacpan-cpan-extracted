#!/usr/bin/env perl
package
  Greetings_oo_modulino_with_fields;
use strict;
use warnings;

use fields qw/name no-thanx x y/;
sub MY () {__PACKAGE__}

unless (caller) {
  my $self = MY->new(name => 'world', MY->_parse_posix_opts(\@ARGV));

  my $cmd = shift
    or die "Usage: $0 COMMAND ARGS...\n";

  print $self->$cmd(@ARGV), "\n";
}

sub _parse_posix_opts {
  my ($class, $list) = @_;
  my @opts;
  while (@$list and $list->[0] =~ /^--(?:(\w+)(?:=(.*))?)?\z/s) {
    shift @$list;
    last unless defined $1;
    push @opts, $1, $2 // 1;
  }
  @opts;
}

sub new  { my MY $self = fields::new(shift); %$self = @_; $self }

sub hello { my MY $self = shift; join " ", "Hello", $self->{name} }

sub goodnight { my MY $self = shift; join(" ", "Good night" => $self->{name}, @_)}

1;

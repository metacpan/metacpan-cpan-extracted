package Data::Object::Code::Func;

use 5.014;

use strict;
use warnings;

use Data::Object::Class;

with 'Data::Object::Role::Throwable';

our $VERSION = '2.05'; # VERSION

# BUILD

sub BUILDARGS {
  my ($class, @args) = @_;

  return {@args} if ! ref $args[0];

  return $class->configure(@args);
}

# METHODS

sub execute {
  return;
}

sub configure {
  my ($class, @args) = @_;

  my $data = {};

  for my $expr ($class->mapping) {
    last if !@args;

    my $regx = qr/^(\W*)(\w+)$/;

    my ($type, $attr) = $expr =~ $regx;

    if (!$type) {
      $data->{$attr} = shift(@args);
    } elsif ($type eq '@') {
      $data->{$attr} = [@args];
      last;
    } elsif ($type eq '%') {
      $data->{$attr} = {@args};
      last;
    }
  }

  return $data;
}

sub mapping {
  return (); # noop
}

sub recurse {
  my ($self, @args) = @_;

  my $class = ref($self) || $self;

  return $class->new(@args)->execute;
}

sub unpack {
  my ($self) = @_;

  my @args;

  for my $expr ($self->mapping) {
    my $regx = qr/^(\W*)(\w+)$/;

    my ($type, $attr) = $expr =~ $regx;

    if (!$type) {
      push @args, $self->$attr;
    } elsif ($type eq '@') {
      push @args, @{$self->$attr} if $self->$attr;
      last;
    } elsif ($type eq '%') {
      push @args, @{$self->$attr} if $self->$attr;
      last;
    }
  }

  return @args;
}

1;

package DBIO::Replicated::Backend;
# ABSTRACT: Wrapper base class for replicated backends

use strict;
use warnings;

use base 'DBIO::Base';
use Scalar::Util 'weaken';
use namespace::clean;

our $AUTOLOAD;

__PACKAGE__->mk_group_accessors(simple => qw/
  storage
  dsn
  id
  active
  kind
/);

sub new {
  my ($class, %args) = @_;

  my $self = bless {
    storage => $args{storage},
    dsn     => $args{dsn},
    id      => $args{id},
    active  => exists $args{active} ? $args{active} : 1,
    kind    => $args{kind} || 'backend',
  }, $class;

  $self->master($args{master}) if exists $args{master};

  return $self;
}

sub master {
  my $self = shift;
  if (@_) {
    $self->{master} = $_[0];
    weaken $self->{master} if ref $self->{master};
  }
  return $self->{master};
}

sub install_debug_proxy {
  my ($self, $target) = @_;
  require DBIO::Replicated::DebugProxy;

  if (eval { $target->isa('DBIO::Replicated::DebugProxy') }) {
    $target = $target->target;
  }

  $self->storage->debugobj(
    DBIO::Replicated::DebugProxy->new(
      backend => $self,
      target  => $target,
    )
  );
}

sub debugobj {
  my $self = shift;
  return $self->storage->debugobj(@_) if @_;
  return $self->storage->debugobj;
}

sub AUTOLOAD {
  my $self = shift;
  my ($method) = $AUTOLOAD =~ /::([^:]+)\z/;
  return if $method eq 'DESTROY';

  my $storage = $self->storage
    or $self->throw_exception("No wrapped storage available for $method()");

  my $code = $storage->can($method)
    or $self->throw_exception(ref($storage) . " does not implement $method()");

  unshift @_, $storage;
  goto &$code;
}

sub DESTROY { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated::Backend - Wrapper base class for replicated backends

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

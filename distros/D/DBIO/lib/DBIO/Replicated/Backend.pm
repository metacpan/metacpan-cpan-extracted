package DBIO::Replicated::Backend;
# ABSTRACT: Wrapper base class for replicated backends

use strict;
use warnings;

our $VERSION = '0.900004';

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

version 0.900004

=head1 DESCRIPTION

Wraps one real storage of a replicated setup (the master or a replicant) and
carries its identity: C<storage> (the wrapped storage), C<dsn>, C<id>,
C<active> and C<kind> are plain read/write accessors. Every other method
call is forwarded to the wrapped storage through C<AUTOLOAD>; it throws if
there is no wrapped storage or the storage does not implement the method.

=head1 METHODS

=head2 new

  my $backend = DBIO::Replicated::Backend->new(
    storage => $storage,
    dsn     => $dsn,
    id      => 'replica-1',
    active  => 1,          # default 1
    kind    => 'backend',  # default 'backend'
    master  => $master,    # optional
  );

=head2 master

Getter/setter for the master backend this one belongs to. The reference is
held weakly.

=head2 install_debug_proxy

  $backend->install_debug_proxy($debugobj);

Sets the wrapped storage's C<debugobj> to a L<DBIO::Replicated::DebugProxy>
around C<$debugobj> (unwrapping it first if it is already such a proxy), so
the trace output of this backend names it.

=head2 debugobj

Getter/setter forwarded to the wrapped storage's C<debugobj>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

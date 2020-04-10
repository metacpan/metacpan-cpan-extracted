package Async::Methods;

our $VERSION = '0.000001'; # 0.0.1

$VERSION = eval $VERSION;

use strict;
use warnings;
use Carp ();
use Hash::Util qw(fieldhash);

fieldhash my %start;
fieldhash my %then;
fieldhash my %else;

package start;

sub AUTOLOAD {
  my ($self, @args) = @_;
  our $AUTOLOAD;
  Carp::croak "Can't call $AUTOLOAD on class $self" unless ref($self);
  my ($method) = $AUTOLOAD =~ /^then::(.+)$/;
  $method = shift @args if $method eq '_';
  my $f = $self->$method(@args);
  $start{$f} = $self;
  return $f;
}

package then;

sub AUTOLOAD {
  my ($self, @args) = @_;
  our $AUTOLOAD;
  Carp::croak "Can't call $AUTOLOAD on class $self" unless ref($self);
  my ($method) = $AUTOLOAD =~ /^then::(.+)$/;
  $method = shift @args if $method eq '_';
  my $f_type = ref($self);
  my $f; $f = $self->then(
    sub { my ($obj) = @_; $obj->$method(@args) }.
    sub {
      if (my $else = $else{$f}) {
        $else->(@_)
      } else {
        $f_type->AWAIT_FAIL(@_)
      }
    },
  );
  $then{$f} = $start{$f} = $start{$self};
  return $f;
}

package else;

sub AUTOLOAD {
  my ($self, @args) = @_;
  our $AUTOLOAD;
  Carp::croak "Can't call $AUTOLOAD on class $self" unless ref($self);
  my ($method) = $AUTOLOAD =~ /^else::(.+)$/;
  $method = shift @args if $method eq '_';
  Carp::croak "Can only call else on result of then"
    unless my $start_obj = $then{$self};
  $else{$self} = sub { $start_obj->$method(@_) };
  return $self;
}

package catch;

sub AUTOLOAD {
  my ($self, @args) = @_;
  our $AUTOLOAD;
  Carp::croak "Can't call $AUTOLOAD on class $self" unless ref($self);
  my ($method) = $AUTOLOAD =~ /^catch::(.+)$/;
  $method = shift @args if $method eq '_';
  Carp::croak "Can only call await on start:: or then:: object"
    unless my $start_obj = $start{$self};
  $self->catch(sub { $start_obj->$method(@_) });
}

package await;

sub this {
  my ($self) = @_;
  if ($self->isa('Mojo::Promise') and !$self->can('get')) {
    require Mojo::Promise::Role::Get;
    $self = $self->with_roles('+Get');
  }
  return $self->get;
}

sub AUTOLOAD {
  my ($self, @args) = @_;
  our $AUTOLOAD;
  Carp::croak "Can't call $AUTOLOAD on class $self" unless ref($self);
  my ($method) = $AUTOLOAD =~ /^await::(.+)$/;
  $method = shift @args if $method eq '_';
  my $f = $self->${\"then::${method}"}(@args);
  $f->await::this;
}

1;

=head1 NAME

Async::Methods - Helpers for async method work

=head1 SYNOPSIS

Sorry, this is not documented yet and is just a demonstration of the
relevant ideas. Please don't try and use it yet.

=head1 DESCRIPTION

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2020 the Async::Methods L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

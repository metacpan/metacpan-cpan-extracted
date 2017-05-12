package Class::Persist::Base;
use warnings;
use strict;

use EO;
use EO::Class;
use EO::System;

use base qw( EO );
our $VERSION = '0.01';

exception Class::Persist::Error                    extends => 'EO::Error';
exception Class::Persist::Error::New               extends => 'EO::Error::New';
exception Class::Persist::Error::TimeOut           extends => 'Class::Persist::Error';
exception Class::Persist::Error::InvalidParameters extends => 'Class::Persist::Error';
exception Class::Persist::Error::Multiple          extends => 'Class::Persist::Error';

=head2 oid

A UUID that uniquely identifies this object in the world. It would be bad to
change this unless you know what you are doing. It's probably bad even if you
do know what you're doing.

=cut

sub oid {
  my $self = shift;
  return $self->set($Class::Persist::ID_FIELD, shift) if @_;
  $self->set( $Class::Persist::ID_FIELD, $self->generate_oid )
    unless $self->get( $Class::Persist::ID_FIELD );
  return $self->get( $Class::Persist::ID_FIELD );
}

*set_oid = \&oid;

=head2 mk_accessors

=cut

sub mk_accessors {
  my $class = shift;
  no strict 'refs';
  for my $method (@_) {
    #next if $class->can($method); # don't overwrite existing methods
    *{ $class."::".$method } = $class->_accessor($method);
  }
}

sub _accessor {
  my ($class, $field) = @_;
  return sub {
    my $self = shift;
    return $self->set($field, @_) if @_;
    return $self->get($field);
  }
}

=head2 set( column => value, [ column => value ... ] )

=cut

sub set {
  my $self = shift;
  while (@_) {
    my $col = shift;
    my $value = shift;
    $self->{$col} = $value;
  }
  return $self;
}

=head2 get( column )

=cut

sub get {
  my $self = shift;
  my $col = shift;
  die "did you mean 'set'?" if @_;
  return $self->{$col};
}

sub _duplicate_from {
  my $self = shift;
  my $source = shift;
  %$self = ();
  $self->{$_} = $source->{$_}
    for (keys(%{ $source }));
  return $self;
}


sub init {
  my $self = shift;
  my $params;
  if (ref( $_[0] )) {
    $params = $_[0];
  } else {
    throw Class::Persist::Error::InvalidParameters text => "Bad number of parameters"
      unless (scalar(@_) % 2 == 0);
    $params = { @_ };
  }
  if ($params) {
    my $errors = {};
    foreach my $method (keys %$params) {
      if ( my $can = $self->can($method) ) {
        next unless defined( $params->{$method} );

        my $result = eval { $can->($self, $params->{$method}) };
        if (UNIVERSAL::isa($@, "Class::Persist::Error::InvalidParameters")) {
          $errors->{$method} = $@->text;
        } elsif ($@) { die $@; }

        if (!$result) {
          $errors->{$method} ||= "Method $method didn't return a true value";
        }

      } else {
        $errors->{$method} = "Method $method doesn't exist";
      }
    }
    if (%$errors) {
      throw Class::Persist::Error::Multiple
        text => "Error calling init for ".ref($self)." - ".Dumper($errors),
        errors => $errors;
    }
  }

  $self->SUPER::init(@_);
}

sub _populate {
  my $self = shift;
  my $cols = shift;
  for (keys(%$cols)) {
    $self->set($_, $cols->{$_});
  }
  return $self;
}

sub loadModule {
  my ($self, $class) = @_;
  EO::Class->new_with_classname( $class )->load;
}

sub emit {
  my $class = shift;
  my $msg = shift;
  use Data::Dumper;
  $msg = Dumper($msg) if ref($msg);
  no warnings qw(uninitialized);
  EO::System->new->error->print(
    '['.[caller]->[0].'/'.[caller]->[2].'] '.
    '['. scalar(localtime()) . '] '.
    $msg . "\n"
  );
  return;
}


sub record {
  my $self      = shift;
  my $exception = shift;
  my %param = $_[1] ? @_ : ( text => $_[0] );

  my $error = "[$exception] ";
  $error .= join(' / ', map { "$_ => ".($param{$_}||'') } keys(%param) );
  #$self->emit($error);
  $exception->record(%param);
  return;
}

sub throw {
  my $self = shift;
  my $exception = shift;
  my %param = @_;

  $self->emit($param{text});
  $exception->throw(%param);
  return;
}


1;

__END__

=head1 NAME

Class::Persist::Base - Base class for Class::Persist

=head1 DESCRIPTION

This is a useful thing to inherit from - it gives you accessors, a new /
init method that will initialise the object, emit/throw/record methods
for throwing errors, and does the right thing when accessors don't
return true values.

=head1 METHODS

=head2 new( key => value, key => value, ... )

new creates and returns a new object. Any parameters are passed to the init
method.

=head2 init

the init method is called by new() after it creates an object. The init
assumes the passed parameters are a hash, takes the keys, and
calls the methods with the names of the keys, passing the values. The
common use for this is to pass initial values for all the accessor methods
when calling new():

  my $object = Your::Subclass->new( foo => 'bar' );

override the init method in your subclass if you need to perform setup, but
remember to call the init method of the superclass first, and return undef if
it fails:

  sub init {
    my $self = shift;
    $self->SUPER::init(@_) or return;

    ...
    return 1;
  }

EO will complain if the init call is not passed up to the superclass.

Return 1 to indicate your init was successful, and the new method will return
the object. Returning a false value will cause new() to fail.

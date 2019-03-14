package Data::Object::Path;

use Path::Tiny ();

use Data::Object::Class;

with 'Data::Object::Role::Proxyable';

use overload (
  '""'     => 'string',
  '~~'     => 'string',
  fallback => 1
);

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  my $origin = $self->origin;

  $self->{source} = $origin->new($args->{source});

  return $self;
}

sub BUILDARGS {
  my ($self, @args) = @_;

  unshift @args, 'source', @args ? () : '.' if @args < 2;

  return {@args};
}

sub BUILDPROXY {
  my ($class, $method, @args) = @_;

  my $self = shift @args;
  my $source = $self->source;

  unless ($class->can($method) || $source->can($method)) {
    return;
  }
  return sub {
    # force-handle wantarray :(
    my @results = $source->$method(@args);

    if (@results > 1) {
      return (@results);
    } elsif (ref($results[0])) {
      my $result = $results[0];
      return UNIVERSAL::isa($result, ref($source)) ? $class->new($result) : $result;
    } else {
      return $results[0];
    }
  };
}

# METHODS

sub origin {
  return 'Path::Tiny';
}

sub source {
  my ($self) = @_;

  return $self->{source};
}

sub string {
  my ($self) = @_;

  my $source = $self->source;

  return $source->stringify;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Path

=cut

=head1 ABSTRACT

Data-Object Path Class

=cut

=head1 SYNOPSIS

  use Data::Object::Path;

  my $path = Data::Object::Path->new('/tmp/test.txt');

  $path->absolute;

=cut

=head1 DESCRIPTION

Data::Object::Path provides methods for manipulating file paths and
encapsulates the behavior of L<Path::Tiny>.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 buildproxy

  BUILDPROXY(Any @args) : CodeRef

The BUILDPROXY method handles resolving missing-methods via autoloaded. This
method is never called directly.

=over 4

=item BUILDPROXY example

  # given $path

  $path->BUILDPROXY(...);

  # ...

=back

=cut

=head2 origin

  origin() : Str

The origin method returns the package name of the proxy used.

=over 4

=item origin example

  # given $origin

  $path->origin();

  # Path::Tiny

=back

=cut

=head2 source

  source() : Object

The source method returns the underlying proxy object used.

=over 4

=item source example

  # given $source

  $path->source();

  # Path::Tiny (object)

=back

=cut

=head2 string

  string() : Str

The string method returns the string representation of the object.

=over 4

=item string example

  # given $path

  $path->string();

  # ...

=back

=cut

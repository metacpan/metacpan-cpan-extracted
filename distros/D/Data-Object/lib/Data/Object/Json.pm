package Data::Object::Json;

use JSON::Tiny ();

use Data::Object::Class;

# BUILD
# METHODS

sub dump {
  my ($self, $data) = @_;

  my $space = $self->space;

  return $space->call('encode_json', $data);
}

sub from {
  my ($self, $data) = @_;

  my $next = ref $data ? 'dump' : 'load';

  return $data ? $self->new->$next($data) : $self->new;
}

sub load {
  my ($self, $data) = @_;

  my $space = $self->space;

  return $space->call('decode_json', $data);
}

sub read {
  my ($self, $file) = @_;

  return unless $file;

  my $data = $self->file($file)->slurp;

  return $self->load($data);
}

sub write {
  my ($self, $file, $data) = @_;

  return unless $file && $data;

  $data = $self->dump($data);
  $file = $self->file($file);

  $file->spew($data);

  return $data;
}

sub space {
  my ($self) = @_;

  require Data::Object::Space;

  return Data::Object::Space->new($self->origin);
}

sub file {
  my ($self, $file) = @_;

  require Data::Object::Path;

  return Data::Object::Path->new($file) if $file;

  return Data::Object::Path->new->tempfile(rand);
}

sub origin {
  return 'JSON::Tiny';
}

1;

=encoding utf8

=head1 NAME

Data::Object::Json

=cut

=head1 ABSTRACT

Data-Object Json Class

=cut

=head1 SYNOPSIS

  use Data::Object::Json;

  my $json = Data::Object::Json->new;

  my $data = $json->from($arg);

=cut

=head1 DESCRIPTION

Data::Object::Json provides methods for reading and writing JSON data.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 dump

  # given $json

  my $string = $json->dump($data);

  # '{"foo":...}'

The dump method converts a data structure into a JSON string.

=cut

=head2 from

  # given $json

  my $data = $json->from($string);

  # {,...}

  my $string = $json->from($data);

  # '{"foo":...}'

The from method calls C<dump> or C<load> based on the give data.

=cut

=head2 load

  # given $json

  my $data = $json->load($string);

  # {,...}

The load method converts a string into a Perl data structure.

=cut

=head2 read

  # given $json

  my $data = $json->read($file);

  # {,...}

The read method reads JSON from the given file and returns a data structure.

=cut

=head2 write

  # given $json

  my $string = $json->write($file, $data);

  # ...

The write method writes the given data structure to a file as a JSON string.

=cut

=head2 space

  # given $json

  my $space = $json->space();

  # JSON::Tiny

The space method returns a L<Data::Object::Space> object for the C<origin>.

=cut

=head2 file

  # given $json

  my $path = $json->file($file);

  # ...

The file method returns a L<Data::Object::Path> object for the given file.

=cut

=head2 origin

  # given $json

  my $origin = $json->origin();

  # JSON::Tiny

The origin method returns the package name of the underlying JSON library used.

=cut

package Data::Object::Yaml;

use YAML::Tiny ();

use Data::Object::Class;

# BUILD
# METHODS

sub dump {
  my ($self, $data) = @_;

  my $space = $self->space;

  return $space->build($data)->write_string;
}

sub from {
  my ($self, $data) = @_;

  my $next = ref $data ? 'dump' : 'load';

  return $data ? $self->new->$next($data) : $self->new;
}

sub load {
  my ($self, $data) = @_;

  my $space = $self->space;

  return $space->build->read_string($data)->[-1];
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
  return 'YAML::Tiny';
}

1;

=encoding utf8

=head1 NAME

Data::Object::Yaml

=cut

=head1 ABSTRACT

Data-Object Yaml Class

=cut

=head1 SYNOPSIS

  use Data::Object::Yaml;

  my $yaml = Data::Object::Yaml->new;

  my $data = $yaml->from($arg);

=cut

=head1 DESCRIPTION

Data::Object::Yaml provides methods for reading and writing YAML data.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 dump

  # given $yaml

  my $string = $yaml->dump($data);

  # '--- {name: ...}'

The dump method converts a data structure into a YAML string.

=cut

=head2 from

  # given $yaml

  my $data = $yaml->from($string);

  # {,...}

  my $string = $yaml->from($data);

  # '--- {foo: ...}'

The from method calls C<dump> or C<load> based on the give data.

=cut

=head2 load

  # given $yaml

  my $data = $yaml->load($string);

  # {,...}

The load method converts a string into a Perl data structure.

=cut

=head2 read

  # given $yaml

  my $data = $yaml->read($file);

  # {,...}

The read method reads YAML from the given file and returns a data structure.

=cut

=head2 write

  # given $yaml

  my $string = $yaml->write($file, $data);

  # ...

The write method writes the given data structure to a file as a YAML string.

=cut

=head2 space

  # given $yaml

  my $space = $yaml->space();

  # YAML::Tiny

The space method returns a L<Data::Object::Space> object for the C<origin>.

=cut

=head2 file

  # given $yaml

  my $path = $yaml->file($file);

  # ...

The file method returns a L<Data::Object::Path> object for the given file.

=cut

=head2 origin

  # given $yaml

  my $origin = $yaml->origin();

  # YAML::Tiny

The origin method returns the package name of the underlying YAML library used.

=cut

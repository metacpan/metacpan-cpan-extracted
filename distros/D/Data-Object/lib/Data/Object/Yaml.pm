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

  dump(HashRef $arg1) : Str

The dump method converts a data structure into a YAML string.

=over 4

=item dump example

  # given $yaml

  my $string = $yaml->dump($data);

  # '--- {name: ...}'

=back

=cut

=head2 file

  file() : Object

The file method returns a L<Data::Object::Path> object for the given file.

=over 4

=item file example

  # given $yaml

  my $path = $yaml->file($file);

  # ...

=back

=cut

=head2 from

  from(Any $arg1) : Any

The from method calls C<dump> or C<load> based on the give data.

=over 4

=item from example

  # given $yaml

  my $data = $yaml->from($string);

  # {,...}

  my $string = $yaml->from($data);

  # '--- {foo: ...}'

=back

=cut

=head2 load

  load(Str $arg1) : HashRef

The load method converts a string into a Perl data structure.

=over 4

=item load example

  # given $yaml

  my $data = $yaml->load($string);

  # {,...}

=back

=cut

=head2 origin

  origin() : Str

The origin method returns the package name of the underlying YAML library used.

=over 4

=item origin example

  # given $yaml

  my $origin = $yaml->origin();

  # YAML::Tiny

=back

=cut

=head2 read

  read(Str $arg1) : HashRef

The read method reads YAML from the given file and returns a data structure.

=over 4

=item read example

  # given $yaml

  my $data = $yaml->read($file);

  # {,...}

=back

=cut

=head2 space

  space() : Object

The space method returns a L<Data::Object::Space> object for the C<origin>.

=over 4

=item space example

  # given $yaml

  my $space = $yaml->space();

  # YAML::Tiny

=back

=cut

=head2 write

  writes(Str $arg1, HashRef $arg2) : Str

The write method writes the given data structure to a file as a YAML string.

=over 4

=item write example

  # given $yaml

  my $string = $yaml->write($file, $data);

  # ...

=back

=cut

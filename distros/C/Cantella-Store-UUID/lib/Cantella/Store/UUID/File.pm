package Cantella::Store::UUID::File;

use Moose;
use JSON ();

use File::MimeInfo::Magic ();
use MooseX::Types::Data::GUID qw/GUID/;
use MooseX::Types::Path::Class qw/Dir File/;

use namespace::autoclean;

our $VERSION = '0.003003';

has uuid => (is => 'ro', isa => GUID, coerce => 1, required => 1);
has dir => (is => 'ro', isa => Dir,  coerce => 1);

has path => (is => 'ro', isa => File, coerce => 1, lazy_build => 1);
has _meta_file => (is => 'ro', isa => File, coerce => 1, lazy_build => 1);

has metadata => (
  traits => ['Hash'],
  is => 'rw',
  isa => 'HashRef',
  lazy_build => 1,
  trigger => sub { shift->write_metadata },
  handles => {
    'get_property' => 'get',
    'set_property' => 'set',
    'has_property' => 'exists',
    'clear_property', => 'delete',
  },
);

sub _build_path {
  my $self = shift;
  $self->dir->file( $self->uuid->as_string );
}

sub _build__meta_file {
  my $self = shift;
  $self->dir->file((join '.', $self->uuid->as_string, 'meta' ));
}

sub _build_metadata {
  my $self = shift;
  my $file = $self->_meta_file;
  if( my $json = $file->slurp ){
    if( my $perl = eval { JSON::from_json( $json ) }){
      return $perl;
    }
    die("Failed to parse contents of meta file $file: ${@}");
  }
  die("Failed to read file $file: ${!}");
}

sub write_metadata {
  my $self = shift;
  my $file = $self->_meta_file;
  if (my $json = JSON::to_json( $self->metadata || {} ) ){
    if( my $fh = $file->openw ){
      print $fh $json;
      return 1;
    }
    die("Failed to write meta file '${file}' Contents: '${json}': ${!}");
  }
  die("Failed to serialize metadata");
}

sub remove {
  my $self = shift;
  my $uuid = $self->uuid;
  my $file_path = $self->path;
  my $meta_path = $self->_meta_file;

  if( -e $meta_path && !$meta_path->remove ){
    die("Can't remove '${uuid}': Failed to delete '${meta_path}': ${!}");
  }
  if (-e $file_path && !$file_path->remove){
    die("Can't remove '${uuid}': Failed to delete '${file_path}': ${!}");
  }

  return ! (-e $self->path || -e $self->_meta_file);
}

sub exists {
  my $self = shift;
  return -e $self->path and -e $self->_meta_file;
}

sub extension {
  my $self = shift;
  if( my $type = $self->mime_type ){
    if( my $ext = File::MimeInfo::extensions( $type ) ){
      return $ext;
    }
  }
  if( $self->has_property('original_name') ){
    if( $self->get_property('original_name') =~ /\.(\w+)$/){
      return $1;
    }
  }
  return '';
}

sub mime_type {
  my $self = shift;
  return $self->get_property('mime-type') if $self->has_property('mime-type');
  if( my $type = File::MimeInfo::Magic::mimetype( $self->path->stringify ) ){
    $self->set_property('mime-type', $type);
    $self->write_metadata;
    return $type;
  }
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Cantella::Store::UUID::File - File represented by a UUID

=head1 A NOTE ABOUT EXTENSIONS

To make file location deterministic, files are stored under only their UUID,
along with their respective meta file which is named C<$UUID.meta> eg
(C<DD5EB40A-164B-11DE-9893-5FA9AE3835A0.meta>). The meta files may contain any
number of key/value pairs relevant to the file such as the original file name,
extension, MIME type, etc. Meta files are stored in JSON format.

=head1 ATTRIBUTES

C<Cantella::Store::UUID> is a subclass of L<Moose::Object>. It inherits the
C<new> object provided by L<Moose>. All attributes can be set using the C<new>
constructor method, or their respecitive writer method, if applicable.

=head2 uuid

=over 4

=item B<uuid> - reader

=back

Required, read-only L<Data::GUID> object, will automatically coerce.

=head2 dir

=over 4

=item B<dir> - reader

=back

Required, read-only L<Path::Class::File> object representing the directory
where this file is stored. Automatically coercing.

=head2 path

=over 4

=item B<path> - reader

=item B<has_path> - predicate

=item B<_build_path> - builder

=item B<clear_path> - clearer

=back

Lazy-building, read-only L<Path::Class::File> object representing the file
being stored under this UUID.

=head2 metadata

=over 4

=item B<metadata> - accessor

=item B<has_metadata> - predicate

=item B<_build_metadata> - builder

=item B<clear_metadata> - clearer

=item B<has_property> - key predicate

=item B<set_property> - key writer

=item B<get_property> - key reader

=item B<clear_property> - key clearer

=back

Lazy_building, read-write hashref which contains the file's metadata. Setting
it with the writer method will write the data to disk, modifying the
hashref directly, or via the key writer, will not.

=head2 _meta_file

=over 4

=item B<_meta_file> - reader

=item B<_has_meta_file> - predicate

=item B<_build__meta_file> - builder

=item B<clear__meta_file> - clearer

=back

Lazy-building, read-only L<Path::Class::File> object pointing at the meta file.

=head1 METHODS

=head2 new

=over 4

=item B<arguments:> C<\%arguments>

=item B<return value:> C<$object_instance>

=back

Constructor.

=head2 write_metadata

=over 4

=item B<arguments:> none

=item B<return value:> none

=back

Write the contents of C<metadata> to the metadata file.

=head2 remove

=over 4

=item B<arguments:> none

=item B<return value:> C<$bool_success>

=back

Removes the file and metadata file from the store. Returns true if both are
removed successfully. An exception will be thrown if there is an error deleting
the files.

=head2 exists

=over 4

=item B<arguments:> none

=item B<return value:> C<$bool>

=back

Checks for existence of both the file and the metadata file. Returns true only
if both exist.

=head2 mime_type

=over 4

=item B<arguments:> none

=item B<return value:> C<$mime_type>

=back

Will return the mime-type for the file. If there is a value for the 'mime-type'
property, that value will be used. If the key isn't present, L<File::MimeInfo>
will be used to find the mime-type of the file and store in the meta file.

If no mime-type can be determined, undef will be returned in scalr context and
an empty list in list context.

=head2 extension

=over 4

=item B<arguments:> none

=item B<return value:> C<$extension>

=back

Will return an appropriate extension for a file, by using it's mime-type, or
original file name if mime-type is unavailable. If no known extension is known
it returns an empty string.

=head1 SEE ALSO

L<Cantella::Store::UUID>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009, 2010 by Guillermo Roditi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Cantella::Store::UUID;

use Moose;
use Try::Tiny;
use Class::MOP;
use Data::GUID;
use File::Copy qw();
use Path::Class qw();
use Cantella::Store::UUID::Util '_mkdirs';
use MooseX::Types::Path::Class qw/Dir/;

use namespace::autoclean;

our $VERSION = '0.003003';
$VERSION = eval $VERSION;

has nest_levels => (
  is => 'ro',
  isa => 'Int',
  required => 1,
);

has root_dir => (
  is => 'ro',
  isa => Dir,
  coerce => 1,
  required => 1
);

has file_class => (
  is => 'ro',
  isa => 'ClassName',
  required => 1,
  default => sub {
    Class::MOP::load_class('Cantella::Store::UUID::File');
    return 'Cantella::Store::UUID::File';
  }
);

# File::Copy 2.10 introduced 'sub _eq' in lieu of a simple "$from eq $to" check
# to enable checking of whether strings _or_ refs were identical. However, this
# resulted in
#
# Argument "...." isn't numeric in numeric eq (==) at /usr/share/perl/5.10/File/Copy.pm line 70.
#
# this hack will implement File::Copy 2.13's version of 'sub _eq'

# 5.8.8  File::Copy 2.09 -- ok
# 5.9.5  File::Copy 2.10 -- broken
# 5.8.9  File::Copy 2.13 -- ok
# 5.10.0 File::Copy 2.11 -- broken
# 5.10.1 File::Copy 2.14 -- ok

if ($File::Copy::VERSION >= 2.10 && $File::Copy::VERSION <= 2.12) {
  Class::MOP::Package->initialize('File::Copy')->add_package_symbol('&_eq' => sub {
    my $Scalar_Util_loaded = eval q{ require Scalar::Util; require overload; 1 };
    my ($from, $to) = map {
        $Scalar_Util_loaded && Scalar::Util::blessed($_)
           && overload::Method($_, q{""})
            ? "$_"
            : $_
    } (@_);
    return '' if ( (ref $from) xor (ref $to) );
    return $from == $to if ref $from;
    return $from eq $to;
  });
}

sub from_uuid {
  my ($self, $uuid) = @_;
  return $self->file_class->new(
    uuid => $uuid,
    dir => $self->_get_dir_for_uuid($uuid),
    _document_store => $self,
  );
}

sub new_uuid {
  Data::GUID->new;
}

sub create_file {
  my( $self, $source_file, $uuid, $metadata) = @_;
  $source_file = Path::Class::file($source_file) unless blessed $source_file;
  my %meta = %{ $metadata || {} };
  $meta{original_name} = $source_file->basename;

  my $new_file = $self->from_uuid( $uuid );
  $new_file->metadata( \%meta );
  return $new_file if File::Copy::copy($source_file, $new_file->path);

  my $new_path = $new_file->path;
  die("File copy from ${source_file} to ${new_path} failed: $!");
}

sub deploy {
  my $self = shift;

  my $root = $self->root_dir;
  unless( -d $root || $root->mkpath ){
    die("Failed to create ${root}");
  }
  _mkdirs($root, $self->nest_levels);
  return 1;
}

sub _get_dir_for_uuid {
  my ($self, $uuid) = @_;
  $uuid = Data::GUID->from_any_string($uuid) unless blessed $uuid;
  my $target = $self->root_dir;
  my @dirs = split('', uc(substr($uuid->as_hex, 2, $self->nest_levels)));

  return $target->subdir( @dirs );
}

sub grep_files {
  my($self, $test) = @_;
  my @result;

  my $callback = sub {
    my $node = shift;
    return if $node->is_dir;
    return unless $node->basename =~ /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/;
    my $uuid;
    try {
      $uuid = Data::GUID->from_string($node->basename);
    } catch {
      warn("Invalid object in file storage at: ${node}");
    };
    push(@result, $uuid) if $test->( $self->from_uuid($uuid) );
  };

  $self->root_dir->recurse(callback => $callback, depthfirst => 1, preorder => 0);
  return @result;
}

sub map_files {
  my($self, $block) = @_;
  my @result;

  my $callback = sub {
    my $node = shift;
    return if $node->is_dir;
    return unless $node->basename =~ /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/;
    my $uuid;
    try {
      $uuid = Data::GUID->from_string($node->basename);
    } catch {
      warn("Invalid object in file storage at: ${node}");
    };
    push(@result, $block->( $self->from_uuid($uuid) ));
  };

  $self->root_dir->recurse(callback => $callback, depthfirst => 1, preorder => 0);
  return @result;
}


__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Cantella::Store::UUID - UUID based file storage

=head1 DESCRIPTION

L<Cantella::Store::UUID> stores documents in a deterministic location based on
a UUID. Depending on the number of files to be stored, a store may use 1
or more levels. A level is composed of 16 directories (0-9 and A-F) nested to
C<n> depth. For Example, if a store has 3 levels, the path to file represented
by UUID C<A5D45AF2-73D1-11DD-AA18-4B321EADD46B> would be
C<A/5/D/A5D45AF2-73D1-11DD-AA18-4B321EADD46B>.

The goal is to provide a simple way to spread the storage  of a large number of
files over many directories to prevent any single directory from storing too-many
files. Optionally, lower level tools can then be utilized to spread the
underlying storage points accross different physical devices if necessary.

The number of final storage points available can be calculated by raising 16 to
the nth power, where n is the number of C<nest levels>.

B<Caution:> The number of directories generated is actually larger than the
number of final storage points because all directories in the hierarchy must
be counted, thus the number of directories a store contains is
C<(16^n) + (16^(n-1)) .. (16^1) + (16^0)> and a 5 level deep hierarchy for
all three storage points would create 3,355,443 directories. For this reason,
any number larger than 4 is cautioned against.

=head1 SYNOPSYS

    use Path::Class qw(file);
    use Cantella::Store::UUID;

    my $store = Cantella::Store::UUID->new(
      root_dir => './test-cantella-store-uuid',
      nest_levels => 3,
    );
    $store->deploy; #create the storage dirs (should only be done once)

    my $new_uuid = $store->new_uuid;
    {
      my $source_file = file './some-file';
      my $stored_file = $store->create_file($source_file, $new_uuid, {foo => 'bar'});
      $source_file->remove; #it was copied into the storage
    }

    #this object is identical to the one returned by ->create_file
    my $stored_file = $store->from_uuid($new_uuid);
    print $stored_file->metadata->{foo}; #prints 'bar'

    # $grep_results[0] eq $new_uuid#
    my @grep_results = $store->grep_files(sub { exists shift->metadata->{foo}});

    # $map_results[0] eq 'bar'
    my @map_results = $store->grep_files(sub { $_->metadata->{foo}});

=head1 ATTRIBUTES

C<Cantella::Store::UUID> is a subclass of L<Moose::Object>. It inherits the
C<new> object provided by L<Moose>. All attributes can be set using the C<new>
constructor method, or their respecitive writer method, if applicable.

=head2 nest_levels

Required, read-only integer representing how many levels of depth to use in
the directory structure.

The following methods are associated with this attribute:

=over 4

=item B<nest_levels> - reader

=back

=head2 root_dir

=over 4

=item B<root_dir> - reader

=back

Required, read-only directory location for the root of the hierarchy.

=head2 file_class

=over 4

=item B<file_class> - reader

=back

Required, read-only class name. The class to use for stored file objects.
Defaults to L<Cantella::Store::UUID::File>.

=head1 METHODS

=head2 new

=over 4

=item B<arguments:> C<\%arguments>

=item B<return value:> C<$object_instance>

=back

Constructor.

=head2 from_uuid

=over 4

=item B<arguments:> C<$uuid>

=item B<return value:> C<$file_object>

=back

Return the apropriate file object for C<$uuid>. Please note that this
particular file does not neccesarily exist and its presence is not checked for.
See L<exists|Cantella::Store::UUID::File/exists>.

=head2 new_uuid

=over 4

=item B<arguments:> none

=item B<return value:> C<$uuid>

=back

Returns a new UUID object suitable for use with this module. By default, it
currently uses L<Data::GUID>.

=head2 create_file

=over 4

=item B<arguments:> C<$original, $uuid, $metadata>

=item B<return value:> C<$file_object>

=back

Will copy the C<$original> file into the the UUID storage and return the
file object representing it. The key C<original_name> will be automatically
set on the metadata with the base name of the original file.

=head2 deploy

=over 4

=item B<arguments:> none

=item B<return value:> none

=back

Create directory hierarchy, starting with C<root_dir>. A call to deploy may
take a couple of minutes or even hours depending on the value of C<nest_levels>
and the speed of the storage being utilized.

=head2 grep_files

=over 4

=item B<arguments:> C<$code_ref>

=item B<return value:> C<@matching_uuids>

=back

Recurse the storage testing every file against C<$code_ref>. Return all of the
UUIDs where C<$code_ref> returns a true value. The only argument given to
C<$code_ref> is a file object. The order in which files are tested and
subsequently returned is undefined behavior and may change. Be aware that,
depending on the number of @matching_ids and the number of documents stored,
this method could take a very, very long time to finish and use considerable
amounts of memory.

=head2 map_files

=over 4

=item B<arguments:> C<$code_ref>

=item B<return value:> C<@return_values>

=back

Recurse the storage executing C<$code_ref> on every file. Return all of the
values returned by C<$code_ref>. The only argument given to C<$code_ref> is
a file object. The order in which files are tested and subsequently returned
is undefined behavior and may change. Be aware that, depending on the result
values and number of documents stored, this method could take a very, very long
time to finish and use considerable amounts of memory.

=head2 _get_dir_for_uuid

=over 4

=item B<arguments:> C<$uuid>

=item B<return value:> C<Path::Class::Dir $dir>

=back

Given a UUID, it returns the apropriate directory;

=head1 SEE ALSO

L<Cantella::Store::UUID::File>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009, 2010 by Guillermo Roditi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

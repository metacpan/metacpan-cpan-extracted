use v5.34;
use warnings;
use Object::Pad 0.73;

class Archive::SCS::InMemory 1.06
  :isa( Archive::SCS::Mountable );

use stable 0.031 'isa';

use Archive::SCS::CityHash 'cityhash64';
use Archive::SCS::DirIndex;
use Carp 'croak';
use File::Temp 0.05 'mktemp';
use List::Util 'first';
use Path::Tiny 0.017 ();

our @CARP_NOT = qw( Archive::SCS );

field $is_mounted = 0;
field $path :reader = Path::Tiny::path mktemp 'Archive-SCS-InMemory-XXXXXXXX';
# Archive::SCS expects that mounts relate to a file path,
# so we need to make up a random one.

field %entries;
field @dirs;
field @files;


method file () {
  warnings::warnif deprecated => "file() is deprecated; use path()";
  $path
}


method mount () {
  $is_mounted = 1;
  return $self;
}


method unmount () {
  $is_mounted = 0;
}


method is_mounted () {
  !! $is_mounted
}
# Archive::SCS expects that mounting is stateful.


method read_dir_tree (@roots) {
  my $root = first { exists $entries{ cityhash64 $_ } } @roots;
  defined $root or return;

  @dirs = ($root);
  @files = ();
  for (my $i = 0; $i < @dirs; ++$i) {
    my $dir = $dirs[$i];

    my $entry = $self->read_entry( cityhash64 $dir );
    $entry isa Archive::SCS::DirIndex or croak
      sprintf "%s: Directory '%s' not found", __PACKAGE__, $dir;

    $dir .= '/' if length $dir;
    push @dirs,  map { "$dir$_" } $entry->dirs;
    push @files, map { "$dir$_" } $entry->files;
  }
}


method list_dirs () {
  return @dirs;
}


method list_files () {
  return @files;
}


method entry_meta ($hash) {
  return {
    is_dir => $entries{ $hash } isa Archive::SCS::DirIndex,
  };
}


method add_entry ($path, $entry) {
  if (ref $entry eq 'HASH') {
    $entry = Archive::SCS::DirIndex->new($entry->%*);
  }
  $entries{ cityhash64 $path } = $entry;
  return $self
}


method read_entry ($hash) {
  return $entries{ $hash };
}


method entries () {
  keys %entries
}

1;


=head1 NAME

Archive::SCS::InMemory - In-memory SCS archive handler

=head1 SYNOPSIS

  my $mem = Archive::SCS::InMemory->new;

  # Add regular files:
  $mem->add_entry('manifest.sii' => $manifest);
  $mem->add_entry('def/env_data.sii' => $env_data);

  # Add directory listing for the root dir:
  $mem->add_entry( '' => {
    dirs  => [ 'def' ],
    files => [ 'manifest.sii' ],
  });

  my $scs = Archive::SCS->new;
  $scs->mount($mem);

=head1 DESCRIPTION

Represents a virtual SCS archive file entirely contained in memory.
Use cases:

=over

=item *

CI testing (this is why it exists, really)

=item *

Inject missing files or directory listings into an archive
environment. Allows adding file names to orphans (if you know
their names, that is).

=item *

Create archive files on disk from scratch. This assumes there is a
way to create a new archive file from an L<Archive::SCS> object.

=back

Hash values used with this module must be in the internal format
(currently, an 8-byte scalar PV in network byte order).

=head1 METHODS

=head2 add_entry

  # Regular file:
  $mem = $mem->add_entry($path => $file_contents);

  # Directory listing:
  $mem = $mem->add_entry($path => {
    dirs  => [ @subdirs ],
    files => [ @filenames ],
  });

=head2 entries

  $entry_hashes = $mem->entries;

=head2 is_mounted

  $bool = $mem->is_mounted;

=head2 list_dirs

  @directories = $mem->list_dirs;

=head2 list_files

  @files = $mem->list_files;

=head2 mount

  $archive = $mem->mount;

=head2 new

  $mem = Archive::SCS::InMemory->new;

=head2 read_dir_tree

  $mem->read_dir_tree;

=head2 read_entry

  $data = $mem->read_entry($hash);

=head2 unmount

  $mem->unmount;

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2025 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

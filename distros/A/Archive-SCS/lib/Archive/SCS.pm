use v5.32;
use warnings;
use Object::Pad 0.73;

class Archive::SCS 1.03;

use stable 0.031 'isa';

use Archive::SCS::CityHash qw(cityhash64 cityhash64_hex cityhash64_as_hex);
use Carp 'croak';
use List::Util 1.45 qw(first uniqstr);
use Module::Load 'load';
use Path::Tiny 0.054 'path';

use Archive::SCS::HashFS;
use Archive::SCS::HashFS2;

field @formats = qw( HashFS2 HashFS );

field @mounts;
field %entries;

my @ROOTS = ('', 'locale');


method formats () {
  @formats
}


method set_formats {
  load __PACKAGE__ . "::$_" for @_;
  @formats = @_;
  return $self;
}


method format_module ($file) {
  open my $fh, '<:raw', $file or croak
    sprintf "%s: $!", $file->basename;
  read $fh, my $header, 8 or croak
    sprintf "%s: $!", $file->basename;

  my @modules = map { __PACKAGE__ . "::$_" } @formats;
  my $module = first { $_->handles_file($fh, $header) } @modules or croak
    sprintf "%s: No suitable format handler found", $file->basename;

  close $fh;
  return $module;
}


method mount ($mountable) {
  if ( not $mountable isa Archive::SCS::Mountable ) {
    my $file = path $mountable;
    my $format = $self->format_module($file);
    $mountable = $format->new(file => $file);
  }
  my $basename = $mountable->file->basename;

  $self->is_mounted($mountable) and croak
    sprintf "%s: Already mounted", $basename;

  my $mount = $mountable->mount;
  push @mounts, $mount;
  push $entries{$_}->@*, $mount for my @entries = $mount->entries;
  $mount->read_dir_tree(@ROOTS);

  return $mount;
}


method unmount ($mount) {
  if ( not $mount isa Archive::SCS::Mountable ) {
    my $file = path $mount;
    $mount = first { $file->realpath eq $_->file->realpath } @mounts or croak
      sprintf "%s: Not mounted", $file->basename;
  }

  $mount->unmount;

  # Remove mount from entries list
  for my $hash ( keys %entries ) {
    $entries{$hash} = [ grep { $mount != $_ } $entries{$hash}->@* ];
    $entries{$hash}->@* == 0 and delete $entries{$hash};
  }
  @mounts = grep { $mount != $_ } @mounts;

  return $mount;
}


method is_mounted ($mountable) {
  first { $mountable->file->realpath eq $_->file->realpath } @mounts
}


method entry_mounts ($path) {
  my $mounts = $entries{ cityhash64 $path };
  $mounts //= $entries{ cityhash64_hex $path };
  my @mounts = $mounts ? $mounts->@* : ();
  return @mounts;
}


method read_entry ($path) {
  my $hash;
  my $mounts = $entries{ $hash = cityhash64 $path };
  $mounts //= $entries{ $hash = cityhash64_hex $path };
  $mounts or croak
    sprintf "'%s': no entry found", $path;

  my $mount = $mounts->[ $#{$mounts} ];
  return $mount->read_entry($hash);
}


method list_dirs ($root = '') {
  my @dirs = uniqstr sort map { $_->list_dirs } @mounts;
  @dirs = grep /^\Q$root\E(?:\/|$)/, @dirs if length $root;

  # Skip default root (the empty string)
  shift @dirs unless length $dirs[0];
  return @dirs;
}


method list_files ($root = '') {
  my @files = uniqstr sort map { $_->list_files } @mounts;
  @files = grep /^\Q$root\E(?:\/|$)/, @files if length $root;

  return @files;
}


method list_orphans () {
  my @paths = ( eval { $self->list_dirs }, eval { $self->list_files } );
  my %paths = map {( cityhash64 $_ => $_ )} @paths, @ROOTS;

  my @orphans;
  for my $hash ( keys %entries ) {
    defined $paths{$hash} or push @orphans, $hash;
  }
  return map { cityhash64_as_hex $_ } uniqstr sort @orphans;
}

1;


=head1 NAME

Archive::SCS - SCS archive controller

=head1 SYNOPSIS

  my $scs = Archive::SCS->new;
  $scs->mount("$path/base.scs");
  $scs->mount("$path/def.scs");

  my @contents = sort $scs->list_dirs, $scs->list_files;

  say $scs->read_entry('def/env_data.sii');

=head1 DESCRIPTION

Handles the union file system used by SCS archive files.
Allows mounting of multiple files and
performs lookups in all of them using the SCS hash algorithm.

These modules exist primarily to support the F<scs_archive>
command-line tool included in this distribution.

=head1 METHODS

=head2 formats

  @formats = $scs->formats;

Returns the list of currently active formats.
See C<set_formats()>.

=head2 list_dirs

  @directories = $scs->list_dirs;

Returns an ordered list of all directory paths in currently
mounted archives. The root directory, represented by an empty
string, is currently omitted from the list.

Paths are returned without a leading C</> because that's the
way they are stored internally. This is subject to change,
but the output of C<list_dirs()> will always be good to use
as path for C<read_entry()>.

=head2 list_files

  @files = $scs->list_files;

Returns an ordered list of all file paths in currently mounted
archives.

Paths are returned without a leading C</> because that's the
way they are stored internally. This is subject to change,
but the output of C<list_files()> will always be good to use
as path for C<read_entry()>.

=head2 list_orphans

  @orphan_hashes = $scs->list_orphans;

Returns a list of hash values for
orphans in currently mounted archives.

Some file formats allow files (or subdirs) without a directory entry.
These files may be accessed directly using their hash value. This
software refers to such files as orphans. For example, the following
orphans are known to exist in 1.49.3.14:

  05c075dc23d8d177 # in core.scs, 'def/achievements.sii'
  0eeaffbe65995414 # in base.scs + core.scs, 'ui/desktop_demo.sii'
  0fb3a3294f8ac99c # in base_cfg.scs
  2a794836b65afe88 # in base.scs
  34f7048e2d3b04b6 # in core.scs, 'def/online_economy_data.sii'
  507dcc5fb3fb6443 # in core.scs, 'def/online_data.sii'
  83a9902d7733b94d # in core.scs, 'def/mod_manager_data.sii'
  88a1194cb25b253c # in core.scs, 'ui/desktop_standalone_demo.sii'
  c09356068ea66aac # in core.scs, 'def/world/building_scheme_core_scs.sii'
  d9d3d2a218c69f3d # in base.scs
  e773fb1407c8468d # in core.scs, 'def/world/building_model_core_scs.sii'

=head2 mount

  $archive = $scs->mount($pathname);
  $archive = $scs->mount($mountable);

Adds the given SCS archive to the currently mounted archives.
Returns an L<Archive::SCS::Mountable> object. If a file system
path is given as argument, the object will be created by
attempting to load the given archive with the currently active
formats. See C<set_formats()>.

=head2 new

  $scs = Archive::SCS->new;

Creates a new L<Archive::SCS> object.

=head2 read_entry

  $data = $scs->read_entry($pathname);
  $data = $scs->read_entry($hash);

Returns the contents of the given entry. Directories will be
returned as L<Archive::SCS::DirIndex> objects and S<HashFS v2>
texture objects as L<Archive::SCS::TObj>.

The argument may be the pathname within the archive or its hash
value, hex-encoded in network byte order as a 16-byte scalar PV.
Paths are expected without a leading C</> because that's the
way they are stored internally. This is subject to change,
but the output of C<list_files()> will always be good to use
as path for C<read_entry()>.

=head2 set_formats

  $scs = $scs->set_formats(qw[ HashFS Zip ]);

Sets the list of currently active formats. All formats must be
in the C<Archive::SCS> namespace. By default, the list includes
all formats implemented in this distribution, which currently
are the following:

=over

=item * L<Archive::SCS::HashFS>

=item * L<Archive::SCS::HashFS2>

=back

=head2 unmount

  $archive = $scs->unmount($pathname);
  $archive = $scs->mount($mountable);

Removes the given SCS archive from currently mounted archives.
Returns the archive's L<Archive::SCS::Mountable> object.

=head1 SEE ALSO

=over

=item * L<Archive::SCS::GameDir>

=back

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2024 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Includes L<CityHash|https://github.com/google/cityhash> 1.0.3,
Copyright (c) 2011 Google, Inc. (MIT license)

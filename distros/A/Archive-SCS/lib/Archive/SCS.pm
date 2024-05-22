use v5.38;
use feature 'class';
no warnings 'experimental::class';

class Archive::SCS 0.02;

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


=head1 NAME

Archive::SCS - SCS archive controller

=head1 SYNOPSIS

  my $scs = Archive::SCS->new;
  $scs->mount("$path/base.scs");
  $scs->mount("$path/def.scs");

  my @contents = sort $scs->list_dirs, $scs->list_files;

  say $scs->read_entry('version.txt');

=head1 DESCRIPTION

Handles SCS archive files. Allows mounting of multiple files and
performs lookups in all of them using the SCS hash algorithm.

Note that this software currently requires L<String::CityHash
B<version 0.10>|https://metacpan.org/release/ALEXBIO/String-CityHash-0.10/view/lib/String/CityHash.pm>,
which is only available on BackPAN.

=head1 METHODS

=head2 formats

  @formats = $scs->formats;

=head2 list_dirs

  @directories = $scs->list_dirs;

=head2 list_files

  @files = $scs->list_files;

=head2 list_orphans

  @orphan_hashes = $scs->list_orphans;

Some file formats allow files (or subdirs) without a directory entry.
These files may be accessed directly using their hash value. This
software refers to such files as orphans. For example, the following
orphans are known to exist in 1.49.3.14:

  05c075dc23d8d177 # in core.scs
  0eeaffbe65995414 # in base.scs + core.scs
  0fb3a3294f8ac99c # in base_cfg.scs
  2a794836b65afe88 # in base.scs
  34f7048e2d3b04b6 # in core.scs
  507dcc5fb3fb6443 # in core.scs
  83a9902d7733b94d # in core.scs
  88a1194cb25b253c # in core.scs, 'ui/desktop_standalone_demo.sii'
  c09356068ea66aac # in core.scs
  d9d3d2a218c69f3d # in base.scs
  e773fb1407c8468d # in core.scs

=head2 mount

  $archive = $scs->mount($pathname);

=head2 read_entry

  $data = $scs->read_entry($pathname);
  $data = $scs->read_entry($hash);

The argument may be the pathname within the archive or its hash
value, hex-encoded in network byte order as a 16-byte scalar PV.

=head2 set_formats

  $scs = $scs->set_formats(qw[ HashFS Zip ]);

=head2 unmount

  $archive = $scs->unmount($pathname);

=head1 SEE ALSO

=over

=item * L<Archive::SCS::GameDir>

=item * L<Archive::SCS::HashFS>

=item * L<Archive::SCS::HashFS2>

=back

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2024 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

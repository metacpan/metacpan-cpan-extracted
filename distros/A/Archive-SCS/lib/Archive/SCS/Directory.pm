use v5.34;
use warnings;
use Object::Pad 0.73 ':experimental(adjust_params)';

class Archive::SCS::Directory 1.06
  :isa( Archive::SCS::Mountable );

use builtin 'reftype';
use stable 0.031 'isa';
no warnings 'experimental::builtin';

use Archive::SCS::CityHash 'cityhash64';
use Archive::SCS::DirIndex;
use Carp 'croak';
use List::Util 1.33 'none';
use Path::Tiny 0.062 ();

our @CARP_NOT = qw( Archive::SCS );
our $follow_symlinks = 1;
our @skip = ( qr{^\.git(?:$|/)}, qr{(?:^|/)\.DS_Store$} );

field $path :param :reader;
field @ignores;

field %entries;
field @dirs;
field @files;

ADJUST :params ( :$ignore = undef ) {
  $path isa Path::Tiny && $path->exists or croak
    "Param file must be a valid Path::Tiny object";

  if (defined $ignore) {
    reftype $ignore eq 'REGEXP' or croak
      "Param ignore must be a regular expression";
    @ignores = ( $ignore );
  }
}


sub handles_path ($class, $path, $header) {
  $path->is_dir
}


method mount () {
  $self->is_mounted and croak sprintf "%s: Already mounted", $path->basename;

  push @dirs, '';
  my $index = {};
  $path->visit(
    sub {

      my $real_path = shift;
      my $scs_path = $real_path->relative($path);
      none { $scs_path =~ $_ } @skip or return;
      none { $scs_path =~ $_ } @ignores or return;

      my $dir = $index->{ $scs_path->parent } //= {};

      if ( $real_path->is_dir ) {
        push $dir->{dirs}->@*, $scs_path->basename;
        push @dirs, $scs_path;
        $index->{ $scs_path } //= {};
      }
      else {
        push $dir->{files}->@*, $scs_path->basename;
        push @files, $scs_path;
        $entries{ cityhash64 $scs_path } = $real_path;
      }

    },
    {
      recurse => 1,
      follow_symlinks => $follow_symlinks,
    },
  );

  $index->{''} = delete $index->{'.'};
  $entries{ cityhash64 $_ } = Archive::SCS::DirIndex->new($index->{$_}->%*)
    for keys $index->%*;

  return $self;
}


method unmount () {
  undef %entries;
  undef @dirs;
  undef @files;
}


method is_mounted () {
  !! %entries
}


method read_dir_tree (@roots) {
  # mount() does all the work
}


method ignore ($re) {
  $self->is_mounted and croak
    sprintf "%s: Call ignore() while unmounted", $path->basename;

  reftype $re eq 'REGEXP' or croak
    "ignore() argument must be a regular expression (qr//)";

  push @ignores, $re;
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


method read_entry ($hash) {
  my $entry = $entries{ $hash };
  $entry isa Archive::SCS::DirIndex ? $entry : $entry->slurp_raw
}


method entries () {
  keys %entries
}

1;


=head1 NAME

Archive::SCS::Directory - File system directory format handler

=head1 SYNOPSIS

  my $path = Path::Tiny->new('dir/');
  my $dir = Archive::SCS::Directory->new(path => $path)->mount;

  my @contents = sort $dir->list_dirs, $dir->list_files;

  my $hash = Archive::SCS::CityHash::cityhash64('def/city.sii');
  my $data = $dir->read_entry($hash);

=head1 DESCRIPTION

Represents an SCS archive that's actually a directory in the
file system. Useful for partially extracted archive files.

Symbolic links are supported, as long as they don't form a loop.
Changes to the contents of a mounted directory are not observed.
The directory tree is only read during mounting. To update the
object's view of a directory, C<unmount()>, then C<mount()>.

Hash values used with this module must be in the internal format
(currently, an 8-byte scalar PV in network byte order).

I<Since version 1.06.>

=head1 METHODS

=head2 entries

  $entry_hashes = $dir->entries;

=head2 ignore

  $dir->ignore($regexp);

=head2 is_mounted

  $bool = $dir->is_mounted;

=head2 handles_path

  $bool = Archive::SCS::Directory->handles_path($path, $header);

=head2 list_dirs

  @subdirs = $dir->list_dirs;

=head2 list_files

  @files = $dir->list_files;

=head2 mount

  $dir = $dir->mount;

=head2 new

  $dir = Archive::SCS::Directory->new(path => $path_tiny);
  $dir = Archive::SCS::Directory->new(path => $path_tiny, ignore => qr//);

=head2 path

  $path_tiny = $dir->path;

=head2 read_dir_tree

  $dir->read_dir_tree; # no-op

=head2 read_entry

  $data = $dir->read_entry($hash);

=head2 unmount

  $dir->unmount;

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2025 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

use v5.34;
use warnings;
use Object::Pad 0.73;

class Archive::SCS::Zip 1.07
  :isa( Archive::SCS::Mountable );

use builtin qw( blessed true );
use stable 0.031 'isa';
no warnings 'experimental::builtin';

use Archive::SCS::CityHash 'cityhash64';
use Archive::SCS::DirIndex;
use Carp 'croak';
use IO::Compress::Zip qw( :constants $ZipError );
use IO::Uncompress::Unzip qw( $UnzipError );
use Path::Tiny 0.054 ();

our @CARP_NOT = qw( Archive::SCS );

my $LOCAL_HEADER_SIGNATURE = "PK\x03\x04";

field $path :param :reader;
field $zip;

field %entries;
field @dirs;
field @files;

ADJUST {
  $path isa Path::Tiny && $path->exists or croak
    "Param file must be a valid Path::Tiny object";
}


method handles_path :common ($path, $header) {
  $header =~ /^\Q$LOCAL_HEADER_SIGNATURE\E/
  # According to the "appnote" spec, ZIP files don't begin with magic. Instead,
  # we'd need to scan the file's last 66 KB for the "end of central directory
  # record" signature, then heuristically determine if it looks like a ZIP file.
  # However, in practice, the overwhelming majority of ZIP files starts with a
  # "local file header" signature, which we can simply check for here.
}


method mount () {
  my $filename = $path->basename;
  $self->is_mounted and croak sprintf "%s: Already mounted", $filename;

  $zip = IO::Uncompress::Unzip->new( "$path", Append => 1 ) or croak
    "$filename: IO::Uncompress init: $UnzipError";

  my $status = 1;
  while ($status > 0) {
    my $entry = $zip->getHeaderInfo;

    my $name = $entry->{Name};
    my $is_empty = blessed $entry->{UncompressedLength} # type seems to vary by version
      ? $entry->{UncompressedLength}->isZero
      : $entry->{UncompressedLength} == 0;

    $entry->{is_dir} = $is_empty && $name =~ s|/\z||;
    $entries{ cityhash64 $name } = $entry;

    if ($entry->{is_dir}) {
      push @dirs, $name;
      next;
    }
    push @files, $name;

    $entry->{__data} = '';
    $status = $zip->read($entry->{__data}) while $status > 0;
    $status < 0 and croak
      "$filename: IO::Uncompress read ($entry->{Name}): $UnzipError ($status $!)";
  }
  continue {
    $status = $zip->nextStream;
    $status < 0 and croak
      "$filename: IO::Uncompress nextStream: $UnzipError ($!)";
  }
  $zip->close;

  return $self;
}


method unmount () {
  undef $zip;
  undef %entries;
  undef @dirs;
  undef @files;
}


method is_mounted () {
  !! $zip
}


method read_dir_tree (@roots) {
  my %index = Archive::SCS::DirIndex->auto_index(\@files, \@dirs)->%*;

  while ( my ($dirpath, $dirindex) = each %index ) {
    my $hash = cityhash64 $dirpath;
    $entries{$hash}{__data} = $dirindex;
    $entries{$hash}{is_dir} = true;
  }

  delete $index{''};
  @dirs = sort keys %index;
}


method list_dirs () {
  @dirs
}


method list_files () {
  @files
}


method entry_meta ($hash) {
  $entries{ $hash }
}


method read_entry ($hash) {
  my $entry = $entries{ $hash } or croak
    sprintf "'%s': no entry for hash value %s", $path->basename, $hash;

  $entry->{__data}
}


method entries () {
  keys %entries
}


sub create_file ($zipname, $scs, $file_opts = {}) {
  $scs isa Archive::SCS or croak "Archive::SCS instance required";

  my $description;
  my $comment = Path::Tiny->new($zipname)->basename;
  if ( my $manifest = eval { $scs->read_entry('manifest.sii') } ) {
    $manifest =~ m/package_version:  \s*"(.+?)"/ax and $comment .= " version $1";
    $manifest =~ m/author:           \s*"(.+?)"/ax and $comment .= " by $1";
    $manifest =~ m/description_file: \s*"(.+?)"/ax and $description = $1;
  }

  # ZIP file format specification 4.1.11:
  # The manifest file SHOULD be the first file in the ZIP file
  $file_opts->{'manifest.sii'} //= {
    zip_opts => { Method => ZIP_CM_STORE },
    order => chr 0,
  };

  # Make the mod description the second file, directly after the manifest
  # (uncompressed so that it's readable when the file is viewed in binary)
  defined $description and $file_opts->{$description} //= {
    zip_opts => { Method => ZIP_CM_STORE },
    order => chr 1,
  };

  # Add records for empty directories (non-empty dirs are implicit in ZIP)
  my @dirs;
  for my $dir ($scs->list_dirs) {
    my $index = $scs->read_entry($dir);
    push @dirs, $dir unless $index->dirs || $index->files;
  }

  my @entries = sort {
    ($file_opts->{$a}{order} // $a) cmp ($file_opts->{$b}{order} // $b)
  } @dirs, $scs->list_files;
  @entries or croak "Creating empty ZIP files unimplemented";

  my $zip;
  for my $entry (@entries) {
    my $data = $scs->read_entry($entry);
    utf8::upgrade($entry);

    if ($data isa Archive::SCS::DirIndex) {
      $file_opts->{$entry}{zip_opts} //= {
        ExtAttr => (0o40755 << 16) | 0x10, # Unix and DOS directory flags
        Method  => ZIP_CM_STORE,
        Name    => "$entry/",
      };
      $data = '';
    }

    my %zip_opts = (
      Efs        => 1,
      ExtAttr    => $IO::Compress::Zip::PARAMS{ExtAttr},
      Level      => Z_BEST_COMPRESSION,
      Method     => ZIP_CM_DEFLATE,
      Name       => $entry,
      Stream     => 0,
      TextFlag   => !!( $entry =~ m/\.(sii|sui|txt)\z/n ),
      ZipComment => $comment,
      ( $file_opts->{$entry}{zip_opts} // {} )->%*,
    );
    utf8::encode($zip_opts{Name});

    if ($zip) {
      $zip->newStream(%zip_opts);
    }
    else {
      $zip = IO::Compress::Zip->new("$zipname", %zip_opts)
        or die "IO::Compress::Zip failed: $ZipError\n";
    }

    $zip->write($data);
  }
  $zip->close;
}

1;


=head1 NAME

Archive::SCS::Zip - ZIP format handler

=head1 SYNOPSIS

  my $path = Path::Tiny->new('.../mod.scs');
  my $archive = Archive::SCS::Zip->new(path => $path)->mount;

  $archive->read_dir_tree;
  my @contents = sort $archive->list_dirs, $archive->list_files;

  my $hash = Archive::SCS::CityHash::cityhash64('manifest.sii');
  my $data = $archive->read_entry($hash);

=head1 DESCRIPTION

Represents an SCS archive stored in ZIP file format.

Hash values used with this module must be in the internal format
(currently, a 16-byte hex scalar in network byte order).

=head1 METHODS

=head2 entries

  $entry_hashes = $archive->entries;

=head2 is_mounted

  $bool = $archive->is_mounted;

=head2 handles_path

  $bool = Archive::SCS::Zip->handles_file($fh, $header);

=head2 list_dirs

  @directories = $archive->list_dirs;

=head2 list_files

  @files = $archive->list_files;

=head2 mount

  $archive = $archive->mount;

=head2 new

  $archive = Archive::SCS::Zip->new(file => $path_tiny);

=head2 path

  $path_tiny = $archive->path;

=head2 read_dir_tree

  $archive->read_dir_tree;

=head2 read_entry

  $data = $archive->read_entry($hash);

=head2 unmount

  $archive->unmount;

=head1 LIMITATIONS

Mounting an archive reads all contents into memory, which can be
inefficient for large ZIP files on slow disks.

Some invalid (and, rarely, valid) ZIP files that are accepted by
SCS's software cannot be mounted by this module. However, all plain
ZIP files that conform to the "appnote" spec should work just fine.

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2025 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

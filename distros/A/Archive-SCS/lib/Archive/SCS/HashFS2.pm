use v5.39.2;
use feature 'class';
no warnings 'experimental::class';

class Archive::SCS::HashFS2 0.03
  :isa( Archive::SCS::Mountable );

use Archive::SCS::CityHash qw(
  cityhash64
  cityhash64_int
  cityhash64_hex
  cityhash64_as_hex
  cityhash64_as_int
);
use Archive::SCS::DirIndex;
use Archive::SCS::TObj;

use Carp 'croak';
use Compress::Raw::Zlib 2.048 qw(Z_OK Z_STREAM_END);
use Fcntl 'SEEK_SET';
use List::Util 'first';
use Path::Tiny 0.011 'path';

our @CARP_NOT = qw( Archive::SCS );

my $MAGIC = 'SCS#';

field $file :param;
field $fh;

field %entries;
field @dirs;
field @files;

ADJUST {
  $file isa Path::Tiny && $file->exists or croak
    "Param file must be a valid Path::Tiny object";
}

my $zlib = do {
  my %opts = ( -ConsumeInput => 0 );
  my ($zlib, $status) = Compress::Raw::Zlib::Inflate->new( %opts );
  $zlib or die $status;
};


method file () {
  $file
}


sub handles_file ($class, $fh, $header) {
  $header =~ /^\Q$MAGIC\E\x02\x00/
}


method mount () {
  my $filename = $file->basename;
  $self->is_mounted and croak sprintf "%s: Already mounted", $filename;

  # Read HashFS file header

  open $fh, '<:raw', $file or croak "$filename: $!";
  read $fh, my $header, 0x34 or croak "$filename: $!";

  my ($magic, $version, $salt, $hash_method, $entry_count,
    $size1, $word_count2, $size2, $start1, $start2, $cert_start)
    = unpack 'A4 vv A4 V  VVV (QQQ)<', $header;

  $magic eq $MAGIC or croak
    "$filename: Not an SCS HashFS archive";
  $version == 2 or croak
    "$filename: HashFS version $version unsupported";
  $salt == 0 or croak
    "$filename: HashFS salt unsupported";
  $hash_method eq 'CITY' or croak
    "$filename: HashFS hash method '$hash_method' unsupported";

  # Read HashFS entry headers

  my $index1 = $self->_get_index( $start1, $size1, $entry_count * 0x10 );
  my $index2 = $self->_get_index( $start2, $size2, $word_count2 * 4 );

  for (my $j = 0; $j < $entry_count; ++$j) {

    # Index 1: hashes

    my ($hash, $index_offset, $parts, $flags1)
      = unpack '(QLSS)<', substr $index1, ($j * 0x10), 0x10;

    my $is_dir  = $flags1 & 1;
    my $preload = $flags1 & 4;

    # Index 2: headers

    my $data_part_header;
    my @parts;
    for (my $k = 0; $k < $parts; ++$k) {
      my ($offset, $offset_high, $kind )
        = unpack '(SCC)<', substr $index2, (($index_offset + $k) * 4), 4;

      $offset |= $offset_high << 0x10;
      my $size = (my $is_data_part = $kind & 0x80) ? 16
        : $kind == 1 ? 8
        : $kind == 2 ? 4
        : 0 or warnings::warnif io =>
          sprintf "Encountered index 2 part with unknown kind %02x", $kind;

      push @parts, {
        offset => $offset,
        kind => $kind,
        header => (my $header = substr $index2, ($offset * 4), $size),
      };
      $is_data_part and $data_part_header = $header;
    }

    my (
      $zsize, $zsize_high, $flags2,
      $usize, $usize_high, $flags3,
      $unknown7, $data_offset,
    )
    = unpack '(SCC SCC LL)<', $data_part_header;

    $zsize |= $zsize_high << 0x10;
    $usize |= $usize_high << 0x10;
    my $compression = $flags2 & 0xf0;
    my $is_tobj = $parts[0]->{kind} == 1;

    $entries{ cityhash64_int $hash } = {
      offset => $data_offset * 0x10,
      zsize => $zsize,
      size => $usize,
      compression => $compression,
      is_dir => $is_dir,
      is_tobj => $is_tobj,
      parts => \@parts,
      flags1 => $flags1,
      flags2 => $flags2,
      flags3 => $flags3,
    };

  }

  return $self;
}


method unmount () {
  close $fh or croak sprintf "%s: $!", $file->basename;
  $fh = undef;
}


method is_mounted () {
  !! $fh
}


method _get_index ($start, $size, $expected) {
  seek $fh, $start, SEEK_SET;
  my $length = read $fh, (my $raw), $size;

  defined $length or croak
    sprintf "Failed to read index at %06x: %s", $start, $!;
  $length == $size or croak
    sprintf "Read %i bytes from index at %06x, expected %i bytes",
    $length, $start, $size;

  my $status = $zlib->inflate( \$raw, \(my $index) );

  $status == Z_OK || $status == Z_STREAM_END or warnings::warnif io =>
    sprintf "Failed to inflate index at %06x: %s (%i)",
    $start, $zlib->msg // "", $status;
  $expected == length $index or warnings::warnif io =>
    sprintf "Inflated index at %06x to %i bytes, expected %i bytes",
    $start, length $index, $expected;

  $zlib->inflateReset;
  return $index;
}


method read_dir_tree (@roots) {
  my $root = first { exists $entries{ cityhash64 $_ } } @roots;
  defined $root or return;

  @dirs = ($root);
  @files = ();
  for (my $i = 0; $i < @dirs; ++$i) {
    my $dir = $dirs[$i];

    my $data = eval { $self->read_entry( cityhash64 $dir ) };
    $data isa Archive::SCS::DirIndex or croak
      sprintf "%s: Directory '%s' not found", __PACKAGE__, $dir;

    $dir .= '/' if length $dir;
    push @dirs,  map { "$dir$_" } $data->dirs;
    push @files, map { "$dir$_" } $data->files;
  }
}


method list_dirs () {
  return @dirs;
}


method list_files () {
  return @files;
}


method entry_meta ($hash) {
  return $entries{ $hash };
}


method read_entry ($hash) {
  $fh or croak sprintf "%s: Not mounted", $file->basename;

  my $entry = $entries{ $hash };

  seek $fh, $entry->{offset}, SEEK_SET;
  my $length = read $fh, my $data, $entry->{zsize};

  defined $length or croak
    sprintf "%s: %s", $file->basename, $!;
  $length == $entry->{zsize} or croak
    sprintf "%s: Read %i bytes, expected %i bytes",
    $file->basename, $length, $entry->{zsize};

  if ($entry->{compression} == 0x10) { # zlib
    my $status = $zlib->inflate( \(my $raw = $data), \$data );

    $status == Z_OK || $status == Z_STREAM_END
      or warnings::warnif io =>
      sprintf "%s: Inflation failed: %s (%i)",
      $file->basename, $zlib->msg // "", $status;

    $zlib->inflateReset;

    length $data == $entry->{size}
      or warnings::warnif io =>
      sprintf "%s: Inflated to %i bytes, expected %i bytes",
      $file->basename, length $data, $entry->{size};
  }

  if ($entry->{is_dir}) {
    # Parse directory listing
    my %dir_index;
    my $count = unpack "V", $data;
    my @sizes = unpack "C[$count]", substr $data, 4;
    my $offset = 4 + $count;
    for (my $i = 0; $i < $count; ++$i) {
      my $item = substr $data, $offset, $sizes[$i];
      $offset += $sizes[$i];
      if ('/' eq substr $item, 0, 1) {
        push $dir_index{dirs}->@*, substr $item, 1;
      }
      else {
        push $dir_index{files}->@*, $item;
      }
    }
    return Archive::SCS::DirIndex->new(%dir_index);
  }
  elsif ($entry->{is_tobj}) {
    return Archive::SCS::TObj->new(
      meta  => $entry,
      data  => $data,
    );
  }

  return $data;
}


method entries () {
  keys %entries
}


sub create_file ($pathname, $scs) {
  $scs isa Archive::SCS or die;

  # This subroutine is designed for internal testing. It probably won't
  # produce files that are compatible with SCS. All entry contents are
  # loaded into memory.

  my (@entries, %entries);
  push @entries, map { cityhash64 $_ } $scs->list_dirs, $scs->list_files;
  push @entries, map { cityhash64_hex $_ } $scs->list_orphans;
  push @entries, cityhash64 '' if eval { $scs->read_entry(''); 1 };
  $entries{$_} = {
    data => scalar eval { $scs->read_entry(cityhash64_as_hex $_) },
    kind => 0x80,
    flags1 => 0,
  } for @entries;
  @entries = grep { defined $entries{$_}->{data} } @entries;

  # Serialize directory listings
  for my $hash ( @entries ) {
    $entries{$hash}->{data} isa Archive::SCS::DirIndex or next;
    my @dirs  = map { "/$_" } $entries{$hash}->{data}->dirs;
    my @files = $entries{$hash}->{data}->files;
    my $count = @dirs + @files;
    $entries{$hash}->{kind} = 0x81;
    $entries{$hash}->{flags1} |= 1; # is_dir
    $entries{$hash}->{data} =
      (pack "V C[$count]", $count, map { length } @dirs, @files)
      . join '', @dirs, @files;
  }

  # Texture objects are unimplemented
  do { ... } for grep { $entries{$_}->{data} isa Archive::SCS::TObj } @entries;

  @entries = sort {
    ($entries{$b}->{flags1} & 4) <=> ($entries{$a}->{flags1} & 4)
    or $entries{$a}->{flags1} <=> $entries{$b}->{flags1}
    or ($entries{$b}->{kind} & 0x80) <=> ($entries{$a}->{kind} & 0x80)
    or $entries{$a}->{kind} <=> $entries{$b}->{kind}
  } @entries;

  # Prepare entry contents
  my $start = 0x60;
  my $offset = 0;
  for my $hash (@entries) {
    my $entry = $entries{$hash};

    $entry->{usize} = length $entry->{data};
    $entry->{compression} = 0;
    my $compressed = _compress_zlib($entry->{data});
    if (length $compressed < length $entry->{data}) {
      $entry->{data} = $compressed;
      $entry->{compression} = 0x10;
    }

    $entry->{offset} = $offset;
    my $size = length $entry->{data};
    $entry->{padding} = $size & 0xf ? 0x10 - $size & 0xf : 0;
    $offset += $size + $entry->{padding};
  }

  # Prepare indexes
  my $start1 = $start + $offset;
  my $index_offset = 0;
  for my $hash ( @entries ) {
    my $entry = $entries{$hash};

    my $part_offset = $index_offset / 4 + 1;
    my $part_offset_low  =  $part_offset & 0x00ffff;
    my $part_offset_high = ($part_offset & 0xff0000) >> 0x10;
    my $usize_low  =  $entry->{usize} & 0x00ffff;
    my $usize_high = ($entry->{usize} & 0xff0000) >> 0x10;
    my $zsize_low  =  length $entry->{data} & 0x00ffff;
    my $zsize_high = (length $entry->{data} & 0xff0000) >> 0x10;

    $entry->{index1} = pack '(QLSS)<',
      cityhash64_as_int $hash, $index_offset / 4, 1, $entry->{flags1};
    $entry->{index2} = pack '(SCC SCC SCC LL)<',
      $part_offset_low, $part_offset_high, $entry->{kind},
      $zsize_low, $zsize_high, $entry->{compression},
      $usize_low, $usize_high, 0,
      0, ($start + $entry->{offset}) / 0x10;

    $index_offset += length $entry->{index2};
  }

  my $index1 = join '', map { $entries{$_}->{index1} } sort @entries;
  my $index2 = join '', map { $entries{$_}->{index2} } @entries;
  $index1 = _compress_zlib($index1);
  $index2 = _compress_zlib($index2);
  my $padding1 = length $index1 & 0xf ? 0x10 - length $index1 & 0xf : 0;
  my $start2 = $start1 + (length $index1) + $padding1;

  # Write file with header
  my $header = pack 'A4 vv A4 V  VVV (QQQ)<',
    $MAGIC, 2, 0, 'CITY', (scalar @entries),
    (length $index1), (@entries * 5), (length $index2),
    $start1, $start2, 0;

  my $fh = (path $pathname)->openw_raw;
  print $fh $header, "\0" x ($start - length $header);
  print $fh $entries{$_}->{data}, "\0" x $entries{$_}->{padding} for @entries;
  print $fh $index1, "\0" x $padding1;
  print $fh $index2;
}


sub _compress_zlib ($data) {
  state $zlib_d = do {
    my %opts = ( -CRC32 => 1, -WindowBits => 15, -Level => 9 );
    Compress::Raw::Zlib::Deflate->new( %opts ) or die
  };
  state $rfc1950header = chr( 8 | 15-8 << 4 ) . chr( 26 | 0 << 5 | 3 << 6 );

  $zlib_d->deflate( \($data), \(my $compressed = '') );
  $zlib_d->flush( \$compressed );
  $zlib_d->deflateReset;
  return $rfc1950header . $compressed;
}


=head1 NAME

Archive::SCS::HashFS2 - SCS HashFS version 2 format handler

=head1 SYNOPSIS

  my $file = Path::Tiny->new('.../base_share.scs');
  my $archive = Archive::SCS::HashFS2->new(file => $file)->mount;

  $archive->read_dir_tree;
  my @contents = sort $archive->list_dirs, $archive->list_files;

  my $hash = Archive::SCS::CityHash::cityhash64('def/city.sii');
  my $data = $archive->read_entry($hash);

=head1 DESCRIPTION

Represents an SCS archive file encoded in HashFS version 2
(1.50 and later).

Hash values used with this module must be in the internal format
(currently, an 8-byte scalar PV in network byte order).

=head1 METHODS

=head2 entries

  $entry_hashes = $archive->entries;

=head2 file

  $path_tiny = $archive->file;

=head2 is_mounted

  $bool = $archive->is_mounted;

=head2 handles_file

  $bool = Archive::SCS::HashFS2->handles_file($fh, $header);

=head2 list_dirs

  @directories = $archive->list_dirs;

=head2 list_files

  @files = $archive->list_files;

=head2 mount

  $archive = $archive->mount;

=head2 new

  $archive = Archive::SCS::HashFS2->new(file => $path_tiny);

=head2 read_dir_tree

  $archive->read_dir_tree;

=head2 read_entry

  $data = $archive->read_entry($hash);

=head2 unmount

  $archive->unmount;

=head1 LIMITATIONS

Texture objects are currently unimplemented.

=head1 SEE ALSO

=over

=item * L<https://modding.scssoft.com/index.php?title=Documentation/Tools/Game_Archive_Packer&oldid=5546>

=back

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2024 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

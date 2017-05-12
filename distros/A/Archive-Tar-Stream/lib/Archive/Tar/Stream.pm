package Archive::Tar::Stream;

use 5.006;
use strict;
use warnings;

# this is pretty fixed by the format!
use constant BLOCKSIZE => 512;

# dependencies
use IO::File;
use IO::Handle;
use File::Temp;

# XXX - make this an OO attribute
our $VERBOSE = 0;

=head1 NAME

Archive::Tar::Stream - pure perl IO-friendly tar file management

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Archive::Tar::Stream grew from a requirement to process very large
archives containing email backups, where the IO hit for unpacking
a tar file, repacking parts of it, and then unlinking all the files
was prohibitive.

Archive::Tar::Stream takes two file handles, one purely for reads,
one purely for writes.  It does no seeking, it just unpacks
individual records from the input filehandle, and packs records
to the output filehandle.

This module does not attempt to do any file handle management or
compression for you.  External zcat and gzip are quite fast and
use separate cores.

    use Archive::Tar::Stream;

    my $ts = Archive::Tar::Stream->new(outfh => $fh);
    $ts->AddFile($name, -s $fh, $fh);

    # remove large non-jpeg files from a tar.gz
    my $infh = IO::File->new("zcat $infile |") || die "oops";
    my $outfh = IO::File->new("| gzip > $outfile") || die "double oops";
    my $ts = Archive::Tar::Stream->new(infh => $infh, outfh => $outfh);
    $ts->StreamCopy(sub {
        my ($header, $outpos, $fh) = @_;

        # we want all small files
        return 'KEEP' if $header->{size} < 64 * 1024;
        # and any other jpegs
        return 'KEEP' if $header->{name} =~ m/\.jpg$/i;

        # no, seriously
        return 'EDIT' unless $fh;

        return 'KEEP' if mimetype_of_filehandle($fh) eq 'image/jpeg';

        # ok, we don't want other big files
        return 'SKIP';
    });


=head1 SUBROUTINES/METHODS

=head2 new

    my $ts = Archive::Tar::Stream->new(%args);

Args:
   infh      - filehandle to read from
   outfh     - filehandle to write to
   inpos     - initial offset in infh
   outpos    - initial offset in outfh
   safe_copy - boolean.

Offsets are for informational purposes only, but can be
useful if you are tracking offsets of items within your
tar files separately.  All read and write functions
update these offsets.  If you don't provide offsets, they
will default to zero.

Safe Copy is the default - you have to explicitly turn it
off.  If Safe Copy is set, every file is first extracted
from the input filehandle and stored in a temporary file
before appending to the output filehandle.  This uses
slightly more IO, but guarantees that a truncated input
file will not corrupt the output file.

=cut

sub new {
  my $class = shift;
  my %args = @_;

  die "Useless to stream without a filehandle"
    unless ($args{infh} or $args{outfh});

  my $Self = bless {
    # defaults
    safe_copy => 1,
    inpos => 0,
    outpos => 0,
    %args
  }, ref($class) || $class;

  return $Self;
}

=head2 SafeCopy

   $ts->SafeCopy(0);

Toggle the "safe_copy" field mentioned above.

=cut

sub SafeCopy {
  my $Self = shift;
  if (@_) {
    $Self->{safe_copy} = shift;
  }
  return $Self->{safe_copy};
}

=head2 InPos

=head2 OutPos

Read only accessors for the internal position trackers for
the two tar streams.

=cut

sub InPos {
  my $Self = shift;
  return $Self->{inpos};
}

sub OutPos {
  my $Self = shift;
  return $Self->{outpos};
}

=head2 AddFile

Adds a file to the output filehandle, adding sensible
defaults for all the extra header fields.

Requires: outfh

   my $header = $ts->AddFile($name, $size, $fh, %extra);

See TARHEADER for documentation of the header fields.

You must provide 'size' due to the non-seeking nature of
this library, but "-s $fh" is usually fine.

Returns the complete header that was written.

=cut

sub AddFile {
  my $Self = shift;
  my $name = shift;
  my $size = shift;
  my $fh = shift;

  my $header = $Self->BlankHeader(@_);
  $header->{name} = $name;
  $header->{size} = $size;

  my $fullheader = $Self->WriteHeader($header);
  $Self->CopyFromFh($fh, $size);

  return $fullheader;
}

=head2 AddLink

   my $header = $ts->AddLink($name, $linkname, %extra);

Adds a symlink to the output filehandle.

See TARHEADER for documentation of the header fields.

Returns the complete header that was written.

=cut

sub AddLink {
  my $Self = shift;
  my $name = shift;
  my $linkname = shift;

  my $header = $Self->BlankHeader(@_);
  $header->{name} = $name;
  $header->{linkname} = $linkname;
  $header->{typeflag} = 2;

  return $Self->WriteHeader($header);
}

=head2 StreamCopy

Streams all records from the input filehandle and provides
an easy way to write them to the output filehandle.

Requires: infh
Optional: outfh - required if you return 'KEEP'

    $ts->StreamCopy(sub {
        my ($header, $outpos, $fh) = @_;
        # ...
        return 'KEEP';
    });

The chooser function can either return a single 'action' or
a tuple of action and a new header.

The action can be:
   KEEP - copy this file as is (possibly changed header) to output tar
   EDIT - re-call $Chooser with filehandle
   SKIP - skip over the file and call $Chooser on the next one
   EXIT - skip and also stop further processing

EDIT mode:

the file will be copied to a temporary file and the filehandle passed to
$Chooser.  It can truncate, rewrite, edit - whatever.  So long as it updates
$header->{size} and returns it as $newheader it's all good.

you don't have to change the file of course, it's also good just as a way to
view the contents of some files as you stream them.

A standard usage pattern looks like this:

  $ts->StreamCopy(sub {
    my ($header, $outpos, $fs) = @_;

    # simple checks
    return 'KEEP' if do_want($header);
    return 'SKIP' if dont_want($header);

    return 'EDIT' unless $fh;

    # checks that require a filehandle
  });

=cut

sub StreamCopy {
  my $Self = shift;
  my $Chooser = shift;

  while (my $header = $Self->ReadHeader()) {
    my $pos = $header->{_pos};
    my $oldsize = $header->{size};
    if ($Chooser) {
      my ($rc, $newheader) = $Chooser->($header, $Self->{outpos}, undef);

      my $TempFile;
      my $Edited;

      # positive code means read the file
      if ($rc eq 'EDIT') {
        $Edited = 1;
        $TempFile = $Self->CopyToTempFile($header->{size});
        # call chooser again with the contents
        ($rc, $newheader) = $Chooser->($newheader || $header, $Self->{outpos}, $TempFile);
        seek($TempFile, 0, 0);
      }

      # short circuit exit code
      return if $rc eq 'EXIT';

      # NOTE: even the size could have been changed if it's an edit!
      $header = $newheader if $newheader;

      if ($rc eq 'KEEP') {
        print "KEEP $header->{name} $pos/$Self->{outpos}\n" if $VERBOSE;
        if ($TempFile) {
          $Self->WriteHeader($header);
          $Self->CopyFromFh($TempFile, $header->{size});
        }
        # if the sizes don't match we just do a tempfile too
        elsif ($Self->{safe_copy} or ($oldsize != $header->{size})) {
          # guarantee safety by getting everything into a temporary file first
          $TempFile = $Self->CopyToTempFile($oldsize);
          $Self->WriteHeader($header);
          $Self->CopyFromFh($TempFile, $header->{size});
        }
        else {
          $Self->WriteHeader($header);
          $Self->CopyBytes($header->{size});
        }
      }

      # anything else means discard it
      elsif ($rc eq 'SKIP') {
        if ($TempFile) {
          print "LATE REJECT $header->{name} $pos/$Self->{outpos}\n" if $VERBOSE;
          # $TempFile already contains the bytes
        }
        else {
          print "DISCARD $header->{name} $pos/$Self->{outpos}\n" if $VERBOSE;
          $Self->DumpBytes($header->{size});
        }
      }

      else {
        die "Bogus response $rc from callback\n";
      }
    }
    else {
      print "PASSTHROUGH $header->{name} $Self->{outpos}\n" if $VERBOSE;

      if ($Self->{safe_copy}) {
        my $TempFile = $Self->CopyToTempFile($header->{size});
        $Self->WriteHeader($header);
        $Self->CopyFromFh($TempFile, $header->{size});
      }
      else {
        $Self->WriteHeader($header);
        $Self->CopyBytes($header->{size});
      }
    }
  }
}

=head2 ReadBlocks

Requires: infh

   my $raw = $ts->ReadBlocks($nblocks);

Reads 'n' blocks of 512 bytes from the input filehandle
and returns them as single scalar.

Returns undef at EOF on the input filehandle.  Any further
calls after undef is returned will die.  This is to avoid
naive programmers creating infinite loops.

nblocks is optional, and defaults to 1.

=cut

sub ReadBlocks {
  my $Self = shift;
  my $nblocks = shift || 1;
  unless ($Self->{infh}) {
    die "Attempt to read without input filehandle";
  }
  my $bytes = BLOCKSIZE * $nblocks;
  my $buf;
  my @result;
  while ($bytes > 0) {
    my $n = sysread($Self->{infh}, $buf, $bytes);
    unless ($n) {
      delete $Self->{infh};
      return if ($bytes == BLOCKSIZE * $nblocks); # nothing at EOF
      die "Failed to read full block at $Self->{inpos}";
    }
    $bytes -= $n;
    $Self->{inpos} += $n;
    push @result, $buf;
  }
  return join('', @result);
}

=head2 WriteBlocks

Requires: outfh

   my $pos = $ts->WriteBlocks($buffer, $nblocks);

Write blocks to the output filehandle.  If the buffer is too
short, it will be padded with zero bytes.  If it's too long,
it will be truncated.

nblocks is optional, and defaults to 1.

Returns the position of the header in the output stream.

=cut

sub WriteBlocks {
  my $Self = shift;
  my $string = shift;
  my $nblocks = shift || 1;

  my $bytes = BLOCKSIZE * $nblocks;

  unless ($Self->{outfh}) {
    die "Attempt to write without output filehandle";
  }
  my $pos = $Self->{outpos};

  # make sure we've got $nblocks times BLOCKSIZE bytes to write
  if (length($string) > $bytes) {
    $string = substr($string, 0, $bytes);
  }
  elsif (length($string) < $bytes) {
    $string .= "\0" x ($bytes - length($string));
  }

  while ($bytes > 0) {
    my $n = syswrite($Self->{outfh}, $string, $bytes, (BLOCKSIZE * $nblocks) - $bytes);
    unless ($n) {
      delete $Self->{outfh};
      die "Failed to write full block at $Self->{outpos}";
    }
    $bytes -= $n;
    $Self->{outpos} += $n;
  }

  return $pos;
}

=head2 ReadHeader

Requires: infh

   my $header = $ts->ReadHeader(%Opts);

Read a single 512 byte header off the input filehandle and
convert it to a TARHEADER format hashref.  Returns undef
at the end of the file.

If the option (SkipInvalid => 1) is passed, it will skip
over blocks which fail to pass the checksum test.

=cut

sub ReadHeader {
  my $Self = shift;
  my %Opts = @_;

  my ($pos, $header, $skipped) = (0, undef, 0);

  my $initialpos = $Self->{inpos};
  while (not $header) {
    $pos = $Self->{inpos};
    my $block = $Self->ReadBlocks();
    last unless $block;
    $header = $Self->ParseHeader($block);
    last if $header;
    last unless $Opts{SkipInvalid};
    $skipped++;
  }

  return unless $header;

  if ($skipped) {
    warn "Skipped $skipped blocks - invalid headers at $initialpos\n";
  }

  $header->{_pos} = $pos;
  $Self->{last_header} = $header;

  return $header;
}

=head2 WriteHeader

Requires: outfh

   my $newheader = $ts->WriteHeader($header);

Read a single 512 byte header off the input filehandle.

If the option (SkipInvalid => 1) is passed, it will skip
over blocks which fail to pass the checksum test.

Returns a copy of the header with _pos set to the position
in the output file.

=cut

sub WriteHeader {
  my $Self = shift;
  my $header = shift;

  my $block = $Self->CreateHeader($header);
  my $pos = $Self->WriteBlocks($block);
  return( {%$header, _pos => $pos} );
}

=head2 ParseHeader

   my $header = $ts->ParseHeader($block);

Parse a single block of raw bytes into a TARHEADER
format header.  $block must be exactly 512 bytes.

Returns undef if the block fails the checksum test.

=cut

sub ParseHeader {
  my $Self = shift;
  my $block = shift;

  # enforce length
  return unless(512 == length($block));

  # skip empty blocks
  return if substr($block, 0, 1) eq "\0";

  # unpack exactly 15 items from the block
  my @items = unpack("a100a8a8a8a12a12a8a1a100a8a32a32a8a8a155", $block);
  return unless (15 == @items);

  for (@items) {
    s/\0.*//; # strip from first null
  }

  my $chksum = oct($items[6]);
  # do checksum
  substr($block, 148, 8) = "        ";
  unless (unpack("%16C*", $block) == $chksum) {
    return;
  }

  my %header = (
    name => $items[0],
    mode => oct($items[1]),
    uid => oct($items[2]),
    gid => oct($items[3]),
    size => oct($items[4]),
    mtime => oct($items[5]),
    # checksum
    typeflag => $items[7],
    linkname => $items[8],
    # magic
    uname => $items[10],
    gname => $items[11],
    devmajor => oct($items[12]),
    devminor => oct($items[13]),
    prefix => $items[14],
  );

  return \%header;
}

=head2 BlankHeader

  my $header = $ts->BlankHeader(%extra);

Create a header with sensible defaults.  That means
time() for mtime, 0777 for mode, etc.

It then applies any 'extra' fields from %extra to
generate a final header.  Also validates the keys
in %extra to make sure they're all known keys.

=cut

sub BlankHeader {
  my $Self = shift;

  my %hash = (
    name => '',
    mode => 0777,
    uid => 0,
    gid => 0,
    size => 0,
    mtime => time(),
    typeflag => '0', # this is actually the STANDARD plain file format, phooey.  Not 'f' like Tar writes
    linkname => '',
    uname => '',
    gname => '',
    devmajor => 0,
    devminor => 0,
    prefix => '',
  );

  my %overrides = @_;
  foreach my $key (keys %overrides) {
    if (exists $hash{$key}) {
      $hash{$key} = $overrides{$key};
    }
    else {
      warn "invalid key $key for tar header\n";
    }
  }
  return \%hash;
}

=head2 CreateHeader

   my $block = $ts->CreateHeader($header);

Creates a 512 byte block from the TARHEADER format header.

=cut

sub CreateHeader {
  my $Self = shift;
  my $header = shift;

  my $block = pack("a100a8a8a8a12a12a8a1a100a8a32a32a8a8a155",
    $header->{name},
    sprintf("%07o", $header->{mode}),
    sprintf("%07o", $header->{uid}),
    sprintf("%07o", $header->{gid}),
    sprintf("%011o", $header->{size}),
    sprintf("%011o", $header->{mtime}),
    "        ",                  # chksum
    $header->{typeflag},
    $header->{linkname},
    "ustar  \0",                   # magic
    $header->{uname},
    $header->{gname},
    sprintf("%07o", $header->{devmajor}),
    sprintf("%07o", $header->{devminor}),
    $header->{prefix},
  );

  # calculate checksum
  my $checksum = sprintf("%06o", unpack("%16C*", $block));
  substr($block, 148, 8) = $checksum . "\0 ";

  # pad out to BLOCKSIZE characters
  if (length($block) < BLOCKSIZE) {
    $block .= "\0" x (BLOCKSIZE - length($block));
  }
  elsif (length($block) > BLOCKSIZE) {
    $block = substr($block, 0, BLOCKSIZE);
  }

  return $block;
}

=head2 CopyBytes

   $ts->CopyBytes($bytes);

Copies bytes from input to output filehandle, rounded up to
block size, so only whole blocks are actually copied.

=cut

sub CopyBytes {
  my $Self = shift;
  my $bytes = shift;
  my $buf;
  while ($bytes > 0) {
    my $n = int($bytes / BLOCKSIZE);
    $n = 16  if $n > 16;
    my $dump = $Self->ReadBlocks($n);
    $Self->WriteBlocks($dump, $n);
    $bytes -= length($dump);
  }
}

=head2 DumpBytes

   $ts->DumpBytes($bytes);

Just like CopyBytes, but it doesn't write anywhere.
Reads full blocks off the input filehandle, rounding
up to block size.

=cut

sub DumpBytes {
  my $Self = shift;
  my $bytes = shift;
  while ($bytes > 0) {
    my $n = int($bytes / BLOCKSIZE);
    $n = 16  if $n > 16;
    my $dump = $Self->ReadBlocks($n);
    $bytes -= length($dump);
  }
}

=head2 FinishTar

   $ts->FinishTar();

Writes 5 blocks of zero bytes to the output file, which makes
gnu tar happy that it's found the end of the file.

Don't use this if you're planning on concatenating multiple
files together.

=cut

sub FinishTar {
  my $Self = shift;
  $Self->WriteBlocks("\0" x 512);
  $Self->WriteBlocks("\0" x 512);
  $Self->WriteBlocks("\0" x 512);
  $Self->WriteBlocks("\0" x 512);
  $Self->WriteBlocks("\0" x 512);
}

=head2 CopyToTempFile

   my $fh = $ts->CopyToTempFile($header->{size});

Creates a temporary file (with File::Temp) and fills it with
the contents of the file on the input stream.  It reads
entire blocks, and discards the padding.

=cut

sub CopyToTempFile {
  my $Self = shift;
  my $bytes = shift;

  my $TempFile = File::Temp->new();
  while ($bytes > 0) {
    my $n = 1 + int(($bytes - 1) / BLOCKSIZE);
    $n = 16  if $n > 16;
    my $dump = $Self->ReadBlocks($n);
    $dump = substr($dump, 0, $bytes) if length($dump) > $bytes;
    $TempFile->print($dump);
    $bytes -= length($dump);
  }
  seek($TempFile, 0, 0);

  return $TempFile;
}

=head2 CopyFromFh

   $ts->CopyFromFh($fh, $header->{size});

Copies the contents of the filehandle to the output stream,
padding out to block size.

=cut

sub CopyFromFh {
  my $Self = shift;
  my $Fh = shift;
  my $bytes = shift;

  my $buf;
  while ($bytes > 0) {
    my $thistime = $bytes > BLOCKSIZE ? BLOCKSIZE : $bytes;
    my $block = '';
    while ($thistime) {
      my $n = sysread($Fh, $buf, $thistime);
      unless ($n) {
        die "Failed to read entire file, doh ($bytes remaining)!\n";
      }
      $thistime -= $n;
      $block .= $buf;
    }
    if (length($block) < BLOCKSIZE) {
      $block .= "\0" x (BLOCKSIZE - length($block));
    }
    $Self->WriteBlocks($block);
    $bytes -= BLOCKSIZE;
  }
}

=head1 TARHEADER format

This is the "BlankHeader" output, which includes all the fields
in a standard tar header:

  my %hash = (
    name => '',
    mode => 0777,
    uid => 0,
    gid => 0,
    size => 0,
    mtime => time(),
    typeflag => '0', # this is actually the STANDARD plain file format, phooey.  Not 'f' like Tar writes
    linkname => '',
    uname => '',
    gname => '',
    devmajor => 0,
    devminor => 0,
    prefix => '',
  );

You can read more about the tar header format produced by this
module on wikipedia:
L<http://en.wikipedia.org/wiki/Tar_(file_format)#UStar_format>
or here: L<http://www.mkssoftware.com/docs/man4/tar.4.asp>

Type flags:

  '0' Normal file
  (ASCII NUL) Normal file (now obsolete)
  '1' Hard link
  '2' Symbolic link
  '3' Character special
  '4' Block special
  '5' Directory
  '6' FIFO
  '7' Contiguous file

Obviously some module wrote 'f' as the type - I must have found
that during original testing.  That's bogus though.

=head1 AUTHOR

Bron Gondwana, C<< <perlcode at brong.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-archive-tar-stream
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Archive-Tar-Stream>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Archive::Tar::Stream


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Archive-Tar-Stream>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Archive-Tar-Stream>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Archive-Tar-Stream>

=item * Search CPAN

L<http://search.cpan.org/dist/Archive-Tar-Stream/>

=back


=head1 LATEST COPY

The latest copy of this code, including development branches,
can be found at

http://github.com/brong/Archive-Tar-Stream/


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Opera Software Australia Pty Limited

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Archive::Tar::Stream

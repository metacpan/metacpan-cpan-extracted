package Crypt::IDA::ShareFile;

use 5.008008;
use strict;
use warnings;
no warnings qw(redefine);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Carp;
use Fcntl qw(:DEFAULT :seek);
use Crypt::IDA qw(:all);

require Exporter;

my @export_default = qw( sf_calculate_chunk_sizes
			 sf_split sf_combine);
my @export_extras  = qw( sf_sprintf_filename );

our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
		    'all'     => [ @export_extras, @export_default ],
		    'default' => [ @export_default ],
		   );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.01';
our $classname="Crypt::IDA::ShareFile";

sub sf_sprintf_filename {
  my ($self,$class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  my ($format,$filename,$chunk,$share)=@_;

  $format=~s/\%f/$filename/;
  $format=~s/\%c/$chunk/;
  $format=~s/\%s/$share/;

  return $format;
}


# I could eliminate the use of closures below, but it makes for a
# convenient wrapper for handling byte order issues, and also for
# implementing the "dry run" option to sf_write_ida_header later.
sub sf_mk_file_istream {
  my ($self,$class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  my ($filename,$default_bytes_per_read)=@_;
  my ($fh,$eof)=(undef,0);

  # basic checking of args
  $default_bytes_per_read=1 unless defined($default_bytes_per_read);
  if (!defined($filename) or
      $default_bytes_per_read <= 0 or $default_bytes_per_read > 4 or
      int($default_bytes_per_read) != $default_bytes_per_read) {
    return undef;
  }
  die "using istream with >32 bits would lead to precision errors\n"
    if $default_bytes_per_read > 4;

  # try opening the file; use sysopen to match better with later sysreads
  return undef unless sysopen $fh,$filename,O_RDONLY;

  # Use closure/callback technique to provide an iterator for this file
  my $methods=
    {
     FILENAME => sub { $filename },
     FH => sub { $fh },
     READ => sub {
       # This reads words from the file in network (big-endian) byte
       # order, with zero padding in the least significant bytes. So,
       # for example, if we are using 2-byte chunks and the file
       # contains three bytes 0d fe 2d, then two reads on the file
       # will return the values 0dfe and 2d00. Return values are
       # integers or undef on eof.

       my ($override_bytes,$bytes_to_read);

       if ($override_bytes=shift) {
	 $bytes_to_read=$override_bytes;
	 die "Invalid bytes to read $bytes_to_read" if
	   int($bytes_to_read) != $bytes_to_read or $bytes_to_read <= 0;
	 die "using istream with >32 bits would lead to precision errors\n"
	   if $bytes_to_read > 4;
       } else {
	 $bytes_to_read=$default_bytes_per_read;
       }

       my $buf="";
       my $bytes_read=sysread $fh, $buf, $bytes_to_read;

       # There are three possible return value from sysread:
       # undef   there was a problem with the read (caller should check $!)
       # 0       no bytes read (eof)
       # >0      some bytes read (maybe fewer than we wanted, due to eof)
       return undef unless defined($bytes_read);
       if ($bytes_read == 0) {
	 $eof=1;
	 return undef;
       }

       # we don't need to set eof, but it might be useful for callers
       $eof=1 if ($bytes_read < $bytes_to_read);

       # Convert these bytes into a number (first byte is high byte )
       $buf=pack "a$bytes_to_read", $buf; # pad zeroes on right
       #$buf.="\0" x ($bytes_to_read - length $buf);

       # hex() can only handle values up to 32 bits, but perl scalars
       # can handle up to 64 bits (they're upgraded to floats
       # internally after 32 bits, though). I'm disabling this since I
       # don't think it's acceptable. The only upshot for the rest of
       # the program is that file size is now limited to 4Gb - 1 byte.
       my $val=0;
       #       while ($bytes_to_read > 4) {
       #	 $val=unpack "N", (substr $buf,0,4,"");
       #	 $bytes_to_read-=4;
       #	 $val <<= 32;
       #       }
       my $hex_format="H" . ($bytes_to_read * 2); # count nibbles
       return hex unpack $hex_format, $buf;

     },
     EOF   => sub { return $eof; },
     SEEK  => sub { seek $fh, shift, 0; },
     TELL  => sub { tell $fh; },
     CLOSE => sub { close $fh; }
    };
  return $methods;
}

sub sf_mk_file_ostream {
  my ($filename,$default_bytes_per_write)=@_;
  my ($fh,$eof)=(undef,0);

  # basic checking of args
  if (!defined($filename) or !defined($default_bytes_per_write) or
      $default_bytes_per_write <= 0) {
    return undef;
  }

  # try opening the file; use sysopen to match later sysreads
  return undef unless sysopen $fh,$filename,O_CREAT|O_TRUNC|O_WRONLY;

  my $methods=
    {
     FILENAME => sub { $filename },
     FH => sub { $fh },
     WRITE => sub {
       my $num=shift;

       my ($override_bytes,$bytes_to_write);

       if ($override_bytes=shift) {
	 $bytes_to_write=$override_bytes;
       } else {
	 $bytes_to_write=$default_bytes_per_write;
       }

       # Writing is a little easier than reading, but we have to take
       # care if the number passed is too large to fit in the
       # requested number of bytes.  If it's too large a warning will
       # be emitted and we discard any extra *high* bits.

       my $buf="";

       if ($num >= 256 ** $bytes_to_write) {
	 carp "ostream: Number too large. Discarded high bits.";
	 $num %= (256 ** ($bytes_to_write) - 1);
       }

       my $hex_format="H" . ($bytes_to_write * 2);
       $buf=pack $hex_format, sprintf "%0*x", $bytes_to_write*2, $num;
       syswrite $fh,$buf,$bytes_to_write;

     },
     EOF      => sub { 0; },
     FILENAME => sub { return $filename; },
     FLUSH    => sub { 0; },
     SEEK     => sub { seek $fh, shift, 0; },
     TELL     => sub { tell $fh; },
     CLOSE    => sub { close $fh; }
    };
  return $methods;		# be explicit
}

# Routines to read/write share file header
#
# header version 1
#
# bytes  name           value
# 2      magic          marker for "Share File" format; "SF" = {5346}
# 1      version        file format version = 1
# 1      options        options bits (see below)
# 1-2    k,quorum       quorum k-value (set both names on read)
# 1-2    s,security     security level s-value (width in bytes)
# var    chunk_start    absolute offset of chunk in file
# var    chunk_next     absolute offset of next chunk in file
# var    transform      transform matrix row
#
# The options bits are as follows:
#
# Bit    name           Settings
# 0      opt_large_k    Large (2-byte) k value?
# 1 	 opt_large_w    Large (2-byte) s value?
# 2 	 opt_final      Final chunk in file? (1=full file/final chunk)
# 3 	 opt_transform  Is transform data included?
#
# Note that the chunk_next field is 1 greater than the actual offset
# of the chunk end. In other words, the chunk ranges from the byte
# starting at chunk_start up to, but not including the byte at
# chunk_next. That's why it's called chunk_next rather than chunk_end.
#
# More on this: it might seem that it's ok to refuse to split a
# zero-length file, but if we're using this for backups, it's not a
# good idea to fail just because we don't like zero-length
# files. Also, splitting a zero-length file might be useful in some
# cases, since we might be interested in just creating and storing a
# transform matrix for later use, or maybe generating test cases or
# debugging a matrix inverse routine.

sub sf_read_ida_header {
  my $istream=shift;		  # assume istream is at start of file
  my $header_info={};   	  # values will be returned in this hash

  #warn "Reading header from istream " . ($istream->{FILENAME}->()) . "\n";

  # When calling this routine the caller can specify any
  # previously-read values for k, s, and so on and have us check the
  # values in the current header against these values for consistency.
  # This implies that all the shares we're being presented for
  # processing will combine to form a single chunk (or full file). If
  # this is the first share header being read, the following may be
  # undefined. We store any read values in the returned hash, so it's
  # up to the caller to take them out and pass them back to us when
  # reading the next header in the batch.
  my ($k,$w,$start,$next,$hdr)=@_;

  my $header_size=0;		  # we also send this back in hash

  # error reporting
  $header_info->{header_error}=0;   # 0=no error, 1=failure
  $header_info->{error_message}=""; # text of error

  # use a local subroutine to save the tedium of checking for eof and
  # doing conversion of input. Updates variables from our local scope
  # directly, so we don't need to pass them in or out. (Actually,
  # technically speaking, this creates an anonymous closure and
  # locally assigns a name to it for the current scope, but it's
  # pretty much the same thing as a local subroutine)
  local *read_some = sub {
    my ($bytes,$field,$conversion)=@_;
    my ($vec,$hex);
    if ($vec=$istream->{READ}->($bytes), defined($vec)) {
      if (defined ($conversion)) {
	if ($conversion eq "hex") {
	  $vec=sprintf "%*x", $bytes, $vec;
	} elsif ($conversion eq "dec") {
	  $vec=$vec;		# istream already returns integers
	} else {
	  die "Unknown format conversion (use undef, hex or dec)\n";
	}
      }
      $header_info->{$field}=$vec;
      $header_size+=$bytes;
      return 1;			# read some? got some.
    } else {
      $header_info->{error}++;
      $header_info->{error_message}="Premature end of stream\n";
      return 0;                 # read some? got none!
    }
  };

  # same idea for saving and reporting errors
  local *header_error = sub {
    $header_info->{error}++;
    $header_info->{error_message}=shift;
    return $header_info;
  };

  return $header_info unless read_some(2,"magic","hex");
  if ($header_info->{magic} ne "5346") {
    return header_error("This doesn't look like a share file\n" .
			"Magic is $header_info->{magic}\n");
  }

  return $header_info unless read_some(1,"version","dec");
  if ($header_info->{version} != 1) {
    return header_error("Don't know how to handle header version " .
			$header_info->{version} . "\n");
  }

  # read options field and split out into separate names for each bit
  return $header_info unless read_some(1,"options","dec");
  $header_info->{opt_large_k}   = ($header_info->{options} & 1);
  $header_info->{opt_large_w}   = ($header_info->{options} & 2) >> 1;
  $header_info->{opt_final}     = ($header_info->{options} & 4) >> 2;
  $header_info->{opt_transform} = ($header_info->{options} & 8) >> 3;

  # read k (regular or large variety) and check for consistency
  return $header_info unless
    read_some($header_info->{opt_large_k} ? 2 : 1 ,"k","dec");
  if (defined($k) and $k != $header_info->{k}) {
    return header_error("Inconsistent quorum value read from streams\n");
  } else {
    $header_info->{quorum} = $header_info->{k};
  }

  # read s (regular or large variety) and check for consistency
  return $header_info unless
    read_some($header_info->{opt_large_w} ? 2 : 1 ,"w","dec");
  if (defined($w) and $w != $header_info->{w}) {
    return 
      header_error("Inconsistent security values read from streams\n");
  } else {
    $header_info->{security} = $header_info->{w};
  }

  # File offsets can be of variable width, so we precede each offset
  # with a length field. For an offset of 0, we only have to store a
  # single byte of zero (since it takes zero bytes to store the value
  # zero). So while storing the start offset for a complete file is a
  # little bit wasteful (1 extra byte) compared to just using an
  # options bit to indicate that the share is a share for a complete
  # file and just storing the file length, it helps us to keep the
  # code simpler and less prone to errors by not having to treat full
  # files any differently than chunks.

  # Read in the chunk_start value. We'll re-use the offset_width key
  # for the chunk_next code, and then delete that key before pasing the
  # hash back to the caller (provided we don't run into errors).
  return $header_info unless read_some(1 ,"offset_width","dec");
  my $offset_width=$header_info->{offset_width};

  # Perl has no problem working with values as big as 2 ** 41 == 2Tb, but
  # we should probably impose a sane limit on file sizes here.
  if ($offset_width > 4) {
    return header_error("File size must be less than 4Gb!\n");
  }

  # now read in chunk_start and check that that it is a multiple of k * w
  my $colsize=$header_info->{k} * $header_info->{w};
  if ($offset_width) {
    return $header_info unless 
      read_some($offset_width ,"chunk_start","dec");
    if ($header_info->{chunk_start} % ($colsize)) {
      return header_error("Alignment error on chunk start offset\n");
    }
  } else {
    $header_info->{chunk_start}=0;
  }

  # and also that it's consistent with other shares
  if (defined($start) and $start != $header_info->{chunk_start}) {
    return header_error("Inconsistent chunk_start values read from streams\n");
  } else {
    $start=$header_info->{chunk_start};
  }

  # now get in the offset of the end of the chunk
  # Note that chunk_next must be a multiple of k * s
  return $header_info unless read_some(1 ,"offset_width","dec");
  $offset_width=$header_info->{offset_width};
  if ($offset_width > 4) {
    return header_error("File size must be less than 4Gb!\n");
  }
  if ($offset_width) {
    return $header_info unless 
      read_some($offset_width, "chunk_next","dec");
    if (!$header_info->{opt_final} and
	($header_info->{chunk_next}) % ($colsize)) {
      return header_error("Alignment error on non-final chunk end offset\n");
    }
  } else {
    # header end of 0 is strange, but we'll allow it for now and only
    # raise an error later if chunk_next <= chunk_start. Test code
    # should make sure that the program works correctly when
    # splitting/combining zero-length files.
    $header_info->{chunk_next}=0;
  }
  if (defined($next) and $next != $header_info->{chunk_next}) {
    return header_error("Inconsistent chunk_next values read from streams\n");
  } else {
    $next=$header_info->{chunk_next};
  }
  delete $header_info->{offset_width}; # caller doesn't need or want this

  # don't allow chunk_start > chunk_next, but allow chunk_start ==
  # chunk_next to represent an empty file
  if ($header_info->{chunk_start} > $header_info->{chunk_next}) {
    return header_error("Invalid chunk range: chunk_start > chunk_next\n");
  }

  # If transform data is included in the header, then read in a matrix
  # row of $k values of $s bytes apiece
  if ($header_info->{opt_transform}) {
    my $matrix_row=[];
    for my $i (1 .. $header_info->{k}) {
      return $header_info unless read_some($header_info->{w},"element");
      push @$matrix_row, $header_info->{element};
    }
    delete $header_info->{element};
    $header_info->{transform}=$matrix_row;
    #warn "Read transform row: [" . (join ", ", map
    #		  {sprintf("%02x",$_) } @{
    #	    $header_info->{transform}
    #  }) . "]\n";
  }

  # Now that we've read in all the header bytes, check that header
  # size is consistent with expectations.
  if (defined($hdr) and $hdr != $header_size) {
    return header_error("Inconsistent header sizes read from streams\n");
  } else {
    $header_info->{header_size}=$header_size;
  }

  return $header_info;
}

# When writing the header, we return number of header bytes written or
# zero in the event of some error.
sub sf_write_ida_header {
  my ($self,$class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  my %header_info=(
		   ostream => undef,
		   version => undef,
		   quorum => undef,
		   width => undef,
		   chunk_start => undef,
		   chunk_next => undef,
		   transform => undef,
		   opt_final => undef,
		   dry_run => 0,
		   @_
		  );
  my $header_size=0;		

  # save to local variables
  my ($ostream,$version,$k,$s,$chunk_start,$chunk_next,
      $transform,$opt_final,$dry_run) =
    map {
      exists($header_info{$_}) ? $header_info{$_} : undef
    } qw(ostream version quorum width chunk_start chunk_next transform
	 opt_final dry_run);

  return 0 unless defined($version) and $version == 1;
  return 0 unless defined($k) and defined($s) and
    defined($chunk_start) and defined($chunk_next);

  return 0 if defined($transform) and scalar(@$transform) != $k;

  if ($dry_run) {
    $ostream={
	      WRITE => sub { "do nothing" },
	     };
  }

  # magic
  $ostream->{WRITE}->(0x5346,2);
  $header_size += 2;

  # version
  $ostream->{WRITE}->($version,1);
  $header_size += 1;

  # Set up and write options byte
  my ($opt_large_k,$opt_large_w,$opt_transform);

  if ($k < 256) {
    $opt_large_k=0;
  } elsif ($k < 65536) {
    $opt_large_k=1;
  } else {
    return 0;
  }

  if ($s < 256) {
    $opt_large_w=0;
  } elsif ($s < 65536) {
    $opt_large_w=1;
  } else {
    return 0;
  }

  $opt_transform=(defined($transform) ? 1 : 0);

  $ostream->{WRITE}->((
		       ($opt_large_k)        |
		       ($opt_large_w)   << 1 |
		       ($opt_final)     << 2 |
		       ($opt_transform) << 3),
		      1);
  $header_size += 1;

  # write k and s values
  $ostream->{WRITE}->($k, $opt_large_k + 1);
  $header_size += $opt_large_k + 1;

  $ostream->{WRITE}->($s, $opt_large_w + 1);
  $header_size += $opt_large_w + 1;

  # chunk_start, chunk_next
  my ($width,$topval);

  if ($chunk_start == 0) {
    $ostream->{WRITE}->(0,1);
    $header_size += 1;
  } else {
    ($width,$topval)=(1,255);
    while ($chunk_start > $topval) {	# need another byte?
      ++$width; $topval = ($topval << 8) + 255;
    };
    $ostream->{WRITE}->($width,1);
    $ostream->{WRITE}->($chunk_start, $width);
    $header_size += 1 + $width;
  }

  if ($chunk_next == 0) {
    $ostream->{WRITE}->(0,1);
    $header_size += 1;
  } else {
    ($width,$topval)=(1,255);
    while ($chunk_next > $topval) {	# need another byte?
      ++$width; $topval = ($topval << 8) + 255;
    };
    $ostream->{WRITE}->($width,1);
    $ostream->{WRITE}->($chunk_next,$width);
    $header_size += 1 + $width;
  }

  if ($opt_transform) {
    foreach my $elem (@$transform) {
      $ostream->{WRITE}->($elem,$s);
      $header_size += $s;
    }
  }

  return $header_size;
}

# The following routine is exportable, since the caller may wish to
# know how large chunks are going to be before actually generating
# them. This could be useful, for example, if the caller needs to know
# how large the chunks are before deciding where to put them, or for
# trying out a different chunk size/strategy if the first one didn't
# suit their requirements.

sub sf_calculate_chunk_sizes {
  my ($self,$class);
  my %o;

  # despite the routine name, we'll calculate several different values
  # relating to each chunk:
  #  chunk_start
  #  chunk_next
  #  chunk_size   (chunk_next - chunk_start)
  #  file_size    (output file size, including header)
  #  opt_final    (is the last chunk in the file?)
  #  padding      (number of padding bytes in (final) chunk)
  #
  # We store these in a hash, and return a list of references to
  # hashes, one for each chunk.

  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  %o=(
      quorum => undef,
      width => undef,
      filename => undef,
      # misc options
      version => 1,		# header version
      save_transform => 1,	# whether to store transform in header
      # pick one method of calculating chunk size. The file is not
      # broken into chunks unless one of these is defined.
      n_chunks => undef,
      in_chunk_size => undef,
      out_chunk_size => undef,
      out_file_size => undef,
      @_,
      dry_run => 1,		# for call to sf_write_ida_header
     );
  my @chunks=();
  my ($hs,$cb,$cn,$cs,$nc);

  # Copy options into local variables
  my ($k, $w, $filename, $version, $save_transform,
      $n_chunks, $in_chunk_size, $out_chunk_size, $out_file_size) =
	map {
	  exists($o{$_}) ? $o{$_} : undef
	} qw(quorum width filename version save_transform
	     n_chunks in_chunk_size out_chunk_size out_file_size);

  # Check some input values (more checks later)
  unless ($w == 1 or $w == 2 or $w == 4) {
    carp "Invalid width value";
    return undef;
  }
  if ($k < 1 or $k >= 256 ** $w) {
    carp "quorum value out of range";
    return undef;
  }
  # leave version check until call to sf_write_ida_header

  # In all cases, we'll try to make all non-final chunks align to
  # $quorum x $width bytes. Whichever method is used, we need to know
  # what the total file size with/without padding will be.
  my $file_size=-s $filename;
  unless (defined($file_size)) {
    return undef;
  }
  my $padded_file_size=$file_size;
  while ($padded_file_size % ($k * $w)) {
    ++$padded_file_size;	# not very efficient, but it is easy
  }

  # We'll pass %o onto sf_write_ida_header later, so we need a dummy
  # value for transform if "save_transform" is set.
  if (defined($save_transform) and $save_transform) {
    #warn "making dummy transform array\n";
    $o{"transform"} = [ (0) x ($k * $w) ];
  } else {
    #warn "save_transform not defined\n";
    $o{"transform"} = undef;
  }

  # Check that no more than one chunking method is set
  my $defined_methods=0;
  ++$defined_methods if (defined($n_chunks));
  ++$defined_methods if (defined($in_chunk_size));
  ++$defined_methods if (defined($out_chunk_size));
  ++$defined_methods if (defined($out_file_size));

  if ($defined_methods > 1) {
    carp "please select at most one method of calculating chunk sizes";
    return undef;
  } elsif ($file_size == 0 or $defined_methods == 0) {
    # we can also handle the special case where $file_size == 0 here
    unless ($file_size) {
      carp "warning: zero-sized file $filename; will use single chunk";
    }
    ($cb,$cn,$cs)=(0,$file_size,$file_size);
    $o{"chunk_start"} = $cb;
    $o{"chunk_next"}  = $cn;
    $hs=sf_write_ida_header(%o);
    unless (defined ($hs) and $hs > 0) {
      carp "Something wrong with header options.";
      return undef;
    }
    #warn "Single chunk\n";
    return ( {
	      "chunk_start" => $cb,
	      "chunk_next"  => $cn,
	      "chunk_size"  => $cs,
	      "file_size"   => $hs + $cs,
	      "opt_final"   => 1,
	      "padding"     => $padded_file_size - $file_size,
	     } );
  }

  # on to the various multi-chunk methods ...
  if (defined($n_chunks)) {
    unless ($n_chunks > 0) {
      carp "Number of chunks must be greater than zero!";
      return undef;
    }
    my $max_n_chunks=$padded_file_size / ($k * $w);
    if ( $n_chunks > $max_n_chunks ) {
      carp "File is too small for n_chunks=$n_chunks; using " .
	"$max_n_chunks instead";
      $n_chunks=$max_n_chunks;
    }
    # creating chunks of exactly the same size may not be possible
    # since we have to round to matrix column size. Rounding down
    # means we'll end up with a larger chunk at the end, while
    # rounding up means we might produce some zero-sized chunks at the
    # end. The former option is most likely the Right Thing. Even
    # though it might be nice to make the first chunk bigger, it's
    # easier to code if we let the last chunk take up any excess. To
    # do this we can round the chunk size up to the nearest multiple
    # of $n_chunks first, then round down to the nearest column
    # size. We should end up with a non-zero value since we've imposed
    # a limit on the maximum size of $n_chunks above.
    $cs  = int(($padded_file_size + $n_chunks - 1) / $n_chunks);
    $cs -= $cs % ($k * $w);
    die "Got chunk size of zero with padded file_size $padded_file_size," .
      " n_chunks=$n_chunks (this shouldn't happen)\n" unless $cs;
    ($cb,$cn)=(0,$cs);
    for my $i (0 .. $n_chunks - 2) { # all pre-final chunks
      $o{"chunk_start"} = $cb;
      $o{"chunk_next"}  = $cn;
      $hs=sf_write_ida_header(%o);
      unless (defined ($hs) and $hs > 0) {
	carp "Something wrong with header options for chunk $i.";
	return undef;
      }
      #warn "Chunk $cb-$cn, size $cs, fs=$hs + $cs, final=0\n";
      push @chunks, {
		     "chunk_start" => $cb,
		     "chunk_next"  => $cn,
		     "chunk_size"  => $cs,
		     "file_size"   => $hs + $cs,
		     "opt_final"   => 0,
		     "padding"     => 0,
		    };
      $cb += $cs;
      $cn += $cs;
    }
    # final chunk; need to do this separately since we need to pass
    # correct values for chunk range to accurately calculate the
    # header size (ie, a rough figure won't do if chunk_next is close
    # to 256 ** width)
    $o{"chunk_start"} = $cb;
    $o{"chunk_next"}  = $file_size; # without padding
    $hs=sf_write_ida_header(%o);
      push @chunks, {
		     "chunk_start" => $cb,
		     "chunk_next"  => $file_size,
		     "chunk_size"  => $file_size - $cb,
		     "file_size"   => $hs + $padded_file_size,
		     "opt_final"   => 1,
		     "padding"     => $padded_file_size - $file_size,
		    };
    #warn "Last chunk: $cb-$padded_file_size, size ".
    #  ($padded_file_size - $cb) . ", fs=$hs + $padded_file_size - $cb, ".
    #	"final=1\n";

    die "last chunk starts beyond eof (this shouldn't happen)\n" if
      ($cb >= $padded_file_size);
    # ... and return the array
    return @chunks;
  } elsif (defined($in_chunk_size) or defined($out_chunk_size)) {
    # this can actually be rolled into the above n_chunks method
    carp "not implemented yet";
    return undef;
  } elsif (defined($out_chunk_size)) {
    carp "not implemented yet";
    return undef;
  } else {
    1;
    #die "problem deciding chunking method (shouldn't get here)\n";
  }
}

sub sf_split {
  my ($self,$class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  my %o=(
	 # We'll be passing this hash on directly to ida_split later on
	 # so option names here will overlap with the option names needed
	 # by that routine. The same applies to option names in
	 # sf_write_ida_header.
	 shares => undef,
	 quorum => undef,
	 width => 1,
	 filename => undef,
	 # supply a key, a matrix or neither
	 key => undef,
	 matrix => undef,
	 # misc options
	 version => 1,		# header version
	 rand => "/dev/urandom",
	 bufsize => 4096,
	 save_transform => 1,
	 # pick at most one chunking method. The file is not broken into
	 # chunks unless one of these is defined.
	 n_chunks => undef,
	 in_chunk_size => undef,
	 out_chunk_size => undef,
	 out_file_size => undef,
	 # allow creation of a subset of shares, chunks
	 sharelist => undef,	# [ $row1, $row2, ... ]
	 chunklist => undef,	# [ $chunk1, $chunk2, ... ]
	 # specify pattern to use for share filenames
	 filespec => undef,	# default value set later on
	 @_,
	 # The file format uses network (big-endian) byte order, so store
	 # this info after all the user-supplied options have been read
	 # in
	 inorder => 2,
	 outorder => 2,
	 opt_final => 0,
	);

  my (@chunks, @results);

  # Copy options into local variables
  my ($n, $k, $w, $filename,
      $key, $mat, $version,
      $rng, $bufsize,
      $save_transform,
      $n_chunks, $in_chunk_size, $out_chunk_size, $out_file_size,
      $sharelist, $chunklist,$filespec
     ) =
    map {
      exists($o{$_}) ? $o{$_} : undef
    } qw(
      shares quorum width filename
      key matrix version
      rand bufsize save_transform
      n_chunks in_chunk_size out_chunk_size out_file_size
      sharelist chunklist filespec);


  # Pass all options to sf_calculate_chunk_sizes and let it figure out
  # all the details for each chunk.
  @chunks=sf_calculate_chunk_sizes(%o);
  unless (defined($chunks[0])) {
    carp "Problem calculating chunk sizes from given options";
    return undef;
  }

  # Now that we know how many chunks there are, we can check that the
  # filespec mentions "%c" for the chunk number. The "%s" specifier is
  # also always required. Also, we can set up different default
  # filespecs for single-chunk and multi-chunk splits.
  if (defined($filespec)) {
    unless ($filespec =~ /\%s/) {
      carp "filespec must include \%s for share number";
      return undef;
    }
    unless (scalar (@chunks) == 1 or $filespec =~ /\%c/) {
      carp "filespec must include \%c for multi-chunk splits";
      return undef;
    }
  } else {
    $filespec=(scalar (@chunks) == 1) ? '%f-%s.sf' : '%f-%c-%s.sf';
  }

  # check the sharelist and chunklist arrays to weed out dups and
  # invalid share/chunk numbers. If we weren't passed a value for one
  # or the other, then we'll default to processing all shares/all
  # chunks.
  if (defined($sharelist)) {
    ida_check_list($sharelist,"share",0,$n-1);
    unless (scalar(@$sharelist) == $n) {
      carp "sharelist does not contain n=$n share numbers; aborting";
      return undef;
    }
  } else {
    $sharelist=[ 0 .. $n - 1 ];
  }

  if (defined($chunklist)) {
    ida_check_list($chunklist,"chunk",0,scalar(@chunks)-1);
    unless (scalar(@$chunklist) > 0) {
      carp "chunklist does not contain any valid chunk numbers; aborting";
      return undef;
    }
  } else {
    $chunklist=[ 0 .. scalar(@chunks) - 1 ];
  }

  # Now loop through each chunk that we've been asked to create
  for my $i (@$chunklist) {

    my $chunk=$chunks[$i];
    my @sharefiles=();		# we return a list of files in each
                                # chunk at the end of the routine.

    # Unpack chunk details into local variables. Not all these
    # variables are needed, but we might as well unpack them anyway.
    my ($chunk_start,$chunk_next,$chunk_size,$file_size,
	$opt_final,$padding) =
	  map { $chunk->{$_} }
	    qw (
		chunk_start chunk_next chunk_size file_size
		opt_final padding
	       );

    # We should only really need to open the input file once,
    # regardless of how many chunks/shares we're creating. But since
    # we're using Crypt::IDA's file reader, and it allows us to seek
    # to the start of the chunk when we create the callback, it's
    # easier to (re-)open and seek once per chunk.
    my $filler=fill_from_file($filename, $k * $w, $chunk_start);
    unless (defined($filler)) {
      carp "Failed to open input file: $!";
      return undef;
    }

    # Unfortunately, creating a new share isn't quite as simple as
    # calling ida_split with all our parameters. The job is
    # complicated by the fact that we need to store both the share
    # data and (usually) a row of the transform matrix. In the case
    # where a new transform matrix would be created by the call to
    # ida_split, then we would have to wait until it returned before
    # writing the transform rows for it to each share header. But that
    # would require that we write the header after the share, which
    # isn't a very nice solution. Also, we'd still have to calculate
    # the correct amount of space to allocate for the header before
    # setting up the empty handlers, which is also a bit messy.
    #
    # The simplest solution is to examine the key/matrix and
    # save_transform options we've been given and call the
    # ida_generate_key and/or ida_key_to_matrix routines ourselves, if
    # necessary. Then we will know which transform rows to save with
    # each share and we can pass our generated key/matrix directly on
    # to ida_split.

    if (ida_check_transform_opts(%o)) {
      carp "Can't proceed due to problem with transform options";
      return undef;
    }
    unless (defined($mat)) {
      if (defined ($key)) {
	if (ida_check_key($k,$n,$w,$key)) {
	  carp "Problem with supplied key";
	  return undef;
	}
      } else {
	$rng=ida_rng_init($w,$rng);	# swap string for closure
	unless (defined($rng)) {
	  carp "Failed to initialise random number generator";
	  return undef;
	}
	$key=ida_generate_key($k,$n,$w,$rng);
      }

      # now generate matrix from key
      $mat=ida_key_to_matrix( "quorum"      => $k,
			      "shares"      => $n,
			      "width"       => $w,
			      "sharelist"   => $sharelist,
			      "key"         => $key,
			      "skipchecks?" => 0);
      unless (defined($mat)) {
	carp "bad return value from ida_key_to_matrix";
	return undef;
      }
      $o{"matrix"}=$mat;	# stash new matrix
      $o{"key"}=undef;		# and undefine key (if any)
    }

    $o{"chunk_start"}= $chunk_start;  # same values for all shares
    $o{"chunk_next"} = $chunk_next;   # in this chunk
    $o{"opt_final"}  = $opt_final;
    #warn "Going to create chunk $chunk_start - $chunk_next (final $opt_final)\n";
    my $emptiers=[];
    for my $j (@$sharelist) {
      # For opening output files, we're responsible for writing the file
      # header, so we first make one of our ostreams, write the header,
      # then create a new empty_to_fh handler which will seek past the
      # header.
      my $sharename   = sf_sprintf_filename($filespec, $filename, $i, $j);
      unlink $sharename;	# remove any existing file
      my $sharestream = sf_mk_file_ostream($sharename, $w);
      unless (defined($sharestream)) {
	carp "Failed to create share file (chunk $i, share $j): $!";
	return undef;
      }
      my $hs=sf_write_ida_header(%o, ostream => $sharestream,
				 transform => [$mat->getvals($j,0,$k)]);
      unless (defined ($hs) and $hs > 0) {
	carp "Problem writing header for share (chunk $i, share $j)";
	return undef;
      }
      unless ($hs + $chunk_size == $file_size) {
	carp "file size mismatch ($i,$j) (this shouldn't happen)";
	carp "hs=$hs; chunk_size=$chunk_size; file_size=$file_size; pad=$padding";
	return undef;
      }
      my $emptier=empty_to_fh($sharestream->{"FH"}->(),$hs);
      push @$emptiers, $emptier;
      push @sharefiles, $sharename;
    }

    # Now that we've written the headers and set up the fill and empty
    # handlers, we only need to add details of the filler and
    # emptiers, then pass the entire options array on to ida_split to
    # create all shares for this chunk.
    $o{"filler"}   = $filler;
    $o{"emptiers"} = $emptiers;
    my ($key,$mat,$bytes)=ida_split(%o);

    # check for success, then save the results
    unless (defined($mat)) {
      carp "detected failure in ida_split; quitting";
      return undef;
    }
    push @results, [$key,$mat,$bytes, @sharefiles];

    # Perl should handle closing file handles for us once they go out
    # of scope and they're destroyed.

  }

  return @results;

}

sub sf_combine {

  # Combining files is complicated by two issues:
  #
  # * Given a list of files, we don't know anything about which files
  #   are supposed to belong to which chunk, so we would need to read
  #   through the file headers to determine the chunk_start,
  #   chunk_next values and use these to group the files.
  # * The file format allows for omission of the transform data, so we
  #   have to support having a key or transform matrix passed to us
  #   for each chunk.
  #
  # The simplest solution to the first problem is to place
  # responsibilty for identifying which files go together to form a
  # complete chunk on the user. This should not be too onerous a task,
  # since the sf_split routine allows the caller to store the share
  # number and chunk number in each output filename. It also returns
  # the names of the sharefiles for each chunk.
  #
  # That still leaves the problem of passing in a key or transform
  # matrix and a row list (to associate each share with a particular
  # row of the transform matrix). The problem isn't so much with being
  # able to support this method of operation (since ida_combine
  # already supports it), but with coming up with a calling convention
  # which won't be overly complex.
  #
  # Note that the this issue of the key/transform matrix being stored
  # outside the file highlights a potential problem with the file
  # format. Namely, if the transform data isn't stored in the file,
  # there's nothing within the file itself to indicate which row of
  # the transform matrix the share corresponds to. The filename itself
  # should provide this data, but if the contents of the file are
  # transmitted and the filename gets lost or changed, then there's a
  # possibility that the person combining the files will have
  # problems. There are two solutions to this: either the split
  # routine incorporates a share number within the header, or it's up
  # to the central issuing authority (Dealer) to, eg, store a hash of
  # each share and the associated row number for that share in the
  # same database it uses to store the key/transform matrix. Partly
  # because there are solutions, but mostly because I don't think that
  # the centrally-stored key/transform matrix idea is a very good one,
  # I don't feel inclined to change the current file format to include
  # row numbers in the header. At least not for the time being.
  #
  # Getting back to the issue at hand, namely the calling convention,
  # it seems that the best solution would be keep the options here
  # as close as possible to the ones accepted by ida_combine. The two
  # differences are:
  #
  # * instead of fillers and an emptier, we handle infiles and an
  #   outfile
  #
  # * since we might need to handle multiple chunks, but ida_combine
  #   only operates on a single set of shares, we should either accept
  #   an array of options (one for each chunk) or only operate on
  #   one chunk at a time. I'll go with the latter option since it
  #   doesn't place much extra work (if any) on the calling program
  #   and it probably makes it less error-prone since the user doesn't
  #   have to remember to pass an array rather than a list of options.
  #   Having finer granularity might help the caller with regards to
  #   handling return values and error returns, too.
  #
  # That said, on with the code ...

  my ($self,$class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  my %o=
    (
     # Options for source, sinks. These are the only required options.
     infiles => undef,		# [ $file1, $file2, ... ]
     outfile => undef,		# "filename"
     # If specified, the following must agree with the values stored
     # in the sharefiles. There's normally no need to set these.
     quorum => undef,
     width => undef,
     # If matrix is set, it must be a pre-inverted matrix, and it will
     # override any values read in from the file (along with emitting
     # a warning if both are found).  Alternatively, if a key is
     # supplied, the 'shares' and 'sharelist' options must also be
     # given. A 'key' will also override any values stored in the file
     # and also emit a warning if both are found.
     key => undef,
     matrix => undef,
     shares => undef,		# only needed if key supplied
     sharelist => undef,	# only needed if key supplied
     # misc options
     bufsize => 4096,
     @_,
     # byte order options (can't be overriden)
     inorder => 2,
     outorder => 2,
     # no point in accepting a user-supplied value of $bytes, since we
     # determine this from the share headers
     bytes => undef,
    );

  # copy all options into local variables
  my ($k,$n,$w,$key,$mat,$shares,$sharelist,$infiles,$outfile,
      $bufsize,$inorder,$outorder,$bytes) =
	map {
	  exists($o{$_}) ? $o{$_} : undef;
	} qw(quorum shares width key matrix shares sharelist
	     infiles outfile  bufsize inorder outorder bytes);
  my $fillers=[];

  # Check options
  if (defined($key) and defined($mat)) {
    carp "Conflicting key/matrix options given.";
    return undef;
  }
  if (defined($key) and !(defined($shares) and defined($sharelist))) {
    carp "key option also requires shares and sharelist options.";
    return undef;
  }

  # Weed out any duplicate input file names. If duplicates are found,
  # and the sharelist option is given, then some of the share numbers
  # in that list will probably now be wrong. Rather than trying to fix
  # up the numbers, we'll take the easy way out and simply report it
  # as an error and return.
  unless (scalar(@$infiles)) {
    carp "No input files to process; aborting.";
    return undef;
  }
  my %saw_file;
  my $new_filelist=[];
  foreach my $infile (@$infiles) {
    if (exists($saw_file{$infile})) {
      carp "Ignoring duplicate input file: $infile";
    } else {
      if (defined ($sharelist)) {
	carp "Duplicate file invalidates supplied sharelist; aborting";
	return undef;
      }
      $saw_file{$infile} = 1;
      push @$new_filelist, $infile;
    }
  }
  $infiles=$new_filelist;

  # If k-value is given, only check it after we've de-duped the input
  # file list.
  if (defined($k) and scalar(@$infiles) < $k) {
    carp "For given quorum value $k, I need (at least) $k infiles";
    return undef;
  }

  # We won't build the transform matrix until later (or not at all if
  # we're supplied with a matrix or key option). We'll store the
  # values returned from sf_read_ida_header in a regular array and
  # then convert them into a Math::FastGF2::Matrix object when we come
  # to calculating the inverse matrix.
  my @matrix=();

  # Read in headers from each infile and create a new filler for each
  my ($nshares, $header_info, $header_size)=(0,undef,undef);
  my ($chunk_start,$chunk_next)=(undef,undef);
  foreach my $infile (@$infiles) {

    my $istream=sf_mk_file_istream($infile,1);
    unless (defined($istream)) {
      carp "Problem opening input file $infile: $!";
      return undef;
    }

    # It's fine for some of these values to be undefined the first
    # time around. However if they were specified as options and
    # the first header read in doesn't match, or if shares have
    # inconsistent values then read_ida_header will detect this.
    $header_info=sf_read_ida_header($istream,$k,$w,$chunk_start,
				    $chunk_next,$header_size);

    if ($header_info->{error}) {
      carp $header_info->{error_message};
      return undef;
    }

    # Store values to check for consistency across all shares
    $k           = $header_info->{k};
    $w           = $header_info->{w};
    $header_size = $header_info->{header_size};
    $chunk_start = $header_info->{chunk_start};
    $chunk_next  = $header_info->{chunk_next};

    if (++$nshares <= $k) {
      if ($header_info->{opt_transform}) {
	if (defined($mat)) {
	  carp "Ignoring file transform data (overriden by matrix option)";
	} elsif (defined($key)) {
	  carp "Ignoring file transform data (overriden by key option)";
	} else {
	  #warn "Adding new transform row: [" . (join ", ", map
	  #	  {sprintf("%02x",$_) } @{
	  #	    $header_info->{transform}
	  #  }) . "]\n";
	  push @matrix, $header_info->{transform};
	}
      } else {
	unless (defined ($mat) or defined($key)) {
	  carp "Share file contains no transform data and no " .
	    "key/matrix options were supplied.";
	  return undef;
	}
      }
    } else {
      carp "Redundant share(s) detected and ignored";
      last;
    }

    #warn "Filler to skip $header_size bytes\n";
    push @$fillers, fill_from_file($infile,$k * $w, $header_size);
  }

  # Now that the header has been read in and all the streams agree on
  # $k and $w, we proceed to build the inverse matrix unless we've
  # been supplied with a key or (pre-inverted) matrix.

  # first make sure we have k valid shares to combine
  unless ($nshares >= $k) {
    carp "Wrong number of shares to combine (have $nshares, want $k)";
    return undef;
  }

  unless (defined($key) or defined($mat)) {
    #warn "Trying to create combine matrix with k=$k, w=$w\n";
    $mat=Math::FastGF2::Matrix->new(
				    rows  => $k,
				    cols  => $k,
				    width => $w,
				    org   => "rowwise",
				   );
    my @vals=();
    map { push @vals, @$_ } @matrix;
    #warn "matrix is [" . (join ", ", map
    #			  {sprintf("%02x",$_) } @vals) . "] (" .
    #     scalar(@vals) . " values)\n";
    $mat->setvals(0,0, \@vals, $inorder);
    $mat=$mat->invert();
    unless (defined($mat)) {
      carp "Failed to invert matrix!";
      return undef;
    }
    #@vals=$mat->getvals(0,0,$k * $k);
    #warn "inverse is [" . (join ", ", map
    #			  {sprintf("%02x",$_) } @vals) . "] (" .
    #      scalar(@vals) . " values)\n";

  }

  $bytes=$chunk_next - $chunk_start;
  if ($bytes % ($k * $w)) {
    unless ($header_info->{"opt_final"}) {
      carp "Invalid: non-final share is not a multiple of quorum x width";
      return undef;
    }
    $bytes += (($k * $w) - $bytes % ($k * $w));
  }

  # we leave creating/opening the output file until relatively late
  # since we need to know what offset to seek to in it, and we only
  # know that when we've examined the sharefile headers
  my $emptier=empty_to_file($outfile,undef,$chunk_start);

  # Need to update %o before calling ida_combine
  $o{"emptier"} = $emptier;	# leave error-checking to ida_combine
  $o{"fillers"} = $fillers;
  $o{"matrix"}  = $mat     unless (defined($key));
  $o{"quorum"}  = $k;
  $o{"width"}   = $w;
  $o{"bytes"}   = $bytes;

  my $output_bytes=ida_combine(%o);

  return undef unless defined($output_bytes);

  if ($header_info->{opt_final}) {
    #warn "Truncating output file to $header_info->{chunk_next} bytes\n";
    truncate $outfile, $header_info->{chunk_next};
  }

  return $output_bytes;
}

1;

__END__

=head1 NAME

Crypt::IDA::ShareFile - Archive file format for Crypt::IDA module

=head1 SYNOPSIS

  use Crypt::IDA::ShareFile ":default";
 
  @list  = sf_split( ... );
  $bytes = sf_combine ( ... );

=head1 DESCRIPTION

This module implements a file format for creating, storing and
distributing shares created with Crypt::IDA. Created files contain
share data and (by default) the corresponding transform matrix row
used to split the input file. This means that share files are (again,
by default) stand-alone and may recombined later without needing any
other stored key or the involvement of the original issuer.

In addition to creating a number of shares, the module can also handle
breaking the input file into several chunks before processing, in a
way similar to multi-volume PKZIP, ARJ or RAR archives. Each of the
chunks may be split into shares using a different transform matrix.
Individual groups of chunks may be re-assembled independently, as they
are collected, and the quorum for each is satisfied.

=head2 EXPORT

No methods are exported by default. All methods may be called by
prefixing the method names with the module name, eg:

 $foo=Crypt::IDA::ShareFile::sf_split(...)

Alternatively, routines can be exported by adding ":default" to the
"use" line, in which case the routine names do not need to be prefixed
with the module name, ie:

  use Crypt::IDA::ShareFile ":default";
 
  $foo=Crypt::IDA::ShareFile::sf_split(...)
  # ...

Some extra ancillary routines can also be exported with the ":extras"
(just the extras) or ":all" (":extras" plus ":default") parameters to
the use line. See the section L<ANCILLARY ROUTINES> for details.

=head1 SPLIT OPERATION

The template for a call to C<sf_split>, showing all possible inputs
and default values, is as follows:

 @list=sf_split(
	 shares => undef,
	 quorum => undef,
	 width => 1,
	 filename => undef,
	 # supply a key, a matrix or neither
	 key => undef,
	 matrix => undef,
	 # misc options
	 version => 1,		# header version
	 rand => "/dev/urandom",
	 bufsize => 4096,
	 save_transform => 1,
         # chunking methods; pick one at most
	 n_chunks => undef,
	 in_chunk_size => undef,
	 out_chunk_size => undef,
	 out_file_size => undef,
	 # allow creation of a subset of shares, chunks
	 sharelist => undef,	# [ $row1, $row2, ... ]
	 chunklist => undef,	# [ $chunk1, $chunk2, ... ]
	 # specify pattern to use for share filenames
	 filespec => undef,	# default value set later on
   );

The minimal set of inputs is:

 @list=sf_split(
	 shares => $number_of_shares,
	 quorum => $quorum_value,
	 filename => "filename",
   );

The function returns a list of
C<[$key,$mat,$bytes_read,@output_files]> listrefs corresponding to
each chunk that was created, or undef in the case of an error.

The C<n_chunks>, C<in_chunk_size>, C<out_chunk_size> and
C<out_file_size> options allow control over how (or if) the input file
is broken into chunks. At most one of these options may be specified.
The C<n_chunks> option divides the input into the specified number of
chunks, which will be of (more-or-less) equal size.

The filespec option allows control over naming of output files. By
default this is set to '%f-%c-%s.sf' when a file is being split into
several chunks, or '%f-%s.sf' where no chunking is performed. Before
creating the output files, the '%f', '%c' and '%s' patterns are
replaced by:

=over

=item %f: input file name

=item %c: chunk number

=item %s: share number

=back

If an error is encountered during the creation of one set of shares in
a multi-chunk job, then the routine returns immediately without
attempting to split any other remaining chunks.

=head1 COMBINE OPERATION

The template for a call to C<sf_combine>, showing all possible inputs
and default values, is as follows:

 $bytes_read = sf_split (
     infiles => undef,		# [ $file1, $file2, ... ]
     outfile => undef,		# "filename"
     # If specified, the following must agree with the values stored
     # in the sharefiles. There's normally no need to set these.
     quorum => undef,
     width => undef,
     # optional matrix, key parameters
     key => undef,
     matrix => undef,
     shares => undef,		# required if key supplied
     sharelist => undef,	# required if key supplied
     # misc options
     bufsize => 4096,
    );

The minimal set of inputs is:

 $bytes_written = sf_combine (
     infiles => [ $file1, $file2, ... ],
     outfile => $output_filename
 );

The return value is the number of bytes written to the output file or
null in the case of some error.

The current version of the module only supports combining a single
chunk with each call to C<ida_combine>. Apart from being used in the
call to open the input file, the routine does not examine the input
filenames at all since all information necessary to combine the file
is expected to be contained within the files themselves (along with
any key/matrix parameters passed in, in the case where this
information is not stored in the file itself).

Chunks may be combined in any order. When the final chunk is
processed, if any any padding bytes were added to it during the
C<sf_split> routine, these will be removed by truncating the output
file.

=head1 ANCILLARY ROUTINES

The extra routines are exported by using the ":extras" or ":all"
parameter with the initial "use" module line. The extra routines are
as follows:

 $filename = sf_sprintf_filename($format,$infile,$chunk,$share);

This routine creates share file names from the given parameters. It is
used internally by C<sf_split>.

 @chunk_info=sf_calculate_chunk_sizes(
      quorum => undef,
      width => undef,
      filename => undef,
      # misc options
      version => 1,		# header version
      save_transform => 1,	# whether to store transform in header
      # chunking method: pick at most one
      n_chunks => undef,
      in_chunk_size => undef,
      out_chunk_size => undef,
      out_file_size => undef,
 );

This returns a list of hashrefs containing information about chunk
sizes, ranges, etc., with one element for each chunk which would be
created with the given parameters. All input values match those which
would be passed to C<sf_split> except for the C<save_transform> value,
which specifies whether the transform matrix row for each share should
be stored within the file header. Each hash in the returned list has
the following keys:

=over

=item * chunk_start  first byte of chunk

=item * chunk_next   first byte of next chunk

=item * chunk_size   chunk_next - chunk_start

=item * file_size    share file size, including header

=item * opt_final    is the last chunk in the file?

=item * padding      number of padding bytes in (final) chunk

=back

This routine is used internally by C<sf_split> to calculate chunk
sizes. It is available for calling routines since it may be useful to
know in advance how large output files will be before any shares are
created, such as for cases where there is limited space (eg, network
share or CD image) for creation of those output shares.

=head1 KEY MANAGEMENT

Provided the default settings are used, created sharefiles will have
all the information necessary to reconstruct the file once sufficient
shares have been collected. For systems where an alternative scheme is
required, see the discussion in the L<Crypt::IDA> man page.

=head1 TECHNICAL DETAILS

=head2 File Format

Each share file consists of a header and some share data. For the
current version of the file format (version 1), the header format is
as follows:

  Bytes   Name           Value
  2       magic          marker for "Share File" format; "SF" = {5346}
  1       version        file format version = 1
  1       options        options bits (see below)
  1-2     k,quorum       quorum k-value
  1-2     s,security     security level (ie, field width, in bytes)
  var     chunk_start    absolute offset of chunk in file
  var     chunk_next     absolute offset of next chunk in file
  var     transform      transform matrix row (optional)

All values stored in the header file (and the share data) are stored
in network (big-endian) byte order.

The options bits are as follows:

  Bit     name           Settings
  0       opt_large_k    Large (2-byte) k value?
  1 	  opt_large_w    Large (2-byte) w value?
  2 	  opt_final      Final chunk in file? (1=full file/final chunk)
  3 	  opt_transform  Is transform data included?

All file offsets are stored in a variable-width format. They are
stored as the concatenation of two values:

=over

=item * the number of bytes required to store the offset, and

=item * the actual file offset.

=back

So, for example, the offset "0" would be represented as the single
byte "0", while the offset 0x4321 would be represented as the hex
bytes "02", "43", "21".

Note that the chunk_next field is 1 greater than the actual offset of
the chunk end. In other words, each chunk ranges from the byte starting
at chunk_start up to, but not including the byte at chunk_next. That's
why it's called chunk_next rather than chunk_end.

=head1 LIMITATIONS

The current implementation is limited to handling input files less
than 4Gb in size. This is merely a limitation of the current header
handling code, and this restriction may by removed in a later version.

Currently, the only chunking options available are for no chunking or
for chunking a file into a given number of chunks (with n_chunks
option).

=head1 FUTURE VERSIONS

It is possible that the following changes/additions will be made in
future versions:

=over

=item * implement a routine to scan given list of input files and
group them into batches that can be passed to C<sf_combine> (as well
as weeding out sub-quorum batches and broken, overlapping or
non-compliant files);

=item * implement a file format that can keep track of created
sharefiles along with parameters used to create them;

=item * implement encryption of input data stream along with dispersed
storage of decryption key in share files;

=item * implement a cryptographic accumulator to eliminate the
possibility of a cheater presenting an invalid share at the combine
stage;

=item * implement regular checksum/hash to detect damage to share
data;

=item * implement storing a row number with shares in the case where
the transform data for that share is not stored in the sharefile
header;

=item * implement a scatter/gather function to disperse shares over
the network and download (some of) them again to reconstitute the file
(probably in a new module);

=item * implement a network-based peer protocol which allows peers
with the same file to co-ordinate key generation so that they can
generate compatible shares and also share the burden of ShareFile
creation and distribution (long-term goal)

=item * I'm open to suggestions on any of these features or any other
feature that anybody might want ...

=back

=head1 SEE ALSO

See the documentation for L<Crypt::IDA> for more details of the
underlying algorithm for creating and combining shares.

This distribution includes two command-line scripts called
C<rabin-split.pl> and C<rabin-combine.pl> which provide simple
wrappers to access all functionality of the module.

=head1 AUTHOR

Declan Malone, E<lt>idablack@sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of version 2 (or, at your discretion, any later
version) of the "GNU General Public License" ("GPL").

Please refer to the file "GNU_GPL.txt" in this distribution for
details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

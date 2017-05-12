#
# Add SASL encoding/decoding to a filehandle
#

package Authen::SASL::Cyrus::Security;


sub TIEHANDLE {
  my($class, $fh, $conn) = @_;
  my($ref);

  $ref->{fh} = $fh;
  $ref->{conn} = $conn;

  bless($ref,$class);
  return($ref);
}




sub FETCH {
  my($ref) = @_;
  return($ref->{fh});
}



sub FILENO {
  my($ref) = @_;
  return(fileno($ref->{fh}));
}




sub READ {
  my($ref, $buf, $len, $offset) = @_;
  my($need, $didread, $fh, $rc, $cryptbuf, $clearbuf);

  $fh = $ref->{fh};
  $buf = \$_[1];

  # Check if there's leftovers from a previous READ
  $need = $len;
  if ($ref->{readbuf}) {
    # If there's enough in the buffer, just take from there
    if (length($ref->{readbuf}) >= $len) {
      substr($$buf, $offset, $len) = substr($ref->{readbuf}, 0, $len);
      $ref->{readbuf} = substr($ref->{readbuf}, $len);
      return($len);
    }

    # Not enough. Take all of the buffer, and read more
    substr($$buf, $offset, $len) = $ref->{readbuf};
    $didread = length($ref->{readbuf});
    $need -= $didread;
    $offset += $didread;
    $ref->{readbuf} = "";
  }

  # Read in bytes from the socket, and decrypt them
  $rc = sysread($fh, $cryptbuf, ($len < 8)?8:$len);
  return($didread) if ($rc <= 0);
  $didread = length($cryptbuf);
  $clearbuf = $ref->{conn}->decode($cryptbuf);
  return(-1) if (!defined $clearbuf);

  # It may be that more encrypted bytes are needed to decrypt an entire "block"
  # If decode() returned nothing, read in more bytes (arbitrary amounts) until
  # an entire encrypted block is available to decrypt.
  while ($clearbuf eq "") {
    $rc = sysread($fh, $cryptbuf, 8, $didread);
    last if ($rc < 8);
    $didread += $rc;
    $clearbuf = $ref->{conn}->decode($cryptbuf);
    return(-1) if (!defined $clearbuf);
  }

  # Copy what was asked for, stash the rest
  substr($$buf, $offset, $need) = substr($clearbuf, 0, $need);
  $ref->{readbuf} = substr($clearbuf, $need);

  return($len);
}




# Encrypting a write() to a filehandle is much easier than reading, because
# all the data to be encrypted is immediately available
sub WRITE {
  my($ref,$string,$clearSize) = @_;

  my $fh = $ref->{fh};

  # Divide the entire cleartext into chunks that SASL can encrypt
  my $maxChunkSize = $ref->{conn}->property("maxout");
  $maxChunkSize = $clearSize if (! defined $maxChunkSize);
  my $clearOffset = 0;
  while ($clearOffset < $clearSize) {
    my $chunkSize = $clearSize - $clearOffset;
    if ($chunkSize > $maxChunkSize) {
      $chunkSize = $maxChunkSize;
    }
    my $clearbuf = substr($string, $clearOffset, $chunkSize);

    # Encrypt the next chunk
    my $cryptbuf = $ref->{conn}->encode($clearbuf);
    my $cryptSize = length($cryptbuf);
    last if (($ref->{conn}->code != 0) || ($cryptSize == 0));

    # Send the crypt text in however many syswrite() ops it takes
    my $cryptOffset = 0;
    while ($cryptOffset < $cryptSize) {
      my $n = syswrite($fh, $cryptbuf, $cryptSize - $cryptOffset, $cryptOffset);
      last if ($n <= 0);
      $cryptOffset += $n;
    }
    last if ($cryptOffset < $cryptSize);

    $clearOffset += $chunkSize;
  }

  # Return the number of CLEARTEXT bytes sent, not encrypted bytes
  return $clearOffset;
}




# Forward close to the tied handle
sub CLOSE {
  my($ref) = @_;
  close($ref->{fh});
  $ref->{fh} = undef;
}




# Given a GLOB ref, tie the filehandle of the GLOB to this class
sub new {
  my($class, $fh, $conn) = @_;
  tie(*{$fh}, $class, $fh, $conn);
}




# Avoid getting too circular in the free'ing of an object in this class.
sub DESTROY {
  my($self) = @_;
  delete($self->{fh});
  undef $self;
}

1;

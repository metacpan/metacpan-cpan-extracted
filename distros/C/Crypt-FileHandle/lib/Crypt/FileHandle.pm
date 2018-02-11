package Crypt::FileHandle;

require 5.006000;

use strict;
use warnings;
use FileHandle;
use Carp qw(croak carp);

use vars qw($VERSION);
$VERSION = "0.03";

# ensure errors are properly reported to caller
$Carp::Internal{"Crypt::FileHandle"}++;

# internal variable names
our $V_FH = 'fh';
our $V_CIPHER = 'cipher';
our $V_STATE = 'state';
our $V_READ_BUFFER = 'read_buffer';
our $V_TOTAL_BYTES = 'total_bytes';
our $V_EOF = 'eof';

# internal state values
our $STATE_CLOSED = 0;
our $STATE_ENCRYPT = 1;
our $STATE_DECRYPT = 2;

# global variables
our $READSIZE = 4096;

############################################################

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# create tied FileHandle object
	# tie() automatically attaches this class type to it via TIEHANDLE()
	# all methods defined below will be called in place of the real methods
	my $fh = new FileHandle;
	my $self = tie(*$fh, $class, @_);

	# WARNING: do not store tied FileHandle object as this will
	# create a second hidden reference that prevents the tied object
	# from being destroyed; untie() cannot be called automatically

	# return tied FileHandle
	return $fh;
}

############################################################

# global method
# verifies that the given cipher supports the necessary methods
#
sub verify_cipher {
	my $class = shift;
	my $cipher = shift;

	# check parameters
	if (! defined $cipher) {
		return !1;
	}

	# must at least be a reference to something
	if (! ref($cipher)) {
		return !1;
	}

	# verify required methods exist
	if (! $cipher->can("start")) {
		return !1;
	}
	if (! $cipher->can("crypt")) {
		return !1;
	}
	if (! $cipher->can("finish")) {
		return !1;
	}

	return 1;
}

############################################################

# global access method
# affects ALL instances of Crypt::FileHandle
# WARNING: should not be less than minimum encrypted header length
#
sub readsize {
	my $class = shift;
	my $readsize = shift;
	if (!defined $readsize || $readsize <= 0) {
		return $READSIZE;
	}
	# provide warning if READSIZE is smaller than minimum
	# must be able to read at least header on first read
	# "Salted__" or "RandomIV" plus 8 byte IV equals 16 bytes
	if ($readsize < 16) {
		carp "readsize may be too small for encrypted header"
	}
	return $READSIZE = $readsize;
}

############################################################

sub DESTROY {
	my $self = shift;

	# close the real FileHandle
	if ($self->{$V_STATE} != $STATE_CLOSED) {
		$self->CLOSE();
	}

	return 1;
}

############################################################

sub TIEHANDLE {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# required parameters
	my $cipher = shift;

	# create new empty hash reference, bless as class
	my $self = {};
	bless($self, $class);

	# verify cipher
	if (!$self->verify_cipher($cipher)) {
		croak "invalid cipher or cipher not defined";
	}

	# default options
	$self->{$V_CIPHER} = $cipher;
	$self->{$V_STATE} = $STATE_CLOSED;
	$self->{$V_READ_BUFFER} = "";
	$self->{$V_TOTAL_BYTES} = 0;
	$self->{$V_EOF} = 0;

	# create real FileHandle
	# read/write methods below will utilize this FileHandle
	my $fh = new FileHandle;
	$self->{$V_FH} = $fh;

	# automatically call open if additional options are provided
	if (scalar @_ > 0) {
		$self->OPEN(@_) || croak $!;
	}

	return $self;
}

############################################################

# untie gotcha
#
sub UNTIE {
	my ($obj, $c) = @_;
	carp "untie attempted while $c inner references still exist" if $c;
}

############################################################

# open() FileHandle
#
sub OPEN {
	my $self = shift;
	my $fh = $self->{$V_FH};

	# reset variables
	$self->{$V_READ_BUFFER} = "";
	$self->{$V_TOTAL_BYTES} = 0;
	$self->{$V_EOF} = 0;

	# open real FileHandle
	# utilize multiple parameters without directly passing @_
	# perlio complains if undef is inadvertently passed to open()
	my $rtnval;

	# open FILEHANDLE,MODE,EXPR,LIST
	if (scalar @_ >= 3) {
		my $mode = shift;
		my $expr = shift;
		my $list = shift;

		$self->_parse_open_mode($mode);

		$rtnval = open($fh, $mode, $expr, $list);
	}

	# open FILEHANDLE,MODE,EXPR
	elsif (scalar @_ == 2) {
		my $mode = shift;
		my $expr = shift;

		$self->_parse_open_mode($mode);

		$rtnval = open($fh, $mode, $expr);
	}

	# open FILEHANDLE,EXPR
	elsif (scalar @_ == 1) {
		my $expr = shift;

		# determine mode from expr
		my $mode = undef;
		if (defined $expr) {
			if ($expr =~ /(?:^([<>\+\-\|]+)|(\|)$)/) {
				$mode = $1;
			}
		}

		$self->_parse_open_mode($mode);

		$rtnval = open($fh, $expr);
	}

	# open FILEHANDLE
	else {
		croak "Use of uninitialized value in open";
	}

	# determine FileHandle flags to start encryption/decryption
	if ($fh->opened()) {

		# automatically set real FileHandle to binary mode
		# necessary for some systems
		binmode($fh);

		# open for encrypting
		if ($self->{$V_STATE} eq $STATE_ENCRYPT) {
			$self->{$V_CIPHER}->start('encrypting');

			# an error is presented if no data is ever written
			# so force an empty string of data to be encrypted
			$self->_encrypt_write("");
		}

		# open for decrypting
		elsif ($self->{$V_STATE} eq $STATE_DECRYPT) {
			$self->{$V_CIPHER}->start('decrypting');
		}

		# unknown
		else {
			# this should never occur
			croak "Bad state";
		}
	}

	return $rtnval;
}

############################################################

# sets binary mode
#
sub BINMODE {
	my $self = shift;

	# set binary mode on real FileHandle
	my $fh = $self->{$V_FH};
	return binmode($fh, @_) if (@_);
	return binmode($fh);
}

############################################################

# print() to FileHandle
#
sub PRINT {
	my $self = shift;

	# check state
	if ($self->{$V_STATE} == $STATE_CLOSED) {
		carp "print() on closed filehandle";
		return !1;
	}
	if ($self->{$V_STATE} == $STATE_DECRYPT) {
		carp "Filehandle opened only for input";
		return !1;
	}

	# encrypt and write data to real FileHandle
	if ($self->_encrypt_write(@_)) {
		return 1;
	}

	return !1;
}

############################################################

# printf() to FileHandle
#
sub PRINTF {
	my $self = shift;
	my $fmt = shift;

	return $self->PRINT(sprintf($fmt, @_));
}

############################################################

# write() to FileHandle
#
sub WRITE {
	my $self = shift;

	# check state
	if ($self->{$V_STATE} == $STATE_CLOSED) {
		carp "syswrite() on closed filehandle";
		return undef;
	}
	if ($self->{$V_STATE} == $STATE_DECRYPT) {
		carp "Filehandle opened only for input";
		return undef;
	}

	# get parameters
	my ($buf, $len, $off) = @_;

	# check parameters
	if (! defined $buf) {
		carp "Use of uninitialized value";
		return undef;
	}
	if (! defined $len) {
		$len = length($buf);
	}
	if ($len < 0) {
		carp "Negative length";
		return undef;
	}
	if (! defined $off) {
		$off = 0;
	}

	# truncate to length
	$buf = substr($buf, $off, $len);

	# encrypt and write data to real FileHandle
	return $self->_encrypt_write($buf);
}

############################################################

# readline() from FileHandle
#
sub READLINE {
	my $self = shift;

	# check state
	if ($self->{$V_STATE} == $STATE_CLOSED) {
		carp "readline() on closed filehandle";
		return undef;
	}
	if ($self->{$V_STATE} == $STATE_ENCRYPT) {
		carp "Filehandle opened only for output";
		return undef;
	}

	# EOF and buffer is empty
	if ($self->{$V_EOF} && length($self->{$V_READ_BUFFER}) == 0) {
		return undef;
	}

	# utilize INPUT_RECORD_SEPARATOR ($/) to determine end of line
	my $index = -1;
	if (defined $/) {
		# loop reading data until buffer contains $/
		$index = index($self->{$V_READ_BUFFER}, $/);
		while (($index < 0) && $self->_decrypt_read()) {
			$index = index($self->{$V_READ_BUFFER}, $/);
		}
	}
	else {
		# special case if $/ is undef
		# continue looping until entire file is read
		while($self->_decrypt_read()) {
		}
	}

	# if index was found, include $/ in length
	# otherwise an undef length will extract entire buffer
	# return value (extracted length) is unused when reading lines
	my $len = ($index >= 0 ? ($index + length($/)) : undef);
	my $buf;
	$self->_extract_read_buffer($buf, $len);

	return $buf;
}

############################################################

# read() from FileHandle
#
sub READ {
	my $self = shift;

	# check state
	if ($self->{$V_STATE} == $STATE_CLOSED) {
		carp "sysread() on closed filehandle";
		return undef;
	}
	if ($self->{$V_STATE} == $STATE_ENCRYPT) {
		carp "Filehandle opened only for output";
		return undef;
	}

	# get parameters
	# acquire reference to provided scalar
	my $buf = \shift;
	my ($len, $off) = @_;

	# check parameters
	if (! defined $buf) {
		carp "Use of uninitialized value";
		return undef;
	}
	if (! defined $len) {
		carp "Use of uninitialized length";
		return undef;
	}
	if ($len < 0) {
		carp "Negative length";
		return undef;
	}
	if (! defined $off) {
		$off = 0;
	}

	# read more data until buffer is large enough
	while ($len > length($self->{$V_READ_BUFFER})) {
		last if (! $self->_decrypt_read());
	}

	# extract data from buffer
	return $self->_extract_read_buffer($$buf, $len, $off);
}

############################################################

# getc() from FileHandle
#
sub GETC {
	my $self = shift;

	my $buf;
	$self->READ($buf, 1) || return undef;
	return $buf;
}

############################################################

# not implemented
#
#sub SEEK { }

############################################################

# returns the total number of cleartext bytes read or
# written, or -1 if the file is closed
#
sub TELL {
	my $self = shift;

	# check state
	if ($self->{$V_STATE} == $STATE_CLOSED) {
		return -1;
	}

	# return total number of bytes
	return $self->{$V_TOTAL_BYTES};
}

############################################################

# closes the real file
#
sub CLOSE {
	my $self = shift;

	# finish writing leftover data prior to close
	$self->_finish();

	# change state
	$self->{$V_STATE} = $STATE_CLOSED;

	# close the real FileHandle
	my $fh = $self->{$V_FH};
	if (defined $fh) {
		return $fh->close();
	}

	return !1;
}

############################################################

# returns FILENO for real FileHandle
# utilized by a call to opened() on tied FileHandle
#
sub FILENO {
	my $self = shift;
	return fileno($self->{$V_FH});
}

############################################################

# returns true if EOF or CLOSED
#
sub EOF {
	my $self = shift;

	# CLOSED
	if ($self->{$V_STATE} == $STATE_CLOSED) {
		return 1;
	}

	# EOF if real FileHandle is EOF and the buffer is empty
	if ($self->{$V_EOF} && length($self->{$V_READ_BUFFER}) == 0) {
		return 1;
	}

	return !1;
}

############################################################

# finishes up the encryption if there is leftover data to be written
#
sub _finish {
	my $self = shift;

	# check state
	# only necessary if encrypting
	if ($self->{$V_STATE} == $STATE_CLOSED) {
		return !1;
	}
	if ($self->{$V_STATE} == $STATE_DECRYPT) {
		return !1;
	}

	# finish up the encryption
	my $ciphertext = $self->{$V_CIPHER}->finish();

	# write to real FileHandle
	my $fh = $self->{$V_FH};
	my $bytes_written = syswrite($fh, $ciphertext, length($ciphertext));

	return 1;
}

############################################################

# parse the mode provided to open()
#
sub _parse_open_mode {
	my $self = shift;
	my $mode = shift;

	# determine cipher mode (encrypt or decrypt)
	if (! defined $mode || $mode =~ /^</ || $mode =~ /\|$/) {
		# update state to reading
		$self->{$V_STATE} = $STATE_DECRYPT;
	}

	elsif ($mode =~ /^>(?!>)/ || $mode =~ /^\|/) {
		# update state to writing
		$self->{$V_STATE} = $STATE_ENCRYPT;
	}

	elsif ($mode =~ /^\+?>>/) {
		croak "APPEND mode not supported";
	}

	elsif ($mode =~ /^\+[<>]/) {
		croak "READ/WRITE mode not supported";
	}

	else {
		croak "Unknown mode";
	}

	return 1;
}

############################################################

# encrypts the provided parameters and writes to real FileHandle
# returns the number of cleartext bytes processed
#
sub _encrypt_write {
	my $self = shift;

	# check parameters
	return undef unless (@_);

	# check state
	if ($self->{$V_STATE} == $STATE_CLOSED) {
		carp "crypt() on closed FileHandle";
		return undef;
	}
	if ($self->{$V_STATE} == $STATE_DECRYPT) {
		carp "FileHandle opened only for input";
		return undef;
	}

	# append data
	my $cleartext = "";
	foreach (@_) {
		$cleartext .= $_ if (defined $_);
	}

	# encrypt data
	# must call crypt() even if cleartext is empty to ensure
	# header is written to an "empty" file
	my $ciphertext = $self->{$V_CIPHER}->crypt($cleartext);

	# ciphertext is only defined if there is at least one full block
	# after performing the encryption above
	if (defined $ciphertext) {

		# write data to real FileHandle
		my $fh = $self->{$V_FH};
		my $bw = syswrite($fh, $ciphertext, length($ciphertext));

		# check bytes written for errors
		if (! defined $bw) {
			carp $!;
			return undef;
		}
		if ($bw < 0) {
			return undef;
		}
		if ($bw == 0 && length($ciphertext) > 0) {
			return undef;
		}
	}

	# increment total number of cleartext bytes
	$self->{$V_TOTAL_BYTES} += length($cleartext);

	# return the number of cleartext characters processed
	return length($cleartext);
}

############################################################

# performs a single read from the real FileHandle
# decrypts the data and adds it to the buffer
# should be used when more data is needed in the buffer
# returns true on success, or false if EOF or error
#
sub _decrypt_read {
	my $self = shift;

	# end of file
	if ($self->{$V_EOF}) {
		return !1;
	}

	# reference to buffer
	my $rbuf = \$self->{$V_READ_BUFFER};

	# read and decrypt additional data from real Filehandle
	# always read in blocks of READSIZE encrypted bytes
	my $ciphertext;
	my $br = sysread($self->{$V_FH}, $ciphertext, $READSIZE);

	# check bytes read for errors
	if (! defined $br) {
		carp $!;
		return !1;
	}
	if ($br == 0) {
		# end of file (real FileHandle)
		$self->{$V_EOF} = 1;

		# finish decryption, if necessary
		# should only run once based on loop parameters above
		$$rbuf .= $self->{$V_CIPHER}->finish();
	}
	else {
		# decrypt data and append to buffer
		# cleartext length may be less than bytes read
		$$rbuf .= $self->{$V_CIPHER}->crypt($ciphertext) || "";
	}

	return 1;
}

############################################################

# extracts len bytes from the stored buffer
# assumes buffer has already been sufficiently populated with _decrypt_read()
# returns number of bytes extracted or undef on error
#
sub _extract_read_buffer {
	my $self = shift;

	# get parameters
	# acquire reference to provided scalar
	my $buf = \shift;
	my ($len, $off) = @_;

	# check parameters
	if (! defined $buf) {
		carp "Use of uninitialized value";
		return undef;
	}
	if (! defined $len) {
		# return entire buffer
		$len = length($self->{$V_READ_BUFFER});
	}
	if ($len < 0) {
		carp "Negative length";
		return undef;
	}
	if (! defined $off) {
		$off = 0;
	}

	# reference to buffer
	my $rbuf = \$self->{$V_READ_BUFFER};

	# extract requested bytes from buffer and replace with empty string
	# store extracted data in provided scalar at offset position
	# if offset is 0, same as writing over provided scalar
	# should be valid even for 0 byte requests
	# save length of extracted data for increment below
	my $xl;
	if (! defined $$buf) {
		# offset is ignored if provided scalar is not defined
		$$buf = substr($$rbuf, 0, $len, "");
		$xl = length($$buf);
	}
	else {
		$xl = length(substr($$buf, $off) = substr($$rbuf, 0, $len, ""));
	}

	# increment total number of bytes extracted
	# may differ from requested length if _decrypt_read() not called or EOF
	$self->{$V_TOTAL_BYTES} += $xl;

	return $xl;
}

############################################################

1;

__END__

=head1 NAME

Crypt::FileHandle - encrypted FileHandle

=head1 SYNOPSIS

  use Crypt::CBC;
  use Crypt::FileHandle;

  # example cipher
  $cipher = Crypt::CBC->new(
  	-cipher => 'Cipher::AES',
  	-key    => $key,
  	-header => 'salt'
  );

  # create tied FileHandle
  $fh = Crypt::FileHandle->new($cipher);

  ### treat $fh same as any FileHandle

  # write file
  open($fh, '>', $filename) || die $!;
  print $fh "This is a test string\n";
  close($fh);

  # read file
  open($fh, '<', $filename) || die $!;
  while(<$fh>) {
  	print $_;
  }
  close($fh);

=head1 DESCRIPTION

This package creates a tied FileHandle that automatically encrypts or
decrypts data using the provided cipher. The FileHandle returned from
new() can be treated like a normal FileHandle. All encrypting,
decrypting, and buffering is completely transparent to the caller.

=head1 CIPHER METHODS

This package generally supports ciphers compliant with Crypt::CBC,
including CryptX ciphers. The cipher provided to new() must support
at least the methods listed below, but no other methods are utilized
by this package. Refer to Crypt::CBC for more information on these
methods. Even though it is not recommended, a custom home-made cipher
object can be used if it supports these methods.

=over 4

=item start($string)

Initializes the encryption or decryption process according to the
provided string, either 'encrypting' or 'decrypting'.

=item crypt($data)

Encrypts or decrypts the provided data and returns the resulting
data.

=item finish()

Flushes the internal buffer and returns any remaining data.

=back

=head1 GLOBAL METHODS

This package supports the following global methods. These methods
cannot be called on the tied FileHandle returned from new() and
should only be called via the package name.

=over 4

=item F<new($cipher)>

Returns a new FileHandle object that is "tied" with the provided
cipher object. It utilizes TIEHANDLE to tie a FileHandle object with
a real FileHandle object underneath. The returned FileHandle can be
treated like a normal FileHandle, but all writes and reads will occur
on the real FileHandle which will be encrypted or decrypted
automatically using the methods of the cipher object.

The cipher object provided to new() should NOT be used in any other
capacity, otherwise it may disrupt encryption and decryption
operations.

=item F<verify_cipher($cipher)>

Returns true or false if the provided cipher is supported by
confirming that the necessary methods exist. This method is
automatically called by new() to confirm the provided cipher is
valid.

=item F<readsize()>

=item F<readsize($readsize)>

Returns the global READSIZE. When a file is open for reading, data
is read from the real FileHandle in blocks of READSIZE bytes. Any
decrypted data that is not returned by any of the read methods is
automatically stored in an internal buffer to be utilized during
future read calls.

The global READSIZE can be changed by providing an optional
parameter. However, this is a global value and will affect all
instances of Crypt::FileHandle. Beware of setting the READSIZE too
small, which may prevent reading the entire encrypted file header
during the first read call, causing the decryption to fail. The
default READSIZE is 4096 bytes.

=back

=head1 TIED METHODS

The following methods have been implemented for the tied FileHandle
returned by new(). These methods are automatically called through the
tied FileHandle and should not be called directly.

=over 4

=item F<OPEN()>

Called when open() is called on the tied FileHandle returned from
new(). Opens the real FileHandle using the given parameters, and
automatically calls start() on the provided cipher with 'encrypting'
or 'decrypting' based on whether the real FileHandle was opened for
writing or reading. If the mode is not explicitly provided, it
assumes the file was open for reading. Note that sysopen() is not
supported with a tied FileHandle.

=item F<BINMODE()>

Called when binmode() is called on the tied FileHandle returned from
new(). Calls binmode() with the provided parameters on the real
FileHandle. Note that it should not be necessary to use this method
because binmode() is automatically called on the real FileHandle when
open() is called. This is to ensure portability on all systems since
encrypted files will almost certainly contain binary data.

=item F<PRINT()>

=item F<PRINTF()>

=item F<WRITE()>

Called when print(), printf(), or syswrite() is called on the tied
FileHandle returned from new(). Each method will encrypt the data and
write it to the real FileHandle based on the provided cipher. Note
that syswrite() is always utilized to write to the real FileHandle
regardless of the method called.

The number of encrypted bytes written to the real FileHandle may not
be the same as the number of cleartext bytes processed, especially if
a full block of data has not yet been provided. WRITE() will return
the number of cleartext bytes processed, which keeps the encryption
transparent to the caller.

=item F<READLINE()>

=item F<READ()>

=item F<GETC()>

Called when readline() (or <>), sysread(), or getc() is called on the
tied FileHandle returned from new(). Each method will read data from
the real FileHandle and decrypt it based on the provided cipher. Note
that sysread() is always utilized to read from the real FileHandle
regardless of the method called. Data is always read in blocks of
READSIZE bytes. Any data that is read and decrypted but not returned
is stored in an internal buffer to be utilized by future read calls.

READ() will return the number of cleartext bytes processed and not
the actual number of bytes read from the real FileHandle, which keeps
the decryption transparent to the caller.

=item F<TELL()>

Called when tell() is called on the tied FileHandle returned from
new(). Returns the number of cleartext bytes processed through the
tied FileHandle. It does not return the position of the real
FileHandle, which may differ because of the encryption. The logical
position of the data is returned as if a normal FileHandle was used,
which keeps the encryption and decryption transparent to the caller.

=item F<CLOSE()>

Called when close() is called on the tied FileHandle returned from
new(). It closes the real FileHandle. If the real FileHandle was
opened for writing, it calls finish() on the cipher object to
complete the encryption prior to closing the real FileHandle.

=item F<FILENO()>

Called when fileno() is called on the tied FileHandle returned from
new(). Returns the file number of the real FileHandle. Note that this
method is also utilized when opened() is called on the tied
FileHandle. The file number of the real FileHandle is returned to
ensure a call to opened() accurately returns whether or not the file
is actually open or not.

=item F<EOF()>

Called when eof() is called on the tied FileHandle returned from
new(). Returns true if the read calls have reached an end of file
state or if the real FileHandle is closed. Note that the real
FileHandle may have reached end of file when reading, but data may
still exist in the internal buffer, and thus false is returned since
the logical end of file has not yet been reached.

=back

=head1 WARNINGS

The sysopen() method is not supported with a tied FileHandle.

The syswrite() and sysread() methods are always used to write to and
read from real handles. This package cannot be used with handles that
do not support these methods, such as opening directly to a Perl
scalar.

If the salt or randomiv header options are not used in the Crypt::CBC
cipher provided to new(), it is the caller's responsibility to
initialize the decryption cipher appropriately to include any
necessary salt or iv values. Otherwise using the same cipher to both
encrypt and decrypt will be unsuccessful since the salt or iv values
are not included in the encrypted file. When the salt header option
is used, the necessary values are included in the resulting encrypted
file, and can also be decrypted with OpenSSL as shown in the example
below.

=over 4

openssl enc -d -aes-256-cbc -in <file> -k <key>

=back

Due to cipher block chaining (CBC), random access is currently not
permitted with this package. It would likely be necessary to read or
write the entire contents of the file, or large portions of it, to
enable random access. For this reason, the following restrictions
exist.

=over 4

SEEK() is not implemented.

Files must only be opened for read OR write access. Files cannot be
open for both read AND write access.

Files cannot be appended when writing.

=back

=head1 UNTIE and DESTROY

When new() is called, a FileHandle object is created and tie() is
automatically called on this object before it is returned. This is
the tied FileHandle which is described above. All file reads and
writes are performed on the real FileHandle object that is stored and
referenced interally in the Crypt::FileHandle object that the 
FileHandle is tied to.

There is no automatic call to untie() because the tied FileHandle
returned from new() is not accessible from within any of the other
methods that are called. The tied FileHandle can only be accessed
internally if a reference to itself is stored in the
Crypt::FileHandle object created by TIEHANDLE(). Unfortunately,
this would be a second hidden reference to the same object,
preventing the tied object from being destroyed until the program
exits. This behavior is avoided by not storing a second internal
reference, excluding the ability to automatically call untie().

Since it is not automatically called anywhere, the caller can call
untie() on the tied FileHandle if desired, but this will not destroy
the underlying tied Crypt::FileHandle object. The tied FileHandle
returned from new() can be reused like any other FileHandle after it
has been closed, or properly destroyed by setting the reference to
undef like any other reference. This will properly destroy the tied
FileHandle and the Crypt::FileHandle object since there will no
longer be any references to either.

=head1 SEE ALSO

FileHandle(3), Crypt::CBC(3), CryptX(3), OpenSSL(1)

=head1 AUTHOR

Christopher J. Dunkle

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004,2016,2018 by Christopher J. Dunkle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

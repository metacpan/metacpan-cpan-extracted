=head1 NAME

Data::Entropy::RawSource::CryptCounter - counter mode of block cipher
as I/O handle

=head1 SYNOPSIS

	use Data::Entropy::RawSource::CryptCounter;

	my $rawsrc = Data::Entropy::RawSource::CryptCounter
			->new(Crypt::Rijndael->new($key));

	$c = $rawsrc->getc;
	# and the rest of the I/O handle interface

=head1 DESCRIPTION

This class provides an I/O handle connected to a virtual file which
contains the output of a block cipher in counter mode.  This makes a
good source of pseudorandom bits.  The handle implements a substantial
subset of the interfaces described in L<IO::Handle> and L<IO::Seekable>.

For use as a general entropy source, it is recommended to wrap an object
of this class using C<Data::Entropy::Source>, which provides methods to
extract entropy in more convenient forms than mere octets.

The amount of entropy the virtual file actually contains is only the
amount that is in the key, which is at most the length of the key.
It superficially appears to be much more than this, if (and to the
extent that) the block cipher is secure.  This technique is not
suitable for all problems, and requires a careful choice of block
cipher and keying method.  Applications requiring true entropy
should generate it (see L<Data::Entropy::RawSource::Local>) or
download it (see L<Data::Entropy::RawSource::RandomnumbersInfo> and
L<Data::Entropy::RawSource::RandomOrg>).

=cut

package Data::Entropy::RawSource::CryptCounter;

{ use 5.006; }
use warnings;
use strict;

use Params::Classify 0.000 qw(is_number is_ref is_string);

our $VERSION = "0.007";

=head1 CONSTRUCTOR

=over

=item Data::Entropy::RawSource::CryptCounter->new(KEYED_CIPHER)

KEYED_CIPHER must be a cipher object supporting the standard C<blocksize>
and C<encrypt> methods.  For example, an instance of C<Crypt::Rijndael>
(with the default C<MODE_ECB>) would be appropriate.  A handle object
is created and returned which refers to a virtual file containing the
output of the cipher's counter mode.

=cut

sub new {
	my($class, $cipher) = @_;
	return bless({
		cipher => $cipher,
		blksize => $cipher->blocksize,
		counter => "\0" x $cipher->blocksize,
		subpos => 0,
	}, $class);
}

=back

=head1 METHODS

A subset of the interfaces described in L<IO::Handle> and L<IO::Seekable>
are provided:

=over

=item $rawsrc->read(BUFFER, LENGTH[, OFFSET])

=item $rawsrc->getc

=item $rawsrc->ungetc(ORD)

=item $rawsrc->eof

Buffered reading from the source, as in L<IO::Handle>.

=item $rawsrc->sysread(BUFFER, LENGTH[, OFFSET])

Unbuffered reading from the source, as in L<IO::Handle>.

=item $rawsrc->close

Does nothing.

=item $rawsrc->opened

Retruns true to indicate that the source is available for I/O.

=item $rawsrc->clearerr

=item $rawsrc->error

Error handling, as in L<IO::Handle>.

=item $rawsrc->getpos

=item $rawsrc->setpos(POS)

=item $rawsrc->tell

=item $rawsrc->seek(POS, WHENCE)

Move around within the buffered source, as in L<IO::Seekable>.

=item $rawsrc->sysseek(POS, WHENCE)

Move around within the unbuffered source, as in L<IO::Seekable>.

=back

The buffered (C<read> et al) and unbuffered (C<sysread> et al) sets
of methods are interchangeable, because no such distinction is made by
this class.

C<tell>, C<seek>, and C<sysseek> only work within the first 4 GiB of the
virtual file.  The file is actually much larger than that: for Rijndael
(AES), or any other cipher with a 128-bit block, the file is 2^52 YiB
(2^132 B).  C<getpos> and C<setpos> work throughout the file.

Methods to write to the file are unimplemented because the virtual file
is fundamentally read-only.

=cut

sub _ensure_buffer {
	my($self) = @_;
	$self->{buffer} = $self->{cipher}->encrypt($self->{counter})
		unless exists $self->{buffer};
}

sub _clear_buffer {
	my($self) = @_;
	delete $self->{buffer};
}

sub _increment_counter {
	my($self) = @_;
	for(my $i = 0; $i != $self->{blksize}; $i++) {
		my $c = ord(substr($self->{counter}, $i, 1));
		unless($c == 255) {
			substr $self->{counter}, $i, 1, chr($c + 1);
			return;
		}
		substr $self->{counter}, $i, 1, "\0";
	}
	$self->{counter} = undef;
}

sub _decrement_counter {
	my($self) = @_;
	for(my $i = 0; ; $i++) {
		my $c = ord(substr($self->{counter}, $i, 1));
		unless($c == 0) {
			substr $self->{counter}, $i, 1, chr($c - 1);
			return;
		}
		substr $self->{counter}, $i, 1, "\xff";
	}
}

sub close { 1 }

sub opened { 1 }

sub error { 0 }

sub clearerr { 0 }

sub getc {
	my($self) = @_;
	return undef unless defined $self->{counter};
	$self->_ensure_buffer;
	my $ret = substr($self->{buffer}, $self->{subpos}, 1);
	if(++$self->{subpos} == $self->{blksize}) {
		$self->_increment_counter;
		$self->{subpos} = 0;
		$self->_clear_buffer;
	}
	return $ret;
}

sub ungetc {
	my($self, undef) = @_;
	unless($self->{subpos} == 0) {
		$self->{subpos}--;
		return;
	}
	return if $self->{counter} =~ /\A\0*\z/;
	$self->_decrement_counter;
	$self->{subpos} = $self->{blksize} - 1;
	$self->_clear_buffer;
}

sub read {
	my($self, undef, $length, $offset) = @_;
	return undef if $length < 0;
	$_[1] = "" unless defined $_[1];
	if(!defined($offset)) {
		$offset = 0;
		$_[1] = "";
	} elsif($offset < 0) {
		return undef if $offset < -length($_[1]);
		substr $_[1], $offset, -$offset, "";
		$offset = length($_[1]);
	} elsif($offset > length($_[1])) {
		$_[1] .= "\0" x ($offset - length($_[1]));
	} else {
		substr $_[1], $offset, length($_[1]) - $offset, "";
	}
	my $original_offset = $offset;
	while($length != 0 && defined($self->{counter})) {
		$self->_ensure_buffer;
		my $avail = $self->{blksize} - $self->{subpos};
		if($length < $avail) {
			$_[1] .= substr($self->{buffer}, $self->{subpos},
					$length);
			$offset += $length;
			$self->{subpos} += $length;
			last;
		}
		$_[1] .= substr($self->{buffer}, $self->{subpos}, $avail);
		$offset += $avail;
		$length -= $avail;
		$self->_increment_counter;
		$self->{subpos} = 0;
		$self->_clear_buffer;
	}
	return $offset - $original_offset;
}

*sysread = \&read;

sub tell {
	my($self) = @_;
	use integer;
	my $ctr = $self->{counter};
	my $nblocks;
	if(defined $ctr) {
		return -1 if $ctr =~ /\A.{4,}[^\0]/s;
		$ctr .= "\0\0\0\0" if $self->{blksize} < 4;
		$nblocks = unpack("V", $ctr);
	} else {
		return -1 if $self->{blksize} >= 4;
		$nblocks = 1 << ($self->{blksize} << 3);
	}
	my $pos = $nblocks * $self->{blksize} + $self->{subpos};
	return -1 unless ($pos-$self->{subpos}) / $self->{blksize} == $nblocks;
	return $pos;
}

use constant SEEK_SET => 0;
use constant SEEK_CUR => 1;
use constant SEEK_END => 2;

sub sysseek {
	my($self, $offset, $whence) = @_;
	if($whence == SEEK_SET) {
		use integer;
		return undef if $offset < 0;
		my $ctr = $offset / $self->{blksize};
		my $subpos = $offset % $self->{blksize};
		$ctr = pack("V", $ctr);
		if($self->{blksize} < 4) {
			return undef unless
			my $chopped = substr($ctr, $self->{blksize},
					     4-$self->{blksize}, "");
			if($chopped =~ /\A\x{01}\0*\z/ && $subpos == 0) {
				$self->{counter} = undef;
				$self->{subpos} = 0;
				$self->_clear_buffer;
				return $offset;
			} elsif($chopped !~ /\A\0+\z/) {
				return undef;
			}
		} else {
			$ctr .= "\0" x ($self->{blksize} - 4);
		}
		$self->{counter} = $ctr;
		$self->{subpos} = $subpos;
		$self->_clear_buffer;
		return $offset || "0 but true";
	} elsif($whence == SEEK_CUR) {
		my $pos = $self->tell;
		return undef if $pos == -1;
		return $self->sysseek($pos + $offset, SEEK_SET);
	} elsif($whence == SEEK_END) {
		use integer;
		return undef if $offset > 0;
		return undef if $self->{blksize} >= 4;
		my $nblocks = 1 << ($self->{blksize} << 3);
		my $pos = $nblocks * $self->{blksize};
		return undef unless $pos/$self->{blksize} == $nblocks;
		return $self->sysseek($pos + $offset, SEEK_SET);
	} else {
		return undef;
	}
}

sub seek { shift->sysseek(@_) ? 1 : 0 }

sub getpos {
	my($self) = @_;
	return [ $self->{counter}, $self->{subpos} ];
}

sub setpos {
	my($self, $pos) = @_;
	return undef unless is_ref($pos, "ARRAY") && @$pos == 2;
	my($ctr, $subpos) = @$pos;
	unless(!defined($ctr) && $subpos == 0) {
		return undef unless is_string($ctr) &&
			length($ctr) == $self->{blksize} &&
			is_number($subpos) &&
			$subpos >= 0 && $subpos < $self->{blksize};
	}
	$self->{counter} = $ctr;
	$self->{subpos} = $subpos;
	$self->_clear_buffer;
	return "0 but true";
}

sub eof {
	my($self) = @_;
	return !defined($self->{counter});
}

=head1 SEE ALSO

L<Crypt::Rijndael>,
L<Data::Entropy::RawSource::Local>,
L<Data::Entropy::RawSource::RandomOrg>,
L<Data::Entropy::RawSource::RandomnumbersInfo>,
L<Data::Entropy::Source>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2009, 2011
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

package DataStore::CAS::FS::DirCodec;
use 5.008;
use strict;
use warnings;
use Carp;
use Try::Tiny;

our $VERSION= '0.010000';

our %_Formats= ();

# ABSTRACT: Abstract base class for directory encoder/decoders


sub load {
	my $class= shift;
	my %p= (@_ == 1)? ((ref $_[0] eq 'HASH')? %{$_[0]} : ( file => $_[0] )) : @_;

	defined $p{file} or croak "Missing required attribute 'file'";
	defined $p{format} or $p{format}= $class->_read_format(\%p);

	# Once we get the name of the format, we can jump over to the constructor
	# for the appropriate class
	my $codec= $_Formats{$p{format}}
		or croak "Unknown directory format '$p{format}' in ".$p{file}->hash
			."\n(be sure to load relevant modules)\n";
	return $codec->decode(\%p);
}


sub put {
	my ($class, $cas, $format, $entries, $metadata)= @_;
	defined $entries and ref $entries eq 'ARRAY' or croak "entries must be an arrayref";
	my $codec= $_Formats{$format}
		or croak "Unknown directory format '$format'"
			."\n(be sure to load relevant modules)\n";
	my $scalar= $codec->encode($entries, $metadata);
	return $cas->put_scalar($scalar);
}


sub decode {
	(shift)->load(@_);
}


sub encode {
	croak "Only implemented in subclasses";
}


sub register_format {
	my ($class, $format, $codec)= @_;
	my $dec= $codec->can('decode');
	defined $dec && $dec ne \&decode
		or croak ref($codec)." must implement 'decode'";
	$_Formats{$format}= $codec;
}


my $_MagicNumber= 'CAS_Dir ';

sub _magic_number { $_MagicNumber }

sub _calc_header_length {
	my ($class, $format)= @_;
	# Length of sprintf("CAS_Dir %02X %s\n", length($format), $format)
	return length($format)+length($_MagicNumber)+4;
}


sub _read_format {
	my ($class, $params)= @_;

	# The caller is allowed to pre-load the data so that we don't need to read it here.
	my $buf= $params->{data};
	# If they didn't, we need to load it.
	if (!defined $params->{data}) {
		$params->{handle}= $params->{file}->open
			unless defined $params->{handle};
		seek($params->{handle}, 0, 0) or croak "seek: $!";
		$class->_readall($params->{handle}, $buf, length($_MagicNumber)+2);
	}

	# first 8 bytes are "CAS_Dir "
	# Next 2 bytes are the length of the format in uppercase ascii hex (limiting format id to 255 characters)
	substr($buf, 0, length($_MagicNumber)) eq $_MagicNumber
		or croak "Bad magic number in directory ".$params->{file}->hash;
	my $format_len= hex substr($buf, length($_MagicNumber), 2);

	# Now we know how many additional bytes we need
	if (!defined $params->{data}) {
		$class->_readall($params->{handle}, $buf, 1+$format_len+1, length($buf));
	}

	# The byte after that is a space character.
	# The format id string follows, in exactly $format_len bytes
	# There is a newline (\n) at the end of the format string which is not part of that count.
	substr($buf, length($_MagicNumber)+2, 1) eq ' '
		and substr($buf, length($_MagicNumber)+3+$format_len, 1) eq "\n"
		or croak "Invalid directory encoding in ".$params->{file}->hash;
	return substr($buf, length($_MagicNumber)+3, $format_len);
}


sub _readall {
	my $got= read($_[1], $_[2], $_[3], $_[4]||0);
	return $got if defined $got and $got == $_[3];
	my $count= $_[3];
	while (1) {
		if (defined $got) {
			croak "unexpected EOF"
				unless $got > 0;
			$count -= $got;
		}
		else {
			croak "read: $!"
				unless $!{EINTR} || $!{EAGAIN};
		}
		$got= read($_[1], $_[2], $count, length $_[2]);
	}
	1;
}

1;

__END__

=pod

=head1 NAME

DataStore::CAS::FS::DirCodec - Abstract base class for directory encoder/decoders

=head1 VERSION

version 0.011000

=head1 SYNOPSIS

  my $file= $cas->get($digest_hash);
  my $dir= DataStore::CAS::FS::DirCodec->load($file);

=head1 DESCRIPTION

DataStore::CAS::FS stores directories as files.  Thus, they need to be
serialized and deserialized.  I wanted better efficiency than a plain
key/value serialization, but also wanted something flexible and future-proof,
but also wanted it to be easily cross-platform.  In the end I decided on a
pluggable implementation, where a "Universal" plugin uses something plain like
JSON, and more specialized plugins do things like storing an array of UNIX
'stat' fields.  Users can also write their own specialized codecs, and get
the features/performance they need while still using the rest of the code
un-altered.  It also provides an easy path for people to contribute new codecs
to the project.

These are the current implementations:

=over

=item Universal

L<DataStore::CAS::FS::DirCodec::Universal> stores all metadata of each DirEnt
using JSON.  If you use this codec, you are guaranteed that anything your
CAS::FS::Scanner picked up was saved into the CAS.

=item Minimal

L<DataStore::CAS::FS::DirCodec::Minimal> only stores type, filename, and content
reference, and results in a very compact serialization.  Use this one if you
don't care about permissions and just want enough information for a quick
content backup. (ideal for making micro-backups between large comprehensive
backups)

=item Unix

L<DataStore::CAS::FS::DirCodec::Unix> stores bare 'stat' entries for each file.
It isn't so rigid as to use fixed-width fields, so it should serve any
unix-like architecture with similar stat() fields.

=item Planned...

Eventually there will also be a DirCodec::UnixAttr if you want to store ACLs
and Extended Attributes, a DirCodec::DosFat for fat16/32, and a
DirCodec::Windows for ACL-based Windows permissions.  Patches welcome.

=item Your Own

It is very easy to write your own directory serializer!  See the section
on L</EXTENDING>.

For large directories, it is possible with this API to write an indexed
directory format, where you encode your own b-tree or something in each 
directory, and then read it on demand as the user requests entries by name.

=back

=head1 DIR AND DIRENT OBJECTS

(mentioned here for emphasis)

All L<Dir|DataStore::CAS::FS::Dir> objects are intended to be immutable, as are the
L<DirEnt|DataStore::CAS::FS::DirEnt> objects they index.  They are also cached by
L<DataStore::CAS::FS>, so modifying them could cause problems.  Don't do that.

If you want to make changes to a DirEnt, use

  $entry= $entry->clone( %overrides );

=head1 METHODS

=head2 load

  $dir= $class->load( $file | \%params )

This factory method reads the first few bytes of $file (which must be an
instance of L<DataStore::CAS::File>) to determine which codec to use.
(but see parameter 'data')

The appropriate codec's ->decode method will then be invoked, if available.

The method can be called with just the file, or with a hashref of parameters.

Parameters:

=over

=item file

The single $file is equivalent to C<< { file =E<gt> $file } >>.  It specifies the CAS
item to read the serialized directory from.

=item format

If you know the format ahead of time, you may specify it to prevent load() from
needing to read the $file.  (though most directory codecs will immediately
read it anyway)

C<format> must be one of the registered formats.  See L</register_format>.

=item handle

If you already opened the file for some reason, you can let the directory
re-use your handle.  Be warned that the directory will seek to the start of
the file first.  Also beware that some directory implementations might hold
onto the handle and seek around on it as the user iterates the directory.

=item data

If you already have the full data of the $file, you can supply it to the codec
to prevent any I/O activity.  You might choose this if you were trying to use
the library in a non-blocking or event driven application.

=back

=head2 put

  $class->put( $cas, $format, \@entries, \%metadata )

Store an array of directory entries, and optionally some directory metadata,
into the $cas, encoded in $format.

Returns the digest_hash of the new item.

=head2 decode

  $dir= $self->decode( \%params )

Same parameters as L</load>, except they are guaranteed to be a hashref, and it
should be assumed that this codec is the correct one to decode the directory.

=head2 encode

  $self->encode( \@entries, \%metadata )

Encode an array of directory entries, and attach the optional metadata to the
encoded directory.  Each item of @entries may be either a ::DirEnt object
or a hashref of fields.

Codecs should assert that each item has a 'type' and 'name' attribute.

Codecs should inspect 'name' and 'ref' to see if they contain InvalidUTF8
objects, and restore these objects during decode.

Should return a scalar of the serialized directory.

=head2 register_format

  $class->register_format( $format_id => $codec )

Registers a directory codec to be available to the factory method 'load'.

$format_id is a scalar.  Lowercase strings are reserved for the DataStore::CAS
distribution, and custom modules are encouraged to use their full package name
as the $format_id.

$codec is any object implementing L<encode|/"encode API"> and L<decode|/"decode API">.
It should probably be a subclass of DirCodec to take advantage of helper methods.

While the system could have been designed to auto-load classes on demand, that
seemed like a bad idea because it would allow the contents of the CAS to load
perl modules.  With this design, codecs must be manually registered (usually
during 'require' or 'use') before you will be able to decode or encode with
them.  All the directory codecs in the standard distribution of DataStore::CAS
are enabled by default.

=head1 EXTENDING

In order to write your own directory codec, all you need to do is implement
'encode' and 'decode'.

=head2 encode API

An encoder receives an array of directory entries, and an optional hashref of
metadata.  The metadata should be stored as-is.  The directory entries can be
stored however you like, and you may choose to store only a subset of fields.
(be sure to warn users in your documentation if you ignore fields).

The directories can be a mix of DirEnt objects and plain hashrefs.  You should
ensure that each one has a name and a type, that the type is valid, and that
the names aren't duplicated.

Your encoder should attempt to provide a "stable" encoding, so that if it is
called with the same parameters twice, it will return the same exact bytes.
This likely means you need to sort the directory entries, and that you need to
export hashrefs iteratively, because perl will re-arrange the keys randomly.

Your encoded string must be octets (not unicode).

=head2 decode API

A decoder takes a file (or a handle, or a scalar with all the data in it) and
attempts to build a DataStore::CAS::FS::Dir object which views the directory
entries.

See the L<Universal codec|DataStore::CAS::FS::DirCodec::Universal> for an example of how to decode from a plain scalar,
and L<Unix codec|DataStore::CAS::FS::DirCodec::Unix> for an example of how to read through the stream record by
record.

You can use the default directory class L<DataStore::CAS::FS::Dir>, or write
your own.  The default one requires the list of DirEnt objects to be built
first, but you could theoretically write an implementation that decodes the
entries on demand.

=head1 UTILITY METHODS

=head2 _magic_number

  $str= $class->_magic_number()

Returns a string that all serialized directories start with.
This is a constant and should never change.

=head2 _calc_header_length

  $len= $class->_calc_header_length( $format )

The header length is directly determined by the format string.
This method returns the header length in bytes.  A directory's encoded data
begins at this offset.

=head2 _read_format

  $fmt_string= $class->_read_format( \%params )

This method inspects the first few bytes of $params{file} to read the format
string, which it returns.  It first uses $params{data} if available, or
$params{handle}, or if neither is available it opens a new handle to the
file which it returns in $params.

=head2 _readall

  $class->_readall( $handle, $buf, $count, $offset )

A small wrapper around 'read()' which croaks if it can't read the full
requested number of bytes, and properly handles EINTR and EAGAIN and
partial reads.

Always returns true.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

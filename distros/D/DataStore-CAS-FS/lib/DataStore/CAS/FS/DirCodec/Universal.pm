package DataStore::CAS::FS::DirCodec::Universal;
use 5.0080001;
use strict;
use warnings;
use Try::Tiny;
use Carp;
use JSON 2.53 ();
require DataStore::CAS::FS::Dir;
require DataStore::CAS::FS::DirEnt;
require DataStore::CAS::FS::InvalidUTF8;
*decode_utf8= *DataStore::CAS::FS::InvalidUTF8::decode_utf8;

use parent 'DataStore::CAS::FS::DirCodec';

our $VERSION= '0.011000';

__PACKAGE__->register_format( universal => __PACKAGE__ );

# ABSTRACT: Codec for saving all arbitrary fields of a DirEnt


our $_json_coder;
sub _build_json_coder {
	DataStore::CAS::FS::InvalidUTF8->add_json_filter(
		JSON->new->utf8->canonical->convert_blessed, 1
	);
}

sub encode {
	my ($class, $entry_list, $metadata)= @_;
	ref($metadata) eq 'HASH' or croak "Metadata must be a hashref"
		if $metadata;

	my @entries= sort { $a->{name} cmp $b->{name} }
		map {
			my $entry= ref $_ eq 'HASH'? $_ : $_->as_hash;
			defined $entry->{name} or croak "Can't serialize nameless directory entry: ".JSON::encode_json($entry);
			defined $entry->{type} or croak "Can't serialize typeless directory entry: ".JSON::encode_json($entry);
			!defined($_) || (ref $_? ref($_)->can("TO_JSON") : &utf8::is_utf8($_) || !($_ =~ /[\x80-\xFF]/))
				or croak "Can't serialize $entry->{name}, all attributes must be unicode string, or have TO_JSON: '$_'"
				for values %$entry;
			$entry;
		} @$entry_list;

	$_json_coder ||= _build_json_coder();

	my $json= $_json_coder->encode($metadata || {});
	my $ret= "CAS_Dir 09 universal\n"
		."{\"metadata\":$json,\n"
		." \"entries\":[\n";
	for (@entries) {
		$ret .= $_json_coder->encode($_).",\n"
	}

	# remove trailing comma
	substr($ret, -2)= "\n" if @entries;
	return $ret."]}";
}


sub decode {
	my ($class, $params)= @_;
	defined $params->{format} or $params->{format}= $class->_read_format($params);
	my $bytes= $params->{data};
	my $handle= $params->{handle};

	# This implementation just processes the file as a whole.
	# Read it in if we don't have it yet.
	my $header_len= $class->_calc_header_length($params->{format});
	if (defined $bytes) {
		substr($bytes, 0, $header_len)= '';
	}
	else {
		defined $handle or $handle= $params->{file}->open;
		seek($handle, $header_len, 0) or croak "seek: $!";
		local $/= undef;
		$bytes= <$handle>;
	}

	$_json_coder ||= _build_json_coder();

	my $data= $_json_coder->decode($bytes);
	defined $data->{metadata} && ref($data->{metadata}) eq 'HASH'
		or croak "Directory data is missing 'metadata'";
	defined $data->{entries} && ref($data->{entries}) eq 'ARRAY'
		or croak "Directory data is missing 'entries'";
	my @entries;
	for my $ent (@{$data->{entries}}) {
		push @entries, DataStore::CAS::FS::DirEnt->new($ent);
	};
	return DataStore::CAS::FS::Dir->new(
		file => $params->{file},
		format => $params->{format},
		entries => \@entries,
		metadata => $data->{metadata}
	);
}

1;

__END__

=pod

=head1 NAME

DataStore::CAS::FS::DirCodec::Universal - Codec for saving all arbitrary fields of a DirEnt

=head1 VERSION

version 0.011000

=head1 SYNOPSIS

  require DataStore::CAS::FS::DirCodec::Universal
  
  my %metadata= ( foo => 1, bar => 42 );
  my @entries= ( { name => 'file1', type => 'file', ref => 'SHA1DIGESTVALUE', mtime => '1736354736' } );
  
  my $digest_hash= DataStore::CAS::FS::DirCodec->put( $cas, 'universal', \@entries, \%metadata );
  my $dir= DataStore::CAS::FS::DirCodec->load( $cas->get($digest_hash) );
  
  print Dumper( $dir->get_entry('file1') );

=head1 DESCRIPTION

This L<DirCodec|DataStore::CAS::FS::DirCodec> can store any arbitrary metadata about a file.
It uses L<JSON> for its encoding, so other languages/platforms should be able to easily interface
with the files this codec writes ... except for Unicode caveats.

=head2 Unicode

JSON requires that all data be proper Unicode, and some filenames might be
a sequence of bytes which is not a valid Unicode string.  While the high-ascii
bytes of these filenames could be encoded as unicode code-points, this would
create an ambiguity with the names that actually were Unicode.  Instead, I
wrap values which are intended to be a string of octets in an instance of
L<DataStore::CAS::Dir::InvalidUTF8>, which gets written into JSON as

  C<{ "*InvalidUTF8*": $bytes_as_codepoints }>

Any attribute which contains bytes >= 0x80 and which does not have Perl's
unicode flag set will be encoded this way, so that it comes back as it went in.

However, since filenames are intended to be human-readable, they are decoded as
unicode strings when appropriate, even if they arrived as octets which just
happened to be valid UTF-8.

=head1 METHODS

=head2 encode

  my $serialized= $class->encode( \@entries, \%metadata )

Serialize the given entries into a scalar.

C<@entries> is an array of L<DirEnt|DataStore::CAS::FS::DirEnt> objects or hashrefs mimicing them.

C<%metadata> is a hash of arbitrary metadata which you want saved along with the
directory.

This "Universal" DirCodec serializes the data as a short one-line header
followed by a string of JSON. JSON isn't the most efficient format around,
but it has wide cross-platform support, and can store any arbitrary L<DirEnt|DataStore::CAS::FS::DirEnt>
attributes that you might have, and even structure within them.

The serialization contains newlines in a manner that should make it convenient
to write custom processing code to inspect the contents of the directory
without decoding the whole thing with a JSON library.

If you add anything to the metadata, try to keep the data consistent so that
two encodings of the same directory are identical.  Otherwise, (in say, a
backup utility) you will waste disk space storing multiple copies of the same
directory.

=head2 decode

  $dir= $class->decode( %params )

Reverses C<encode>, to create a Dir object.

See L<DirCodec-E<gt>load|DataStore::CAS::FS::DirCodec/load> for details on C<%params>.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

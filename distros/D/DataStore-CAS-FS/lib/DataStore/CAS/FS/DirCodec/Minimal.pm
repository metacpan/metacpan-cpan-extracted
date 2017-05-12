package DataStore::CAS::FS::DirCodec::Minimal;
use 5.008001;
use strict;
use warnings;
use Try::Tiny;
use Carp;
use JSON 2.53 ();
require DataStore::CAS::FS::InvalidUTF8;
require DataStore::CAS::FS::Dir;
*decode_utf8= *DataStore::CAS::FS::InvalidUTF8::decode_utf8;

use parent 'DataStore::CAS::FS::DirCodec';

our $VERSION= '0.011000';

__PACKAGE__->register_format('minimal' => __PACKAGE__);
__PACKAGE__->register_format('' => __PACKAGE__);

# ABSTRACT: Directory representation with minimal metadata


our %_TypeToCode= ( file => 'f', dir => 'd', symlink => 'l', chardev => 'c', blockdev => 'b', pipe => 'p', socket => 's', whiteout => 'w' );
our %_CodeToType= map { $_TypeToCode{$_} => $_ } keys %_TypeToCode;
sub encode {
	my ($class, $entry_list, $metadata)= @_;
	my @entries= map {
		my ($type, $ref, $name)= ref $_ eq 'HASH'?
			( $_->{type}, $_->{ref}, $_->{name} )
			: ( $_->type, $_->ref, $_->name );

		defined $type
			or croak "'type' attribute is required";
		my $code= $_TypeToCode{$type}
			or croak "Unknown directory entry type '$type' for entry $_";
		defined $name
			or croak "'name' attribute is required";
		_make_utf8($name)
			or croak "'name' must be a unicode scalar or an InvalidUTF8 instance";
		$ref= '' unless defined $ref;
		_make_utf8($ref)
			or croak "'ref' must be a unicode scalar or an InvalidUTF8 instance";

		croak "'name' too long: '$name'" if 255 < length $name;
		croak "'ref' too long: '$ref'" if 255 < length $ref;
		pack('CCA', length($name), length($ref), $code).$name."\0".$ref."\0"
	} @$entry_list;
	
	my $ret= "CAS_Dir 00 \n";
	if ($metadata and scalar keys %$metadata) {
		my $enc= JSON->new->utf8->canonical->convert_blessed;
		$ret .= $enc->encode($metadata);
	}
	$ret .= "\0";
	$ret .= join('', sort { substr($a,3) cmp substr($b,3) } @entries );
	croak "Accidental unicode concatenation"
		if utf8::is_utf8($ret);
	$ret;
}

# Convert string in-place to utf-8 bytes, or return false.
# A less speed-obfuscated version might read:
#  my $str= shift;
#  if (ref $str) {
#    return 0 unless ref($str)->can('TO_UTF8');
#    $_[0]= $str->TO_UTF8;
#    return 1;
#  } elsif (utf8::is_utf8($str)) {
#    utf8::encode($_[0]);
#    return 1;
#  } else {
#    return !($_[0] =~ /[\x7F-\xFF]/);
#  }
sub _make_utf8 {
	ref $_[0]?
		(ref($_[0])->can('TO_UTF8') && (($_[0]= $_[0]->TO_UTF8) || 1))
		: &utf8::is_utf8 && (&utf8::encode || 1) || !($_[0] =~ /[\x80-\xFF]/);
}


sub decode {
	my ($class, $params)= @_;
	$params->{format}= $class->_read_format($params)
		unless defined $params->{format};
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
	
	my $meta_end= index($bytes, "\0");
	$meta_end >= 0 or croak "Missing end of metadata";
	if ($meta_end > 0) {
		my $enc= JSON->new()->utf8->canonical->convert_blessed;
		DataStore::CAS::FS::InvalidUTF8->add_json_filter($enc);
		$params->{metadata}= $enc->decode(substr($bytes, 0, $meta_end));
	} else {
		$params->{metadata}= {};
	}

	my $pos= $meta_end+1;
	my @ents;
	while ($pos < length($bytes)) {
		my ($nameLen, $refLen, $code)= unpack('CCA', substr($bytes, $pos, 3));
		my $end= $pos + 3 + $nameLen + 1 + $refLen + 1;
		($end <= length($bytes))
			or croak "Unexpected end of file";
		my $name= decode_utf8(substr($bytes, $pos+3, $nameLen));
		my $ref= $refLen? decode_utf8(substr($bytes, $pos+3+$nameLen+1, $refLen)) : undef;
		push @ents, bless [ $code, $name, $ref ], __PACKAGE__.'::Entry';
		$pos= $end;
	}
	return DataStore::CAS::FS::Dir->new(
		file => $params->{file},
		format => 'minimal', # we encode with format string '', but this is what we want the user to see.
		entries => \@ents,
		metadata => $params->{metadata}
	);
}

package DataStore::CAS::FS::DirCodec::Minimal::Entry;
use strict;
use warnings;
use parent 'DataStore::CAS::FS::DirEnt';

sub type { $_CodeToType{$_[0][0]} }
sub name { $_[0][1] }
sub ref  { $_[0][2] }
sub as_hash {
	my $self= shift;
	return $self->[3] ||= {
		type => $self->type,
		name => $self->name,
		(defined $self->[2]? (ref => $self->[2]) : ())
	};
}

1;

__END__

=pod

=head1 NAME

DataStore::CAS::FS::DirCodec::Minimal - Directory representation with minimal metadata

=head1 VERSION

version 0.011000

=head1 DESCRIPTION

This class packs a directory as a list of [type, hash, filename], which is
very efficient, but omits metadata that you often would want in a backup.

This is primarily intended for making small frequent backups inbetween more
thorough nightly backups.

=head1 METHODS

=head2 encode

  $serialized= $class->encode( \@entries, \%metadata )

Serialize the given entries into a scalar.

Serialize the bare minimum fields of each entry.  Each entry will have 3
pieces of data saved: I<type>, I<name>, and I<ref>.

The C<%metadata> is encoded using L<JSON>, which isn't very compact, but if
you really want a minimal encoding you shouldn't supply metadata anyway.

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

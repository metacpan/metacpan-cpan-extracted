package DataStore::CAS::FS::DirCodec::Unix;
use 5.008;
use strict;
use warnings;
use Try::Tiny;
use Carp;
use JSON 2.53 ();
use Scalar::Util 'looks_like_number';
require DataStore::CAS::FS::Dir;
require DataStore::CAS::FS::DirEnt;
require DataStore::CAS::FS::InvalidUTF8;
*decode_utf8= *DataStore::CAS::FS::InvalidUTF8::decode_utf8;

use parent 'DataStore::CAS::FS::DirCodec';

our $VERSION= '0.011000';

__PACKAGE__->register_format(unix => __PACKAGE__);

# ABSTRACT: Efficiently encode only the attributes of a UNIX stat()


our $_json_coder;
sub _build_json_coder {
	DataStore::CAS::FS::InvalidUTF8->add_json_filter(
		JSON->new->utf8->canonical->convert_blessed, 1
	);
}

our %_TypeToCode= (
	file => ord('f'), dir => ord('d'), symlink => ord('l'),
	chardev => ord('c'), blockdev => ord('b'),
	pipe => ord('p'), socket => ord('s'), whiteout => ord('w'),
);
our %_CodeToType= map { $_TypeToCode{$_} => $_ } keys %_TypeToCode;
our @_FieldOrder= qw(
	type name ref size modify_ts unix_uid unix_gid unix_mode metadata_ts
	access_ts unix_nlink unix_dev unix_inode unix_blocksize unix_blockcount
);

sub encode {
	my ($class, $entry_list, $metadata)= @_;
	$metadata= defined($metadata)? { %$metadata } : {};
	defined $metadata->{_}
		and croak '$metadata{_} is reserved for the directory encoder';
	my (%umap, %gmap);
	my @entries= map {
		my $e= ref $_ eq 'HASH'? $_ : $_->as_hash;
		defined $e->{type}
			or croak "'type' attribute is required";
		my $code= $_TypeToCode{$e->{type}}
			or croak "Unknown directory entry type: ".$e->{type};

		my $name= $e->{name};
		defined $name
			or croak "'name' attribute is required";
		_make_utf8($name)
			or croak "'name' must be a unicode scalar or an InvalidUTF8 instance";

		my $ref= $e->{ref};
		$ref= '' unless defined $ref;
		_make_utf8($ref)
			or croak "'ref' must be a unicode scalar or an InvalidUTF8 instance";

		$umap{$e->{unix_uid}}= $e->{unix_user}
			if defined $e->{unix_uid} && defined $e->{unix_user};
		$gmap{$e->{unix_gid}}= $e->{unix_group}
			if defined $e->{unix_gid} && defined $e->{unix_group};

		my $int_attr_str= join(":",
			map { !defined $_? '' : looks_like_number($_)? $_ : croak "Invalid unix attribute number: $_" }
				@{$e}{@_FieldOrder[3..$#_FieldOrder]}
		);
		# As an optimization, all undef trailing fields can be chopped off.
		$int_attr_str =~ s/:+$//;
		
		croak "'name' too long: '$name'" if length($name) > 255;
		croak "'ref' too long: '$ref'" if length($ref) > 255;
		croak "Unix fields too long: '$int_attr_str'" if length($int_attr_str) > 255;
		pack('CCCC', length($name), length($ref), length($int_attr_str), $code).$name."\0".$ref."\0".$int_attr_str;
	} @$entry_list;

	# Save the mapping of UID to User and GID to Group
	$metadata->{_}{umap}= \%umap;
	$metadata->{_}{gmap}= \%gmap;
	
	my $meta_json= ($_json_coder ||= _build_json_coder())->encode($metadata);
	my $ret= "CAS_Dir 04 unix\n"
		.pack('N', length($meta_json)).$meta_json
		.join('', sort { substr($a,4) cmp substr($b,4) } @entries);
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
	my $handle= $params->{handle};
	if (!$handle) {
		if (defined $params->{data}) {
			open($handle, '<', \$params->{data})
				or croak "can't open handle to scalar";
		} else {
			$handle= $params->{file}->open;
		}
	}

	my $header_len= $class->_calc_header_length($params->{format});
	seek($handle, $header_len, 0) or croak "seek: $!";

	my (@entries, $buf, $pos);

	# first, pull out the metadata, which includes the UID map and GID map.
	$class->_readall($handle, $buf, 4);
	my ($dirmeta_len)= unpack('N', $buf);
	$class->_readall($handle, my $json, $dirmeta_len);
	my $meta= ($_json_coder ||= _build_json_coder())->decode($json);

	# Quick sanity checks
	ref $meta->{_}{umap} and ref $meta->{_}{gmap}
		or croak "Incorrect directory metadata";
	my $dirmeta= delete $meta->{_};

	while (!eof $handle) {
		$class->_readall($handle, $buf, 4);
		my ($name_len, $ref_len, $meta_len, $code)= unpack('CCCC', $buf);
		$class->_readall($handle, $buf, $name_len+$ref_len+$meta_len+2);
		my @fields= (
			$dirmeta,
			$code,
			DataStore::CAS::FS::InvalidUTF8->decode_utf8(substr($buf, 0, $name_len)),
			$ref_len? DataStore::CAS::FS::InvalidUTF8->decode_utf8(substr($buf, $name_len+1, $ref_len)) : undef,
			map { length($_)? $_ : undef } split(":", substr($buf, $name_len+$ref_len+2, $meta_len)),
		);
		push @entries, bless(\@fields, __PACKAGE__.'::Entry');
	}
	close $handle;
	return DataStore::CAS::FS::Dir->new(
		file => $params->{file},
		format => $params->{format},
		metadata => $meta,
		entries => \@entries,
	);
}

package DataStore::CAS::FS::DirCodec::Unix::Entry;
use strict;
use warnings;
use parent 'DataStore::CAS::FS::DirEnt';

sub _dirmeta        { $_[0][0] }
sub type            { $_CodeToType{$_[0][1]} }
sub name            { $_[0][2] }
sub ref             { $_[0][3] }
sub size            { $_[0][4] }
sub modify_ts       { $_[0][5] }
sub unix_uid        { $_[0][6] }
sub unix_gid        { $_[0][7] }
sub unix_mode       { $_[0][8] }
sub metadata_ts     { $_[0][9] }
sub access_ts       { $_[0][10] }
sub unix_nlink      { $_[0][11] }
sub unix_dev        { $_[0][12] }
sub unix_inode      { $_[0][13] }
sub unix_blocksize  { $_[0][14] }
sub unix_blockcount { $_[0][15] }

*unix_mtime= *modify_ts;
*unix_atime= *access_ts;
*unix_ctime= *metadata_ts;
sub unix_user       { my $self= shift; $self->_dirmeta->{umap}{ $self->unix_uid } }
sub unix_group      { my $self= shift; $self->_dirmeta->{gmap}{ $self->unix_gid } }

sub as_hash {
	my $self= shift;
	return {
		type => $self->type,
		map { $_FieldOrder[$_-1] => $self->[$_] } grep { defined $self->[$_] } 2 .. $#$self
	};
}

1;

__END__

=pod

=head1 NAME

DataStore::CAS::FS::DirCodec::Unix - Efficiently encode only the attributes of a UNIX stat()

=head1 VERSION

version 0.011000

=head1 DESCRIPTION

This directory encoder/decoder encodes only the fields of a L<DirEnt|DataStore::CAS::FS::DirEnt>
corresponding to a unix stat_t structure.  (or more precisely, the fields
perl returns from the stat function)  Any other fields in the L<DirEnt|DataStore::CAS::FS::DirEnt> are
ignored.

It does this much more efficiently than would be done in L<JSON>, but still uses
text, to avoid complications of endian-ness and word size. (and because 32-bit
perl can't numerically process 64-bit integers)  The encoding is further
optimized by ordering the fields by likelyhood of being used, and truncating
records at the last used field.

It also imposes some restrictions: 'name' and 'ref' must each be less than 256
bytes when encoded as UTF-8.  There is also a limitation on the unix stat
values, but they will all fit even with max-length 64 bit integers, so this
shouldn't ever be a problem.

=head1 METHODS

=head2 encode

  $serialized= $class->encode( \@entries, \%metadata )

See L<DirCodec-E<gt>encode|DataStore::CAS::FS::DirCodec/encode> for details.

=head2 decode

  my $dir= $class->decode( \%params )

See L<DirCodec-E<gt>load|DataStore::CAS::FS::DirCodec/load> for details on C<%params>.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

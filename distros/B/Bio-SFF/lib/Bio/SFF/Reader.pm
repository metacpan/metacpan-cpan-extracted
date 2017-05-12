package Bio::SFF::Reader;
{
  $Bio::SFF::Reader::VERSION = '0.007';
}

use Moo::Role;

use Bio::SFF::Entry;
use Bio::SFF::Header;
use Carp qw/croak/;
use Config;
use Const::Fast;
use Fcntl qw/SEEK_SET/;
use FileHandle;
use Scalar::Util qw/reftype/;

const my $padding_to => 8;
const my $index_header => 8;
const my $header_size => 31;
const my $entry_header_size => 4;
const my $idx_off_type => ($] >= 5.010 && $Config{use64bitint} ? 'Q>' : 'x[N]N');
const my $size_of_flowgram_value => 2;
const my $uses_number_of_bases => 3;

requires '_has_index';

sub _roundup {
	my $number = shift;
	my $remain = $number % $padding_to;
	return $number + ($remain ? $padding_to - $remain : 0);
}

has _fh => (
	is       => 'ro',
	required => 1,
	init_arg => 'file',
	isa      => sub {
		reftype($_[0]) eq 'GLOB';
	},
	coerce   => sub {
		my $val = shift;
		return $val if ref $val and reftype($val) eq 'GLOB';
		open my $fh, '<:raw', $val or croak "Could open file $val: $!";
		return $fh;
	}
);

has header => (
	is => 'ro',
	init_arg => undef,
	builder => '_build_header',
	lazy => 1,
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines,Subroutines::ProhibitBuiltinHomonyms)
sub _build_header {
	my $self = shift;
	my $templ = "a4N $idx_off_type N2n3C";
	my ($magic, $version, $index_offset, $index_length, $number_of_reads, $header_length, $key_length, $number_of_flows_per_read, $flowgram_format_code) = unpack $templ, $self->_read_bytes($header_size);
	my ($flow_chars, $key_sequence) = unpack sprintf('a%da%d', $number_of_flows_per_read, $key_length), $self->_read_bytes($header_length - $header_size);

	my $header = Bio::SFF::Header->new(
		magic => $magic,
		version => $version,
		index_offset => $index_offset,
		index_length => _roundup($index_length),
		number_of_reads => $number_of_reads,
		header_length => _roundup($header_length),
		number_of_flows_per_read => $number_of_flows_per_read,
		flowgram_format_code => $flowgram_format_code,
		flow_chars => $flow_chars,
		key_sequences => $key_sequence,
	);

	return $header;
}

for my $method (qw/number_of_reads number_of_flows_per_read index_offset index_length/) {
	has "_$method" => (
		is => 'ro',
		init_arg => undef,
		default => sub {
			my $self = shift;
			return $self->header->$method;
		},
		lazy => 1,
	);
}

sub _read_bytes {
	my ($self, $num) = @_;
	my $buffer;
	croak "Could not read SFF file: $!" if not defined read $self->_fh, $buffer, $num;
	return $buffer;
}

my $read_template = 'Nnnnn a%d';
my @header_keys = qw/clip_qual_left clip_qual_right clip_adaptor_left clip_adaptor_right name/;

sub _read_entry {
	my $self = shift;
	my %entry;
	@entry{qw/read_header_length name_length/} = unpack 'nn', $self->_read_bytes($entry_header_size);
	(my ($number_of_bases), @entry{@header_keys}) = unpack sprintf($read_template, $entry{name_length}), $self->_read_bytes($entry{read_header_length} - $entry_header_size);

	my $data_template = sprintf 'a%da%da%da%d', $size_of_flowgram_value * $self->_number_of_flows_per_read, ($number_of_bases) x $uses_number_of_bases;
	my $data_length = _roundup($size_of_flowgram_value * $self->_number_of_flows_per_read + $uses_number_of_bases * $number_of_bases);
	@entry{qw/flowgram_values flow_index_per_base bases quality_scores/} = unpack $data_template, $self->_read_bytes($data_length);
	return Bio::SFF::Entry->new(\%entry);
}

has _index_info => (
	is => 'ro',
	init_arg => undef,
	builder => '_build_index_info',
	lazy => 1,
);

sub _build_index_info {
	my $self = shift;
	my ($index_offset, $index_length) = ($self->header->index_offset, $self->header->index_length);
	return if !$index_offset || !$index_length;
	
	my $tell = $self->_fh->tell;
	$self->_fh->seek($index_offset, SEEK_SET);
	my ($magic_number) = unpack 'A8', $self->_read_bytes($index_header);
	$self->_fh->seek($tell, SEEK_SET);
	return $magic_number;
}

has manifest => (
	is => 'ro',
	init_arg => undef,
	builder => '_build_manifest',
	lazy => 1,
);

sub _build_manifest {
	my $self = shift;
	return $self->_index->manifest if $self->_has_index;
	my $magic_number = $self->_index_info;
	if ($magic_number eq '.mft1.00') { 
		my ($index_offset, $index_length) = ($self->_index_offset, $self->_index_length);
		my $tell = $self->_fh->tell;
		$self->_fh->seek($index_offset + $index_header, SEEK_SET);
		my $xml = $self->_read_manifest($magic_number);
		$self->_fh->seek($tell, SEEK_SET);
		return $xml;
	}
	return;
}

sub _read_manifest {
	my ($self, $magic_number) = @_;
	my $xmldata_head = $self->_read_bytes($index_header);
	if ( $magic_number eq '.mft1.00') {
		my ($xml_size, $data_size) = unpack 'NN', $xmldata_head;
		return $self->_read_bytes($xml_size);
	}
	return;
}

1;

#ABSTRACT: An SFF reader role

__END__

=pod

=head1 NAME

Bio::SFF::Reader - An SFF reader role

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This module is a role and as such can not be instanciated directly. Instead, one should use L<Bio::SFF::Reader::Sequential|Bio::SFF::Reader::Sequential> or L<Bio::SFF::Reader::Random|Bio::SFF::Reader::Random> classes that implement this role. They inherit all methods in this role.

=head1 METHODS

=head2 new(...)

This method creates a new SFF Reader object. It currently takes one named argument:

=over 4

=item * file

The file that should be read. This can either be a filename or a filehandle.

=back

=head2 manifest()

This returns the (XML) manifest as a bytestring or undef if none is present.

=head2 header()

Returns the L<Bio::SFF::Header|Bio::SFF::Header> object associated with this reader.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans, Utrecht University.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

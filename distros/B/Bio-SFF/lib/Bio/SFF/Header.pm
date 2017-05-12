package Bio::SFF::Header;
{
  $Bio::SFF::Header::VERSION = '0.007';
}

use Moo;
use Sub::Name;

use Scalar::Util qw/looks_like_number/;

for my $attr (qw/magic version index_offset index_length number_of_reads header_length number_of_flows_per_read flowgram_format_code/) {
	has $attr => (
		is => 'ro',
		required => 1,
		isa => sub {
			return looks_like_number($_[0]);
		},
	);
}

for my $attr(qw/flow_chars key_sequences/) {
	has $attr => (
		is => 'ro',
		required => 1,
		isa => sub {
			return defined && ref($_[0]) eq '';
		},
	);
}

1;

#ABSTRACT: An SFF header

__END__

=pod

=head1 NAME

Bio::SFF::Header - An SFF header

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This object represents the header of an SFF file. You probably don't want to deal with this in any way.

=head1 ATTRIBUTES

=head2 magic

The magic bytes at the start of any SFF file, this is always C<779314790>.

=head2 version

The version of SFF that is used. This must currently be 1.

=head2 index_offset

The offset of the index, or C<0> if no index is present.

=head2 index_length

The length of the index, or C<0> if no index is present.

=head2 number_of_reads

The number of reads in the SFF file.

=head2 header_length

The length of the header in bytes.

=head2 number_of_flows

The number of flows in the entries.

=head2 flowgram_format_code

Currently, this must always be C<1>.

=head2 flow_chars

The array of nucleotide bases ('A', 'C', 'G' or 'T') that correspond to the nucleotides used for each flow of each read.

=head2 key_sequences

The nucleotide bases of the key sequence used for the reads.

=head2 number_of_flows_per_read

The number of flowgram values in each entry.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans, Utrecht University.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

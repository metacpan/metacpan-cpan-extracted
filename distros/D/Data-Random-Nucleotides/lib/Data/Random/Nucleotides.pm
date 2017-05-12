package Data::Random::Nucleotides;
use strict;
use warnings;
use Carp;
use Data::Dumper;

require Exporter;
use vars qw(
	@ISA
	%EXPORT_TAGS
	@EXPORT_OK
	@EXPORT
);

@ISA = qw(Exporter);

%EXPORT_TAGS = (
	'all' => [
		qw(
		rand_nuc
		rand_wrapped_nuc
		rand_fasta
		)
	]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = qw();

use Data::Random qw/:all/;

$Data::Random::Nucleotides::VERSION = '0.1';


# ABSTRACT: A Module to generate random nucleotide strings and common formats.

=head1 NAME

Data::Random::Nucleotides - Generate random nucleotide strings.

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use Data::Random::Nucleotides qw/:all/;

    # Generate a string of 200 random A/C/G/T characters.
    $nucs = rand_nuc ( size => 200 );

    # Generate a string of random A/C/G/T between 20 and 500 characters.
    $nucs = rand_nuc ( min => 20, max => 500 );

    # Generate a string of 30 random A/C/G/T/N characters.
    $nucs = rand_nuc ( size => 30, N=>1 );

    # Generate a multi-lined string of 500 random A/C/G/T/N characters.
    # The 500 characters will be split into lines of 70 characters each.
    $nucs = rand_wrapped_nuc ( size => 500 );

    # Generate a string containing a single FASTA-like sequence text.
    $fasta = rand_fasta ( size => 200 ) ;

=head1 DESCRIPTION

This module is a thin wrapper around L<Data::Random>, providing utility functions
to generate nucleotide sequence strings and FASTA-looking strings.

nucleotide strings contain only A/C/G/T (and possibly N) characters.
FASTA strings are multi-lined nucleotide strings, with the first line containing a sequence id (see L<http://en.wikipedia.org/wiki/FASTA_format>) .

=head1 METHODS

=head2 rand_nuc()

Returns a string of random nucleotides.

See C<rand_set> in L<Data::Random> for possible parameters (e.g. C<size>, C<min>, C<max>).

If C<N> is set, N will be a possible nucleoide. Otherwise - only A/C/G/T will be returned.

=cut
sub rand_nuc
{
	my %args = @_;
	my @set = qw/A C G T/;
	push @set, "N" if defined $args{N};

	my $size;
	if ( defined $args{size} ) {
		$size = $args{size};
	} else {
		my $min = $args{min} or croak "missing 'min' value (or use 'size')";
		my $max = $args{max} or croak "missing 'max' value (or use 'size')";
		$size = $min + int(rand($max-$min));
	}
	my @nucs;
	foreach ( 1 .. $size ) {
		push @nucs, rand_chars ( set => \@set, size=>1 ) ;
	}
	return join("", @nucs);
}

=head2 rand_wrapped_nuc()

Returns a multi-lined string of random nucleotides.

See C<rand_nuc> for all possible parameters.

The returned string will be broken into lines of 70 characeters each.

=cut
sub rand_wrapped_nuc
{
	my $seq = rand_nuc(@_);
	$seq =~ s/([^\n]{70})/$1\n/g;
	return $seq;
}


=head2 rand_fasta()

Returns a random FASTA string.

First line begins with a C<< > >> prefix, and a random sequence ID (alphanumeric).

The rest of the lines are random nucleotide strings, wrapped at 70 characters.

=cut
sub rand_fasta
{
	my $id = ">" . join("", rand_chars( set => 'loweralpha', size=>3 ) ) .
			"-" . sprintf("%06d", int(rand())) ;
	my $seq = rand_wrapped_nuc(@_);
	return $id . "\n" . $seq ;
}


=head1 AUTHOR

Assaf Gordon, C<< <gordon at cshl.edu> >>

=head1 TODO

=over

=item Finer control over nucleotide composition (currently: completely random)

=item Generate FASTQ files

=item Support lower-case nucleotides

=item generate amino-acid codes

=back

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/agordon/Data-Random-Nucleotides/issues>

=head1 SEE ALSO

BioPerl provides similar functionality L<http://www.bioperl.org/wiki/Random_sequence_generation>, but requires installing the L<BioPerl> module.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Assaf Gordon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

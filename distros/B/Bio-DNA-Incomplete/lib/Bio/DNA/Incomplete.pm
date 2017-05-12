package Bio::DNA::Incomplete;
{
  $Bio::DNA::Incomplete::VERSION = '0.004';
}
use strict;
use warnings;

use Carp 'croak';
use Sub::Exporter::Progressive -setup => { exports => [qw/pattern_to_regex pattern_to_regex_string match_pattern all_possibilities/], groups => { default => [qw/pattern_to_regex pattern_to_regex_string match_pattern all_possibilities/]} };

my %simple = map { ( $_ => $_ ) } qw/A C G T/;

my %meaning_of = (
	R => 'AG',
	Y => 'CT',
	W => 'AT',
	S => 'CG',
	M => 'AC',
	K => 'GT',
	H => 'ACT',
	B => 'CGT',
	V => 'ACG',
	D => 'AGT',
	N => 'ACGT',
);
my %pattern_for = %meaning_of;
$_ = "[$_]" for values %pattern_for;
my ($invalid) = map { qr/[^$_]/ } join '', keys %simple, keys %pattern_for;
my %bases_for = (%meaning_of, %simple);
$_ = [ split // ] for values %bases_for;

sub pattern_to_regex_string {
	my $pattern = uc shift;
	croak 'Invalid pattern' if $pattern =~ /$invalid/;

	$pattern =~ s/([^ATCG])/$pattern_for{$1}/g;
	return "(?i:$pattern)";
}

sub pattern_to_regex {
	my $pattern = uc shift;
	my $string = pattern_to_regex_string($pattern);
	return qr/$string/;
};

sub match_pattern {
	my ($pattern, @args) = @_;
	my $regex = pattern_to_regex($pattern);
	return grep { $_ =~ /\A $regex \z/xms } @args;
}

sub _all_possibilities {
	my ($current, @rest) = @_;
	if (@rest) {
		my @ret;
		my $pretail = _all_possibilities(@rest);
		# Chunks longer than 1 are always /[ACTG]+/, so always match themselves
		for my $head (length $current == 1 ? @{ $bases_for{$current} } : $current) {
			for my $tail (@{$pretail}) {
				push @ret, $head.$tail;
			}
		}
		return \@ret;
	}
	else {
		return $bases_for{$current} || [ $current ];
	}
}

sub all_possibilities {
	my $pattern = uc shift;
	my @bases = $pattern =~ m/[ACTG]+|[^ACGT]/g;
	return @{ _all_possibilities(@bases) };
}

1;

#ABSTRACT: Match incompletely specified bases in nucleic acid sequences

__END__

=pod

=head1 NAME

Bio::DNA::Incomplete - Match incompletely specified bases in nucleic acid sequences

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Sometimes DNA patterns are given with incomplete nucleotides that match more than one real nucleotide. This module helps you deal with them.

=head1 FUNCTIONS

=head2 match_pattern($pattern, @things_to_test)

Returns the list of sequences that match C<$pattern>.

=head2 pattern_to_regex($pattern)

Returns a compiled regex which is the equivalent of the pattern.

=head2 pattern_to_regex_string($pattern)

Returns a regex string which is the equivalent of the pattern.

=head2 all_possibilities($pattern)

Returns a list of all possible sequences that can match the pattern.

=head1 SEE ALSO

=over 4

=item * L<Nomenclature for Incompletely Specified Bases in Nucleic Acid Sequences|http://www.chem.qmul.ac.uk/iubmb/misc/naseq.html>

=item * Text::Glob

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans, Utrecht University.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

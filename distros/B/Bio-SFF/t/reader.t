#! perl

use strict;
use warnings FATAL => 'all';

use Test::More 0.88;

use Bio::SFF::Reader::Random;
use Bio::SFF::Reader::Sequential;
use File::Spec::Functions qw/catfile/;
use Module::Load qw/load/;

my $random = Bio::SFF::Reader::Random->new(file => catfile(qw/corpus E3MFGYR02_random_10_reads.sff/));

like($random->manifest, qr{\Q<accession_prefix>E47WFAY</accession_prefix>}, 'Manifest is present');

is_deeply($random->_index->_offsets, $random->_read_slow_index->_offsets, 'Offsets are correct');

my $sequential = Bio::SFF::Reader::Sequential->new(file => catfile(qw/corpus E3MFGYR02_random_10_reads.sff/));

my (@sequences, $sequence);
push @sequences, $sequence->name while $sequence = $sequential->next_entry;
$sequential->reset;
is_deeply([ sort keys %{ $random->_index->_offsets }], [ sort @sequences ]);

equal_sffs(at_end => [ qw/corpus E3MFGYR02_alt_index_at_end.sff/ ]);
equal_sffs(at_start => [ qw/corpus E3MFGYR02_alt_index_at_start.sff/]);
equal_sffs(in_middle => [ qw/corpus E3MFGYR02_alt_index_in_middle.sff/]);
equal_sffs(at_start2 => [ qw/corpus E3MFGYR02_index_at_start.sff/]);
equal_sffs(in_middle2 => [ qw/corpus E3MFGYR02_index_in_middle.sff/]);

SKIP: {
	skip 'No Bio::Perl available, skiping some tests', 1 if not eval { load('Bio::SeqIO'); 1; };

	my $fastas = Bio::SeqIO->new(-file => catfile(qw/corpus E3MFGYR02_random_10_reads_no_trim.fasta/), -format => 'fasta');
	my $quals  = Bio::SeqIO->new(-file => catfile(qw/corpus E3MFGYR02_random_10_reads_no_trim.qual/), -format => 'qual');

	my $counter = 0;
	while (1) {
		my $seq = $fastas->next_seq;
		my $qual = $quals->next_seq;
		my $entry = $sequential->next_entry;
		last if not defined $seq or not defined $qual or not defined $entry;
		is($entry->bases, uc $seq->seq, "Sequence $counter equals reference $counter, length " . length $entry->bases);
		is(length $entry->bases, scalar($entry->quality_scores), 'Got as many bases as quality scores');
		is_deeply([ $entry->quality_scores ], $qual->qual, "Quality $counter equals reference $counter, length " . scalar @{$qual->qual});
		$counter++;
	}
	$sequential->reset;
}

sub equal_sffs {
	my ($name, $filename) = @_;
	my $other = Bio::SFF::Reader::Sequential->new(file => catfile(@{$filename}));
	my $counter = 0;
	note("Now testing $name");
	while (1) {
		my $left = $other->next_entry;
		my $right = $sequential->next_entry;
		if (not defined $left or not defined $right) {
			is($left, $right, "left and right are equally long");
			last;
		}
		is($left->name, $right->name, "Names are identical $counter");
		is($left->bases, $right->bases, "Sequences are identical $counter");
		$counter++;
	}
	$sequential->reset;
}
done_testing;

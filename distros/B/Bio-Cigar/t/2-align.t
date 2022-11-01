# Test the align() method of Bio::Cigar.

use strict;
use warnings;
use Test::More tests => 5;
use Bio::Cigar;
use Test::Exception;

# Test data
my $query_seq     = 'GGAAAATCGGCATGC';
my $query_seq_rev = 'GCAUGCCGATTTTCC';      # reverse complement of query
my   $ref_seq     = 'CCCCGGCGGGATGCAAA';
my $ref_start     = 5;                      # first matched position of ref
my $cigar_string  = '2=4IX3D4M3N2P4S10H';
my $cigar;

# Test align method availablility.
subtest 'Callable' => sub {
    plan tests => 2;

    $cigar = Bio::Cigar->new($cigar_string);
    isa_ok $cigar, 'Bio::Cigar';
    can_ok $cigar, 'align';
} or BAIL_OUT('Cannot instantiate CIGAR string object or cannot align, stopping');

# Test sanity checks.
subtest 'Sanity checks' => sub {
    plan tests => 3;

    my $wrong_query = 'ATGC';
    throws_ok { $cigar->align($wrong_query, $ref_seq) }
              qr/Query was expected to have length/;
    throws_ok { $cigar->align($wrong_query, $ref_seq, 0) }
              qr/Reference start position must be positive/;
    lives_ok  { $cigar->align($query_seq, $ref_seq, $ref_start) }
              'correct input lives';
};

### Test correctness of alignments.
subtest 'Alignment (start pos arg) ' => sub {
    plan tests => 7;

    # Align sequences.
    my $aln = $cigar->align($query_seq, $ref_seq, $ref_start);
    isa_ok $aln, ref [];                # is an array ref
    cmp_ok scalar(@$aln), '==', 2, 'count aligned sequences';
    my ($query_aln, $ref_aln) = @$aln;

    # Check sequence length.
    is $query_aln =~ s/[^ATGCU]//gr, $query_seq, 'removing gaps yields query';
    is   $ref_aln =~ s/[^ATGCU]//gr,   $ref_seq, 'removing gaps yields reference';
    cmp_ok length $query_aln, '==', length $ref_aln,
           'aligned sequences have equal length';

    # Verify aligment.
    is $query_aln, '    GGAAAAT---CGGC---ATGC', 'query correctly aligned';
    is   $ref_aln, 'CCCCGG----CGGGATGCAAA    ', 'reference correctly aligned';
};

subtest 'Alignment (default)' => sub {
    plan tests => 2;

    # Truncate reference sequence before alignment start position.
    my $short_ref_seq = substr $ref_seq, ($ref_start-1);

    # Check behaviour of reference position arg.
    my ($query_short_aln, $ref_short_aln)
        = @{ $cigar->align($query_seq, $short_ref_seq) };
    is $query_short_aln, 'GGAAAAT---CGGC---ATGC', 'short aln: query correctly aligned';
    is   $ref_short_aln, 'GG----CGGGATGCAAA    ', 'short aln: reference correctly aligned';
};

subtest 'Alignment (reversed)' => sub {
    plan tests => 2;

    # Check behaviour of 'reversed' arg.
    my $reversed = 1;
    my ($query_aln, $ref_aln)
        = @{ $cigar->align($query_seq_rev, $ref_seq, $ref_start, $reversed) };
    is $query_aln, '    GGAAAAT---CGGC---ATGC', 'reversed aln: query correctly aligned';
    is   $ref_aln, 'CCCCGG----CGGGATGCAAA    ', 'reversed aln: reference correctly aligned';
};





# EOF

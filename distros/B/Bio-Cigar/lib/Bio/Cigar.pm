package Bio::Cigar;

use strict;
use warnings;
use 5.014;

=encoding utf-8

=head1 NAME

Bio::Cigar - Parse CIGAR strings and translate coordinates to/from reference/query

=head1 SYNOPSIS

    use 5.014;
    use Bio::Cigar;
    my $cigar = Bio::Cigar->new("2M1D1M1I4M");
    say "Query length is ", $cigar->query_length;
    say "Reference length is ", $cigar->reference_length;

    my ($qpos, $op) = $cigar->rpos_to_qpos(3);
    say "Alignment operation at reference position 3 is $op";

    my $query = "GCAAATGC";
    my $ref   = "AAAAGCAAATGC";
    my $aln   = $cigar->align($query, $ref, 5);  # align query to pos 5 of ref
    say foreach @$aln;

=head1 DESCRIPTION

Bio::Cigar is a small library to parse CIGAR strings ("Compact Idiosyncratic
Gapped Alignment Report"), such as those used in the SAM file format.  CIGAR
strings are a run-length encoding which minimally describes the alignment of a
query sequence to an (often longer) reference sequence.

Parsing follows the L<SAM v1 spec|http://samtools.github.io/hts-specs/SAMv1.pdf>
for the C<CIGAR> column.

Parsed strings are represented by an object that provides a few utility
methods.

=head1 ATTRIBUTES

All attributes are read-only.

=head2 string

The CIGAR string for this object.

=head2 reference_length

The length of the reference sequence segment aligned with the query sequence
described by the CIGAR string.

=head2 query_length

The length of the query sequence described by the CIGAR string.

=head2 ops

An arrayref of C<[length, operation]> tuples describing the CIGAR string.
Lengths are integers, L<possible operations are below|/"CIGAR operations">.

=cut

our $VERSION = '1.02';

use Moo;
use Types::Standard qw< ArrayRef Tuple Int Enum StrMatch >;
use List::Util qw< sum >;
use Carp qw< croak >;
use namespace::clean;

=head3 CIGAR operations

The CIGAR operations are given in the following table, taken from the SAM v1
spec:

    Op  Description
    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    M   alignment match (can be a sequence match or mismatch)
    I   insertion to the reference
    D   deletion from the reference
    N   skipped region from the reference
    S   soft clipping (clipped sequences present in SEQ)
    H   hard clipping (clipped sequences NOT present in SEQ)
    P   padding (silent deletion from padded reference)
    =   sequence match
    X   sequence mismatch

    • H can only be present as the first and/or last operation.
    • S may only have H operations between them and the ends of the string.
    • For mRNA-to-genome alignment, an N operation represents an intron.
      For other types of alignments, the interpretation of N is not defined.
    • Sum of the lengths of the M/I/S/=/X operations shall equal the length of SEQ.

=cut

our $CIGAR_REGEX = qr/^
    (\d*H)?(\d*S)?
    (?<OP>\d*[MIDNP=X])*
    (\d*S)?(\d*H)?
$/xa;

has 'string',
    is       => 'ro',
    isa      => StrMatch[ $CIGAR_REGEX ],
    required => 1;

has 'query_length',
    lazy    => 1,
    is      => 'ro',
    isa     => Int,
    default => sub { sum(map { $_ || 1 } $_[0]->string =~ /(\d*)[MIS=X]/ga) || 0 };

has 'reference_length',
    lazy    => 1,
    is      => 'ro',
    isa     => Int,
    default => sub { sum(map { $_ || 1 } $_[0]->string =~ /(\d*)[MDN=X]/ga) || 0 };

has 'ops',
    lazy    => 1,
    is      => 'ro',
    isa     => ArrayRef[ Tuple[ Int, Enum[split '', 'MIDNSHP=X'] ] ],
    builder => '_parse';

sub BUILDARGS {
    my $class = shift;
    if (@_ == 1 and not ref $_[0]) {
        return { string => $_[0] };
    } else {
        croak sprintf "%s->new must be called with a string as the sole argument", __PACKAGE__;
    }
}

sub _parse {
    my $self  = shift;
    my $cigar = $self->string;
    my @ops;
    for my $op (grep defined, $cigar =~ /(\d*[MIDNSHP=X])/g) {
        my ($len, $type) = $op =~ /(\d*)(\D*)/a;
        push @ops, [ $len || 1, uc $type ];
    }
    return \@ops;
}

=head1 CONSTRUCTOR

=head2 new

Takes a CIGAR string as the sole argument and returns a new Bio::Cigar object.

=head1 METHODS

=head2 rpos_to_qpos

Takes a reference position (origin 1, base-numbered) and returns the
corresponding position (origin 1, base-numbered) on the query sequence.  Indels
affect how the numbering maps from reference to query.

In list context returns a tuple of C<[query position, operation at position]>.
Operation is a single-character string.  See the
L<table of CIGAR operations|/"CIGAR operations">.

If the reference position does not map to the query sequence (as with a
deletion, for example), returns C<undef> or C<[undef, operation]>.

=head2 qpos_to_rpos

Takes a query position (origin 1, base-numbered) and returns the corresponding
position (origin 1, base-numbered) on the reference sequence.  Indels affect
how the numbering maps from query to reference.

In list context returns a tuple of C<[references position, operation at position]>.
Operation is a single-character string.  See the
L<table of CIGAR operations|/"CIGAR operations">.

If the query position does not map to the reference sequence (as with an
insertion, for example), returns C<undef> or C<[undef, operation]>.

=head2 op_at_rpos

Takes a reference position and returns the operation at that position.  Simply
a shortcut for calling L</rpos_to_qpos> in list context and discarding the
first return value.

=head2 op_at_qpos

Takes a query position and returns the operation at that position.  Simply
a shortcut for calling L</qpos_to_rpos> in list context and discarding the
first return value.

=head2 reversed

Returns a new Bio::Cigar object with a CIGAR string that's the reverse of this
one, i.e. the last operation becomes the first, the second-to-last the second,
etc. until the first operation becomes the last.

=head2 align($query, $reference, $start_pos=1, $reversed=0)

Takes a query sequence and a reference sequence and aligns them according to
the CIGAR string, using gap characters (C<->) for indels and spaces for soft
clipping.  This is pure string manipulation and as such the match and mismatch
operators (C<=> and C<X>) are assumed to be correct for the given input
sequences and not verified.  Returns an array ref of C<[query seq, ref seq]>.

Optionally, the leftmost reference position (origin 1) can be passed, i.e. the
query is aligned starting at that position.

When C<$reversed> is given a true value, the reverse complement of the passed
query sequence is used to generate the alignment.  B<Only the IUPAC nucleotide
codes C<ATCGU> are currently supported for reverse complementation.>

=cut

# Consumption table based on
# https://github.com/samtools/htslib/blob/develop/htslib/sam.h#L81-L100
my %op_consumes = (
    # op => [query, reference]
    'M' => [1, 1],
    'I' => [1, 0],
    'D' => [0, 1],
    'N' => [0, 1],
    'S' => [1, 0],
    'H' => [0, 0],
    'P' => [0, 0],
    '=' => [1, 1],
    'X' => [1, 1],
);

sub rpos_to_qpos {
    my $self = shift;
    return $self->_map_position( rpos => @_ );
}

sub qpos_to_rpos {
    my $self = shift;
    return $self->_map_position( qpos => @_ );
}

sub _map_position {
    my $self   = shift;
    my $from   = shift;
    my $target = shift;
    my $target_len = $from eq "rpos" ? "reference_length" : "query_length";

    my $rpos   = 0;
    my $qpos   = 0;

    croak sprintf "$from = %d is < 1 or > $target_len (%d)", $target, $self->$target_len
        if $target < 1 or $target > $self->$target_len;

    # Each cigar operation consumes the reference, query, or both.  We keep
    # track of both positions until the query/reference position hits the
    # target.  Then we return the equivalent other position.

    for my $op (@{ $self->ops }) {
        my ($len, $type) = @$op;
        my $consumes = $op_consumes{$type};
        next unless $consumes->[0] or $consumes->[1];

        $qpos += $len if $consumes->[0];
        $rpos += $len if $consumes->[1];

        # The logic could be written with more variables to reduce the
        # duplication in this if/else, but I think the clarity of the logic is
        # enhanced by the similarity of the if/else branches.  Adding more
        # varibles to make the logic generic muddies the simplicity.
        if ($from eq "rpos") {
            if ($rpos > $target) {
                my $overshoot = $rpos - $target;
                $rpos -= $overshoot;
                $qpos -= $overshoot;
            }
            if ($rpos == $target) {
                if ($consumes->[1] and not $consumes->[0]) {
                    # Reference positions which are missing in the query sequence
                    # don't have a corresponding query position.
                    return wantarray ? (undef, $type) : undef;
                } else {
                    $qpos <= $self->query_length
                        or croak sprintf "Bug! Assertion failed: qpos <= qlen"
                                       . " (target = %d, rpos = %d, qpos = %d, qlen = %d, cigar = %s)",
                            $target, $rpos, $qpos, $self->query_length, $self->string;
                    return wantarray ? ($qpos, $type) : $qpos;
                }
            }
        } else {
            if ($qpos > $target) {
                my $overshoot = $qpos - $target;
                $rpos -= $overshoot;
                $qpos -= $overshoot;
            }
            if ($qpos == $target) {
                if ($consumes->[0] and not $consumes->[1]) {
                    # Query positions which are insertions in the reference sequence
                    # don't have a corresponding reference position.
                    return wantarray ? (undef, $type) : undef;
                } else {
                    $rpos <= $self->reference_length
                        or croak sprintf "Bug! Assertion failed: rpos <= rlen"
                                       . " (target = %d, qpos = %d, rpos = %d, rlen = %d, cigar = %s)",
                            $target, $qpos, $rpos, $self->reference_length, $self->string;
                    return wantarray ? ($rpos, $type) : $rpos;
                }
            }
        }
    }
    croak sprintf "Bug! Ran out of ops but couldn't map %s %d"
                . " (rpos = %d, qpos = %d, cigar = %s)",
        $from, $target, $rpos, $qpos, $self->string;
}

sub op_at_rpos {
    my $self = shift;
    my ($qpos, $type) = $self->rpos_to_qpos(@_);
    return $type;
}

sub op_at_qpos {
    my $self = shift;
    my ($rpos, $type) = $self->qpos_to_rpos(@_);
    return $type;
}

sub reversed {
    my $self = shift;
    return Bio::Cigar->new(join "", map { join "", @$_ } reverse @{$self->ops});
}

sub align {
    my ($self, $query, $ref, $ref_start, $reversed) = @_;
    $ref_start //= 1;                       # default to first posiiton

    ### Sanity checks
    # Note: The match/mismatch operators (=/X) are currently not verified to
    # be correct for the given input sequences.
    #
    # Note: The reference length will likely not match because it is often
    # longer than the query and the CIGAR string doesn't account for that. The
    # best matching thing would be N, but it seems to be mainly used for
    # introns.

    # Reference start position
    croak "Reference start position must be positive, but $ref_start given"
        unless $ref_start > 0;

    # Query length
    my $query_len = $self->query_length;
    croak "Query was expected to have length $query_len, but has length ",
          length($query), " instead"
        unless $query_len == length($query);

    ### Variables
    my (@query_aln, @ref_aln);          # stores chunks of aligned sequences
    my ($query_pos, $ref_pos) = (0, 0); # current position in sequences

    ### Handle optional arguments.
    # Handle reference start position.
    $ref_pos += $ref_start - 1;         # convert 1-based start to 0-based pos
    push @query_aln, ' ' x $ref_pos;    # start at correct position
    push @ref_aln, substr $ref, 0, $ref_pos;

    # Handle reversed query matches.
    if ($reversed) {
        $query = reverse $query =~ tr/ATGCU/TACGA/r;    # reverse complement
    }

    ### Iterate CIGAR ops and generate alignment chunks.
    foreach my $op (@{$self->ops}) {
        my ($op_len, $op_type) = @$op;
        my ($consumes_query, $consumes_ref) = @{ $op_consumes{$op_type} };

        # Get next chunk of respective sequence and update position. Insert
        # gaps in the other sequence if necessary.
        if ($consumes_query) {
            push @query_aln, substr $query, $query_pos, $op_len;
            $query_pos += $op_len;

            unless ($consumes_ref) {
                # Use spaces for soft clips, and dashes for indels etc.
                my $gap_char = $op_type eq 'S' ? ' ' : '-';
                push @ref_aln, $gap_char x $op_len;
            }
        }
        if ($consumes_ref) {
            push @ref_aln, substr $ref, $ref_pos, $op_len;
            $ref_pos += $op_len;

            unless ($consumes_query) {
                push @query_aln, '-' x $op_len;
            }
        }
    }

    # Join chunks and return aligned sequences.
    my $query_aln = join '', @query_aln;
    my $ref_aln   = join '',   @ref_aln;

    return [$query_aln, $ref_aln];
}

=head1 AUTHOR

Thomas Sibley E<lt>trsibley@uw.eduE<gt>

Felix Kühnl E<lt>felix@bioinf.uni-leipzig.deE<gt>

=head1 COPYRIGHT

Copyright 2014- Mullins Lab, Department of Microbiology, University of Washington.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the GNU General Public License, version 2.

=head1 SEE ALSO

L<SAMv1 spec|http://samtools.github.io/hts-specs/SAMv1.pdf>

=cut

1;

package Bio::RNA::Barriers::RateMatrix;
our $VERSION = '0.01';

use 5.012;
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Moose::Util::TypeConstraints qw(enum subtype as where message);

use autodie qw(:all);
use overload '""' => \&stringify;
use Scalar::Util qw( reftype looks_like_number );
use List::Util qw( all uniqnum );

enum __PACKAGE__ . 'RateMatrixType', [qw(TXT BIN)];

# Natural number type directly from the Moose docs.
subtype 'PosInt',
    as 'Int',
    where { $_ > 0 },
    message { "The number you provided, $_, was not a positive number" };

has 'file_name' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_file_name',
);
has 'file_type' => (
    is       => 'rw',
    isa      => __PACKAGE__ . 'RateMatrixType',
    required => 1,
);
has '_file_handle' => (
    is       => 'ro',
    isa      => 'FileHandle',
    init_arg => 'file_handle',
    lazy     => 1,
    builder  => '_build_file_handle',
);
# Splice rate matrix directly when reading the data. This can read big
# matrices when only keeping a few entries.
has 'splice_on_parsing' => (
    is        => 'ro',
    isa       => 'ArrayRef[PosInt]',
    predicate => 'was_spliced_on_parsing',
);
has '_data' => (is => 'ro', lazy => 1, builder => '_build_data');

sub BUILD {
    my $self = shift;

    # Enforce data is read from handle immediately despite laziness.
    $self->dim;
}

# Read the actual rate data from the input file and construct the
# matrix from it.
sub _build_data {
    my $self = shift;

    my $rate_matrix;
    if ($self->file_type eq 'TXT') {
        $rate_matrix = __PACKAGE__->read_text_rate_matrix(
            $self->_file_handle,
            $self->splice_on_parsing,
        );
    }
    elsif ($self->file_type eq 'BIN') {
        $rate_matrix = __PACKAGE__->read_bin_rate_matrix(
            $self->_file_handle,
            $self->splice_on_parsing,
        );
    }
    else {
        confess "Unknown file type, that's a bug...";
    }

    return $rate_matrix;
}

# Class method. Reads a rate matrix in text format from the passed file
# handle and constructs a matrix (2-dim array) from it. Returns a
# reference to the constructed rate matrix.
# Arguments:
#   input_matrix_fh: file handle to text file containing rate matrix
#   splice_to: ORDERED set of states which are to be kept. The other
#       states are pruned from the matrix on-the-fly while parsing.
#       This saves time and memory.
sub read_text_rate_matrix {
    my ($class, $input_matrix_fh, $splice_to_ref) = @_;

    # During parsing, splice the selected rows / columns. Make 0-based.
    my @splice_to_rows = @{ $splice_to_ref // [] };     # 1-based, modified
    my @splice_to_cols = map {$_ - 1} @splice_to_rows;  # 0-based indices

    my (@rate_matrix, $matrix_dim);
    ROW: while (defined (my $line = <$input_matrix_fh>)) {
        if (defined $splice_to_ref) {
            last unless @splice_to_rows;            # we're done!
            next ROW if $. != $splice_to_rows[0];   # this row is not kept
            shift @splice_to_rows;              # remove the leading index
        }

        my @row = split q{ }, $line;                # awk-style splitting
        # Since the diagonal element may be more or less anything, we need
        # to check it separately (e.g. to not choke on BHGbuilder output).
        my @row_no_diag = @row[0..($.-2), ($.)..$#row];    # $. is 1-based
        confess 'Input file contains non-numeric or negative input on ',
                "line $.:\n$line"
            unless looks_like_number $row[$.-1]     # diag elem can be <0
                   and all {looks_like_number $_ and $_ >= 0} @row_no_diag;

        # Check that element count is equal in all rows.
        $matrix_dim //= @row;         # first-time init
        confess 'Lines of input file have varying number of elements'
            unless $matrix_dim == @row;

        @row = @row[@splice_to_cols] if defined $splice_to_ref;
        push @rate_matrix, \@row;
        confess 'Input file contains more lines than there are columns'
            if @rate_matrix > $matrix_dim;
    }
    confess 'End of file reached before finding all states requested by ',
            'splicing operation'
        if defined $splice_to_ref and @splice_to_rows > 0;
    confess 'Requested splicing of non-contained state'
        unless all {$_ < $matrix_dim} @splice_to_cols;
    confess 'Input file is empty'
        unless @rate_matrix;
    # Adjust dimension if splicing was applied.
    confess 'Input file contains less lines than there are columns'
        if @rate_matrix < (defined $splice_to_ref ? @splice_to_cols
                                                  : $matrix_dim     );

    return \@rate_matrix;
}

sub _transpose_matrix {
    my ($class, $matrix_ref) = @_;

    # Determine dimnensions
    my $max_row = @$matrix_ref - 1;
    return unless $max_row >= 0;
    my $max_col = @{ $matrix_ref->[0] } - 1;    # check elems of first row

    # Swap values
    for my $row (0..$max_row) {
        for my $col (($row+1)..$max_col) {
            my $temp = $matrix_ref->[$row][$col];
            $matrix_ref->[$row][$col] = $matrix_ref->[$col][$row];
            $matrix_ref->[$col][$row] = $temp;
        }
    }
}

# Class method. Reads a rate matrix in binary format from the passed file
# handle and constructs a matrix (2-dim array) from it. Returns a
# reference to the constructed rate matrix.
sub read_bin_rate_matrix {
    my ($class, $input_matrix_fh, $splice_to_ref) = @_;

    # During parsing, splice the selected rows / columns. Make 0-based.
    my @splice_to_cols = @{ $splice_to_ref // [] };     # 1-based, modified
    my @splice_to_rows = map {$_ - 1} @splice_to_cols;  # 0-based indices

    # Set read mode to binary
    binmode $input_matrix_fh;

    ##### Read out matrix dimension
    my $size_of_int = do {use Config; $Config{intsize}};
    my $read_count
        = read($input_matrix_fh, my $raw_matrix_dim, $size_of_int);
    confess "Could not read dimension from file, ",
          "expected $size_of_int bytes, got $read_count"
        if $read_count != $size_of_int;

    my $matrix_dim = unpack 'i', $raw_matrix_dim;       # unpack integer

    confess 'Requested splicing of non-contained state'
        unless all {$_ < $matrix_dim} @splice_to_rows;

    ##### Read rate matrix
    my @rate_matrix;
    my $size_of_double = do {use Config; $Config{doublesize}};
    my $bytes_per_column = $size_of_double * $matrix_dim;
    COL: for my $i (1..$matrix_dim) {
        # Each column consists of n=matrix_dim doubles.
        $read_count
            = read($input_matrix_fh, my $raw_column, $bytes_per_column);
        confess "Could not read column $i of file, ",
              "expected $bytes_per_column bytes, got $read_count"
            if $read_count != $bytes_per_column;

        # Skip column if splicing and column not requested.
        if (defined $splice_to_ref) {
            last unless @splice_to_cols;            # we're done!
            next COL if $i != $splice_to_cols[0];   # this col is not kept
            shift @splice_to_cols;              # remove the leading index
        }

        # Decode raw doubles.
        my @matrix_column = unpack "d$matrix_dim", $raw_column;

        # Splice parsed column if requested.
        @matrix_column = @matrix_column[@splice_to_rows]
            if defined $splice_to_ref;

        push @rate_matrix, \@matrix_column;
    }
    confess 'End of file reached before finding all states requested by ',
            'splicing operation'
        if defined $splice_to_ref and @splice_to_cols > 0;
    confess 'Read data as suggested by dimension, but end of file ',
            'not reached'
        unless defined $splice_to_ref or eof $input_matrix_fh;

    # For whatever reasons, binary rates are stored column-wise instead of
    # row-wise. Transpose to fix that.
    __PACKAGE__->_transpose_matrix(\@rate_matrix);

    return \@rate_matrix;
}

sub _build_file_handle {
    my $self = shift;

    confess 'File required if no file handle is passed'
        unless $self->has_file_name;

    open my $handle, '<', $self->file_name;
    return $handle;
}

# Get the dimension (= number of rows = number of columns) of the matrix.
sub dim {
    my $self = shift;

    my $dimension = @{ $self->_data };
    return $dimension;
}

# Get the rate from state i to state j. States are 1-based (first state =
# state 1) just as in the results file.
sub rate_from_to {
    my ($self, $from_state, $to_state) = @_;

    # Check states are within bounds
    confess "from_state $from_state is out of bounds"
        unless $self->_state_is_in_bounds($from_state);
    confess "to_state $to_state is out of bounds"
        unless $self->_state_is_in_bounds($to_state);

    # Retrieve rate.
    my $rate = $self->_data->[$from_state-1][$to_state-1];
    return $rate;
}

# Check whether given state is contained in the rate matrix.
sub _state_is_in_bounds {
    my ($self, $state) = @_;

    my $is_in_bounds = ($state >= 1 && $state <= $self->dim);
    return $is_in_bounds;
}

# Returns a sorted list of all states connected to the (mfe) state 1.
# Assumes a symmetric transition matrix (only checks path *from* state 1
# *to* the other states). Quadratic runtime.
sub connected_states {
    my ($self) = @_;

    # Starting at state 1, perform a traversal of the transition graph and
    # remember all nodes seen.
    my $dim = $self->dim;
    my @cue = (1);
    my %connected = (1 => 1);       # state 1 is connected
    while (my $i = shift @cue) {
        foreach my $j (1..$dim) {
            next if $connected{$j} or $self->rate_from_to($i, $j) <= 0;
            $connected{$j} = 1;         # j is connected to 1 via i
            push @cue, $j;
        }
    }

    # Sort in linear time.
    my @sorted_connected = grep {$connected{$_}} 1..$dim;
    return @sorted_connected;
}

# Only keep the states connected to the mfe (as determined by
# connected_states()). Returns a list of all connected (and thus preserved)
# minima.
sub keep_connected {
    my ($self) = @_;
    my @connected_indices = map {$_ - 1} $self->connected_states;
    return map {$_ + 1} @connected_indices      # none removed.
        if $self->dim == @connected_indices;

    $self->_splice_indices(\@connected_indices);

    return map {$_ + 1} @connected_indices;       # turn into states again
}

# Remove all but the passed states from this rate matrix. States are
# 1-based (first state = state 1) just as in the results file.
sub keep_states {
    my ($self, @states_to_keep) = @_;

    # We need a sorted, unique list.
    @states_to_keep = uniqnum sort {$a <=> $b} @states_to_keep;

    # Check whether states are within bounds.
    foreach my $state (@states_to_keep) {
        confess "State $state is out of bounds"
            unless $self->_state_is_in_bounds($state);
    }

    return if @states_to_keep == $self->dim;    # keep all == no op

    $_-- foreach @states_to_keep;               # states are now 0-based
    $self->_splice_indices(\@states_to_keep);

    return $self;
}

# Only keep the passed states and reorder them as in the passed list. In
# particular, the same state can be passed multiple times and will then be
# deep-copied.
# Arguments:
#   states: Ordered list of states defining the resulting matrix. May
#       contain duplicates.
sub splice {
    my ($self, @states) = @_;

    # Check whether states are within bounds.
    foreach my $state (@states) {
        confess "State $state is out of bounds"
            unless $self->_state_is_in_bounds($state);
    }

    $_-- foreach @states;                       # states are now 0-based
    $self->_splice_indices(\@states);

    return $self;
}

# Internal version which performs no boundary checks and assumes REFERENCE
# to state list.
sub _splice_indices {
    my ($self, $kept_indices_ref) = @_;

    my $matrix_ref = $self->_data;

    # If no entries are kept, make matrix empty.
    if (@$kept_indices_ref == 0) {
        @$matrix_ref = ();
        return;
    }

    # Splice the matrix.
    # WARNING: This makes a shallow copy of the rows if the same index is
    # passed more than once (e.g. from splice()).
    @$matrix_ref = @{$matrix_ref}[@$kept_indices_ref];  # rows

    # Deep-copy duplicated rows (if any).
    my %row_seen;
    foreach my $row (@$matrix_ref) {
        $row = [@$row] if $row_seen{$row};              # deep-copy array
        $row_seen{$row} = 1;
    }
    @$_ = @{$_}[@$kept_indices_ref]                     # columns
        foreach @$matrix_ref;

    return $self;
}

# Remove the passed states from this rate matrix. States are 1-based
# (first state = state 1) just as in the results file.
sub remove_states {
    my ($self, @states_to_remove) = @_;

    return unless @states_to_remove;        # removing no states at all

    # Check states are within bounds.
    foreach my $state (@states_to_remove) {
        confess "State $state is out of bounds"
            unless $self->_state_is_in_bounds($state);
    }

    # Invert state list via look-up hash.
    my %states_to_remove = map {$_ => 1} @states_to_remove;
    my @states_to_keep
        = grep {not $states_to_remove{$_}} 1..$self->dim;

    # Let _keep_indices() do the work.
    $_-- foreach @states_to_keep;               # states are now 0-based
    $self->_splice_indices(\@states_to_keep);

    return $self;
}

# Print this matrix as text, either to the passed handle, or to STDOUT.
sub print_as_text {
    my ($self, $text_matrix_out_fh) = @_;
    $text_matrix_out_fh //= \*STDOUT;       # write to STDOUT by default

    my $rate_format = '%10.4g ';            # as in Barriers code

    foreach my $row (@{ $self->_data }) {
        printf {$text_matrix_out_fh} $rate_format, $_ foreach @$row;
        print  {$text_matrix_out_fh} "\n";
    }
}

# Print this matrix as binary data, either to the passed handle or to
# STDOUT.  Data format: matrix dimension as integer, then column by column
# as double.
sub print_as_bin {
    my ($self, $rate_matrix_out_fh ) = @_;

    my $rate_matrix_ref = $self->_data;

    # Set write mode to binary
    binmode $rate_matrix_out_fh;

    ##### Print out matrix dimension
    my $matrix_dim = @$rate_matrix_ref;
    my $packed_dim = pack 'i', $matrix_dim;     # machine representation, int
    print {$rate_matrix_out_fh} $packed_dim;

    ##### Print columns of rate matrix
    # For whatever reasons, binary rates are stored column-wise instead of
    # row-wise (Treekin works with the transposed matrix and this way it's
    # easier to slurp the entire file. Treekin transposes the text rates
    # during reading).
    #_transpose_matrix $rate_matrix_ref;
    foreach my $col (0..($matrix_dim-1)) {
        foreach my $row (0..($matrix_dim-1)) {
            # Pack rate as double
            my $packed_rate = pack 'd', $rate_matrix_ref->[$row][$col];
            print {$rate_matrix_out_fh} $packed_rate;
        }
        # my $column = map {$_->[$i]} @$rate_matrix_ref;
        # my $packed_column = pack "d$matrix_dim", @column;
    }
}

# Return string containing binary the representation of the matrix (cf.
# print_as_bin).
sub serialize {
    my $self = shift;

    # Use print function and capture matrix in a string.
    my $matrix_string;
    open my $matrix_string_fh, '>', \$matrix_string;
    $self->print_as_bin($matrix_string_fh);

    return $matrix_string;
}

# Returns a string containing the text representation of the matrix. The
# overloaded double-quote operator calls this method.
sub stringify {
    my $self = shift;

    # Use print function and capture matrix in a string. Empty matrices
    # give an empty string (not undef).
    my $matrix_string = q{};
    open my $matrix_string_fh, '>', \$matrix_string;
    $self->print_as_text($matrix_string_fh);

    return $matrix_string;
}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::RNA::Barriers::RateMatrix - Store and manipulate a I<Barriers>
transition rate matrix.

=head1 SYNOPSIS

    use Bio::RNA::Barriers;

    # Functional interface using plain Perl lists to store the matrix.
    my $list_mat
        = Bio::RNA::Barriers::RateMatrix->read_text_rate_matrix($input_handle);
    $list_mat
        = Bio::RNA::Barriers::RateMatrix->read_bin_rate_matrix($input_handle);

    # Read a binary rate matrix directly from file. Binary matrices are more
    # precise and smaller than text matrices.
    my $rate_matrix = Bio::RNA::Barriers::RateMatrix->new(
        file_name => '/path/to/rates.bin',
        file_type => 'BIN',
    );

    # Read a text rate matrix from an opened handle.
    open my $rate_matrix_fh_txt, '<', '/path/to/rates.out';
    my $rate_matrix = Bio::RNA::Barriers::RateMatrix->new(
        file_handle => $rate_matrix_fh_txt,
        file_type   => 'TXT',
    );

    # Print matrix, dimension, and a single rate.
    print "$rate_matrix";
    print 'Dimension of rate matrix is ', $rate_matrix->dim, "\n";
    print 'Rate from state 1 to state 3 is ',
          $rate_matrix->rate_from_to(1, 3),
          "\n";

    # Remove entries for a list of states {1, 3, 5} (1-based as in bar file).
    $rate_matrix->remove_states(1, 5, 5, 3);    # de-dupes automatically
    # Note: former state 2 is now state 1 etc.

    # Keep only states {1, 2, 3}, remove all others. Can also de-dupe.
    $rate_matrix->keep_states(1..3);

    # Write binary matrix to file.
    open my $out_fh_bin, '>', '/path/to/output/rates.bin';
    $rate_matrix->print_as_bin($out_fh_bin);

=head1 DESCRIPTION

Parse, modify and print/write rate matrix files written by I<Barriers>, both
in text and binary format.

=head1 METHODS

=head3 Bio::RNA::Barriers::RateMatrix->new(arg_name => $arg, ...)

Constructor. Reads a rate matrix from a file / handle and creates a new rate
matrix object.

=over 4

=item Arguments:

=over 4

=item file_name | file_handle

Source of the data to read. Pass either or both.

=item file_type

Specifies whether the input data is in binary or text format. Must be either
C<'TXT'> or C<'BIN'>.

=item splice_on_parsing (optional)

Array ref of integers denoting states for which the transition rates should be
parsed. All other states are skipped. This dramatically improves the
performance and memory efficiency for large matrices if only a few states are
relevant (e.g. only connected states).

=back

=back

=head3 $mat->file_name()

File from which the data was read. May be undef if it was read from a file
handle.

=head3 $mat->file_type()

Specifies whether the input data is in binary or text format. Must be either
C<'TXT'> or C<'BIN'>.

=head3 Bio::RNA::RateMatrix->read_text_rate_matrix($input_matrix_filehandle)

Class method. Reads a rate matrix in text format from the passed file
handle and constructs a matrix (2-dim array) from it. Returns an array
reference containing the parsed rate matrix.

Use this function if you do not want to use the object-oriented interface.

=head3 Bio::RNA::RateMatrix->read_bin_rate_matrix($input_matrix_filehandle)

Class method. Reads a rate matrix in binary format from the passed file
handle and constructs a matrix (2-dim array) from it. Returns an array
reference containing the parsed rate matrix.

Use this function if you do not want to use the object-oriented interface.

=head3 $mat->dim()

Get the dimension (= number of rows = number of columns) of the matrix.

=head3 $mat->rate_from_to($i, $j)

Get the rate from state i to state j. States are 1-based (first state = state
1) just as in the results file.

=head3 $mat->remove_states(@indices)

Remove the passed states from this rate matrix. States are 1-based (first
state = state 1) just as in the results file.

=head3 $mat->connected_states()

Returns a sorted list of all states connected to the (mfe) state 1.
Assumes a symmetric transition matrix (only checks path B<from> state 1
B<to> the other states). Quadratic runtime.

=head3 $mat->keep_connected()

Only keep the states connected to the mfe (as determined by
C<connected_states()>).

=head3 $mat->keep_states(@indices)

Remove all but the passed states from this rate matrix. States are 1-based
(first state = state 1) just as in the results file. C<@indices> may be
unordered and contain duplicates.

=head3 $mat->splice(@indices)

Only keep the passed states and reorder them to match the order of
C<@indices>. In particular, the same state can be passed multiple times and
will then be deep-copied. C<@indices> may be unordered and contain duplicates.

=head3 $mat->print_as_text($out_handle)

Print this matrix as text, either to the passed handle, or to STDOUT if
C<$out_handle> is not provided.

=head3 $mat->print_as_bin()

Print this matrix as binary data, either to the passed handle, or to STDOUT if
C<$out_handle> is not provided.

Data format: matrix dimension as integer, then column by column as double.

=head3 $mat->serialize()

Return string containing binary representation of the matrix (cf.
print_as_bin).

=head3 $mat->stringify()

Returns a string containing the text representation of the matrix. The
overloaded double-quote operator calls this method.


=head1 AUTHOR

Felix Kuehnl, C<< <felix at bioinf.uni-leipzig.de> >>

=head1 BUGS

Please report any bugs or feature requests by raising an issue at
L<https://github.com/xileF1337/Bio-RNA-Barriers/issues>.

You can also do so by mailing to C<bug-bio-rna-barmap at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-RNA-BarMap>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::RNA::Barriers


You can also look for information at the official Barriers website:

L<https://www.tbi.univie.ac.at/RNA/Barriers/>


=over 4

=item * Github: the official repository

L<https://github.com/xileF1337/Bio-RNA-Barriers>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-RNA-Barriers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-RNA-Barriers>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Bio-RNA-Barriers>

=item * Search CPAN

L<https://metacpan.org/release/Bio-RNA-Barriers>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2019-2021 Felix Kuehnl.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut


# End of Bio/RNA/Barriers/RateMatrix.pm

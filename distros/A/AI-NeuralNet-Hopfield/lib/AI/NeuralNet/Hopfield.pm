package AI::NeuralNet::Hopfield;

use v5.10;
use strict;
use warnings;
use Moose;
use Math::SparseMatrix;


=head1 NAME

AI::NeuralNet::Hopfield - A simple Hopfiled Network Implementation.

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

has 'matrix' => ( is => 'rw', isa => 'Math::SparseMatrix');

has 'matrix_rows'   => ( is => 'rw', isa => 'Int');

has 'matrix_cols'   => ( is => 'rw', isa => 'Int');

sub BUILD {
	my $self = shift;
	my $args = shift;
	my $matrix = Math::SparseMatrix->new($args->{row}, $args->{col});
	$self->matrix($matrix);	
	$self->matrix_rows($args->{row});
	$self->matrix_cols($args->{col});
}

sub train() {	
	my $self = shift;
	my @pattern = @_;	

	if ( ($#pattern + 1) != $self->matrix_rows) {
		die "Can't train a pattern of size " . ($#pattern + 1) . " on a hopfield network of size " , $self->matrix_rows;
	}
	
	my $m2 = &convert_array($self->matrix_rows, $self->matrix_cols, @pattern);

	my $m1 = &transpose($m2);

	my $m3 = &multiply($m1, $m2);

	my $identity = &identity($m3->{_rows});

	my $m4 = &subtract($m3, $identity);

	my $m5 = &add($self->matrix, $m4);
	
	$self->matrix($m5);	
}

sub evaluate() {
	my $self = shift;
	my @pattern = @_;

	my @output = ();

	my $input_matrix = &convert_array($self->matrix_rows, $self->matrix_cols, @pattern);

	for (my $col = 1; $col <= ($#pattern + 1); $col++) {
		
		my $column_matrix = &get_col($self, $col);
		
		my $transposed_column_matrix = &transpose($column_matrix);
		
		my $dot_product = &dot_product($input_matrix, $transposed_column_matrix);
		
		#say $dot_product;

		if ($dot_product > 0) {
			$output[$col - 1] = "true";
		} else {
			$output[$col - 1] = "false";
		}
	}
	return @output;
}

sub convert_array() {
	my $rows    = shift;
	my $cols 	= shift;
	my @pattern = @_;
	my $result  = Math::SparseMatrix->new(1, $cols);

	for (my $i = 0; $i < ($#pattern + 1); $i++) {
		if ($pattern[$i] =~ m/true/ig) {
			$result->set(1, ($i +1 ), 1);
		} else {
			$result->set(1, ($i + 1), -1);
		}
	}
	return $result;
}

sub transpose() {
	my $matrix  = shift;
	my $rows = $matrix->{_rows};
	my $cols = $matrix->{_cols};

	my $inverse = Math::SparseMatrix->new($cols, $rows);
		
	for (my $r = 1; $r <= $rows; $r++) {
		for (my $c = 1; $c <= $cols; $c++) {
			my $value = $matrix->get($r, $c);
			$inverse->set($c, $r, $value);
		}
	}
	return $inverse;
}

sub multiply() {
	my $matrix_a  = shift;
	my $matrix_b  = shift;

	my $a_rows = $matrix_a->{_rows};
	my $a_cols = $matrix_a->{_cols};

	my $b_rows = $matrix_b->{_rows};
	my $b_cols = $matrix_b->{_cols};

	my $result = Math::SparseMatrix->new($a_rows, $b_cols);

	if ($matrix_a->{_cols} != $matrix_b->{_rows}) {
		die "To use ordinary matrix multiplication the number of columns on the first matrix must mat the number of rows on the second";
	}

	for (my $result_row = 1; $result_row <= $a_rows; $result_row++) {
		for(my $result_col = 1; $result_col <= $b_cols; $result_col++) {
			my $value = 0;
			for (my $i = 1; $i <= $a_cols; $i++) {
				$value += ($matrix_a->get($result_row, $i)) * ($matrix_b->get($i, $result_col));
			}
			$result->set($result_row, $result_col, $value);
		}
	}
	return $result;
}

sub identity() {
	my $size = shift;

	if ($size < 1) {
		die "Identity matrix must be at least of size 1.";
	}
	
	my $result = Math::SparseMatrix->new ($size, $size);

	for (my $i = 1; $i <= $size; $i++) {
		$result->set($i, $i, 1);
	}
	return $result;
}

sub subtract() {
	my $matrix_a = shift;
	my $matrix_b = shift;

    my $a_rows = $matrix_a->{_rows};
    my $a_cols = $matrix_a->{_cols};

	my $b_rows = $matrix_b->{_rows};
	my $b_cols = $matrix_b->{_cols};

	if ($a_rows != $b_rows) {
		die "To subtract the matrixes they must have the same number of rows and columns.";
	}

	if ($a_cols != $b_cols) {
		die "To subtract the matrixes they must have the same number of rows and columns.  Matrix a has ";
	}

	my $result = Math::SparseMatrix->new($a_rows, $a_cols);

	for (my $result_row = 1; $result_row <= $a_rows; $result_row++) {
		for (my $result_col = 1; $result_col <= $a_cols; $result_col++) {
			my $value = ( $matrix_a->get($result_row, $result_col) ) - ( $matrix_b->get($result_row, $result_col));
			
			if ($value == 0) {
				$value += 2;
			}			
			$result->set($result_row, $result_col, $value);
		}
	}
	return $result;
}

sub add() {
	#weight matrix.
    my $matrix_a = shift;
	#identity matrix.
    my $matrix_b = shift;

	my $a_rows = $matrix_a->{_rows};
	my $a_cols = $matrix_a->{_cols};

	my $b_rows = $matrix_b->{_rows};
	my $b_cols = $matrix_b->{_cols};
	
	if ($a_rows != $b_rows) {
		die "To add the matrixes they must have the same number of rows and columns.";
	}

	if ($a_cols != $b_cols) {
		 die "To add the matrixes they must have the same number of rows and columns.";
	}

	my $result = Math::SparseMatrix->new($a_rows, $a_cols);

	for (my $result_row = 1; $result_row <= $a_rows; $result_row++) {
		for (my $result_col = 1; $result_col <= $a_cols; $result_col++) {
			my $value = $matrix_b->get($result_row, $result_col);			
			$result->set($result_row, $result_col, $matrix_a->get($result_row, $result_col) + $value  )
		}
	}
	return $result;
}

sub dot_product() {
	my $matrix_a = shift;
	my $matrix_b = shift;
	
	my $a_rows = $matrix_a->{_rows};
	my $a_cols = $matrix_a->{_cols};
	
	my $b_rows = $matrix_b->{_rows};
	my $b_cols = $matrix_b->{_cols};

	my @array_a = &packed_array($matrix_a);
	my @array_b = &packed_array($matrix_b);

	for (my $n = 0; $n <= $#array_b; $n++) {
		if ($array_b[$n] == 2) {
			$array_b[$n] = 0;
		}
	}
	
	if ($#array_a != $#array_b) {
		die "To take the dot product, both matrixes must be of the same length.";
	}

	my $result = 0;
	my $length = $#array_a + 1;

	for (my $i = 0; $i < $length; $i++) {
		$result += $array_a[$i] * $array_b[$i];
	}
	return $result;
}

sub packed_array() {
	my $matrix = shift;
	my @result = ();

	for (my $r = 1; $r <= $matrix->{_rows}; $r++) {
		for (my $c = 1; $c <= $matrix->{_cols}; $c++) {
			push(@result, $matrix->get($r, $c)); 
		}
	}
	return @result;
}

sub get_col() {
	my $self = shift;
	my $col  = shift;

	my $matrix = $self->matrix();
	
	my $matrix_rows = $self->matrix_rows();

	if ($col > $matrix_rows) {
		die "Can't get column";
	}

	my $new_matrix = Math::SparseMatrix->new($matrix_rows, 1);

	for (my $row = 1; $row <= $matrix_rows; $row++) {
		my $value = $matrix->get($row, $col);
		$new_matrix->set($row, 1, $value);
	}
	return $new_matrix;
}

sub print_matrix() {
    my $matrix  = shift;
    my $rs = $matrix->{_rows};
    my $cs = $matrix->{_cols};

	for (my $i = 1; $i <= $rs; $i++) {
		for (my $j = 1; $j <= $cs; $j++) {
			say "[$i,$j]" . $matrix->get($i, $j);
		}
	}
}

=head1 SYNOPSIS

This is a version of a Hopfield Network implemented in Perl. Hopfield networks are sometimes called associative networks since 
they associate a class pattern to each input pattern, they are tipically used for classification problems with binary pattern vectors.

=head1 SUBROUTINES/METHODS

=head2 New

In order to build new calssifiers, you have to pass to the constructor the number of rows and columns (neurons) for the matrix construction.

	my $hop = AI::NeuralNet::Hopfield->new(row => 4, col => 4);

=cut

=head2 Train

The training method configurates the network memory.

	my @input_1 = qw(true true false false);
	$hop->train(@input_1);

=cut

=head2 Evaluation

The evaluation method compares the new input with the information stored in the matrix memory.
The output is a new array with the boolean evaluation of each neuron.

	my @input_2 = qw(true true true false);
	my @result = $hop->evaluate(@input_2);

=cut


=head1 AUTHOR

Felipe da Veiga Leprevost, C<< <leprevost at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-neuralnet-hopfield at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-NeuralNet-Hopfield>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::NeuralNet::Hopfield


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-NeuralNet-Hopfield>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AI-NeuralNet-Hopfield>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AI-NeuralNet-Hopfield>

=item * Search CPAN

L<http://search.cpan.org/dist/AI-NeuralNet-Hopfield/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 leprevost.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of AI::NeuralNet::Hopfield

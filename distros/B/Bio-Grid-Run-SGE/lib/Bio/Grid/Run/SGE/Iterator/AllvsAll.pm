package Bio::Grid::Run::SGE::Iterator::AllvsAll;

use Mouse;

use warnings;
use strict;
use List::Util qw/reduce/;

use constant {
    FROM_IDX            => 0,
    TO_IDX              => 1,
    EXTRA_IDX           => 2,
    BEYOND_LAST_ELEMENT => -2,
};


our $VERSION = '0.042'; # VERSION

has cur_comb_idx => ( is => 'rw', lazy_build => 1 );

with 'Bio::Grid::Run::SGE::Role::Iterable';

sub next_comb {
    my ($self) = @_;

    unless ( $self->_iterating ) {
        confess "you need to start the iterator with a predefined range";
    }

    return if ( $self->cur_comb_idx == BEYOND_LAST_ELEMENT );

    my $cidx = $self->cur_comb_idx + 1;

    $self->cur_comb_idx($cidx);
    if ( $cidx > $self->num_comb ) {
        confess "You specified a range that is bigger than the number of combinations";
    }

    if ( $cidx > $self->_range->[TO_IDX] ) {
        my $comb;
        if ( defined( $self->_range->[EXTRA_IDX] ) ) {
            $self->cur_comb_idx( $self->_range->[EXTRA_IDX] );
            $comb = $self->cur_comb;
        }
        $self->cur_comb_idx(BEYOND_LAST_ELEMENT);
        return $comb;
    }

    return $self->cur_comb;
}

sub start {
    my ( $self, $idx_range ) = @_;

    if ( $self->_iterating ) {
        map { $_->close } @{ $self->indices };
    }
    $self->_range($idx_range);

    $self->_iterating(1);
    $self->cur_comb_idx( $idx_range->[FROM_IDX] - 1 );

    return;
}

sub cur_comb_coords {
    my ($self) = @_;
    
    #we did not start yet.
    return if ( $self->cur_comb_idx == BEYOND_LAST_ELEMENT );

    my $num_rows = $self->indices->[0]->num_elem;
    my $num_cols = $self->indices->[0]->num_elem;
    my $idx = $self->cur_comb_idx;

    my $row_idx = int($idx/$num_cols);
    my $col_idx = $idx % $num_cols;

    return ($row_idx, $col_idx);
}

sub cur_comb {
    my ($self) = @_;

    my ($row_idx, $col_idx) = $self->cur_comb_coords;

    return [ $self->indices->[0]->get_elem( $row_idx ), $self->indices->[0]->get_elem($col_idx) ];
}

sub num_comb {
    my ($self) = @_;

    return $self->indices->[0]->num_elem ** 2;
}

sub peek_comb_idx {
    my ($self) = @_;

    return
        unless ( $self->_iterating );

    return if ( $self->cur_comb_idx == BEYOND_LAST_ELEMENT );

    my $cidx = $self->cur_comb_idx + 1;

    if ( $cidx > $self->num_comb ) {
        confess "You specified a range that is bigger than the number of combinations";
    }

    if ( $cidx > $self->_range->[TO_IDX] ) {
        return $self->_range->[EXTRA_IDX]
            if ( defined( $self->_range->[EXTRA_IDX] ) );
        return;
    }

    return $cidx;
}
__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Bio::Grid::Run::SGE::Iterator::AllvsAll - Runs all elements of one index against each other

=head1 SYNOPSIS

    use Bio::Grid::Run::SGE::Iterator::AllvsAll;
    use Bio::Grid::Run::SGE::Index;

    # the dummy index contains the letters a..c as elements
    my $index = Bio::Grid::Run::SGE::Index->new( format => 'Dummy', idx_file => undef, idx => [ 'a'..'c'] )->create;

    my $it = Bio::Grid::Run::SGE::Iterator::AllvsAll->new( indices => [$index] );

    # run through all combinations
    my ($from, $to) = (0, $it->num_comb - 1);
    $it->start( [ $from, $to]  );

    my @result;
    my $i = $from;
    while ( my $comb = $it->next_comb ) {
      print "job " . $i++ . " -> " . join(" ",  $comb->[0], $comb->[1] ) . "\n";
    }


=head1 DESCRIPTION


Runs all elements of the index against each other. Takes exactly one index.
Results in C<N * N> jobs with N as number of elements in the index.

The difference to L<Bio::Grid::Run::SGE::Iterator::AllvsAllNoRep> is that it
does B<NOT> assume symmetry. Thus, runing element B<x> vs B<y> is different from running
B<y> vs B<x>.

=head2 ITERATION SCHEME


An index with 3 elements (a..c) combines to:

    job 1 -> a a
    job 2 -> a c
    job 3 -> a b
    job 4 -> b a
    job 5 -> b b
    job 6 -> b c
    job 7 -> c a
    job 8 -> c b
    job 9 -> c c

=head2 CONFIGURATION

  ---
  ...
  mode: AllvsAll
  ...

=head2 COMPLETE EXAMPLE

=head3 CONFIG FILE

    ---
    input:
      - format: List
        elements: [ "a", "b", "c" ]
    job_name: AllvsAll_test
    mode: AllvsAll

=head3 CLUSTER SCRIPT

    #!/usr/bin/env perl

    use warnings;
    use strict;
    use 5.010;

    use Bio::Grid::Run::SGE;
    use File::Spec::Functions qw(catfile);
    use Bio::Grid::Run::SGE::Util qw(result_files);

    run_job(
      task => \&do_worker_stuff
    );

    sub do_worker_stuff {
      my ( $c, $result_prefix, $elems_a, $elems_b ) = @_;

      # write results to result prefix (== result file)
      open my $fh, '>', $result_prefix or die "Can't open filehandle: $!";

      # because we have list indices, $elems_a and $elems_b are (paired) array references
      # other indices might give file names instead, so check the documentation

      my $num_elems = @$elems_a;
      for ( my $i = 0; $i < @$elems_a; $i++ ) {
        say $fh join( " ", $elems_a->[$i], $elems_b->[$i] );
      }
      $fh->close;

      # return 1 on success
      return 1;
    }

    1;

=head1 SEE ALSO

L<Bio::Grid::Run::SGE::Role::Iterable>, L<Bio::Grid::Run::SGE::Iterator>

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut

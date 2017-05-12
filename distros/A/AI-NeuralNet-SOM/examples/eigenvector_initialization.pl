use strict;
use Data::Dumper;

use AI::NeuralNet::SOM::Rect;

my @vs  = ([ 3, 2, 4 ], [ -1, -1, -1 ], [ 0, 4, -3]);
my $dim = 3;

#my @vs  = ([1,-0.5],    [0,1]);
#my $dim = 2;

my $epsilon = 0.001;
my $epochs  = 400;

{ # random initialisation
    my $nn = new AI::NeuralNet::SOM::Rect (output_dim => "5x6",
					   input_dim  => $dim);

    $nn->initialize;                                      # random
    my @mes = $nn->train ($epochs, @vs);
    warn "random:   length until error is < $epsilon ". scalar (grep { $_ >= $epsilon } @mes);
}

{ # constant initialisation
    my $nn = new AI::NeuralNet::SOM::Rect (output_dim => "5x6",
					   input_dim  => $dim);

    $nn->initialize ($vs[-1]);
    my @mes = $nn->train ($epochs, @vs);
    warn "constant: length until error is < $epsilon ". scalar (grep { $_ >= $epsilon } @mes);
}

{ # eigenvector initialisation
    my $nn = new AI::NeuralNet::SOM::Rect (output_dim => "5x6",
					   input_dim  => $dim);
    my @training_vectors;                                                # find these training vectors 
    {                                                                    # and prime them with this eigenvector stuff;
	use PDL;
	my $A = pdl \@vs;

	while ($A->getdim(0) < $A->getdim(1)) {                          # make the beast quadratic
	    $A = append ($A, zeroes (1));                                # by padding zeroes
	}
	my ($E, $e) = eigens_sym $A;
#	print $E;
#	print $e;

	my @es = list $e;                                                # eigenvalues
#	warn "es : ".Dumper \@es;
	my @es_desc = sort { $b <=> $a } @es;                            # eigenvalues sorted desc
#	warn "desc: ".Dumper \@es_desc;
	my @es_idx  = map { _find_num ($_, \@es) } @es_desc;             # eigenvalue indices sorted by eigenvalue (desc)
#	warn "idx: ".Dumper \@es_idx;

sub _find_num {
    my $v = shift;
    my $l = shift;
    for my $i (0..$#$l) {
	return $i if $v == $l->[$i];
    }
    return undef;
}

	for (@es_idx) {                                                  # from the highest values downwards, take the index
	    push @training_vectors, [ list $E->dice($_) ] ;              # get the corresponding vector
	}
    }

    $nn->initialize (@training_vectors[0..0]);                           # take only the biggest ones (the eigenvalues are big, actually)
#warn $nn->as_string;
    my @mes = $nn->train ($epochs, @vs);
    warn "eigen:    length until error is < $epsilon ". scalar (grep { $_ >= $epsilon } @mes);
}

__END__

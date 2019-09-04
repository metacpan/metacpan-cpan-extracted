# ABSTRACT: turns baubles into trinketsA

package AI::ML::LogisticRegression;
use strict;
use warnings;

use Scalar::Util 'blessed';
use aliased 'Math::Lapack::Matrix' => 'M';
use Math::Lapack::Expr;
use AI::ML::Expr;
use parent 'AI::ML::Expr';
use Data::Dumper;


=head2 new

=cut
sub new {
	my ($self, %opts) = @_;
	$self = bless {} => 'AI::ML::LogisticRegression';

	$self->{reg} 	= $opts{reg} 			if exists $opts{reg};
    $self->{cost} 	= $opts{cost}			if exists $opts{cost};
    $self->{plot} 	= $opts{plot}			if exists $opts{plot};

	$self->{n} 	    = exists $opts{n}     ? $opts{n}     : 100;
    $self->{alpha} 	= exists $opts{alpha} ? $opts{alpha} : 0.1;

	return $self;
}

=head2 logistic_regression

    considerando x [m,n]
    considerando y [m,1]

=cut

sub train {
    my ($self, $x, $y) = @_;
    my ($lambda, $thetas, $h, $cost, $reg, $reg_thetas, $grad);

    my $iters     = $self->{n};
    my $alpha     = $self->{alpha};
		#my $cost_file = exists $opts{cost}  ? $opts{cost}  : undef;

    $x = Math::Lapack::Matrix::concatenate(
        M->ones($x->rows,1),
        $x
    );

    my($m, $n) = $x->shape;

    $thetas = M->random($n,1);
    my @cost_values=();
    if ( exists $self->{reg} ) {
				$lambda = $self->{reg};
    		for my $i (1 .. $iters) {
        		$h = sigmoid($x x $thetas);
        		$reg = ($lambda / (2 * $m)) * sum( $thetas->slice(x0 => 1) ** 2 );
        		$cost = (-1 / $m) * sum($y * log($h) + (1 - $y) * log(1-$h)) + $reg;

        		push @cost_values, $cost->get_element(0,0) if exists $self->{cost};

        		$reg_thetas = ($lambda / $m) * $thetas;
        		$reg_thetas->set_element(0,0,0);

        		$grad = ($x->T x ($h - $y)) / $m;

        		$thetas = $thetas - $alpha * ( $grad + $reg_thetas );
      	}
    }
    else {
      	for my $i (1 .. $iters) {
        	$h = sigmoid($x x $thetas);
        	$cost = (-1 / $m)*sum(($y * log($h)) + ((1-$y) * log(1-$h)));

        	push @cost_values, $cost->get_element(0,0) if exists $self->{cost};

        	$grad = ($x->T x ($h - $y)) / $m;
        	$thetas = $thetas - $alpha * $grad;
      	}
    }
		AI::ML::Expr::plot_cost($self->{cost}, @cost_values) if exists $self->{cost};
		$self->{thetas} = $thetas;
}


=head2 classification

=cut
sub classification {
    my ($self, $x) = @_;
    $x = (M->ones($x->rows,1))->append($x);
    $self->{classification} = sigmoid($x x $self->{thetas});
}


=head2 prediction

=cut
sub prediction {
    my ($self, $x, %opts) = @_;
    $x = Math::Lapack::Matrix::concatenate(
        M->ones($x->rows,1),
        $x
    );
    my $h = sigmoid($x x $self->{thetas});
    $self->{yatt} =  AI::ML::Expr::prediction($h, %opts);
}



=head2 accuracy

=cut
sub accuracy {
		my ($self, $y) = @_;
		unless( exists $self->{yatt} ) {
				print STDERR "You should first predict the values!\n";
				exit;
		}
		return AI::ML::Expr::accuracy($y, $self->{yatt});
}


=head2 precision 

=cut
sub precision {
		my ($self, $y) = @_;
		unless( exists $self->{yatt} ) {
				print STDERR "You should first predict the values!\n";
				exit;
		}
		return AI::ML::Expr::precision($y, $self->{yatt});
}


=head2 recall 

=cut
sub recall {
		my ($self, $y) = @_;
		unless( exists $self->{yatt} ) {
				print STDERR "You should first predict the values!\n";
				exit;
		}
		return AI::ML::Expr::recall($y, $self->{yatt});
}



=head2 f1

=cut
sub f1 {
		my ($self, $y) = @_;
		unless( exists $self->{yatt} ) {
				print STDERR "You should first predict the values!\n";
				exit;
		}
		return AI::ML::Expr::f1($y, $self->{yatt});
}

1;

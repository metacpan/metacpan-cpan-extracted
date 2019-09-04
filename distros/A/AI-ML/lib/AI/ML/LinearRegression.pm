# ABSTRACT: turns baubles into trinkets

package AI::ML::LinearRegression;
use strict;
use warnings;

use Scalar::Util 'blessed';
use aliased 'Math::Lapack::Matrix' => 'M';
use Math::Lapack::Expr;
use parent 'AI::ML::Expr';

use Data::Dumper;

=head2 new

=cut
sub new {
	my ($self, %opts) = @_;
	$self = bless {} => 'AI::ML::LinearRegression';
		
	$self->{grad} 	= $opts{gradient} if exists $opts{gradient}; 
	$self->{reg} 	= $opts{lambda}   if exists $opts{lambda};
    $self->{cost} 	= $opts{cost}	  if exists $opts{cost};
    $self->{plot} 	= $opts{plot}	  if exists $opts{plot};

	$self->{n} 	    = exists $opts{n}     ? $opts{n}     : 100;
    $self->{alpha} 	= exists $opts{alpha} ? $opts{alpha} : 0.1;
		
	return $self;
}

=head2 linear_regression

    considerando X com as dimensoes(m,n) e theta com as dimensoes (n,1)
    #Default is normal equation
    #Option
    #gradient => not use normal equation
    #plot => plot data and linear
    #cost => plot cost
    #alpha
    #n => number of iterations

=cut

sub train {
    my ($self, $x, $y) = @_;
    my ($thetas, $iters, $alpha, $lambda);
	
    if( exists $self->{grad} ) {
        $iters     = $self->{n};
        $alpha     = $self->{alpha};
        my ($cost, $grads, $reg_thetas);
        my $x = Math::Lapack::Matrix::concatenate(
            M->ones($x->rows, 1),
            $x
        );
        my ($m, $n) = $x->shape();
        $thetas = M->random($n,1);
        my @cost_values = ();
        if(defined $self->{reg}){
            $lambda = $self->{reg};
            for my $i (1..$iters){

                $cost = sum( ( ($x x $thetas) - $y) ** 2) / (2 * $m) + $lambda * sum( $thetas->slice(x0 => 1) );
                push @cost_values, $cost->get_element(0,0) if defined $self->{cost};

                $grads =  ($x->T x (($x x $thetas)-$y)) / $m;

                $reg_thetas = ($lambda / $m) * $thetas;
                # do not regularize theta 0
                $reg_thetas->set_element(0,0,0);
                $thetas = $thetas - $alpha * ( $grads + $reg_thetas );
            }
        }
        else{
            for my $i (1..$iters)
            {
        				if( exists $self->{cost} ) {
                            $cost = sum( ( ($x x $thetas) - $y) ** 2) / (2 * $m);
                            push @cost_values,$cost->get_element(0,0);
                        }

        				$grads =  ($x->T x (($x x $thetas)-$y)) / $m;
        				$thetas = $thetas - $alpha * $grads;
            }

        }

				AI::ML::Expr::plot($x->slice(col => 1), $y, $thetas, $self->{plot}) if defined $self->{plot};
				AI::ML::Expr::plot_cost($self->{cost}, @cost_values) if exists $self->{cost};
    }
    else{
        $thetas = normal_eq($x, $y);
		AI::ML::Expr::plot($x, $y, $thetas, $self->{plot}) if defined $self->{plot};
    }
    $self->{thetas} = $thetas;
}

=head2 normal_eq

=cut

sub normal_eq {
    my ($x, $y) = @_;
    #adiciona coluna de uns a matrix X
    $x = Math::Lapack::Matrix::concatenate(
        M->ones($x->rows, 1),
        $x
    );
    return ((($x->T x $x)->inverse) x $x->T) x $y;
}

=head2 linear_regression_pred

    devolve o valor previsto
    considerando X com as dimensoes(m,n) e theta com as dimensoes (n,1)

=cut

sub linear_regression_pred {
    my ($x, $thetas) = @_;
    return $x x $thetas;
}

1;

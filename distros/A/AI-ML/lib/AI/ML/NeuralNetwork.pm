# ABSTRACT: turns baubles into trinkets

package AI::ML::NeuralNetwork;
use strict;
use warnings;

use Scalar::Util 'blessed';
use Math::Lapack::Matrix;
use Math::Lapack::Expr;
use parent 'AI::ML::Expr';

my $functions = {
		sigmoid 	=> \&AI::ML::Expr::sigmoid,
		relu   		=> \&AI::ML::Expr::relu,
		lrelu 		=> \&AI::ML::Expr::lrelu,
		softmax 	=> \&AI::ML::Expr::softmax,
		tanh 		=> \&AI::ML::Expr::tanh,
		dsigmoid    => \&AI::ML::Expr::d_sigmoid,
		drelu   	=> \&AI::ML::Expr::d_relu,
		dlrelu 		=> \&AI::ML::Expr::d_lrelu,
		dtanh  		=> \&AI::ML::Expr::d_tanh
};

=head2 new

=cut
sub new {
	my ($self, $layers, %opts) = @_;
	$self = bless {} => 'AI::ML::NeuralNetwork';

	my $i = 0;
	for my $href ( @$layers ) {
		if( $i == 0 ){
			$self->{"l$i"} = { units => $href };
		}		
		else {
			if( $href =~ qw.^\d+$. ){
				$self->{"l$i"} = { units => $href, func => "sigmoid", dfunc => "dsigmoid" };
			}
			elsif( ref($href) eq "HASH" ) {
				if ( exists $href->{func} ) {
					if ( exists $functions->{$href->{func}} ) 
					{
						$self->{"l$i"}{func}  = $href->{func};
						$self->{"l$i"}{dfunc} = 'd' . $href->{func};
					}
					else
					{
						die "Invalid activation function for layer $i: $href->{func}\n";
					}	
				}
				else {
					$self->{"l$i"}{func} = "sigmoid";		
				}
				if( exists($href->{units}) && $href->{units} =~ qw. ^\d+$ . ) {
					$self->{"l$i"}{units} = $href->{units};
				} else{
					die "undefined number of units in layer $i\n";
				}
			}
		}
		$i++;
	}
	$self->load_weights_bias();
		
	$self->{n} 	    = exists $opts{n}     ? $opts{n}     : 100;
    $self->{alpha} 	= exists $opts{alpha} ? $opts{alpha} : 0.1;
	$self->{reg}    = exists $opts{reg}   ? $opts{reg}   : undef;
    $self->{cost} 	= exists $opts{cost}  ? $opts{cost}  : undef;
    $self->{plot} 	= exists $opts{plot}  ? $opts{plot}  : undef;
	return $self;
}


=head2 load_weights_bias

=cut
sub load_weights_bias {
	my ($self) = @_;
	my $size = keys %$self;
	$self->{layers} = $size;
	for my $i ( 1 .. $size-1 ) {
		my $j = $i - 1;
		$self->{"l$i"}{w} = Math::Lapack::Matrix->random($self->{"l$i"}{units}, $self->{"l$j"}{units});
		$self->{"l$i"}{b} = Math::Lapack::Matrix->zeros($self->{"l$i"}{units}, 1);
	}
}


=head2 train

=cut
sub train {
	my ($self, $x, $y, %opts) = @_;
	my $m = $x->columns;
	my $layers = $self->{layers};

	die "Wrong number of units in input layer" 	if ( $x->rows != $self->{"l0"}{units} );
	die "Wrong number of units in output layer" if ( $y->rows != $self->{"l".($layers-1)}{units} );

	my $var = { A0 => $x };

	my $iters     = $self->{n};
    my $alpha     = $self->{alpha};

	my ($rows, $cols, $cost);

	for my $iter (1 .. $iters) {
		my $aux;
		# forward propagation
		my ($i,$j);
		for ( 1 .. $layers-1){
			$i = $_;
			$j = $i - 1;
			$var->{"Z$i"} = $self->{"l$i"}{w} x $var->{"A$j"} + $self->{"l$i"}{b};
			$var->{"A$i"} = $functions->{ $self->{"l$i"}{func} }->($var->{"Z$i"});
			$i++;
		}
		$i--;

        if ($iter % 1000 == 0){
        	$cost = (-1 / $m)*sum(($y * log($var->{"A$i"})) + ((1-$y) * log(1-$var->{"A$i"})));
            $cost = $cost->get_element(0,0);
        }
		#
		## back propagation
		$var->{"dz$i"} = $var->{"A$i"} - $y;
		$aux = $var->{"dz$i"};
        #$aux->save_csv("/tmp/DZ$i.csv");

		$var->{"dw$i"} = (1 / $m) * ( $var->{"dz$i"} x T($var->{"A$j"}) );
		$var->{"db$i"} = (1 / $m) * sum( $var->{"dz$i"} , 0 );
		$var->{"da$j"} = T($self->{"l$i"}{w}) x $var->{"dz$i"};

        $self->{"l$i"}{w} = $self->{"l$i"}{w} - ( $alpha * $var->{"dw$i"} );
		$self->{"l$i"}{b} = $self->{"l$i"}{b} - ( $alpha * $var->{"db$i"} );

        $self->{"l$i"}{b}->get_element(0,0); #force eval
        $self->{"l$i"}{w}->get_element(0,0);

        if($iter == 100){
            $aux = $var->{"dw$i"};
            #$aux->save_csv("/tmp/DW$i.csv");
            $aux = $var->{"db$i"};
            #$aux->save_csv("/tmp/DB$i.csv");
            $aux = $var->{"da$j"};
            #$aux->save_csv("/tmp/da$j.m");

            $aux = $self->{"l$i"}{w};
            #$aux->save_csv("/tmp/W$i.csv");
            $aux = $self->{"l$i"}{b};
            #$aux->save_csv("/tmp/B$i.csv");
        }

		##print STDERR Dumper($self,$var);
		##
		$i--;$j--;
		for(; $j >= 0; $i--, $j--) {
			#print STDERR "Iter: $i\n";

			$var->{"dz$i"} = $var->{"da$i"} * $functions->{ $self->{"l$i"}{dfunc} }->($var->{"Z$i"}) ;
			$var->{"dw$i"} = (1 / $m) * ( $var->{"dz$i"} x T($var->{"A$j"}) );
			$var->{"db$i"} = (1 / $m) * sum( $var->{"dz$i"} , 0 );
			$var->{"da$j"} = T($self->{"l$i"}{w}) x $var->{"dz$i"} if $j >= 1;

            $self->{"l$i"}{w} = $self->{"l$i"}{w} - ( $alpha * $var->{"dw$i"} ); 
			$self->{"l$i"}{b} = $self->{"l$i"}{b} - ( $alpha * $var->{"db$i"} ); 


            if($iter == 100){
                $aux = $var->{"dz$i"};
                #$aux->save_csv("/tmp/DZ$i.csv");
                $aux = $var->{"dw$i"};
                #$aux->save_csv("/tmp/DW$i.csv");
                $aux = $var->{"db$i"};
                #$aux->save_csv("/tmp/DB$i.csv");
                #if ($j>=1){$aux = $var->{"da$j"};
                #$aux->save_csv("/tmp/da$j.m");}

                $aux = $self->{"l$i"}{w};
                #$aux->save_csv("/tmp/W$i.csv");
                $aux = $self->{"l$i"}{b};
                #$aux->save_csv("/tmp/B$i.csv");
            }
	    }
	}
    $self->{grads} = %$var if exists $opts{grads};
}


=head2 gradient_checking

=cut
sub gradient_checking {
    my ($self, $x, $y) = @_;
    my ($params, $grads, %dims) = $self->_get_params_grads();
    #print STDERR Dumper($params);
    #print STDERR Dumper($grads);
    #print STDERR Dumper(%dims);

    #my $n = $params->rows;
    #my $m = $params->columns;
    #print STDERR "elements:$n,$m\nParams vector\n";
    #for my $i (0..$n-1){
    #    print STDERR "$i:" .$params->get_element($i,0)."\n";
    #}
    #print STDERR "Grads vector\n";

    #for my $j (0..$n-1){
    #    print STDERR $params->get_element($j,0)."\n";
    #}
  
    #my $epsilon = 1e-7;
    #my $J_plus = Math::Lapack::Matrix->zeros($n,1);
    #my $J_minus = Math::Lapack::Matrix->zeros($n,1);
    #my $grad_aprox = Math::Lapack::Matrix->zeros($n,1);
    
    #for my $i (0..$n-1){
    #    $theta_plus = $params;
    #    $theta_plus->set_element($i,0) = $theta_plus->get_element($i,0) + $epsilon;       
    #    $J_plus($i,0) = _forward_prop_n($x, $y, _vector_to_hash($theta_plus, $n, %dims));
    #    
    #    $theta_minus = $params;
    #    $theta_minus->set_element($i,0) = $theta_minus->get_element($i,0) - $epsilon;       
    #    $J_minus($i,0) = _forward_prop_n($x, $y, _vector_to_hash($theta_minus, $n));

    #    $grad_aprox($i,0) = ($J_plus($i,0) - $j_minus($i,0)) / (2*$epsilon);
    #}

} 
    

=head2 _vector_to_hash

=cut
sub _vector_to_hash {
    my ($vector, $n, %dims) = @_;
    my $size = $vector->rows;
    my $pos = 0;
    my ($n_values, $weight, $bias);
    my %hash = {};
    
    for my $i (1..$n-1){
        $n_values = $dims{"w$i"}{rows} * $dims{"w$i"}{cols};
        $weight = $vector->slice( row_range => [$pos, $pos+$n_values-1] );
        $hash{"l$i"}{w} = $weight->reshape($dims{"w$i"}{rows}, $dims{"w$i"}{cols});         
        $pos += $n_values;

        $n_values = $dims{"b$i"}{rows} * $dims{"b$i"}{cols};
        $bias = $vector->reshape( row_range => [$pos, $pos+$n_values-1]);
        $hash{"l$i"}{b} = $bias->reshape($dims{"b$i"}{rows},$dims{"b$i"}{cols});
    
        $pos += $n_values;
    }
    return %hash;
}


=head2 _get_params_grads


=cut
sub _get_params_grads {
    my ($self) = @_;
    
    my ($matrix, $params, $grads, $n, %dims);

    my ($r, $c);
    $n = $self->{layers};

    $matrix = $self->{"l1"}{w};
    $dims{"w1"}{rows} = $matrix->rows; 
    $dims{"w1"}{cols} = $matrix->columns;
 ($r, $c) = $matrix->shape;
print STDERR "New dimension shape: $r,$c\n";
    $params = $matrix->reshape($matrix->rows * $matrix->columns, 1);
    ($r, $c) = $params->shape;
    print STDERR "$r,$c\n";
    
    $matrix = $self->{grads}{"dw1"};
    $grads = $matrix->reshape($matrix->rows * $matrix->columns, 1);
    for my $i (1..$n-1){
        print STDERR "layer: $i\n";
        if( $i > 1 ){
            $matrix = $self->{"l$i"}{w};
            $dims{"w$i"}{rows} = $matrix->rows; 
            $dims{"w$i"}{cols} = $matrix->columns;
            
            $matrix = $matrix->reshape($matrix->rows* $matrix->columns, 1);
 ($r, $c) = $matrix->shape;
print STDERR "New dimension shape: $r,$c\n";
            $params->append($matrix,1);
        
            $matrix = $self->{grads}{"dw$i"};
            $grads->append($matrix->reshape($matrix->rows*$matrix->columns, 1),0);
        }

    ($r, $c) = $params->shape;
    print STDERR "$r,$c\n";
        $matrix = $self->{"l$i"}{b};
        $dims{"b$i"}{rows} = $matrix->rows; 
        $dims{"b$i"}{cols} = $matrix->columns;
 ($r, $c) = $matrix->shape;
print STDERR "New dimension shape: $r,$c\n";
        $params->append($matrix->reshape($matrix->rows *$matrix->columns,1), 0);
        

    ($r, $c) = $params->shape;
    print STDERR "$r,$c\n";
        $matrix = $self->{grads}{"db$i"};
        $grads->append($matrix->reshape($matrix->rows *$matrix->columns,1), 0);
    }

    #print STDERR "cols: $c, rows: $r\n";
    #print STDERR Dumper(%dims);

    return ($params, $grads, %dims);
}


=head2 prediction

=cut
sub prediction {
    my ($self, $x, %opts) = @_;
    my $layers = $self->{layers};
    my $var = { A0 => $x };
    my ($i, $j);
	for ( 1 .. $layers-1){
		$i = $_; 
		$j = $i - 1;
		$var->{"Z$i"} = $self->{"l$i"}{w} x $var->{"A$j"} + $self->{"l$i"}{b};
		$var->{"A$i"} = $functions->{ $self->{"l$i"}{func} }->($var->{"Z$i"});
        $i++;				
    }
    $i--;
    $self->{yatt} = AI::ML::Expr::prediction($var->{"A$i"}, %opts);
    
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

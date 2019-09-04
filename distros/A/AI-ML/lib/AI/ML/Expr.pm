# ABSTRACT: turns baubles into trinkets

package AI::ML::Expr;
use strict;
use warnings;

use Chart::Gnuplot;
use Scalar::Util 'blessed';
use AI::ML;
use Math::Lapack;
use aliased 'Math::Lapack::Matrix' => 'M';


use parent 'Exporter';
use parent 'Math::Lapack::Expr';
our @EXPORT = qw(mini_batch tanh sigmoid relu lrelu d_sigmoid d_relu d_lrelu d_tanh softmax sigmoid_cost plot plot_cost);
use Math::Lapack::Expr;

sub _bless {
    my $matrix = shift;
    return bless { _matrix => $matrix, type => 'matrix' } => "Math::Lapack::Matrix";
}

=head2 sigmoid

Allow apply the function sigmoid to every element of the matrix.

    $m = $m->sigmoid();
    $m = sigmoid($m);

=cut

sub sigmoid {
    my ($self) = @_;

    return bless { package => __PACKAGE__, type => 'sigmoid', args => [$self] } => __PACKAGE__
}

sub eval_sigmoid {
    my $tree = shift;
    if (blessed($tree) && $tree->isa("Math::Lapack::Matrix")) {
      return _bless _sigmoid($tree->matrix_id);
    }

    die "Sigmoid for non matrix: " . ref($tree);
}

=head2 relu

Allows apply the function relu to every element of the matrix.

    $m = $m->relu();
    $m = relu($m);

=cut

sub relu {
    my ($self) = @_;
    return bless { package => __PACKAGE__, type => 'relu', args => [$self] } => __PACKAGE__;
}

sub eval_relu {
    my $tree = shift;
    if (ref($tree) eq "Math::Lapack::Matrix") {
        return _bless _relu($tree->matrix_id);
    }
    die "ReLU for non matrix";
}

=head2 d_relu

Allows apply the function d_relu to every element of the matrix.

    $m = $m->d_relu();
    $m = d_relu($m);

=cut

sub d_relu {
    my ($self) = @_;
    return bless { package => __PACKAGE__, type => 'd_relu', args => [$self] } => __PACKAGE__;
}

sub eval_d_relu {
    my $tree = shift;
    if (ref($tree) eq "Math::Lapack::Matrix") {
        return _bless _d_relu($tree->matrix_id);
    }
    die "ReLU for non matrix";
}

=head2 lrelu

Allows apply the function lrelu to every element of the matrix.

    $th::Lapack::Matrixref(1)m = lrelu($m, 0.0001);
    $m = m->lrelu(0.1);

=cut

sub lrelu {
    my ($self, $v) = @_;
    return bless { package => __PACKAGE__, type => 'lrelu', args => [$self, $v] } => __PACKAGE__;
}

sub eval_lrelu {
    my ($tree, $v) = @_;
    if (ref($tree) eq "Math::Lapack::Matrix") {
        return _bless _lrelu($tree->matrix_id, $v);
    }
    die "lReLU for non matrix";
}

=head2 d_lrelu

Allows apply the function d_lrelu to every element of the matrix.

    $th::Lapack::Matrixref(1)m = lrelu($m, 0.0001);
    $m = m->lrelu(0.1);

=cut

sub d_lrelu {
    my ($self, $v) = @_;
    return bless { package => __PACKAGE__, type => 'd_lrelu', args => [$self, $v] } => __PACKAGE__;
}

sub eval_d_lrelu {
    my ($tree, $v) = @_;
    if (ref($tree) eq "Math::Lapack::Matrix") {
        return _bless _d_lrelu($tree->matrix_id, $v);
    }
    die "lReLU for non matrix";
}


=head2 softmax
Allows apply the function softmax to every element of the matrix.

    $m = softmax($m);
    $m = $m->softmax();
=cut

sub softmax {
    my ($self) = @_;
    return bless { package => __PACKAGE__, type => 'softmax', args => [$self] } => __PACKAGE__; 
}

sub eval_softmax {
    my $tree = shift;
    if (ref($tree) eq "Math::Lapack::Matrix") {
        my $s = $tree->max();
        my $e_x = exp( $tree - $s );
        my $div = sum( $e_x, 1 );
        return $e_x / $div;
        #use Data::Dumper;
        #print STDERR Dumper $matrix;
#        return _bless _softmax($tree->matrix_id);
    }
    die "softmax for non matrix";
}

=head2 d_softmax
Allows apply the function d_softmax to every element of the matrix.

    $m = d_softmax($m);
    $m = $m->d_softmax();
=cut

sub d_softmax {
    my ($self) = @_;
    return bless { package => __PACKAGE__, type => 'd_softmax', args => [$self] } => __PACKAGE__; 
}

sub eval_d_softmax {
    my $tree = shift;
    if (ref($tree) eq "Math::Lapack::Matrix") {
        return _bless _d_softmax($tree->matrix_id);
    }
    die "d_softmax for non matrix";
}

=head2 tanh
Allows apply the function tanh to every element of the matrix.

    $m = tanh($m);
    $m = $m->tanh();

=cut
sub tanh {
    my ($self) = @_;
    return bless { package => __PACKAGE__, type => 'tanh', args => [$self] } => __PACKAGE__;
}

sub eval_tanh {
    my $tree = shift;
    if( ref($tree) eq "Math::Lapack::Matrix"){
        return _bless _tanh($tree->matrix_id);
    }
    die "tanh for non matrix";
}

=head2 d_tanh
Allows apply the function d_tanh to every element of the matrix.

    $m = d_tanh($m);
    $m = $m->d_tanh();

=cut
sub d_tanh {
    my ($self) = @_;
    return bless { package => __PACKAGE__, type => 'd_tanh', args => [$self] } => __PACKAGE__;
}

sub eval_d_tanh {
    my $tree = shift;
    if( ref($tree) eq "Math::Lapack::Matrix"){
        return _bless _d_tanh($tree->matrix_id);
    }
    die "d_tanh for non matrix";
}

 
=head2 d_sigmoid

Allow apply the derivate of function sigmoid to every element of the matrix.

    $m = $m->d_sigmoid();
    $m = d_sigmoid($m);

=cut

sub d_sigmoid {
    my ($self) = @_;
    return bless { package => __PACKAGE__, type => 'd_sigmoid', args => [$self] } => __PACKAGE__;
} 

sub eval_d_sigmoid {
    my $tree = shift;
    if( ref($tree) eq "Math::Lapack::Matrix"){
        return _bless _d_sigmoid($tree->matrix_id);
    }
    return "d_sigmoid for non matrix";
}

=head2 sigmoid_cost
Allows get the value of the cost of sigmoid function.

    put examples

=cut
sub sigmoid_cost {
    my ($x, $y, $weights) = @_;
    return _sigmoid_cost($x->matrix_id, $y->matrix_id, $weights->matrix_id);
}


=head2 mini-batch

=cut
sub mini_batch {
    my ($self, $start, $size, $axis) = @_;
    $axis = 0 unless defined $axis; #default
    return _bless _mini_batch($self->matrix_id, $start, $size, $axis);
}


=head2 prediction

=cut
sub prediction {
    my ($self, %opts) = @_;
		my $t = exists $opts{threshold} ? $opts{threshold} : 0.50;
		return _bless _predict_binary_classification($self->matrix_id, $t);
}

=head2 precision

=cut
sub precision {
    my ($y, $yatt) = @_;
    return _precision($y->matrix_id, $yatt->matrix_id);
}


=head2 accuracy

=cut
sub accuracy {
    my ($y, $yatt) = @_;
    return _accuracy($y->matrix_id, $yatt->matrix_id);
}


=head2 recall 

=cut
sub recall {
    my ($y, $yatt) = @_;
    return _recall($y->matrix_id, $yatt->matrix_id);
}


=head2 f1

=cut
sub f1 {
    my ($y, $yatt) = @_;
    return _f1($y->matrix_id, $yatt->matrix_id);
}



=head2 plot

=cut

sub plot {
    my ($x, $y, $theta, $file) = @_;
    my @xdata  = $x->vector_to_list();
    my @ydata  = $y->vector_to_list();
    my @thetas = $theta->vector_to_list();
    my $f = $thetas[0] . "+" . $thetas[1] . "*x";

    #print STDERR "$_\n" for(@xdata);
    #rint STDERR "$_\n" for(@ydata);
    #print STDERR "$f\n";
    #print STDERR "\n\nFILE == $file\n\n";
    my $chart = Chart::Gnuplot->new(
            output     => $file,
            title     => "Nice one",
            xlabel     => "x",
            ylabel     => "y"
    );

    my $points = Chart::Gnuplot::DataSet->new(
            xdata     => \@xdata,
            ydata     => \@ydata,
            style     => "points"
    );

    my $func = Chart::Gnuplot::DataSet->new(
            func     => $f
    );

    $chart->plot2d($points, $func);
}

=head2 plot_cost

=cut
sub plot_cost{
    my ($file, @costs) = @_;
    my @iters = (1 .. scalar(@costs));

    my $chart = Chart::Gnuplot->new(
            output     => $file,
            title     => "Cost",
            xlabel  => "Iter",
            ylabel     => "Cost"
    );
    $chart->png;
    my $data = Chart::Gnuplot::DataSet->new(
            xdata     => \@iters,
            ydata     => \@costs,
            style     => "linespoints"
    );
    $chart->plot2d($data);

}

1;

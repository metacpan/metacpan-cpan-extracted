package Algorithm::LibLinear;

use 5.014;
use Algorithm::LibLinear::DataSet;
use Algorithm::LibLinear::Model;
use Algorithm::LibLinear::Types;
use List::Util qw/sum/;
use Smart::Args;
use XSLoader;

our $VERSION = '0.19';

XSLoader::load(__PACKAGE__, $VERSION);

my %default_eps = (
    L2R_LR => 0.01,
    L2R_L2LOSS_SVC_DUAL => 0.1,
    L2R_L2LOSS_SVC => 0.01,
    L2R_L1LOSS_SVC_DUAL => 0.1,
    MCSVM_CS => 0.1,
    L1R_L2LOSS_SVC => 0.01,
    L1R_LR => 0.01,
    L2R_LR_DUAL => 0.1,

    # Solvers for regression problem
    L2R_L2LOSS_SVR => 0.001,
    L2R_L2LOSS_SVR_DUAL => 0.1,
    L2R_L1LOSS_SVR_DUAL => 0.1,
);

my %solvers = (
    # Solvers for classification problem
    L2R_LR => 0,
    L2R_L2LOSS_SVC_DUAL => 1,
    L2R_L2LOSS_SVC => 2,
    L2R_L1LOSS_SVC_DUAL => 3,
    MCSVM_CS => 4,
    L1R_L2LOSS_SVC => 5,
    L1R_LR => 6,
    L2R_LR_DUAL => 7,

    # Solvers for regression problem
    L2R_L2LOSS_SVR => 11,
    L2R_L2LOSS_SVR_DUAL => 12,
    L2R_L1LOSS_SVR_DUAL => 13,
);

sub new {
    args
        my $class => 'ClassName',
        my $bias => +{ isa => 'Num', default => -1.0, },
        my $cost => +{ isa => 'Num', default => 1, },
        my $epsilon => +{ isa => 'Num', optional => 1, },
        my $loss_sensitivity => +{ isa => 'Num', default => 0.1, },
        my $solver => +{
            isa => 'Algorithm::LibLinear::SolverDescriptor',
            default => 'L2R_L2LOSS_SVC_DUAL',
        },
        my $weights => +{
            isa => 'ArrayRef[Algorithm::LibLinear::TrainingParameter::ClassWeight]',
            default => [],
        };

    $epsilon //= $default_eps{$solver};
    my (@weight_labels, @weights);
    for my $weight (@$weights) {
        push @weight_labels, $weight->{label};
        push @weights, $weight->{weight};
    }
    my $training_parameter = Algorithm::LibLinear::TrainingParameter->new(
        $solvers{$solver},
        $epsilon,
        $cost,
        \@weight_labels,
        \@weights,
        $loss_sensitivity,
    );
    bless +{
      bias => $bias,
      training_parameter => $training_parameter,
    } => $class;
}

sub bias { $_[0]->{bias} }

sub cost { $_[0]->training_parameter->cost }

sub cross_validation {
    args
        my $self,
        my $data_set => 'Algorithm::LibLinear::DataSet',
        my $num_folds => 'Int';

    my $targets = $self->training_parameter->cross_validation(
        $data_set->as_problem(bias => $self->bias),
        $num_folds,
    );
    my @labels = map { $_->{label} } @{ $data_set->as_arrayref };
    if ($self->is_regression_solver) {
        my $total_square_error = sum map {
            ($targets->[$_] - $labels[$_]) ** 2;
        } (0 .. $data_set->size - 1);
        # Returns mean squared error.
        # TODO: Squared correlation coefficient (see train.c in LIBLINEAR.)
        return $total_square_error / $data_set->size;
    } else {
        my $num_corrects =
            grep { $targets->[$_] == $labels[$_] } (0 .. $data_set->size - 1);
        return $num_corrects / $data_set->size;
    }
}

sub epsilon { $_[0]->training_parameter->epsilon }

sub find_cost_parameter {
    args
        my $self,
        my $data_set => 'Algorithm::LibLinear::DataSet',
        my $initial => +{ isa => 'Num', default => -1.0, },
        my $max => 'Num',
        my $num_folds => 'Int',
        my $update => +{ isa => 'Bool', default => 0, };

    $self->training_parameter->find_cost_parameter(
        $data_set->as_problem(bias => $self->bias),
        $num_folds,
        $initial,
        $max,
        $update,
    );
}

sub is_regression_solver { $_[0]->training_parameter->is_regression_solver }

sub loss_sensitivity { $_[0]->training_parameter->loss_sensitivity }

sub training_parameter { $_[0]->{training_parameter} }

sub train {
    args
        my $self,
        my $data_set => 'Algorithm::LibLinear::DataSet';

    my $raw_model = Algorithm::LibLinear::Model::Raw->train(
        $data_set->as_problem(bias => $self->bias),
        $self->training_parameter,
    );
    Algorithm::LibLinear::Model->new(raw_model => $raw_model);
}

sub weights {
    args
        my $self;

    my $labels = $self->training_parameter->weight_labels;
    my $weights = $self->training_parameter->weights;
    [ map {
        +{ label => $labels->[$_], weight => $weights->[$_], }
    } 0 .. $#$labels ];
}

1;
__END__

=head1 NAME

Algorithm::LibLinear - A Perl binding for LIBLINEAR, a library for classification/regression using linear SVM and logistic regression.

=head1 SYNOPSIS

  use Algorithm::LibLinear;
  # Constructs a model for L2-regularized L2 loss support vector classification.
  my $learner = Algorithm::LibLinear->new(
    cost => 1,
    epsilon => 0.01,
    solver => 'L2R_L2LOSS_SVC_DUAL',
    weights => [
      +{ label => 1, weight => 1, },
      +{ label => -1, weight => 1, },
    ],
  );
  # Loads a training data set from DATA filehandle.
  my $data_set = Algorithm::LibLinear::DataSet->load(fh => \*DATA);
  # Updates training parameter.
  $learner->find_cost_parameter(data_set => $data_set, max => 1000, num_folds => 5, update => 1);
  # Executes cross validation.
  my $accuracy = $learner->cross_validation(data_set => $data_set, num_folds => 5);
  # Executes training.
  my $classifier = $learner->train(data_set => $data_set);
  # Determines which (+1 or -1) is the class for the given feature to belong.
  my $class_label = $classifier->predict(feature => +{ 1 => 0.38, 2 => -0.5, ... });
  
  __DATA__
  +1 1:0.708333 2:1 3:1 4:-0.320755 5:-0.105023 6:-1 7:1 8:-0.419847 9:-1 10:-0.225806 12:1 13:-1 
  -1 1:0.583333 2:-1 3:0.333333 4:-0.603774 5:1 6:-1 7:1 8:0.358779 9:-1 10:-0.483871 12:-1 13:1 
  +1 1:0.166667 2:1 3:-0.333333 4:-0.433962 5:-0.383562 6:-1 7:-1 8:0.0687023 9:-1 10:-0.903226 11:-1 12:-1 13:1 
  -1 1:0.458333 2:1 3:1 4:-0.358491 5:-0.374429 6:-1 7:-1 8:-0.480916 9:1 10:-0.935484 12:-0.333333 13:1 
  -1 1:0.875 2:-1 3:-0.333333 4:-0.509434 5:-0.347032 6:-1 7:1 8:-0.236641 9:1 10:-0.935484 11:-1 12:-0.333333 13:-1 
  ...

=head1 DESCRIPTION

Algorithm::LibLinear is an XS module that provides features of LIBLINEAR, a fast C library for classification and regression.

Current version is based on LIBLINEAR 2.21, released on Oct 5, 2018.

=head1 METHODS

=head2 new([bias => -1.0] [, cost => 1] [, epsilon => 0.1] [, loss_sensitivity => 0.1] [, solver => 'L2R_L2LOSS_SVC_DUAL'] [, weights => []])

Constructor. You can set several named parameters:

=over 4

=item bias

Bias term to be added to prediction result (i.e., C<-B> option for LIBLINEAR's C<train> command.).

This parameter makes sense only when its value is positive.

=item cost

Penalty cost for misclassification (C<-c>.)

=item epsilon

Termination criterion (C<-e>.)

Default value of this parameter depends on the value of C<solver>.

=item loss_sensitivity

Epsilon in loss function of SVR (C<-p>.)

=item solver

Kind of solver (C<-s>.)

For classification:

=over 4

=item 'L2R_LR' - L2-regularized logistic regression

=item 'L2R_L2LOSS_SVC_DUAL' - L2-regularized L2-loss SVC (dual problem)

=item 'L2R_L2LOSS_SVC' - L2-regularized L2-loss SVC (primal problem)

=item 'L2R_L1LOSS_SVC_DUAL' - L2-regularized L1-loss SVC (dual problem)

=item 'MCSVM_CS' - Crammer-Singer multiclass SVM

=item 'L1R_L2LOSS_SVC' - L1-regularized L2-loss SVC

=item 'L1R_LR' - L1-regularized logistic regression (primal problem)

=item 'L1R_LR_DUAL' -  L1-regularized logistic regression (dual problem)

=back

For regression:

=over 4

=item 'L2R_L2LOSS_SVR' - L2-regularized L2-loss SVR (primal problem)

=item 'L2R_L2LOSS_SVR_DUAL' - L2-regularized L2-loss SVR (dual problem)

=item 'L2R_L1LOSS_SVR_DUAL' - L2-regularized L1-loss SVR (dual problem)

=back

=item weights

Weights adjust the cost parameter of different classes (C<-wi>.)

For example,

  my $learner = Algorithm::LibLinear->new(
    weights => [
      +{ label => 1, weight => 0.5 },
      +{ label => 2, weight => 1 },
      +{ label => 3, weight => 0.5 },
    ],
  );

is giving a doubling weight for class 2. This means that samples belonging to class 2 have stronger effect than other samples belonging class 1 or 3 on learning.

This option is useful when the number of training samples of each class is not balanced.

=back

=head2 cross_validation(data_set => $data_set, num_folds => $num_folds)

Evaluates training parameter using N-fold cross validation method.
Given data set will be split into N parts. N-1 of them will be used as a training set and the rest 1 part will be used as a test set.
The evaluation iterates N times using each different part as a test set. Then average accuracy is returned as result.

=head2 find_cost_parameter(data_set => $data_set, max => $max_cost, num_folds => $num_folds [, initial => -1.0] [, update => 0])

Find the best cost parameter in terms of cross validation result, between C<initial> and C<max>. If C<initial> parameter is omitted an appropriate value is automatically estimated.
When true value is specified as C<update> parameter, the instance is updated to use the found cost. This behaviour is disabled by default.

Return value is an ArrayRef containing 2 values: the found cost and its cross validation score (i.e., accuracy.)

=head2 train(data_set => $data_set)

Executes training and returns a trained L<Algorithm::LibLinear::Model> instance.
C<data_set> is same as the C<cross_validation>'s.

=head1 AUTHOR

Koichi SATOH E<lt>sekia@cpan.orgE<gt>

=head1 SEE ALSO

L<Algorithm::LibLinear::DataSet>

L<Algorithm::LibLinear::FeatureScaling>

L<Algorithm::LibLinear::Model>

L<LIBLINEAR Homepage|http://www.csie.ntu.edu.tw/~cjlin/liblinear/>

L<Algorithm::SVM> - A Perl binding to LIBSVM.

=head1 LICENSE

=head2 Algorithm::LibLinear

Copyright (c) 2013-2018 Koichi SATOH. All rights reserved.

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head2 LIBLINEAR

Copyright (c) 2007-2018 The LIBLINEAR Project.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

3. Neither name of copyright holders nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

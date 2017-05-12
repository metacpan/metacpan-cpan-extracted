use strict;
use warnings;

package AI::MaxEntropy::Model;

use YAML::Syck;

our $VERSION = '0.20';

sub new {
    my ($class, $model) = @_;
    my $self = bless {}, $class;
    $self->load($model) if defined($model);
    return $self;
}

sub load {
    my ($self, $file) = @_;
    my $model = LoadFile($file);
    ($self->{x_list}, $self->{y_list}, $self->{f_map}, $self->{lambda})
        = @$model;
    $self->{x_num} = scalar(@{$self->{x_list}});
    $self->{y_num} = scalar(@{$self->{y_list}});
    $self->{f_num} = scalar(@{$self->{lambda}});
    $self->{x_bucket}->{$self->{x_list}->[$_]} = $_
        for (0 .. $self->{x_num} - 1);
    $self->{y_bucket}->{$self->{y_list}->[$_]} = $_
        for (0 .. $self->{y_num} - 1);
}

sub save {
    my ($self, $file) = @_;
    my $data = [
        $self->{x_list},
	$self->{y_list},
	$self->{f_map},
	$self->{lambda}
    ];
    DumpFile($file, $data);    
}

sub all_x { @{$_[0]->{x_list}} }
sub all_labels { @{$_[0]->{y_list}} }

sub score {
    my $self = shift;
    my ($x, $y) = @_;
    # preprocess if $x is hashref
    $x = [
        map {
	    my $attr = $_;
	    ref($x->{$attr}) eq 'ARRAY' ? 
	        map { "$attr:$_" } @{$x->{$attr}} : "$_:$x->{$_}" 
        } keys %$x
    ] if ref($x) eq 'HASH';
    # calculate score
    my @x1 = map { $self->{x_bucket}->{$_} } @$x;
    my $lambda_f = 0;
    if (defined(my $y1 = $self->{y_bucket}->{$y})) {
        for my $x1 (@x1) {
	    if (defined($x1)) {
	        my $lambda_i = $self->{f_map}->[$y1]->[$x1];
                $lambda_f += $self->{lambda}->[$lambda_i]
		    if $lambda_i != -1;
            }
        }
    }
    return $lambda_f; 
}

sub predict {
    my $self = shift;
    my $x = shift;
    my @score = map { $self->score($x => $_) } @{$self->{y_list}};
    my ($max_score, $max_y) = (undef, undef);
    for my $y (0 .. $self->{y_num} - 1) {
        ($max_score, $max_y) = ($score[$y], $y) if not defined($max_y);
	($max_score, $max_y) = ($score[$y], $y) if $score[$y] > $max_score;
    }
    return $self->{y_list}->[$max_y];
}

1;

__END__

=head1 NAME

AI::MaxEntropy::Model - Perl extension for using Maximum Entropy Models

=head1 SYNOPSIS

  use AI::MaxEntropy::Model;

  # learn a model by AI::MaxEntropy
  require AI::MaxEntropy;
  my $me = AI::MaxEntropy->new;
  $me->see(['round', 'smooth', 'red'] => 'apple' => 2);
  $me->see(['long', 'smooth', 'yellow'] => 'banana' => 3);
  $me->see(['round', 'rough'] => 'orange' => 2);
  my $model = $me->learn;

  # make prediction on unseen data
  # ask what a red round thing is most likely to be
  my $y = $model->predict(['round', 'red']);
  # the answer apple is expected

  # print out scores of all possible labels
  for ($model->all_labels) {
      my $s = $model->score(['round', 'red'] => $_);
      print "$_: $s\n";
  }
  
  # save the model to file
  $model->save('model_file');

  # load the model from file
  $model->load('model_file');

=head1 DESCRIPTION

This module manipulates models learnt by L<AI::MaxEntropy>. For details
about Maximum Entropy learner, please refer to L<AI::MaxEntropy>.

=head1 FUNCTIONS

=head2 new

Create a new model object from a model file.

  my $model = AI::MaxEntropy::Model->new('model_file');

=head2 predict

Get the most possible label for a unlabeled sample

  ...
  
  $y = $model->predict(['round', 'red']);

=head2 score

Get scores for every possible label for a unlabeled sample

  ...

  $s = $model->score(['round', 'red'] => 'apple');

=head2 save

Dumps the model to a file.

  ...

  $model->save('model_file');

=head2 load

Loads the model from a file.

  ...

  $model->load('model_file');

=head2 all_x

Returns a list of all x.

=head2 all_labels

Returns a list of all y (labels).

=head1 SEE ALSO

L<AI::MaxEntropy>

=head1 AUTHOR

Laye Suen, E<lt>laye@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The MIT License

Copyright (C) 2008, Laye Suen

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=head1 REFERENCE

=over

=item
A. L. Berge, V. J. Della Pietra, S. A. Della Pietra. 
A Maximum Entropy Approach to Natural Language Processing,
Computational Linguistics, 1996.

=item
S. F. Chen, R. Rosenfeld.
A Gaussian Prior for Smoothing Maximum Entropy Models,
February 1999 CMU-CS-99-108.

=back


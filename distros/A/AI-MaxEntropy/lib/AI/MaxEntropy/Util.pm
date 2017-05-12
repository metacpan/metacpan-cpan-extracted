use strict;
use warnings;

package AI::MaxEntropy::Util;

use Exporter;

our $VERSION = '0.20';

our @ISA = qw/Exporter/;

our @EXPORT_OK =
    qw/traverse_partially map_partially train_and_test precision recall/;

our %EXPORT_TAGS =
    (all => [@EXPORT_OK]);

sub traverse_partially(&$$;$) {
    my ($code, $samples, $pattern, $t) = @_;
    $t ||= 'x';
    my ($p, $n) = (length($pattern), scalar(@$samples));
    for my $i (grep { substr($pattern, $_, 1) eq $t } (0 .. $p - 1)) {
        for (int($n * $i / $p) .. int($n * ($i + 1) / $p) - 1) {
	    $_ = $samples->[$_];
	    $code->();
	}
    }
}

sub map_partially(&$$;$) {
    my ($code, $samples, $pattern, $t) = @_;
    my @r;
    traverse_partially { push @r, $code->($_) } $samples, $pattern, $t;
    return \@r;
}

sub train_and_test {
    my ($me, $samples, $pattern) = @_;
    traverse_partially { $me->see(@$_) } $samples, $pattern, 'x';
    my $m = $me->learn;
    my $r = map_partially { [$_ => $m->predict($_->[0])] }
        $samples, $pattern, 'o';
    return ($r, $m);
}

sub precision {
    my $r = shift;
    my ($c, $n) = (0, 0);
    for (@$r) {
        my $w = defined($_->[0]->[2]) ? $_->[0]->[2] : 1;
        $n += $w;
        $c += $w if $_->[0]->[1] eq $_->[1];
    }
    return $c / $n;
}

sub recall {
    my $r = shift;
    my $label = shift;
    my ($c, $n) = (0, 0);
    for (@$r) {
        if ($_->[0]->[1] eq $label) {
            my $w = defined($_->[0]->[2]) ? $_->[0]->[2] : 1;
	    $n += $w;
	    $c += $w if $_->[1] eq $label;
	}
    }
    return $c / $n;
}

1;

__END__

=head1 NAME

AI::MaxEntropy::Util - Utilities for doing experiments with ME learners 

=head1 SYNOPSIS

  use AI::MaxEntropy;
  use AI::MaxEntropy::Util qw/:all/;

  my $me = AI::MaxEntropy->new;
  
  my $samples = [
      [['a', 'b', 'c'] => 'x'],
      [['e', 'f'] => 'y' => 1.5],
      ...
  ];

  my ($result, $model) = train_and_test($me, $samples, 'xxxo');

  print precision($result)."\n";
  print recall($result, 'x')."\n";

=head1 DESCRIPTION

This module makes doing experiments with Maximum Entropy learner easier.

Generally, an experiment involves a training set and a testing set
(sometimes also a parameter adjusting set). The learner is trained with
samples in the training set and tested with samples in the testing set.
Usually, 2 measures of performance are concerned.
One is precision, indicating the percentage of samples which are correctly
predicted in the testing set. The other one is recall, indicating the 
precision of samples with a certain label.

=head1 FUNCTIONS

=head2 train_and_test

This function automated the process of training and testing.

    my $me = AI::MaxEntropy->new;
    my $sample = [
        [ ['a', 'b'] => 'x' => 1.5 ],
	...
    ];
    my ($result, $model) = train_and_test($me, $sample, 'xxxo');

First, the whole samples set will be divided into a training set and a
testing set according to the specified pattern. A pattern is a string,
in which each character stands for a part of the samples set.
If the character is C<'x'>, the corresponding part is used for training.
If the character is C<'o'>, the corresponding part is used for testing.
Otherwise, the corresponding part is simply ignored.

For example, the pattern 'xxxo' means the first three forth of the samples
set are used for training while the last one forth is used for testing.

The function returns two values. The first one is an array ref describe
the result of testing, in which each element follows a structure like
C<[sample =E<gt> result]>. The second one is the model learnt from the
training set, which is an L<AI::MaxEntropy::Model> object.

=head2 traverse_partially

This function is the core implementation of L</train_and_test>. It traverse
through some of the elements in an array according to a pattern,
and does some specified actions with each of these elements.
  
  my $arr = [1, 2, 3, 4, 5];

  # print out the first two firth of the array
  traverse_partially { print } $arr, 'xx---';

  # do the same thing, using custom significant character 'o'
  traverse_partially { print } $arr, 'oo---' => 'o';

  my $samples = [
      [['a', 'b'] => 'x'],
      [['c', 'd'] => 'y' => 1.5],
      ...
  ];
  my $me = AI::MaxEntropy->new;

  # see the first one third and the last one third samples
  traverse_partially { $me->see(@$_) } $samples, 'x-x';

=head2 map_partially

This function is similar to L</traverse_partially>. However, it returns an
array ref in which all elements in the original array is mapped according
to the code snippet's return value.

  my $arr = [1, 2, 3, 4, 5];
  
  # increase the last one third of the elements by 1
  $arr = map_partially { $_ + 1 } $arr, '--x';

=head2 precision

Calculates the precision based on the result returned by
L</train_and_test>.

  ...
  my ($result, $model) = train_and_test(...);
  print precision($result)."\n";

Note that the weights of samples are taken into consideration.

=head2 recall

Calculates the recall of a certain label based on the result returned by
L</train_and_test>.

  ...
  my ($result, $model) = train_and_test(...);
  print recall($result, 'label')."\n";

Note that the weights of samples are taken into consideration.

=head1 SEE ALSO

L<AI::MaxEntropy>, L<AI::MaxEntropy::Model>

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


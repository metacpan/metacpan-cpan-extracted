package Algorithm::X::DLX;

use strict;
use warnings;

our $VERSION = '0.03';

require 5.06.0;

use Algorithm::X::LinkedMatrix;

sub new {
  my ($class, $problem) = @_;
  return bless { A_ => Algorithm::X::LinkedMatrix->new($problem), iterator => undef }, $class;
}

sub count_solutions {
  my $self = shift;

  my $options = Options();
  $options->{get_solutions} = 0;

  return $self->search($options)->{number_of_solutions};
}

sub find_solutions {
  my ($self, $max) = @_;

  my $options = Options();
  $options->{max_solutions} = $max if defined $max;

  return $self->search($options)->{solutions};
}

sub search {
  my ($self, $options) = @_;
  $options ||= Options();
  
  if ($options->{random_engine}) {
    die "The option to select a random engine has been removed in Perl";
  }

  my $result = { profile => [], number_of_solutions => 0, solutions => [] };
  $self->{iterator} ||= $self->get_solver($options->{choose_random_column}, $result->{profile});

  while (my $solution = $self->{iterator}() ) {
    $result->{number_of_solutions}++;
    if ($options->{get_solutions}) {
      push @{$result->{solutions}}, $solution;
    }
    last if $result->{number_of_solutions} >= $options->{max_solutions};
  }
  
  return $result;
}

sub next_solution {
  my $self = shift;

  return $self->{iterator}();
}

sub get_solver {
  my ($self, $random_column, $profile) = @_;

  my $h = $self->{A_}->root_id();
  my @placed = ();
  my $level = 0;
  my @state_stack = ([undef, undef]);

  return sub {
    # brought back on track by by Antti Ajanki, Tom Boothby at https://github.com/sagemath/sage/blob/develop/src/sage/combinat/dlx.py

    while ( $level >= 0 ) {
      my ($c, $r) = @{$state_stack[$level]};

      if ( not $c ) {
        ++$profile->[ @placed ] if $profile;

        if ($self->R($h) == $h) {
          # base case ( no columns left )
          $level--;
          return [ @placed ];

        } else {
          # fetch remaining columns that share the same, lowest node count at present
          my @cs = ();
          for (my $j = $self->R($h); $j != $h; $j = $self->R($j)) {
            if (@cs && $self->S($j) < $self->S($cs[0])) {
              @cs = ();
            }
            push @cs, $j if !@cs || $self->S($j) == $self->S($cs[0]);
          }

          die "No columns found" if !@cs;
          
          if ($self->S($cs[0]) < 1) {
            $level--;
            next;
          }

          $c = $random_column ? ($cs[int rand @cs]) : $cs[0];

          $self->cover_column($c);
          $state_stack[$level] = [$c, $c];
        }

      } elsif ($self->D($r) != $c) {

        if ($c != $r) {
          pop @placed;
          for (my $j = $self->L($r); $j != $r; $j = $self->L($j) ) {
            $self->uncover_column($j);
          }
        }

        $r = $self->D($r);
        $placed[$level] = $self->Y($r);
        for (my $j = $self->R($r); $j != $r; $j = $self->R($j)) {
          $self->cover_column($j);
        }

        $state_stack[$level] = [$c, $r];
        $level++;

        if (@state_stack == $level) {
          push @state_stack, [undef, undef];
        } else {
          $state_stack[$level] = [undef, undef];
        }

      } else {
        if ($c != $r) {
          pop @placed;

          for (my $j = $self->L($r); $j != $r; $j = $self->L($j) ) {
            $self->uncover_column($j);
          }
        }
        $self->uncover_column($c);
        $level--;
      }
    }
  };
}

sub Options {
  return  {
    choose_random_column => 0,
    get_solutions => 1,
    max_solutions => ~0,
  #  random_engine => undef,
  }
}

# acquire some matrix methods
sub cover_column   { return shift()->{A_}->cover_column(@_) }
sub uncover_column { return shift()->{A_}->uncover_column(@_) }
sub Y { return shift()->{A_}->Y(@_) }
sub S { return shift()->{A_}->S(@_) }
sub R { return shift()->{A_}->R(@_) }
sub L { return shift()->{A_}->L(@_) }
sub D { return shift()->{A_}->D(@_) }

1;

__END__

=encoding UTF-8

=head1 NAME

Algorithm::X::DLX - Solve exact cover problems with Algorithm-X and Dancing Links

=head1 DESCRIPTION

The ubiquitous implementation of Donald Knuth's Algorithm X with dancing links.
Algorithm X is a clever way to execute a brute force search, aiming to find the solutions for any specific I<exact cover problem>.
The dancing links technique (DLX) for generic backtracking was published by Hiroshi Hitotsumatsu and Kōhei Noshita in 1979 already.

=head1 DISCLAIMER

Author of the originating C++ sources, of which this distribution is mostly a direct translation, 
is Johannes Laire at L<https://github.com/jlaire/dlx-cpp>.
Even all the examples, tests and most of the documentation are by him.

There only are two notable deviations from the original:

=over

=item * The backtracking in Algorithm::X::DLX is done iteratively, without recursion.
So it's possible to process huge matrices without worrying about memory.

=item * It's still possible to compare performances between selecting random colummns with lowest node count and just picking the first one (left most) of these by providing the option C<choose_random_column>, but the ability to further differentiate and select a specific random engine with C<random_engine> has been removed. It now just uses the Perl standard random engine on your system.

=back

=head1 SYNOPSIS

  use Algorithm::X::DLX;

  my $problem = Algorithm::X::ExactCoverProblem->new($width, \@input_rows, $secondary_column_count);

  my $dlx = Algorithm::X::DLX->new($problem);

  my $result = $dlx->search();
  foreach my $row_indices (@{$result->{solutions}}) {
    ...

  Or better, especially with searches taking a very long time

  my $iterator = $dlx->get_solver();
  while (my $row_indices = &$iterator()) {
    ...
  

=head1 The Example applications provided under examples/...

There are scripts and modules for various exact cover problems: 

N-queens, Langford, Sudoku, N-pieces and Pentominoes

See L<Algorithm::X::Examples>.

=head2 L<examplesE<sol>dlx.pl|https://metacpan.org/dist/Algorithm-X-DLX/source/examples/dlx.pl>

And a more generic script that makes use of this lib.

  examples$ ./dlx.pl -pv < data/knuth_example.txt
  1 0 0 1 0 0 0
  0 0 1 0 1 1 0
  0 1 0 0 0 0 1

  solutions: 1

=head1 DEPENDENCIES

=over 5

=item * L<Carp>

=back

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in
this distribution, unless explicitly noted otherwise.

This software is copyright (c) 2025 by Steffen Heinrich

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Donald E. Knuth, Stanford University 2000 L<Dancing Links|http://arxiv.org/pdf/cs/0011047v1> 

L<Introduction to Exact Cover Problem and Algorithm X|https://www.geeksforgeeks.org/introduction-to-exact-cover-problem-and-algorithm-x/>

Peter Pfeiffer BSc, Linz 2023 L<Uncovering Exact Cover Encodings|https://epub.jku.at/obvulihs/download/pdf/9260418>

=cut


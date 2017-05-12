package Algorithm::Knap01DP;
use 5.008004;
use strict;
use warnings;
use Carp;
use IO::File;

our $VERSION = '0.25'; 
# Still a very early "alpha" version

sub new {
    my $class = shift;
    my $self = {
        capacity    => 0,       # total capacity of this knapsack
        numobjects  => 0,       # number of objects
        weights     => [],      # weights to be packed into the knapsack
        profits     => [],      # profits to be packed into the knapsack
        tableval    => [],      # f[k][c] DP table of values
        tablesol    => [],      # x[k][c] DP table of sols 
                                # (0 = out, 1 = in, 2 = in and out)
        solutions   => [],      # list of lists of object indexes 
        filename    => "",      # name of the file the problem was read from
        @_,
    };
    
    croak "Profits and Weights don't have the same size" 
           unless scalar(@{$self->{weights}}) == scalar(@{$self->{profits}});

    bless $self, $class;
}

sub Knap01DP {
  my $self = shift();
  my $M = $self->{capacity};
  my @w = @{$self->{weights}};
  my @p = @{$self->{profits}};

  croak "Weight list is empty" unless (@w > 0);

  my $N = @w;
  my (@f, @x);

  for my $c (0..$M) {
    if ($w[0] <= $c) {
      $f[0][$c] = $p[0];
      $x[0][$c] = 1;
    }
    else {
      $f[0][$c] = 0;
      $x[0][$c] = 0;
    }
  }

  for my $k (1..$N-1) {
    for my $c (0..$M) {
      my $n = $f[$k-1][$c];
      if ($c >= $w[$k]) {
        my $y = $f[$k-1][$c-$w[$k]]+$p[$k];
        if ($n < $y) {
          $f[$k][$c] = $y;
          $x[$k][$c] = 1;
        }
        elsif ($n > $y) { 
          $f[$k][$c] = $n;
          $x[$k][$c] = 0;
        }
        else { # $n == $y
          $f[$k][$c] = $n;
          $x[$k][$c] = 2; # both ways
        }
      }
      else { 
        $f[$k][$c] = $n; 
        $x[$k][$c] = 0; 
      }
    }
  }
  ($self->{tableval}, $self->{tablesol}) = (\@f, \@x);
}

sub solutions {
  my $self = shift();
  my $N = $self->{numobjects};
  my $M = $self->{capacity};
  my @w = @{$self->{weights}};
  my (@f, @x);

  $self->Knap01DP() if (!@{$self->{tableval}});
  @f = @{$self->{tableval}}; 
  @x = @{$self->{tablesol}}; 

  my ($k, $c, $s);

  my @sol = ({ sol=>[], cap=>$M });
  for($k = $N-1; $k >= 0; $k--) {
    my @temp = ();
    foreach $s (@sol) {
      $c = $s->{cap};
      if ($x[$k][$c] == 1) {
        unshift @{$s->{sol}}, $k;
        $s->{cap} -= $w[$k];
      }
      elsif ($x[$k][$c] == 2) {
        push @temp, {sol => [ @{$s->{sol}} ], cap =>$s->{cap}};
        unshift @{$s->{sol}}, $k;
        $s->{cap} -= $w[$k];
      }
    } # foreach $s
    push @sol, @temp if @temp;
  } # for
  $self->{solutions} = \@sol;
}

sub ReadKnap {
  my $class = shift;
  my $filename = shift;

  my $file = IO::File->new("< $filename");
  croak "Can't open $filename" unless defined($file);
  my (@w, @p);
  
  my $N = <$file>; chomp($N);
  my $M = <$file>; chomp($M);
  for (0..$N-1) {
    $w[$_] = <$file>;
    $p[$_] = <$file>;
  }
  chomp @w; chomp @p;
  return $class->new(
                 capacity => $M, 
                 numobjects => $N,
                 weights =>\@w,
                 profits => \@p,
                 filename => $filename);
}

sub GenKnap {
  my $class = shift;
  my $N = (shift() || 17); # number of objects
  my $R = (shift() || $N); # range

  croak "Number of objects and Range must be positive integers" 
     unless ($N > 0) and ($R > 0) and ($N == int($N)) and ($R == int($R));
  
  my ($x, $M, @w);
  @w = map { $x = 1 + int(rand($R)); $M += $x; $x } 1..$N;
  $M = int ($M / 2);
  return $class->new(
                 capacity => $M, 
                 numobjects => $N,
                 weights =>\@w,
                 profits => \@w,
                 filename => 'RANDOM');
}

sub ShowResults {
  my $self = shift();
  my $width = (shift() || 8);
  my @sol = @{$self->{solutions}};
  my ($x, $i, $w);

  print "Problem: ";
  print "$self->{filename}\n" if defined($self->{filename});
  print "Number of Objects = $self->{numobjects} Capacity = $self->{capacity}\n";
  for (@sol) {
    my @s = @{$_->{sol}};

    $i = 1;
    $w = 0;
    for $x (@s) {
      print "$x ($self->{weights}[$x])\t";
      $w += $self->{weights}[$x];
      print "\n" if ($i % $width) == 0;
      $i++;
    }
    print "Used Capacity = $w\n";
  }
  print "Profit = $self->{tableval}[-1][-1]\n";
}

1;
__END__

=head1 NAME

Algorithm::Knap01DP - Solves the 0-1 Knapsack problem using the Dynamic Programming Technique

=head1 SYNOPSIS

  use Algorithm::Knap01DP;

  $knap = Algorithm::Knap01DP->ReadKnap($file); # constructor: read from $file
  $knap = Algorithm::Knap01DP->new( # constructor
              capacity => 100, weights => [ 1..5 ], profits => [1..10]);
  srand(7);
  $knap = Algorithm::Knap01DP->GenKnap(); # constructor: randomly generated problem

  $knap->Knap01DP(); # computes the DP tables
  $knap->solutions(); # computes all the solutions
  $knap->ShowResults(); # shows all the solutions

=head1 DESCRIPTION

Solves the 0-1 Knapsack problem using the Dynamic Programming Technique.
See an example of problem format

    $ cat knapanderson.dat
    6   # number of objects
    30  # capacity
    14  # weight object 0
    14  # profit object 0
    5   # etc.
    5
    2
    2
    11
    11
    3
    3
    8
    8
    
This corresponds to a problem with N=6, M=30 (objects, capacity)
then the following consecutive pair of lines hold the weight and
profit (in that order) of the different objects.
A program illustrating the use of the module follows:

    $ cat -n example.pl
    1  use strict;
    2  use Algorithm::Knap01DP;
    3
    4  die "Usage:\n$0 knapsackfile\n" unless @ARGV;
    5  my $knap = Algorithm::Knap01DP->ReadKnap($ARGV[0]);
    6  $knap->solutions();
    7  $knap->ShowResults();

The output is:

    $ perl example.pl knapanderson.dat
    Problem: knapanderson.dat
    Number of Objects = 6 Capacity = 30
    0 (14)  1 (5)   4 (3)   5 (8)   Used Capacity = 30
    0 (14)  2 (2)   3 (11)  4 (3)   Used Capacity = 30
    0 (14)  1 (5)   3 (11)  Used Capacity = 30
    Profit = 30

The algorithm has complexity order M x N, being M the capacity and N the number
of objects. Since M is usually much smaller than 2^N, the algorithm 
gives a efficient way to find all the solutions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Algorithm::Knapsack> http://nereida.deioc.ull.es/~lhp/perlexamples/ (Spanish)

=head1 AUTHOR

Casiano Rodriguez Leon E<lt>casiano@ull.esE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Casiano Rodriguez Leon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

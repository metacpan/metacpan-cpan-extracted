package Algorithm::PageRank;
$|++;
use strict;
use warnings;
our $VERSION = '0.08';

use fields qw(graph prvect size);

sub new { bless {}, shift }

use List::Util;
use PDL;
#use Data::Dumper;
#use PDL::IO::Dumper;

#*STDERR = \*STDOUT;

our $d_factor = 0.05; # dampening factor

sub graph {
    my $self = shift;
    my $graph = shift;

    die "Odd number of node numbers is not valid\n" if scalar(@$graph)%2;

    my $size = List::Util::max(@$graph)+1;
    $self->{size} = $size;

    $self->{graph} = zeroes($size, $size);
    for (my $i = 0 ; $i<@$graph ; $i+=2){
	$self->{graph}->index2d(
				$graph->[$i],
				$graph->[$i+1],
				) .= 1;
    }

    foreach my $i (0..$self->{size}-1){
	my $outdeg_sum = sum $self->{graph}->slice(join q/:/, $i, $i); 
	if($outdeg_sum){
	    $self->{graph}->slice(join q/:/, $i, $i) /=
		$outdeg_sum;
	}
    }

    $self->{graph} = transpose $self->{graph};
    $self->{prvect} = ones($size) / $size;    # the initial pagerank
#    print $self->{graph}->slice(":");
#    print sdump $self;
#    print $self->{prvect}->slice(":");
}

sub iterate {
    my $self = shift;
    my $iter = shift || 100;
    my $normal_factor = $d_factor/$self->{size};
    my $inv_d_factor = 1 - $d_factor;
#    print $self->{prvect}->slice(":");
#    print $self->{graph}->slice(":");
    foreach (1..$iter){
      $self->{prvect} =
	$inv_d_factor * $self->{prvect} x $self->{graph} + $normal_factor * $self->{prvect};
#      print $self->{prvect}->slice(":");
#      print sdump (($d_factor/$self->{size}) * $self->{prvect});
    }
}


sub result {
    my $self = shift;
    $self->{prvect};
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Algorithm::PageRank - Calculate PageRank in Perl

=head1 SYNOPSIS

  use Algorithm::PageRank;
  $pr = new Algorithm::PageRank;

  $pr->graph([
	      0 => 1,
	      0 => 2,
	      1 => 0,
	      2 => 1,
	      ]
	      );

  $pr->iterate();
  $pr->iterate(50);

  $pr->result();

=head1 DESCRIPTION

This is a simple implementation of PageRank algorithm. Please do not
expect it to be potent to cope with zilla-size of data.

=head2 graph

Feed the graph topology. Vertices count from 0.

=head2 iterate

Calculate the pagerank vector. The parameter is the maximal number of
iterations. If the vector does not converge before reaching the
threshold, then calculation will stop at the maximum. Default
iteration number is 100.

You can also reset the dampening factor
($Algorithm::PageRank::d_factor).  The default value is 0.05.

=head2 result

Return the pagerank vector in PDL object format.


=head1 COPYRIGHT

Copyright (C) 2004 by Yung-chung Lin (a.k.a. xern) <xern@cpan.org>

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself

=cut

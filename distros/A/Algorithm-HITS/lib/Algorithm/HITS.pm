package Algorithm::HITS;

use strict;
use warnings;

our $VERSION = '0.04';

use fields qw(graph graph_t size hub_v aut_v);

sub new { bless {}, $_[0] }

use PDL;
use List::Util;
#use Data::Dumper;
use PDL::IO::Dumper;

sub graph {
    my $self = shift;
    my $graph = shift;

    die "Odd number of node numbers is not valid\n" if scalar(@$graph)%2;

    my $size = List::Util::max(@$graph)+1;
    $self->{size} = $size;

    $self->{graph} = zeroes($size, $size);
    for (my $i = 0 ; $i<@$graph ; $i+=2){
#	print STDERR "$graph->[$i] ==> $graph->[$i+1]\n";
	$self->{graph}->index2d(
				$graph->[$i],
				$graph->[$i+1],
				) .= 1;
    }
    $self->{graph_t} = transpose $self->{graph};

    $self->{hub_v} = norm (ones $size);
    $self->{aut_v} = norm (ones $size);

#    print STDERR $self->{graph}->slice(':'), $self->{power_matrix_t}->slice(':'), $self->{power_matrix}->slice(':');

#    print STDERR $self->{aut_v}->slice(':'), $self->{hub_v}->slice(':');
}

sub set_authority {
    my $self = shift;
    my $vect = shift;
    foreach my $i (0..$#$vect){
	$self->{aut_v}->index($i) .= $vect->[$i];
    }
    $self->{aut_v} = norm $self->{aut_v};
    1;
}

sub set_hub {
    my $self = shift;
    my $vect = shift;
    foreach my $i (0..$#$vect){
	$self->{hub_v}->index($i) .= $vect->[$i];
    }
    $self->{hub_v} = norm $self->{hub_v};
    1;
}

sub iterate {
    my $self = shift;
    my $iter = shift || 1;
    foreach (1..$iter){
	$self->{hub_v} = norm ($self->{aut_v} x $self->{graph});

	$self->{aut_v} = norm ($self->{hub_v} x $self->{graph_t});

#	print STDERR "Authority => ", $self->{aut_v}->slice(':'), "Hub => ", $self->{hub_v}->slice(':');
    }
    1;
}

sub result {
    my $self = shift;
#    print STDERR sdump $self->{aut_v};
#    print STDERR sdump $self->{hub_v};
    +{
	authority => $self->{aut_v},
	hub => $self->{hub_v},
    }
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Algorithm::HITS - Perl implementation of HITS algorithm

=head1 DESCRIPTION

This module implements the HITS algorithm (Kleinberg's
hypertext-induced topic selection).

See also L<http://www2002.org/CDROM/refereed/643/node1.html>

=head1 USAGE

  use Algorithm::HITS;

  $h = new Algorithm::HITS;

=head2 SET UP GRAPH

  $h->graph(
	    [
	     0 => 1,
	     0 => 2,
	     
	     1 => 0,
	     1 => 2,
	     
	     2 => 1,
	     ]
	    );

=head2 ITERATE THROUGH COMPUTATION

Iterate 1000 times.

  $h->iterate(1000);

Default value is 1

  $h->iterate();

=head2 RETURN RESULT

Return hub vector and authority vector in PDL object format.

  $h->result();


=head2 SETTINGS

Set initial authority vector. Vector is normalized to unit Euclidean
length.

  $h->set_authority(\@v);


Set initial hub vector. Vector is normalized to unit Euclidean length.

  $h->set_hub(\@v);

=head1 ACKNOWLEDGEMENT

Thanks goes to Hugo Zanghi for pointing out the bug in normalizing vectors.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Yung-chung Lin (a.k.a. xern) <xern@cpan.org>

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut

package Algorithm::DBSCAN;

use strict;
use warnings;
use 5.10.1;

use Data::Dumper;

use Algorithm::DBSCAN::Point;
use Algorithm::DBSCAN::Dataset;

=head1 NAME

Algorithm::DBSCAN - (ALFA code) Perl implementation of the DBSCAN (Density-Based Spatial Clustering of Applications with Noise) algorithm

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

This module can be used to find clusters of points in a multidimensional space. 
More information can be found on Wikipedia: L<DBSCAN|https://en.wikipedia.org/wiki/DBSCAN>

The simple usage:

    use Algorithm::DBSCAN;
    
    my $points_data_file =     
        'point_1 56.514307478581514 37.146118456702034
        point_2 34.02049221667614 46.024651786417536
        point_3 23.473087508078684 60.62328221968349
        point_4 10.418513808840482 24.59808378533684
        point_5 10.583414831970764 25.902459835735534
        point_6 9.756855426925464 24.062840099892146
        point_7 10.567067873860672 22.32511341184489
        point_8 11.070046359352189 25.91278382647844
        point_9 9.537780590838175 25.000630928726288
        point_10 10.507367338512058 27.637356924097915
        point_11 11.949089580614444 30.67843911922257
        point_12 10.373548645248105 25.699863108892945
        point_13 47.061169019689615 12.482585189174058
        point_14 47.00269836645959 12.04880276389404
        point_15 47.197663384856476 12.899232975457025
        point_16 44.3719178488551 15.41709269630616
        point_17 46.31921200316786 12.556849509965417
        point_18 44.128763621333135 14.657970021594974
        point_19 48.89953587475758 15.183892607591467
        point_20 52.15333345222132 16.354597634497154
        point_21 50.03978361242539 14.85901473647285';

    my $dataset = Algorithm::DBSCAN::Dataset->new();
    my @lines = split(/\n\s+/, $points_data_file);
    foreach my $line (@lines) {
        $dataset->AddPoint(new Algorithm::DBSCAN::Point(split(/\s+/, $line)));
    }

    my $dbscan = Algorithm::DBSCAN->new($dataset, 4 * 4, 2);

    $dbscan->FindClusters();
    $dbscan->PrintClustersShort();
    
If you have huge datasets and want to use multiple CPUs in a optimal way you can build 
the region index with an external tool (will soon be available). En axample of code that 
uses a region index would be as follow.

Given the dataset:

    point_1 56 37
    point_2 34 46
    point_3 23 60
    point_4 10 24
    point_5 10 25
    point_6 9 24
    point_7 10 22
    point_8 11 25
    point_9 9 25
    point_10 10 27
    point_11 11 30
    point_12 10 25
    point_13 47 12
    point_14 47 12
    point_15 47 12
    point_16 44 15
    point_17 46 12
    point_18 44 14
    point_19 48 15
    point_20 52 16
    point_21 50 14

The region index with $eps = 4 x 4 and $min_distance = 2 would look like this:

    0 0
    1 1
    2 2
    3 3 4 5 6 7 8 9 11
    4 3 4 5 6 7 8 9 11
    5 3 4 5 6 7 8 9 11
    10 9 10
    12 12 13 14 16 17 18 20
    11 3 4 5 6 7 8 9 11
    13 12 13 14 16 17 18 20
    14 12 13 14 16 17 18 20
    15 15 16 17
    16 12 13 14 15 16 17 18
    18 12 13 14 16 18 20
    7 3 4 5 6 7 8 9 11
    20 12 13 14 18 19 20
    6 3 4 5 6 7 8 11
    17 12 13 14 15 16 17
    19 19 20
    8 3 4 5 6 7 8 9 11
    9 3 4 5 7 8 9 10 11

To use this index you can use the following code:

    use Algorithm::DBSCAN;
    
    my $points_data_file =     
        'point_1 56 37
        point_2 34 46
        point_3 23 60
        point_4 10 24
        point_5 10 25
        point_6 9 24
        point_7 10 22
        point_8 11 25
        point_9 9 25
        point_10 10 27
        point_11 11 30
        point_12 10 25
        point_13 47 12
        point_14 47 12
        point_15 47 12
        point_16 44 15
        point_17 46 12
        point_18 44 14
        point_19 48 15
        point_20 52 16
        point_21 50 14';

    my $dataset = Algorithm::DBSCAN::Dataset->new();
    my @lines = split(/\n\s+/, $points_data_file);
    foreach my $line (@lines) {
        $dataset->AddPoint(new Algorithm::DBSCAN::Point(split(/\s+/, $line)));
    }

    my $dbscan = Algorithm::DBSCAN->new($dataset, 4 * 4, 2);

    $dbscan->UseRegionIndex(the filename containg the previous region index);
    $dbscan->FindClusters();
    $dbscan->PrintClustersShort();
  

=head1 SUBROUTINES/METHODS

=cut

=head2 new

The constructor takes 3 parameters:
    
    $dataset: The Algorithm::DBSCAN::Dataset dataset object
        
        Create the Dataset object:
            my $dataset = Algorithm::DBSCAN::Dataset->new();
        
        Add points (the first parameter is a point_id the other are point coordinates)
            $dataset->AddPoint(new Algorithm::DBSCAN::Point('point_1', 1, 2, 3, 4, 5);
            
    $eps: The epsilon parameter used for region density computation
        WARNING: This implementation uses the sqare distance between the points to avoid 
        a useless square root call. If you want to use the euclidian distance you need to 
        convert it to the right value yourself.
        
        For example for the previous point with 5 dimensions 
        $eps = $euclidian_distance * $euclidian_distance * $euclidian_distance * $euclidian_distance * $euclidian_distance; 
        
    $min_points: the minimal number of points in a region with a radius of $eps. $eps 
    and $min_points are the 2 parameters used to compute the denisty of a region. If 
    the number of points in a region with radius $eps is lower than $min_points the 
    point is considered as an outlier point that can't be included in any cluster.

=cut

sub new {
	my($type, $dataset, $eps, $min_points) = @_;
	
	my $self = {};
	$self->{dataset_object} = $dataset;
	$self->{dataset} = $dataset->{points};
	@{$self->{id_list}} = keys %{$dataset->{points}};
	$self->{eps} = $eps;
	$self->{min_points} = $min_points;
	$self->{current_cluster} = 1;
	$self->{use_external_region_index} = 0;
		
	bless($self, $type);

	return($self);
}

=head2 FindClusters

The main method that will run the DBSCAN algorithm on the Dataset.

=cut

sub FindClusters {
	my ($self, $starting_point_id) = @_;

	my $i = 0;
	unshift(@{$self->{id_list}}, $starting_point_id) if (defined $starting_point_id);
	foreach my $id (@{$self->{id_list}}) {
		my $point = $self->{dataset}->{$id};
		say "$i";
		$i++;
		next if ($point->{visited});
		$point->{visited} = 1;
		$self->_one_more_point_visited();
		
		my $neighborPts = $self->GetRegion($point);
#say Dumper($neighborPts);
		
		if (scalar(@$neighborPts) < $self->{min_points}) {
			$point->{cluster_id} = -1;
		}
		else {
			$self->ExpandCluster($point, $neighborPts);
		}
	}
}

=head2 ExpandCluster

This method will expand the cluster starting by the neighborhood of point $point

=cut

sub ExpandCluster {
	my ($self, $point, $neighborPts) = @_;
	
	if (scalar(@$neighborPts) < $self->{min_points}) {
		$point->{cluster_id} = -1;
	}
	else {
		$self->{current_cluster}++;

		$point->{cluster_id} = $self->{current_cluster};
	
		my %cluster_points;
		map { $cluster_points{$_}++ } @$neighborPts;
		my $cluster_expanded = 0;
		do {
			$cluster_expanded = 0;
			foreach my $id (keys %cluster_points) {
				my $p = $self->{dataset}->{$id};
				unless ($p->{visited}) {
					$p->{visited} = 1;
					$self->_one_more_point_visited();
					
					my $neighborPtsOfClusterMember = $self->GetRegion($p);
					if (scalar(@$neighborPtsOfClusterMember) >= $self->{min_points}) {
						map { $cluster_points{$_}++ } @$neighborPtsOfClusterMember;

say "Cluster [$self->{current_cluster}] has now [".scalar(keys %cluster_points)."] members, added region of point:[$p->{point_id}]";
						$cluster_expanded = 1;
						last;
					}
				}

				$p->{cluster_id} = $self->{current_cluster} unless($p->{cluster_id});
			}
		}
		while($cluster_expanded);
	}
}

=head2 GetRegion

Find all points in the dataset that are in the neighborhood of $point

=cut

sub GetRegion {
	my ($self, $point) = @_;

	my $result; 
	
	my $coordinate_id = join(',', @{$point->{coordinates}});
	if ($self->{use_external_region_index}) {
		my $fh = $self->{region_index_filehandle};
		seek($fh, $self->{region_seek_index}->{$point->{id}}, 0) or return;
		my $region_str = <$fh>;
		my @points = split(/\s+/, $region_str);
		shift(@points);
		$result = \@points;
	}
	else {
		unless ($self->{point_neighbourhood_cache}->{$coordinate_id}) {
			my @region;
			
			foreach my $region_candidate_point_id (@{$self->{id_list}}) {
				push(@region, $region_candidate_point_id) if ($self->{dataset}->{$region_candidate_point_id}->Distance($point) < $self->{eps});
			}
			$self->{point_neighbourhood_cache}->{$coordinate_id} = \@region;
		}
		
		$result = $self->{point_neighbourhood_cache}->{$coordinate_id};
	}
	
	return $result;
}

=head2 UseRegionIndex

For huge datasets a region index can be generated separately (and using multiple cores).
The index is a list of regions for each point in the dataset.

=cut

sub UseRegionIndex {
	my ($self, $region_index_filename) = @_;

	open(my $fh,  "<", $region_index_filename);
	my $offset = 0;

	while (<$fh>) {
		my @points = split(/\s+/, $_);
		$self->{region_seek_index}->{$points[0]} = $offset;
		$offset = tell($fh);
	}
		
	$self->{use_external_region_index} = 1;
	$self->{region_index_filehandle} = $fh;
}

=head2 PrintClusters

Will print the contents of the clusters

=cut

sub PrintClusters {
	my ($self, $point) = @_;

	my %clusters;
	
	foreach my $point (@{$self->{dataset}}) {
		push(@{$clusters{$point->{cluster_id}}}, $point->{point_id});
	}
	
	foreach my $cluster_id (sort keys %clusters) {
		say "CLUSTER: $cluster_id";
		foreach my $point_id (sort @{$clusters{$cluster_id}}) {
			my $min_distance = 1000000000000;
			my $closest_point_id;
			foreach my $distance_point_id (sort @{$clusters{$cluster_id}}) {
				if ($distance_point_id ne $point_id) {
					my $this_point = $self->{dataset_object}->GetPointById($point_id);
					my $distance_point = $self->{dataset_object}->GetPointById($distance_point_id);
					
					my $distance = $this_point->Distance($distance_point);
					
					if ($distance < $min_distance) {
						$min_distance = $distance;
						$closest_point_id = $distance_point_id;
					}
				}
			}
			
			say "\t$point_id : (closest point: $closest_point_id, distance: $min_distance)";
		}
	}
}

=head2 PrintClustersShort

Will print the contents of the clusters (abreviated version)

=cut

sub PrintClustersShort {
	my ($self) = @_;

	my %clusters;

	foreach my $id (keys %{$self->{dataset}}) {
	my $point = $self->{dataset}->{$id};
		push(@{$clusters{$point->{cluster_id}}}, $point->{point_id});
	}

	foreach my $cluster_id (sort keys %clusters) {
	say "CLUSTER: $cluster_id, [".scalar(@{$clusters{$cluster_id}})."] points";
	my $nb = 0;
		foreach my $point_id (sort @{$clusters{$cluster_id}}) {
			$nb++;
			say "\t$point_id";
			last if ($nb >= 100);
		}
	}
}

=head2 _one_more_point_visited

Simple method used to display progress

=cut

sub _one_more_point_visited {
	my ($self) = @_;
	
	$self->{nb_visited_points}++;
	$self->{start_time} = time() unless ($self->{start_time});
	my $eta = time() + ((time() - $self->{start_time})/$self->{nb_visited_points})*(500000);
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($eta);

	say "ETA:".sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	say "nb visited:".$self->{nb_visited_points};
}

=head1 AUTHOR

Michal TOMA, C<< <mtoma at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests on github: L<https://github.com/mtoma/Algorithm-DBSCAN>

By e-mail to C<bug-algorithm-dbscan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-DBSCAN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::DBSCAN


You can also look for information at:

=over 5

=item * Github: Issues (report bugs here)

L<https://github.com/mtoma/Algorithm-DBSCAN>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-DBSCAN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Algorithm-DBSCAN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Algorithm-DBSCAN>

=item * Search CPAN

L<http://search.cpan.org/dist/Algorithm-DBSCAN/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Michal TOMA.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Algorithm::DBSCAN

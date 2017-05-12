#!perl -T
use strict;
use warnings;
use 5.10.1;

use Test::More;
use File::Slurp;

BEGIN { chdir 't' if -d 't' }

use_ok( 'Algorithm::DBSCAN' ) || print "Bail out!\n";

sub validate_answer {
	my ($dbscan, $results_file) = @_;
	
	my %clusters;
	
	foreach my $id (keys %{$dbscan->{dataset}}) {
		my $point = $dbscan->{dataset}->{$id};
		$clusters{$point->{cluster_id}}{$point->{point_id}}++;
	}
#die Dumper(\%clusters);
	
	my @result_clusters = split(/\n/, read_file($results_file));
	
	die "The number of clusters doesn't match" if (scalar(keys %clusters) - 1 != scalar(@result_clusters));

	foreach my $result_cluster (@result_clusters) {
		$result_cluster =~ s/[<>,]//g;
		my @points = split(/\s+/, $result_cluster);
		shift(@points);
		my $cluster_found = 0;
		foreach my $cluster_id (keys %clusters) {
			if ($clusters{$cluster_id}->{$points[0]}) {
				$cluster_found++;
				my $nb_ok = 0;
				foreach my $p (@points) {
					$nb_ok++ if ($clusters{$cluster_id}->{$p})
				}
				
				die "error: [$nb_ok] != [".scalar(keys %{$clusters{$cluster_id}})."]" unless ($nb_ok == scalar(keys %{$clusters{$cluster_id}}));
			}
		}
		die "error: point [$points[0]] not found in any cluster" unless($cluster_found);
	}
	
	say "RESULT OK";
	return 1;
}

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
my $result = validate_answer($dbscan, 'test_datasets/dbscan_test_dataset_module_synopsis_result.txt');

ok( $result eq '1', 'Clustering of dataset module-synopsis-code ok' );

done_testing;
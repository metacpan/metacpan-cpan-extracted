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

my $dataset = Algorithm::DBSCAN::Dataset->new();
my @lines = split(/\n/, read_file('test_datasets/dbscan_test_dataset_1.txt'));
foreach my $line (@lines) {
	$dataset->AddPoint(new Algorithm::DBSCAN::Point(split(/\s+/, $line)));
}

my $dbscan = Algorithm::DBSCAN->new($dataset, 3.1 * 3.1, 6);

$dbscan->FindClusters();
$dbscan->PrintClustersShort();
my $result = validate_answer($dbscan, 'test_datasets/dbscan_test_dataset_1_result.txt');

ok( $result eq '1', 'Clustering of dataset 1 ok' );

done_testing;
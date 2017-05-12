use Test::Simple tests => 3;

use lib '../blib/lib','../blib/arch';

use Algorithm::ExpectationMaximization;

# Test 1 (Data Generation):

my $datafile = "__testdata.dat";
Algorithm::ExpectationMaximization->cluster_data_generator( 
                        output_datafile => $datafile,
                        total_number_of_data_points => 60 );
open IN, $datafile;
my @data_records = <IN>;
ok( @data_records == 60,  'Data generation works' );


# Test 2 (EM Clustering):

my $mask = "N111";
my $clusterer = Algorithm::ExpectationMaximization->new( 
                                         datafile => $datafile,
                                         mask     => "N111",
                                         K        => 3,
                );

$clusterer->read_data_from_file();
$clusterer->seed_the_clusters();
$clusterer->EM();
$clusterer->run_bayes_classifier();
my $clusters = $clusterer->return_disjoint_clusters();
ok( @$clusters == 3,  'Clustering works' );

# Test 3 (Data Visualization)

eval {
    my $visualization_mask = "111";
    my $pause_time = 2;
    $clusterer->visualize_clusters($visualization_mask, $pause_time);
};
print ${$@} if ($@); 

ok( !$@,  'Visualization works' );

unlink "__testdata.dat";

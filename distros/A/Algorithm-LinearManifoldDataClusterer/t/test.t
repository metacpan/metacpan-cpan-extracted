use Test::Simple tests => 3;

use lib '../blib/lib','../blib/arch';

use Algorithm::LinearManifoldDataClusterer;

# Test 1 (Data Generation):

my $datafile = "__datadump.csv";
#my $datagen = Algorithm::LinearManifoldDataClusterer::DataGenerator->new( 
my $datagen = DataGenerator->new( 
                                  output_file => $datafile,
                                  total_number_of_samples_needed => 100,
                                  number_of_clusters_on_sphere => 3,
                                );
$datagen->gen_data_and_write_to_csv();
open IN, $datafile;
my @data_records = <IN>;
ok( @data_records == 99,  'Data generation works' );


# Test 2 (Linear-Manifold Based Clustering):

my $mask = "N111";
my $clusterer = Algorithm::LinearManifoldDataClusterer->new( 
                                     datafile => $datafile,
                                     mask     => "N111",
                                     K        => 3,
                                     P        => 2,
                                     max_iterations => 1,
                                     cluster_search_multiplier => 1,
                                     terminal_output => 0,
                                     visualize_each_iteration => 0,
                                     show_hidden_in_3D_plots => 0,
                                     make_png_for_each_iteration => 0,
                );
$clusterer->get_data_from_csv();
my $clusters = $clusterer->auto_retry_clusterer();
ok( @$clusters == 3,  'Clustering works' );

# Test 3 (Data Visualization)

eval {
    my $pause_time = 1;
    $clusterer->visualize_clusters_on_sphere("", $clusters, "", $pause_time);
};
print ${$@} if ($@); 

ok( !$@,  'Visualization works' );

unlink "__datadump.csv";

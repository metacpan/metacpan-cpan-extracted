use strict;
use warnings;
use Test::More tests => 19;
use Bio::Homology::InterologWalk;

my $sourceorg = 'Mus musculus';
my $destorg = 'all';
my $url = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/"; 
my $test_data_dir = 't/testdata/';
my $ont_path   = 'scripts/Data/psi-mi.obo';


require_ok('Bio::Perl');
require_ok('Bio::EnsEMBL::Registry') or diag(
     "The Ensembl Perl API was not found.\n"
);
BEGIN { use_ok('Bio::Homology::InterologWalk') };

diag("\n");
diag("\n#######PLEASE NOTE######\n");
diag("########################\n");
diag("In order for some of the following tests to succeed, \n");
diag("remote services provided by Ensembl and Intact MUST BE ACTIVE.\n");
diag("in case of multiple test failure,\n");
diag("please check status of Ensembl services on announce\@ensembl.org\n");
diag("and status of EBI Intact PSICQUIC service on\n");
diag("www.ebi.ac.uk/Tools/webservices/psicquic/registry/registry?action=STATUS\n");
diag("########################\n");
diag("########################\n\n");


diag("Testing interfaces to remote services..Please be patient..\n\n");


my %adaptor_options = (            
            'Ensembl_Vertebrates'    =>   ['ensembl'   , 'Mus musculus'           ],
            'Ensembl_Genomes_Metazoa' =>  ['metazoa' , 'Caenorhabditis elegans' ],            
            'Ensembl_Multiple'       =>   ['all'     , 'Drosophila melanogaster'],
);



while (my ($key, $value) = each(%adaptor_options)){
     my $reg = Bio::Homology::InterologWalk::setup_ensembl_adaptor(
                                              connect_to_db    => $value -> [0],
                                              source_org       => $value -> [1],
                                              dest_org         => 'all',
                                              );
     SKIP: {
          if(!$reg){
               diag("\n\n===$key DB: WARNING===\n");
               diag("No EnsemblGenomes Metazoa DBs available for connection with the Ensembl API version installed.\n");
               diag("You WILL NOT be able to query EnsemblGenomes Metazoa data. Skipping test..\n");
               diag("======================\n\n");
               skip('An EnsemblCompara DB compatible with the Ensembl API you have installed could not be found', 2);
          }
          ok( defined $reg, "setup_ensembl_adaptor() ($key DB) - return value appears to be correct." );
          ok( $reg->isa('Bio::EnsEMBL::Registry'), "setup_ensembl_adaptor() ($key DB) - connection successful." );
     }
     $reg->clear() if($reg);
}


my $registry = Bio::Homology::InterologWalk::setup_ensembl_adaptor(
                                                   connect_to_db    => 'ensembl',
                                                   source_org       => 'Mus musculus',
                                                   dest_org         => 'all',
                                                   );
                                                   
my $in_path = $test_data_dir . "mmus.txt";
my $out_path = $test_data_dir . "mmus.test1";
my $rc_1 = Bio::Homology::InterologWalk::get_direct_interactions(
                                                   registry         => $registry,
                                                   source_org       => $sourceorg,
                                                   input_path       => $in_path,
                                                   output_path      => $out_path,
                                                   url              => $url,
                                                   );
ok( defined $rc_1,            "get_direct_interactions() return value appears to be correct" );


$out_path = $test_data_dir . "mmus.test2";
my $rc_2 = Bio::Homology::InterologWalk::get_forward_orthologies(
                                                 registry        => $registry,
                                                 ensembl_db      => 'ensembl',
                                                 input_path      => $in_path,
                                                 output_path     => $out_path,
                                                 source_org      => $sourceorg,
                                                 dest_org        => $destorg,
                                                 hq_only         => 1
                                              );
ok( defined $rc_2,            "get_forward_orthologies() return value appears to be correct" );

$in_path = $out_path;
$out_path = $test_data_dir . "mmus.test3";
my $rc_3 = Bio::Homology::InterologWalk::get_interactions(
                                          input_path      => $in_path,
                                          output_path     => $out_path,
                                          url             => $url,
                                          );
ok( defined $rc_3,            "get_interactions() return value appears to be correct" );

$in_path = $out_path;
$out_path = $test_data_dir . "mmus.test4";
my $rc_4 = Bio::Homology::InterologWalk::get_backward_orthologies(
                                                  registry      => $registry,
                                                  ensembl_db    => 'ensembl',
                                                  input_path    => $in_path,
                                                  output_path   => $out_path,
                                                  source_org    => $sourceorg,
                                                  hq_only       => 1
                                                  );
ok( defined $rc_4,            "get_backward_orthologies() return value appears to be correct" );


$in_path = $out_path;
$out_path = $test_data_dir . "mmus.test5";
my $rc_5 = Bio::Homology::InterologWalk::do_counts(
                                   input_path  => $in_path,
                                   output_path => $out_path
                                   );
                                   
ok( defined $rc_5,            "do_counts() return value appears to be correct" );


my $onto_graph = Bio::Homology::InterologWalk::Scores::parse_ontology($ont_path);
ok( defined $onto_graph,            "parse_ontology() returns non null value." );
ok( $onto_graph->isa('GO::Model::Graph'), "parse_ontology() returns correct object" );


$in_path = $out_path;
$out_path = $test_data_dir . "mmus.test6";
my $rc_6 = Bio::Homology::InterologWalk::Scores::compute_prioritisation_index(
                                        input_path        => $in_path,
                                        output_path       => $out_path,
                                        term_graph        => $onto_graph,
                                        #test
                                        meanscore_em      => 1, 
                                        meanscore_it      => 1,
                                        meanscore_dm      => 1,
                                        meanscore_me_dm   => 1,
                                        meanscore_me_taxa => 1
);

ok( defined $rc_6,            "compute_confidence_score() return value appears to be correct" );

my $rc_7 = Bio::Homology::InterologWalk::Networks::do_network(
                                             registry    => $registry,
                                             data_file   => "mmus.test6", 
                                             data_dir    => $test_data_dir,
                                             source_org  => $sourceorg
                                             );
                                              
ok( defined $rc_7,            "do_network() return value appears to be correct" );

my $rc_8 = Bio::Homology::InterologWalk::Networks::do_attributes(
                                                registry    => $registry,
                                                data_file   => "mmus.test6",
                                                start_file  => "mmus.txt",
                                                data_dir    => $test_data_dir,
                                                source_org  => $sourceorg
                                                );
                                                 
ok( defined $rc_8,            "do_attributes()  return value appears to be correct" );

#done_testing();


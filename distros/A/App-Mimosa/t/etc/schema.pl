use warnings;
use strict;

return {
  'schema_class' => 'App::Mimosa::Schema::BCS',
  'connect_info' => App::Mimosa::Test::app->model('BCS')->connect_info,
  'resultsets'   => [],

  'fixture_sets' => {
        # basic sequence set test data
        'basic_ss' => {
            'Mimosa::SequenceSet' => [
                [qw/ mimosa_sequence_set_id shortname title description alphabet source_spec lookup_spec info_url update_interval is_public /],
                [ 1, 'blastdb_test.nucleotide.seq', 'test db', 'test db', 'nucleotide', '', '', ,'', 30, 1    ],
                [ 2, 'solanum_foobarium_dna.seq', 'Solanum foobarium DNA sequences', 'DNA sequences for S. foobarium', 'nucleotide', '', '', ,'', 30, 0    ],
                [ 3, 'Blargopod_foobarium_protein.seq', 'Blargopod foobarium protein sequences', 'Protein sequences for B. foobarium', 'protein', '', '', ,'', 60, 1    ],
                [ 4, 'trollus_trollus.seq', 'Common Wild Troll species DNA sequence', 'DNA sequences for T. trollus', 'nucleotide', '', '', ,'', 60, 1    ],
              ],
        },
        'basic_ss_organism' => {
            'Mimosa::SequenceSetOrganism' => [
                [qw/ mimosa_sequence_set_id organism_id /],
                [ 3, 1, ],
            ],
        },
        'basic_organism' => {
             'Organism' => [
                [qw/organism_id genus species common_name/],
                [1, "Blargopod", "Blargopod foobarium", "blargwart"],
             ],
        },
        # basic job test data
        'basic_job' => {
            'Mimosa::Job' => [
                [qw/mimosa_job_id sha1 user start_time end_time/],
                [ 1, 'deadbeef', 'blarg', '1010102011', undef, ],
            ],
        },
  },
};

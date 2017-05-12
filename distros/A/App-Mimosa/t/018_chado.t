use Test::Most tests => 5;
use strict;
use warnings;
use autodie;
use Carp::Always;
use Data::Dumper;

use lib 't/lib';
use App::Mimosa::Test;

use Bio::Chado::Schema::Test;
use App::Mimosa::Schema::BCS;

my $bcs_db;

BEGIN {
    $bcs_db = "t/var/BCS.db";

    diag("Removing $bcs_db");
    unlink $bcs_db if -e $bcs_db;

}

my $bcs_schema = Bio::Chado::Schema::Test->init_schema(
    deploy            => 1,
    populate          => 1,
);

isa_ok($bcs_schema, 'Bio::Chado::Schema');


# Now deploy the mimosa schema

my $mimosa_schema = App::Mimosa::Schema::BCS->connect("dbi:SQLite:dbname=$bcs_db");

isa_ok($mimosa_schema, 'App::Mimosa::Schema::BCS');
lives_ok { $mimosa_schema->deploy({
    sources => [
        'Mimosa::Job',
        'Mimosa::SequenceSet',
        'Mimosa::SequenceSetOrganism',
    ]
    }
)
} 'deploying mimosa schema to a BCS schema works';

lives_ok { $mimosa_schema->populate('Mimosa::SequenceSet', [
    [qw/shortname title description alphabet source_spec lookup_spec info_url update_interval is_public/],
    ['acidiphilium_cryptum_protein', 'A. cryptum hypothetical protein', 'A. cryptum hypothetical protein in CP000694', 'protein', 'ftp://ftp.ncbi.nlm.nih.gov/genbank/genomes/Bacteria/Acidiphilium_cryptum_JF-5_uid15753/CP000694.faa', '', ,'', 10, 0    ],
    ]);
} 'populating a mimosa table in a chado schema works';

my $rs = $mimosa_schema->resultset('Mimosa::SequenceSet');

is_deeply( [ sort map { $_->mimosa_sequence_set_id } ($rs->all) ], [ 1 ], 'we get back one mimosa sequence with the correct id');

END {
    $bcs_db = "t/var/BCS.db";

    diag("Removing $bcs_db");
    unlink $bcs_db if -e $bcs_db;
}

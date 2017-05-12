use Test::Most tests => 18;
use strict;
use warnings;

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;
use Test::JSON;
use File::Copy;
use File::Spec::Functions;

fixtures_ok 'basic_ss';
fixtures_ok 'basic_ss_organism';
fixtures_ok 'basic_organism';
action_ok   '/api/grid/json.json';

my $seq_data_dir = app->config->{sequence_data_dir};
diag "Sequence data dir is $seq_data_dir";
my $extraseq     = catfile($seq_data_dir, 'extra', 'extraomgbbq.seq');
my $extraseq2    = catfile($seq_data_dir, 'extra', 'cyclops.fasta');
my $extraseq3    = catfile($seq_data_dir, 'extra', 'cyclops.fasta.nsi');
my $gff          = catfile($seq_data_dir, 'extra', 'foo.gff3');

BEGIN {
    # Remove these in case something left them behind
    unlink( catfile($seq_data_dir, 'extraomgbbq.seq') );
    unlink( catfile($seq_data_dir, 'cyclops.fasta') );
    unlink( catfile($seq_data_dir, 'cyclops.fasta.nsi') );
    unlink( catfile($seq_data_dir, 'foo.gff3') );
}

{
my $r    = request('/api/grid/json.json');
my $json = $r->content;

is_valid_json( $json, 'it returns valid JSON') or diag $json;

# 3 = length("{ }")
cmp_ok(length $json,'>', 3, 'got non-empty-looking json');

like($json, qr/mimosa_sequence_set_id/, 'mimosa_sequence_set_id appears in JSON');
like($json, qr/description/, 'description appears in JSON');
like($json, qr/blargwart/, 'blargwart common_name appears');

# This test depends on the data in t/etc/schema.pl and which data the JSON controller returns
is_json($json, <<JSON, 'got the JSON we expected');
{"rows":[{"mimosa_sequence_set_id":1,"name":"blastdb_test.nucleotide.seq","description":"test db","alphabet":"nucleotide"},{"mimosa_sequence_set_id":2,"name":"solanum_foobarium_dna.seq","description":"DNA sequences for S. foobarium","alphabet":"nucleotide"},{"mimosa_sequence_set_id":3,"name":"Blargopod foobarium (blargwart)","description":"Protein sequences for B. foobarium","alphabet":"protein"},{"mimosa_sequence_set_id":4,"name":"trollus_trollus.seq","description":"DNA sequences for T. trollus","alphabet":"nucleotide"},{"mimosa_sequence_set_id":5,"name":"archaeopteryx_protein.seq","description":null,"alphabet":"nucleotide"}],"total":4}
JSON
#diag $json;
}

# Test autodection
{

# grab one copy of the json
my $r    = request('/api/grid/json.json');
my $json = $r->content;

# now add a new seq file to the sequence directory
diag "copying $extraseq to $seq_data_dir";
copy($extraseq, $seq_data_dir);

# ask for the grid json again
# foo=bar is to defeat caching, if it exists
my $r2    = request('/api/grid/json.json?foo=bar');
my $json2 = $r2->content;
cmp_ok (length($json2),'>', length($json), 'autodetection: new json is bigger than original');
like($json2, qr/"extraomgbbq\.seq"/, 'autodetection: the correct shortname appears in the new json');

# now add a new fasta file to the sequence directory
diag "copying $extraseq2 to $seq_data_dir";
copy($extraseq2, $seq_data_dir);

# ask for the grid json again
my $r3    = request('/api/grid/json.json?blarg=poop');
my $json3 = $r3->content;
cmp_ok (length($json3),'>', length($json2), 'autodetection: new json is bigger than original');
like($json3, qr/"cyclops\.fasta"/, 'autodetection: the correct shortname appears in the new json');

copy($extraseq3, $seq_data_dir);

# ask for the grid json yet again, make sure it did not autodetect the *.nsi file
my $r4    = request("/api/grid/json.json?time=" . localtime() );
my $json4 = $r4->content;
cmp_ok (length($json4),'==', length($json3), 'autodetection: new json is same size as previous');
unlike($json4, qr/"cyclops\.fasta\.nsi"/, 'autodetection: cyclops.fasta.nsi does not appear');

# now add a gff file, which should not be autodetected
diag "copying $gff to $seq_data_dir";
copy($gff, $seq_data_dir);

my $r5    = request('/api/grid/json.json?f=g');
my $json5 = $r5->content;
cmp_ok (length($json5),'==', length($json3), 'autodetection: do not autodetect gff files');
unlike($json3, qr/"foo.gff3"/, 'autodetection: no foo.gff3 in json');

}


END {
    unlink( catfile($seq_data_dir, 'extraomgbbq.seq') );
    unlink( catfile($seq_data_dir, 'cyclops.fasta') );
    unlink( catfile($seq_data_dir, 'cyclops.fasta.nsi') );
    unlink( catfile($seq_data_dir, 'foo.gff3') );
}

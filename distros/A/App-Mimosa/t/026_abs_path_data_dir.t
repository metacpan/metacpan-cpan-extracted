use Test::Most tests => 2;
use strict;
use warnings;

BEGIN {
    $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing_abs_path_data_dir';
}

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;
use Test::JSON;
use HTTP::Request::Common;
use File::Spec::Functions;

my $r    = request('/api/grid/json.json?blarg=poop');
my $json = $r->content;
is_valid_json( $json, 'it returns valid JSON') or diag $json;
is_json($json, <<JSON, 'got the JSON we expected');
{"rows":[{"mimosa_sequence_set_id":1,"name":"chupacabra_dna.seq","description":null,"alphabet":"nucleotide"}],"total":0}
JSON

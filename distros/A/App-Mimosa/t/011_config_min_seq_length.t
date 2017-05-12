use Test::Most tests => 3;
use strict;
use warnings;

BEGIN {
    $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing2';

}

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;

use File::Slurp qw/slurp/;
use HTTP::Request::Common;
use File::Spec::Functions;

fixtures_ok 'basic_ss';

my $response = request POST '/submit', [
                program                 => 'blastn',
                sequence                => ">fasta title\nabitsmall",
                maxhits                 => 100,
                matrix                  => 'BLOSUM62',
                evalue                  => 0.1,
                mimosa_sequence_set_ids => 42,
];
is($response->code, 400, "/submit with too small input sequence returns 400");
like($response->content,qr/Sequence input too short\. Must have a length of at least 17/, "error explains the min length");

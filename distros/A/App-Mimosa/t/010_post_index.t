use Test::Most tests => 3;
use strict;
use warnings;

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;

use File::Slurp qw/slurp/;
use HTTP::Request::Common;
use File::Spec::Functions;
use HTML::Entities;

fixtures_ok 'basic_ss';

my $seq = slurp(catfile(qw/t data blastdb_test.nucleotide.seq/));
my $eseq = encode_entities($seq);
{
    my $response = request POST '/', [
                    sequence_input         => $seq,
    ];
    is($response->code, 200, '/submit returns 200');
    like($response->content, qr/\Q$eseq\E/ms, 'the sequence appears on the index page when POSTed');
}

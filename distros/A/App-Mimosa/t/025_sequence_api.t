use Test::Most tests => 17;
use strict;
use warnings;

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;
use HTTP::Request::Common;
use File::Spec::Functions;
use File::Slurp qw/slurp/;
use Test::JSON;

fixtures_ok 'basic_ss';

# we need to generate a report first, so our db gets indexed

my $seq = slurp(catfile(qw/t data blastdb_test.nucleotide.seq/));
my $response = request POST '/submit', [
                program                => 'blastn',
                sequence_input_file    => '',
                sequence               => $seq,
                maxhits                => 100,
                matrix                 => 'BLOSUM62',
                evalue                 => 0.1,
                mimosa_sequence_set_ids=> 1,
                alphabet               => 'nucleotide',
];


sub basic_test {
    my $url = shift;
    my $seq = 'AATTATTTTATTTGGTTTATTGTAGTCCTTAAGACAGTTAGGATACCTGAGTTATGTATC';

    my $r = request $url;
    is($r->code, 200, "200 GET $url" );
    ok($r->content !~ m/Bio::BLAST::Database::Seq/);
    like($r->content, qr/^>LE_HBa0001A15_T7_30 Chromat_file:Le-HBa001_A15-T7\.ab1 SGN_GSS_ID:30 \(vector and quality trimmed\)/, 'got the correct desc line back');
    like($r->content, qr/$seq/, 'looks like the same FASTA');

    is(length($r->content),596, 'got non-zero content length') or diag $r->content;
}
{
    basic_test('/api/sequence/id/1/LE_HBa0001A15_T7_30.txt');
    basic_test('/api/sequence/id/1/LE_HBa0001A15_T7_30.fasta');
    basic_test('/api/sequence/id/1/LE_HBa0001A15_T7_30');

    # TODO
    # basic_test('/api/sequence/1/LE_HBa0001A15_T7_30.json');
}
{
    my $r = request '/api/sequence/id/99/blarg.txt';
    is($r->code, 400, 'asking for the sequence of a non-existent mimosa_sequence_set_id borks' );
}


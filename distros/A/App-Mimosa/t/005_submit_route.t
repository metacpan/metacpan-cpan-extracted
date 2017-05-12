use strict;
use warnings;
use Test::Most tests => 25;

use lib 't/lib';
use App::Mimosa::Test;
use App::Mimosa::Util qw/clean_up_indices/;
use Test::DBIx::Class;

use File::Slurp qw/slurp/;
use HTTP::Request::Common;
use File::Spec::Functions;
#use Carp::Always;

fixtures_ok 'basic_ss';

{
    my $seq = slurp(catfile(qw/t data blastdb_test.nucleotide.seq/));
    my $response = request POST '/submit', [
                    program                => 'tblastx',
                    sequence_input_file    => '',
                    sequence               => $seq,
                    maxhits                => 100,
                    matrix                 => 'BLOSUM62',
                    evalue                 => 0.1,
                    mimosa_sequence_set_ids=> 1,
                    alphabet               => 'nucleotide',
    ];
    is($response->code, 200, '/submit returns 200');
    like($response->content,qr!/api/report/raw/\d+!, 'download raw report link');
    like($response->content,qr!/api/report/html/\d+!, 'download raw report link');
}

{
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
    is($response->code, 200, '/submit returns 200');
    like($response->content,qr!/api/report/raw/\d+!, 'download raw report link');
    like($response->content,qr!/api/report/html/\d+!, 'download raw report link');
}
{
    my $seq = slurp(catfile(qw/t data blastdb_test.nucleotide.seq/));
    my $response = request POST '/submit', [
                    program                => 'blastn',
                    sequence               => $seq,
                    maxhits                => 100,
                    matrix                 => 'BLOSUM62',
                    evalue                 => 0.1,
                    mimosa_sequence_set_ids=> 1,
                    alphabet               => 'nucleotide',
                    alignment_view         => 8, # XML
    ];
    is($response->code, 200, '/submit returns 200');
    # TODO: verify the raw blast report is valid XML
}
{
    my $response = request POST '/submit', [
                    program                => 'blastn',
                    sequence               => "small",
                    maxhits                => 100,
                    matrix                 => 'BLOSUM62',
                    evalue                 => 0.1,
                    mimosa_sequence_set_ids => 42,
                    alphabet               => 'nucleotide',
    ];
    is($response->code, 400, "/submit with too small input sequence returns 400");
    like($response->content,qr/Sequence input too short\. Must have a length of at least 6/, "error explains the min length");
}

{
    my $seq = slurp(catfile(qw/t data blastdb_test.nucleotide.seq/));
    my $f = sub {
        return request POST '/submit', [
                    program  => 'blastn',
                    sequence => $seq,
                    maxhits  => 100,
                    alphabet => 'nucleotide',
                    matrix   => 'BLOSUM62',
                    evalue   => 0.1,
       ];
    };
    my $res = $f->();
    is($res->code, 400, '/submit returns 400 without a mimosa_sequence_set_ids');
}

{
    my $seq = <<SEQ;
>foo
ATATATATATAT
SEQ
    my $f = sub {
        return request POST '/submit', [
                    program                => 'blastn',
                    sequence               => $seq,
                    maxhits                => 100,
                    alphabet               => 'nucleotide',
                    matrix                 => 'BLOSUM62',
                    evalue                 => 0.1,
                    mimosa_sequence_set_ids => 1,
       ];
    };
    my $res = $f->();
    is($res->code,400,'/submit gives an ungapped error');
    like($res->content,qr/Could not calculate ungapped Karlin-Altschul parameters/);
    ok($res->content !~ qr/catalyst_detach/, "We don't get the error Invalid input: catalyst_detach");
}


{
    my $sequence = <<SEQ;
>Solanum foobarium FAKE DNA 2
TGCGAGATGCAGAAACTAAAATAGTTCCAATTCCAATATCTCACAAAGCCACTACCCCTC
SEQ
    my $r = request POST '/submit', Content_Type => 'multipart/form-data', Content => [
            program                 => 'blastn',
            mimosa_sequence_set_ids => 1,
            matrix                  => 'BLOSUM62',
            maxhits                 => 42,
            evalue                  => 0.1,
            alphabet                => 'nucleotide',
            sequence                => '',
            sequence_input_file => [
                undef, 'test.fasta',
                Content_Type => 'application/octet-stream',
                Content      => $sequence,
            ],
    ];
    is($r->code, 200, 'Posting a sequence file gives a 200') or diag $r->content;
    like($r->content, qr!/api/report/!, 'page contains api links');
}

{
    my $sequence = <<SEQ;
>Solanum foobarium FAKE DNA 2
TGCGAGATGCAGAAACTAAAATAGTTCCAATTCCAATATCTCACAAAGCCACTACCCCTC
SEQ
    my $r = request POST '/submit', Content_Type => 'multipart/form-data', Content => [
            program                 => 'blastn',
            mimosa_sequence_set_ids => 1,
            matrix                  => 'BLOSUM62',
            maxhits                 => 42,
            evalue                  => 0.1,
            alphabet                => 'nucleotide',
            alignment_view			=> 8, # tabular
            sequence                => '',
            sequence_input_file => [
                undef, 'test.fasta',
                Content_Type => 'application/octet-stream',
                Content      => $sequence,
            ],
    ];
    is($r->code, 200, 'Posting a sequence file and asking for a tabular report gives a 200') or diag $r->content;
    ok($r->content !~ qr!No hits found!, 'Report has hits');
}

{
    my $sequence = <<SEQ;
>Solanum foobarium FAKE DNA 2
TGCGAGATGCAGAAACTAAAATAGTTCCAATTCCAATATCTCACAAAGCCACTACCCCTC
SEQ
    my $r = request POST '/submit', Content_Type => 'multipart/form-data', Content => [
            program                 => 'blastn',
            mimosa_sequence_set_ids => 1,
            matrix                  => 'BLOSUM62',
            maxhits                 => 42,
            evalue                  => 0.1,
            alphabet                => 'nucleotide',
            alignment_view			=> 9, # tabular with comments
            sequence                => '',
            sequence_input_file => [
                undef, 'test.fasta',
                Content_Type => 'application/octet-stream',
                Content      => $sequence,
            ],
    ];
    is($r->code, 200, 'Posting a sequence file and asking for a tabular+comments report gives a 200') or diag $r->content;
    ok($r->content !~ qr!No hits found!, 'Report has hits');
}
{
    my $sequence = <<SEQ;
>Solanum foobarium FAKE DNA 2
TGCGAGATGCAGAAACTAAAATAGTTCCAATTCCAATATCTCACAAAGCCACTACCCCTC
SEQ
    my $r = request POST '/submit', Content_Type => 'multipart/form-data', Content => [
            program                 => 'blastn',
            mimosa_sequence_set_ids => 1,
            matrix                  => 'BLOSUM62',
            maxhits                 => 42,
            evalue                  => 0.1,
            alphabet                => 'nucleotide',
            alignment_view			=> 7, # xml
            sequence                => '',
            sequence_input_file => [
                undef, 'test.fasta',
                Content_Type => 'application/octet-stream',
                Content      => $sequence,
            ],
    ];
    is($r->code, 200, 'Posting a sequence file and asking for a XML report gives a 200') or diag $r->content;
    ok($r->content !~ qr!No hits found!, 'Report has hits');
}

{
    my $sequence = <<SEQ;
>Solanum foobarium FAKE DNA 2
TGCGAGATGCAGAAACTAAAATAGTTCCAATTCCAATATCTCACAAAGCCACTACCCCTC
SEQ
    my $r = request POST '/submit',
    Content_Type => 'application/x-www-form-urlencoded',
    Content => [
            program                 => 'blastn',
            mimosa_sequence_set_ids => 1,
            matrix                  => 'BLOSUM62',
            maxhits                 => 42,
            evalue                  => 0.1,
            alphabet                => 'nucleotide',
            sequence                => '',
            sequence_input_file => [
                undef, 'test.fasta',
                Content_Type => 'application/octet-stream',
                Content      => $sequence,
            ],
    ];
    is($r->code, 400, 'Posting a sequence file with incorrect content type borks') or diag $r->content;
}
{
    my $sequence = <<SEQ;
>Solanum foobarium FAKE DNA 2
TGCGAGATGCAGAAACTAAAATAGTTCCAATTCCAATATCTCACAAAGCCACTACCCCTC
SEQ
    my $r = request POST '/submit', Content_Type => 'multipart/form-data', Content => [
            program                 => 'blastn',
            mimosa_sequence_set_ids => 1,
            matrix                  => 'BLOSUM62',
            maxhits                 => 42,
            evalue                  => 0.1,
            alphabet                => 'nucleotide',
            alignment_view			=> 10, # ASN text
            sequence                => '',
            sequence_input_file => [
                undef, 'test.fasta',
                Content_Type => 'application/octet-stream',
                Content      => $sequence,
            ],
    ];
    is($r->code, 200, 'Posting a sequence file and asking for an ASN(text) report gives a 200') or diag $r->content;
    ok($r->content !~ qr!No hits found!, 'Report has hits') or diag $r->content;
}

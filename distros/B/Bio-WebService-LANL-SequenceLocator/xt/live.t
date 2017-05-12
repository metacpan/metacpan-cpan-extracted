use strict;
use warnings FATAL => 'all';
use 5.018;

use Test::More;
use Test::Deep;
use Test::LongString;
use Path::Tiny;
use JSON qw< decode_json >;
use FindBin '$RealBin';
use HTTP::Request::Common;

use_ok('Bio::WebService::LANL::SequenceLocator');
use_ok('Bio::WebService::LANL::SequenceLocator::Server');

my @tests = (
    {   name        => "mixed bases",
        sequences   => ['SLYNTVAVLYYVHQR', 'TCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG'],
        json        => path("$RealBin/data/mixed-bases.json"),
        csv         => path("$RealBin/data/mixed-bases.csv"),
    },
    {   name        => "amino acids",
        sequences   => ['MGGDMKDNW'],
        args        => { base => 'aa' },
        json        => path("$RealBin/data/amino-acids.json"),
        csv         => path("$RealBin/data/amino-acids.csv"),
    },
    {   name        => "nucleotides",
        sequences   => ['agcaatcagatggtcagccaaaattgccctatagtgcagaacatccaggggcaagtggtacatcaggccatatcacctagaactttaaatgca'],
        args        => { base => 'nuc' },
        json        => path("$RealBin/data/nucleotides.json"),
        csv         => path("$RealBin/data/nucleotides.csv"),
    },
);

for my $test (@tests) {
    my $expected = decode_json($test->{json}->slurp);
    cmp_deeply from_native($test), $expected, "$test->{name}: native";
    cmp_deeply from_web($test),    $expected, "$test->{name}: web";

    cmp_deeply from_web($test, as_fasta => 1), $expected, "$test->{name}: fasta";

    if ($test->{csv}) {
        my $csv = $test->{csv}->slurp_utf8;
        local $test->{args}{format} = 'csv';
        is_string from_web($test),                $csv, "$test->{name}: csv";
        is_string from_web($test, as_fasta => 1), $csv, "$test->{name}: csv fasta";
    }
}

sub from_native {
    my $test = shift;
    state $locator = Bio::WebService::LANL::SequenceLocator->new(
        agent_string => 'automated testing'
    );
    return scalar $locator->find($test->{sequences}, %{$test->{args} || {}});
}

sub from_web {
    my $test = shift;
    my %opts = @_;
    my @data;

    if ($opts{as_fasta}) {
        my $i = 1;
        @data = (
            Content_Type => 'form-data',
            Content      => [
                fasta    => [
                    undef,
                    "test.fa",
                    Content => join "\n",
                        map { sprintf ">seq%d\n%s\n", $i++, $_ }
                           @{ $test->{sequences} }
                ],
                %{$test->{args} || {}},
            ],
        );
    } else {
        @data = [
            sequence => $test->{sequences},
            %{$test->{args} || {}},
        ];
    }
    my $response = request( POST '/within/hiv' => @data );
    my $results  = $response->decoded_content;
    if ($response->content_type =~ /^application\/json/) {
        $results = decode_json($results);
    }
    return $results;
}

sub request {
    state $app = Bio::WebService::LANL::SequenceLocator::Server->new(
        contact => 'automated testing'
    );
    my $response = $app->run_test_request(@_);
    note "Request failed: ", $response->as_string, "\n"
        unless $response and $response->is_success;
    return $response;
}

done_testing;

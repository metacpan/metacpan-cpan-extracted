package Bencher::Scenario::Serializers;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.010001;
use strict;
use utf8;
use warnings;

our $scenario = {
    summary => 'Benchmark Perl data serialization modules',
    participants => [
        {
            tags => ['json', 'serialize'],
            module => 'JSON::PP',
            function => 'encode_json',
            code_template => 'state $json = JSON::PP->new->allow_nonref; $json->encode(<data>)',
        },
        {
            tags => ['json', 'deserialize'],
            module => 'JSON::PP',
            function => 'decode_json',
            code_template => 'state $json = JSON::PP->new->allow_nonref; $json->decode(<data>)',
        },
        {
            tags => ['json', 'serialize'],
            module => 'JSON::Tiny',
            function => 'encode_json',
            code_template => 'JSON::Tiny::encode_json(<data>)',
        },
        {
            tags => ['json', 'deserialize'],
            module => 'JSON::Tiny',
            function => 'decode_json',
            code_template => 'JSON::Tiny::decode_json(<data>)',
        },
        {
            tags => ['json', 'serialize'],
            module => 'JSON::XS',
            function => 'encode_json',
            code_template => 'state $json = JSON::XS->new->allow_nonref; $json->encode(<data>)',
        },
        {
            tags => ['json', 'deserialize'],
            module => 'JSON::XS',
            function => 'decode_json',
            code_template => 'state $json = JSON::XS->new->allow_nonref; $json->decode(<data>)',
        },
        {
            tags => ['json', 'serialize'],
            module => 'Cpanel::JSON::XS',
            function => 'encode_json',
            code_template => 'state $json = Cpanel::JSON::XS->new->allow_nonref; $json->encode(<data>)',
        },
        {
            tags => ['json', 'deserialize'],
            module => 'Cpanel::JSON::XS',
            function => 'decode_json',
            code_template => 'state $json = Cpanel::JSON::XS->new->allow_nonref; $json->decode(<data>)',
        },
        {
            tags => ['json', 'serialize'],
            module => 'JSON::MaybeXS',
            function => 'encode_json',
            code_template => 'state $json = JSON::MaybeXS->new(allow_nonref=>1); $json->encode(<data>)',
        },
        {
            tags => ['json', 'deserialize'],
            module => 'JSON::MaybeXS',
            function => 'decode_json',
            code_template => 'state $json = JSON::MaybeXS->new(allow_nonref=>1); $json->decode(<data>)',
        },
        {
            tags => ['json', 'deserialize'],
            fcall_template => 'JSON::Decode::Regexp::from_json(<data>)',
        },
        {
            tags => ['json', 'deserialize'],
            fcall_template => 'PERLANCAR::JSON::Match::match_json(<data>)',
            include_by_default => 0,
        },
        {
            tags => ['json', 'deserialize', 'cant_handle_scalar'],
            fcall_template => 'JSON::Decode::Marpa::from_json(<data>)',
        },
        {
            name => 'Pegex::JSON',
            tags => ['json', 'deserialize'],
            module => 'Pegex::JSON',
            code_template => 'state $obj = Pegex::JSON->new; $obj->load(<data>);',
        },
        {
            tags => ['json', 'serialize'],
            fcall_template => 'JSON::Create::create_json(<data>)',
        },
        {
            tags => ['json', 'deserialize'],
            fcall_template => 'JSON::Parse::parse_json(<data>)',
        },

        {
            tags => ['yaml', 'serialize'],
            fcall_template => 'YAML::Old::Dump(<data>)',
        },
        {
            tags => ['yaml', 'deserialize'],
            fcall_template => 'YAML::Old::Load(<data>)',
        },
        {
            tags => ['yaml', 'serialize'],
            fcall_template => 'YAML::Syck::Dump(<data>)',
        },
        {
            tags => ['yaml', 'deserialize'],
            fcall_template => 'YAML::Syck::Load(<data>)',
        },
        {
            tags => ['yaml', 'serialize'],
            fcall_template => 'YAML::XS::Dump(<data>)',
        },
        {
            tags => ['yaml', 'deserialize'],
            fcall_template => 'YAML::XS::Load(<data>)',
        },

        {
            tags => ['binary', 'serialize', 'cant_handle_scalar'],
            fcall_template => 'Storable::freeze(<data>)',
        },
        {
            tags => ['binary', 'deserialize', 'cant_handle_scalar'],
            fcall_template => 'Storable::thaw(<data>)',
        },

        {
            tags => ['binary', 'serialize'],
            fcall_template => 'Sereal::encode_sereal(<data>)',
        },
        {
            tags => ['binary', 'deserialize'],
            fcall_template => 'Sereal::decode_sereal(<data>)',
        },

        {
            name => 'Data::MessagePack::pack',
            tags => ['binary', 'serialize'],
            module => 'Data::MessagePack',
            function => 'pack',
            code_template => 'state $obj = Data::MessagePack->new; $obj->pack(<data>)',
        },
        {
            name => 'Data::MessagePack::unpack',
            tags => ['binary', 'deserialize'],
            module => 'Data::MessagePack',
            function => 'unpack',
            code_template => 'state $obj = Data::MessagePack->new; $obj->unpack(<data>)',
        },
    ],

    # XXX: add more datasets (larger data, etc)
    datasets => [
        {
            name => 'undef',
            summary => 'undef',
            args => {data=>undef},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
            exclude_participant_tags => ['cant_handle_scalar'],
        },
        {
            name => 'num',
            summary => 'A single number (-1.23)',
            args => {data=>-1.23},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
            exclude_participant_tags => ['cant_handle_scalar'],
        },
        {
            name => 'str1k',
            summary => 'A non-Unicode string 1024 characters/bytes long',
            args => {data=>'a' x 1024},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
            exclude_participant_tags => ['cant_handle_scalar'],
        },
        {
            name => 'str1k',
            summary => 'A Unicode string 1024 characters (3072-bytes) long',
            args => {data=>'我爱你爱你一辈子' x 128},
            tags => ['serialize', 'unicode'],
            include_participant_tags => ['serialize'],
            exclude_participant_tags => ['cant_handle_scalar'],
        },

        {
            name => 'array_int_10',
            summary => 'A 10-element array containing ints',
            args => {data=>[1..10]},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
        },
        {
            name => 'array_int_100',
            summary => 'A 100-element array containing ints',
            args => {data=>[1..100]},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
        },
        {
            name => 'array_int_1000',
            summary => 'A 1000-element array containing ints',
            args => {data=>[1..1000]},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
        },
        {
            name => 'array_str1k_10',
            summary => 'A 10-element array containing 1024-characters/bytes-long non-Unicode strings',
            args => {data=>[('a' x 1024) x 10]},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
        },
        {
            name => 'array_ustr1k_10',
            summary => 'A 10-element array containing 1024-characters-long (3072-bytes long) Unicode strings',
            args => {data=>[('我爱你爱你一辈子' x 128) x 10]},
            tags => ['serialize', 'json'],
            include_participant_tags => ['serialize'],
        },

        {
            name => 'hash_int_10',
            summary => 'A 10-key hash {1=>0, ..., 10=>0}',
            args => {data=>{map {$_=>0} 1..10}},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
        },
        {
            name => 'hash_int_100',
            summary => 'A 100-key hash {1=>0, ..., 100=>0}',
            args => {data=>{map {$_=>0} 1..100}},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
        },
        {
            name => 'hash_int_1000',
            summary => 'A 1000-key hash {1=>0, ..., 1000=>0}',
            args => {data=>{map {$_=>0} 1..1000}},
            tags => ['serialize'],
            include_participant_tags => ['serialize'],
        },

        {
            name => 'json:null',
            summary => 'null',
            args => {data=>'null'},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
            exclude_participant_tags => ['cant_handle_scalar'],
        },
        {
            name => 'json:num',
            summary => 'A single number (-1.23)',
            args => {data=>-1.23},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
            exclude_participant_tags => ['cant_handle_scalar'],
        },
        {
            name => 'json:str1k',
            summary => 'A non-Unicode (ASCII) string 1024-characters/bytes long',
            args => {data=>'"' . ('a' x 1024) . '"'},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
            exclude_participant_tags => ['cant_handle_scalar'],
        },

        {
            name => 'json:array_int_10',
            summary => 'A 10-element array containing ints',
            args => {data=>'['.join(',',1..10).']'},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
        },
        {
            name => 'json:array_int_100',
            summary => 'A 10-element array containing ints',
            args => {data=>'['.join(',',1..100).']'},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
        },
        {
            name => 'json:array_int_1000',
            summary => 'A 1000-element array containing ints',
            args => {data=>'['.join(',',1..1000).']'},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
        },
        {
            name => 'json:array_str1k_10',
            summary => 'A 10-element array containing 1024-characters/bytes-long non-Unicode strings',
            args => {data=>'['.join(',',(('"'.('a' x 1024).'"') x 10)).']'},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
        },

        {
            name => 'json:hash_int_10',
            summary => 'A 10-key hash {"1":0, ..., "10":0}',
            args => {data=>'{'.join(',', map {qq("$_":0)} 1..10).'}'},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
        },
        {
            name => 'json:hash_int_100',
            summary => 'A 100-key hash {"1":0, ..., "100":0}',
            args => {data=>'{'.join(',', map {qq("$_":0)} 1..100).'}'},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
        },
        {
            name => 'json:hash_int_1000',
            summary => 'A 1000-key hash {"1":0, ..., "1000":0}',
            args => {data=>'{'.join(',', map {qq("$_":0)} 1..1000).'}'},
            tags => ['deserialize'],
            include_participant_tags => ['json & deserialize'],
        },
    ],
};

1;
# ABSTRACT: Benchmark Perl data serialization modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Serializers - Benchmark Perl data serialization modules

=head1 VERSION

This document describes version 0.14 of Bencher::Scenario::Serializers (from Perl distribution Bencher-Scenario-Serializers), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Serializers

To run module startup overhead benchmark:

 % bencher --module-startup -m Serializers

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<JSON::PP> 2.27300

L<JSON::Tiny> 0.56

L<JSON::XS> 3.02

L<Cpanel::JSON::XS> 3.0217

L<JSON::MaybeXS> 1.003005

L<JSON::Decode::Regexp> 0.09

L<JSON::Decode::Marpa> 0.02

L<Pegex::JSON> 0.27

L<JSON::Create> 0.22

L<JSON::Parse> 0.42

L<YAML::Old> 1.07

L<YAML::Syck> 1.29

L<YAML::XS> 0.63

L<Storable> 2.56

L<Sereal> 3.014

L<Data::MessagePack> 1.00

=head1 BENCHMARK PARTICIPANTS

=over

=item * JSON::PP::encode_json (perl_code) [json, serialize]

Code template:

 state $json = JSON::PP->new->allow_nonref; $json->encode(<data>)



=item * JSON::PP::decode_json (perl_code) [json, deserialize]

Code template:

 state $json = JSON::PP->new->allow_nonref; $json->decode(<data>)



=item * JSON::Tiny::encode_json (perl_code) [json, serialize]

Code template:

 JSON::Tiny::encode_json(<data>)



=item * JSON::Tiny::decode_json (perl_code) [json, deserialize]

Code template:

 JSON::Tiny::decode_json(<data>)



=item * JSON::XS::encode_json (perl_code) [json, serialize]

Code template:

 state $json = JSON::XS->new->allow_nonref; $json->encode(<data>)



=item * JSON::XS::decode_json (perl_code) [json, deserialize]

Code template:

 state $json = JSON::XS->new->allow_nonref; $json->decode(<data>)



=item * Cpanel::JSON::XS::encode_json (perl_code) [json, serialize]

Code template:

 state $json = Cpanel::JSON::XS->new->allow_nonref; $json->encode(<data>)



=item * Cpanel::JSON::XS::decode_json (perl_code) [json, deserialize]

Code template:

 state $json = Cpanel::JSON::XS->new->allow_nonref; $json->decode(<data>)



=item * JSON::MaybeXS::encode_json (perl_code) [json, serialize]

Code template:

 state $json = JSON::MaybeXS->new(allow_nonref=>1); $json->encode(<data>)



=item * JSON::MaybeXS::decode_json (perl_code) [json, deserialize]

Code template:

 state $json = JSON::MaybeXS->new(allow_nonref=>1); $json->decode(<data>)



=item * JSON::Decode::Regexp::from_json (perl_code) [json, deserialize]

Function call template:

 JSON::Decode::Regexp::from_json(<data>)



=item * PERLANCAR::JSON::Match::match_json (perl_code) (not included by default) [json, deserialize, cant_handle_scalar]

Function call template:

 JSON::Decode::Marpa::from_json(<data>)



=item * JSON::Decode::Marpa::from_json (perl_code) [json, deserialize]

Code template:

 state $obj = Pegex::JSON->new; $obj->load(<data>);



=item * Pegex::JSON (perl_code) [json, serialize]

Function call template:

 JSON::Create::create_json(<data>)



=item * JSON::Create::create_json (perl_code) [json, deserialize]

Function call template:

 JSON::Parse::parse_json(<data>)



=item * JSON::Parse::parse_json (perl_code) [yaml, serialize]

Function call template:

 YAML::Old::Dump(<data>)



=item * YAML::Old::Dump (perl_code) [yaml, deserialize]

Function call template:

 YAML::Old::Load(<data>)



=item * YAML::Old::Load (perl_code) [yaml, serialize]

Function call template:

 YAML::Syck::Dump(<data>)



=item * YAML::Syck::Dump (perl_code) [yaml, deserialize]

Function call template:

 YAML::Syck::Load(<data>)



=item * YAML::Syck::Load (perl_code) [yaml, serialize]

Function call template:

 YAML::XS::Dump(<data>)



=item * YAML::XS::Dump (perl_code) [yaml, deserialize]

Function call template:

 YAML::XS::Load(<data>)



=item * YAML::XS::Load (perl_code) [binary, serialize, cant_handle_scalar]

Function call template:

 Storable::freeze(<data>)



=item * Storable::freeze (perl_code) [binary, deserialize, cant_handle_scalar]

Function call template:

 Storable::thaw(<data>)



=item * Storable::thaw (perl_code) [binary, serialize]

Function call template:

 Sereal::encode_sereal(<data>)



=item * Sereal::encode_sereal (perl_code) [binary, deserialize]

Function call template:

 Sereal::decode_sereal(<data>)



=item * Sereal::decode_sereal (perl_code) [binary, serialize]

Code template:

 state $obj = Data::MessagePack->new; $obj->pack(<data>)



=item * Data::MessagePack::pack (perl_code) [binary, deserialize]

Code template:

 state $obj = Data::MessagePack->new; $obj->unpack(<data>)



=item * Data::MessagePack::unpack (perl_code)

L<Data::MessagePack>::unpack



=back

=head1 BENCHMARK DATASETS

=over

=item * undef [serialize]

undef

=item * num [serialize]

A single number (-1.23)

=item * str1k [serialize]

A non-Unicode string 1024 characters/bytes long

=item * str1k [serialize, unicode]

A Unicode string 1024 characters (3072-bytes) long

=item * array_int_10 [serialize]

A 10-element array containing ints

=item * array_int_100 [serialize]

A 100-element array containing ints

=item * array_int_1000 [serialize]

A 1000-element array containing ints

=item * array_str1k_10 [serialize]

A 10-element array containing 1024-characters/bytes-long non-Unicode strings

=item * array_ustr1k_10 [serialize, json]

A 10-element array containing 1024-characters-long (3072-bytes long) Unicode strings

=item * hash_int_10 [serialize]

A 10-key hash {1=>0, ..., 10=>0}

=item * hash_int_100 [serialize]

A 100-key hash {1=>0, ..., 100=>0}

=item * hash_int_1000 [serialize]

A 1000-key hash {1=>0, ..., 1000=>0}

=item * json:null [deserialize]

null

=item * json:num [deserialize]

A single number (-1.23)

=item * json:str1k [deserialize]

A non-Unicode (ASCII) string 1024-characters/bytes long

=item * json:array_int_10 [deserialize]

A 10-element array containing ints

=item * json:array_int_100 [deserialize]

A 10-element array containing ints

=item * json:array_int_1000 [deserialize]

A 1000-element array containing ints

=item * json:array_str1k_10 [deserialize]

A 10-element array containing 1024-characters/bytes-long non-Unicode strings

=item * json:hash_int_10 [deserialize]

A 10-key hash {"1":0, ..., "10":0}

=item * json:hash_int_100 [deserialize]

A 100-key hash {"1":0, ..., "100":0}

=item * json:hash_int_1000 [deserialize]

A 1000-key hash {"1":0, ..., "1000":0}

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark serializing (C<< bencher -m Serializers --include-participant-tags serialize >>):

 #table1#
 {dataset=>"array_int_10"}
 +-------------------------------+-----------+------------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs)  | vs_slowest |  errors | samples |
 +-------------------------------+-----------+------------+------------+---------+---------+
 | YAML::Old::Dump               |      3400 | 300        |      1     | 1.9e-06 |      24 |
 | JSON::PP::encode_json         |     65900 |  15.2      |     19.5   | 6.7e-09 |      20 |
 | YAML::Syck::Dump              |     91000 |  11        |     27     | 1.3e-08 |      20 |
 | JSON::Tiny::encode_json       |     96100 |  10.4      |     28.4   | 3.3e-09 |      21 |
 | YAML::XS::Dump                |    120000 |   8.1      |     36     | 1.3e-08 |      20 |
 | Storable::freeze              |    310000 |   3.22     |     91.5   | 1.4e-09 |      27 |
 | Sereal::encode_sereal         |   1400000 |   0.71     |    420     | 8.3e-10 |      20 |
 | JSON::Create::create_json     |   1490000 |   0.669    |    441     | 1.8e-10 |      28 |
 | Cpanel::JSON::XS::encode_json |   1500000 |   0.66     |    450     | 8.1e-10 |      21 |
 | JSON::MaybeXS::encode_json    |   1500000 |   0.66     |    450     | 8.3e-10 |      20 |
 | JSON::XS::encode_json         |   1530000 |   0.654    |    451     | 6.2e-10 |      20 |
 | Data::MessagePack::pack       |   1605190 |   0.622979 |    473.866 |   0     |      20 |
 +-------------------------------+-----------+------------+------------+---------+---------+

 #table2#
 {dataset=>"array_int_100"}
 +-------------------------------+-----------+------------+------------+---------+---------+
 | participant                   | rate (/s) |  time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+------------+------------+---------+---------+
 | YAML::Old::Dump               |       474 | 2.11       |      1     |   2e-06 |      20 |
 | JSON::PP::encode_json         |      7300 | 0.14       |     15     | 2.1e-07 |      20 |
 | JSON::Tiny::encode_json       |     10000 | 0.08       |     30     |   1e-06 |      29 |
 | YAML::Syck::Dump              |     16000 | 0.064      |     33     | 1.1e-07 |      20 |
 | YAML::XS::Dump                |     17200 | 0.0582     |     36.3   | 2.7e-08 |      20 |
 | Storable::freeze              |    130000 | 0.0076     |    280     | 1.3e-08 |      20 |
 | Cpanel::JSON::XS::encode_json |    210000 | 0.0048     |    440     | 6.7e-09 |      20 |
 | JSON::MaybeXS::encode_json    |    210000 | 0.0048     |    440     | 6.5e-09 |      21 |
 | JSON::XS::encode_json         |    215000 | 0.00465    |    454     | 1.7e-09 |      20 |
 | Sereal::encode_sereal         |    270000 | 0.0037     |    560     | 6.7e-09 |      20 |
 | Data::MessagePack::pack       |    280557 | 0.00356433 |    592.155 |   0     |      20 |
 | JSON::Create::create_json     |    280000 | 0.0035     |    600     | 5.5e-09 |      29 |
 +-------------------------------+-----------+------------+------------+---------+---------+

 #table3#
 {dataset=>"array_int_1000"}
 +-------------------------------+-----------+------------+------------+---------+---------+
 | participant                   | rate (/s) | time (ms)  | vs_slowest |  errors | samples |
 +-------------------------------+-----------+------------+------------+---------+---------+
 | YAML::Old::Dump               |      47   | 21         |      1     | 5.2e-05 |      20 |
 | JSON::PP::encode_json         |     830   |  1.2       |     18     | 2.2e-06 |      20 |
 | JSON::Tiny::encode_json       |    1400   |  0.714     |     29.6   | 2.7e-07 |      20 |
 | YAML::Syck::Dump              |    1600   |  0.62      |     34     |   1e-06 |      24 |
 | YAML::XS::Dump                |    1790   |  0.559     |     37.8   | 2.1e-07 |      20 |
 | Storable::freeze              |   15900   |  0.0627    |    337     | 2.7e-08 |      20 |
 | JSON::MaybeXS::encode_json    |   22210.8 |  0.0450231 |    469.034 | 9.6e-12 |      26 |
 | Cpanel::JSON::XS::encode_json |   22259.9 |  0.0449238 |    470.071 |   0     |      20 |
 | JSON::XS::encode_json         |   22000   |  0.045     |    470     | 5.2e-08 |      21 |
 | JSON::Create::create_json     |   25600   |  0.0391    |    540     | 3.8e-08 |      22 |
 | Sereal::encode_sereal         |   29400   |  0.034     |    620     | 1.3e-08 |      20 |
 | Data::MessagePack::pack       |   30300   |  0.033     |    641     | 1.1e-08 |      29 |
 +-------------------------------+-----------+------------+------------+---------+---------+

 #table4#
 {dataset=>"array_str1k_10"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               |   2700    |  370      |    1       | 4.3e-07 |      20 |
 | YAML::XS::Dump                |   8817.75 |  113.408  |    3.22297 | 1.2e-11 |      25 |
 | JSON::PP::encode_json         |  12152.6  |   82.2868 |    4.44189 |   0     |      20 |
 | JSON::Tiny::encode_json       |  20389.3  |   49.0454 |    7.45246 |   0     |      20 |
 | YAML::Syck::Dump              |  26100    |   38.3    |    9.53    | 1.3e-08 |      22 |
 | JSON::Create::create_json     |  36927.8  |   27.0798 |   13.4975  | 1.2e-11 |      30 |
 | Cpanel::JSON::XS::encode_json |  40000    |   30      |   10       | 5.7e-07 |      21 |
 | JSON::MaybeXS::encode_json    |  41000    |   24      |   15       | 2.7e-08 |      20 |
 | JSON::XS::encode_json         |  42014.4  |   23.8013 |   15.3567  |   0     |      20 |
 | Storable::freeze              | 220000    |    4.54   |   80.4     | 1.7e-09 |      20 |
 | Data::MessagePack::pack       | 343000    |    2.92   |  125       | 8.3e-10 |      20 |
 | Sereal::encode_sereal         | 370000    |    2.7    |  130       | 3.3e-09 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"array_ustr1k_10"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               |      1080 |     924   |       1    | 6.4e-07 |      20 |
 | JSON::Tiny::encode_json       |      1120 |     893   |       1.03 |   2e-07 |      22 |
 | JSON::PP::encode_json         |      2010 |     498   |       1.86 | 1.6e-07 |      20 |
 | Cpanel::JSON::XS::encode_json |      3090 |     323   |       2.86 | 5.3e-08 |      20 |
 | YAML::XS::Dump                |      3500 |     290   |       3.2  | 6.6e-07 |      22 |
 | JSON::XS::encode_json         |      3590 |     279   |       3.32 | 2.1e-07 |      20 |
 | JSON::MaybeXS::encode_json    |      3630 |     275   |       3.36 | 5.2e-08 |      21 |
 | YAML::Syck::Dump              |      9900 |     100   |       9.2  | 1.6e-07 |      20 |
 | JSON::Create::create_json     |     15000 |      65   |      14    | 1.1e-07 |      20 |
 | Storable::freeze              |    140000 |       7.2 |     130    |   1e-08 |      20 |
 | Data::MessagePack::pack       |    230000 |       4.4 |     210    | 6.7e-09 |      20 |
 | Sereal::encode_sereal         |    240000 |       4.1 |     220    | 6.4e-09 |      22 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"hash_int_10"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               |      2600 |  390      |       1    |   1e-06 |      25 |
 | JSON::PP::encode_json         |     26000 |   38      |      10    | 5.4e-08 |      31 |
 | JSON::Tiny::encode_json       |     44000 |   23      |      17    | 2.7e-08 |      20 |
 | YAML::Syck::Dump              |     56000 |   18      |      21    | 2.7e-08 |      20 |
 | YAML::XS::Dump                |     63000 |   16      |      24    | 2.6e-08 |      21 |
 | Storable::freeze              |    190000 |    5.2    |      74    | 6.7e-09 |      20 |
 | Sereal::encode_sereal         |    440000 |    2.3    |     170    | 3.3e-09 |      20 |
 | Data::MessagePack::pack       |    467000 |    2.14   |     180    | 8.3e-10 |      20 |
 | Cpanel::JSON::XS::encode_json |    488000 |    2.05   |     188    | 7.6e-10 |      24 |
 | JSON::MaybeXS::encode_json    |    544000 |    1.84   |     210    | 4.4e-10 |      20 |
 | JSON::XS::encode_json         |    550000 |    1.8    |     210    | 3.1e-09 |      24 |
 | JSON::Create::create_json     |    619560 |    1.6141 |     239.22 |   1e-11 |      24 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"hash_int_100"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               |       353 |     2.83  |        1   | 1.3e-06 |      20 |
 | JSON::PP::encode_json         |      2900 |     0.34  |        8.3 | 4.1e-07 |      22 |
 | JSON::Tiny::encode_json       |      5500 |     0.18  |       16   | 4.8e-07 |      20 |
 | YAML::Syck::Dump              |      6600 |     0.15  |       19   | 2.4e-07 |      24 |
 | YAML::XS::Dump                |      7400 |     0.14  |       21   | 6.1e-07 |      22 |
 | Sereal::encode_sereal         |     45000 |     0.022 |      130   | 5.9e-08 |      21 |
 | Storable::freeze              |     47000 |     0.021 |      130   | 3.2e-08 |      22 |
 | Data::MessagePack::pack       |     50000 |     0.02  |      140   | 5.3e-08 |      20 |
 | Cpanel::JSON::XS::encode_json |     53000 |     0.019 |      150   | 2.7e-08 |      20 |
 | JSON::MaybeXS::encode_json    |     59000 |     0.017 |      170   |   2e-08 |      20 |
 | JSON::XS::encode_json         |     60000 |     0.017 |      170   | 2.7e-08 |      20 |
 | JSON::Create::create_json     |     68000 |     0.015 |      190   | 2.7e-08 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"hash_int_1000"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               |        35 |    28     |       1    | 4.8e-05 |      22 |
 | JSON::PP::encode_json         |       341 |     2.93  |       9.68 | 1.6e-06 |      20 |
 | JSON::Tiny::encode_json       |       520 |     1.9   |      15    | 1.2e-05 |      20 |
 | YAML::Syck::Dump              |       650 |     1.5   |      18    | 2.2e-06 |      20 |
 | YAML::XS::Dump                |       739 |     1.35  |      21    | 6.9e-07 |      20 |
 | Sereal::encode_sereal         |      3900 |     0.26  |     110    | 2.7e-07 |      20 |
 | Storable::freeze              |      4510 |     0.222 |     128    | 2.1e-07 |      20 |
 | Data::MessagePack::pack       |      4640 |     0.215 |     132    | 2.1e-07 |      20 |
 | Cpanel::JSON::XS::encode_json |      4900 |     0.21  |     140    | 1.5e-06 |      20 |
 | JSON::Create::create_json     |      5000 |     0.2   |     100    | 2.2e-06 |      21 |
 | JSON::XS::encode_json         |      5100 |     0.2   |     150    | 2.1e-07 |      20 |
 | JSON::MaybeXS::encode_json    |      5100 |     0.2   |     150    | 2.1e-07 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table9#
 {dataset=>"num"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               |     16000 |    64     |        1   | 1.1e-07 |      20 |
 | YAML::Syck::Dump              |    170000 |     5.9   |       11   | 6.7e-09 |      20 |
 | JSON::Tiny::encode_json       |    220000 |     4.6   |       14   | 6.7e-09 |      20 |
 | YAML::XS::Dump                |    300000 |     3.3   |       19   | 6.7e-09 |      20 |
 | JSON::PP::encode_json         |    350000 |     2.9   |       22   | 3.3e-09 |      20 |
 | JSON::XS::encode_json         |   1630000 |     0.614 |      104   |   2e-10 |      21 |
 | Cpanel::JSON::XS::encode_json |   1800000 |     0.55  |      120   | 6.1e-10 |      21 |
 | JSON::MaybeXS::encode_json    |   1828000 |     0.547 |      116.3 | 1.2e-11 |      20 |
 | JSON::Create::create_json     |   2640000 |     0.379 |      168   | 2.1e-10 |      20 |
 | Sereal::encode_sereal         |   3100000 |     0.32  |      200   | 4.2e-10 |      20 |
 | Data::MessagePack::pack       |   3900000 |     0.26  |      250   | 4.2e-10 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table10#
 {dataset=>"str1k"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               |     15000 | 66.8      |     1      | 2.7e-08 |      20 |
 | YAML::XS::Dump                |     77821 | 12.85     |     5.1989 | 4.6e-11 |      24 |
 | JSON::PP::encode_json         |    101000 |  9.89     |     6.75   | 2.7e-09 |      32 |
 | YAML::Syck::Dump              |    128000 |  7.8      |     8.57   | 3.3e-09 |      20 |
 | JSON::Tiny::encode_json       |    149839 |  6.67383  |    10.0102 |   0     |      22 |
 | JSON::Create::create_json     |    320050 |  3.1245   |    21.381  | 1.2e-11 |      20 |
 | JSON::XS::encode_json         |    359000 |  2.78     |    24      | 8.3e-10 |      20 |
 | JSON::MaybeXS::encode_json    |    402000 |  2.49     |    26.9    | 8.6e-10 |      20 |
 | Cpanel::JSON::XS::encode_json |    405251 |  2.46761  |    27.0732 |   0     |      20 |
 | Sereal::encode_sereal         |   2510000 |  0.398    |   168      |   2e-10 |      21 |
 | Data::MessagePack::pack       |   2879310 |  0.347305 |   192.356  |   0     |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table11#
 {dataset=>"undef"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               |     18000 | 55        |      1     |   1e-07 |      21 |
 | YAML::Syck::Dump              |    200000 |  5        |     11     | 6.7e-09 |      20 |
 | JSON::Tiny::encode_json       |    430000 |  2.3      |     24     | 2.5e-09 |      20 |
 | YAML::XS::Dump                |    500000 |  2        |     27     | 3.3e-09 |      20 |
 | JSON::PP::encode_json         |    526000 |  1.9      |     28.9   |   7e-10 |      32 |
 | Sereal::encode_sereal         |   3600000 |  0.28     |    190     | 3.8e-10 |      28 |
 | JSON::XS::encode_json         |   4740000 |  0.211    |    260     | 1.1e-10 |      20 |
 | Data::MessagePack::pack       |   5230330 |  0.191192 |    287.157 |   0     |      20 |
 | Cpanel::JSON::XS::encode_json |   5450000 |  0.183    |    299     | 4.6e-11 |      20 |
 | JSON::MaybeXS::encode_json    |   5790000 |  0.173    |    318     | 1.1e-10 |      20 |
 | JSON::Create::create_json     |   6762430 |  0.147876 |    371.272 |   0     |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+


Benchmark deserializing (C<< bencher -m Serializers --include-participant-tags deserialize >>):

 #table12#
 {dataset=>"json:array_int_10"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Marpa::from_json     |      1300 |   790     |      1     | 4.7e-06 |      20 |
 | Pegex::JSON                        |      1730 |   578     |      1.37  | 3.1e-07 |      21 |
 | JSON::PP::decode_json              |     32309 |    30.951 |     25.672 | 4.7e-11 |      20 |
 | JSON::Decode::Regexp::from_json    |     40000 |    25     |     32     | 4.8e-08 |      31 |
 | JSON::Tiny::decode_json            |     48000 |    21     |     38     | 5.3e-08 |      20 |
 | PERLANCAR::JSON::Match::match_json |     83800 |    11.9   |     66.6   | 3.2e-09 |      22 |
 | Cpanel::JSON::XS::decode_json      |   1400000 |     0.7   |   1100     | 5.5e-09 |      26 |
 | JSON::XS::decode_json              |   1500000 |     0.66  |   1200     | 1.8e-09 |      22 |
 | JSON::MaybeXS::decode_json         |   1500000 |     0.65  |   1200     | 8.3e-10 |      20 |
 | JSON::Parse::parse_json            |   1680000 |     0.594 |   1340     | 1.6e-10 |      20 |
 +------------------------------------+-----------+-----------+------------+---------+---------+

 #table13#
 {dataset=>"json:array_int_100"}
 +------------------------------------+-----------+------------+------------+---------+---------+
 | participant                        | rate (/s) |  time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+------------+------------+---------+---------+
 | Pegex::JSON                        |    360    | 2.8        |      1     | 1.3e-05 |      27 |
 | JSON::Decode::Marpa::from_json     |    420    | 2.4        |      1.2   | 2.5e-06 |      20 |
 | JSON::PP::decode_json              |   3000    | 0.33       |      8.4   | 4.3e-07 |      20 |
 | JSON::Decode::Regexp::from_json    |   4961.88 | 0.201537   |     13.82  | 4.6e-11 |      20 |
 | JSON::Tiny::decode_json            |   6711.8  | 0.14899    |     18.694 | 1.7e-10 |      20 |
 | PERLANCAR::JSON::Match::match_json |   9280    | 0.108      |     25.8   | 4.8e-08 |      25 |
 | Cpanel::JSON::XS::decode_json      | 247793    | 0.00403563 |    690.16  |   0     |      20 |
 | JSON::MaybeXS::decode_json         | 251000    | 0.00398    |    699     | 1.4e-09 |      27 |
 | JSON::XS::decode_json              | 255000    | 0.00392    |    711     | 1.4e-09 |      30 |
 | JSON::Parse::parse_json            | 269000    | 0.00371    |    750     | 1.7e-09 |      20 |
 +------------------------------------+-----------+------------+------------+---------+---------+

 #table14#
 {dataset=>"json:array_int_1000"}
 +------------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                        | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +------------------------------------+-----------+-----------+------------+-----------+---------+
 | Pegex::JSON                        |        41 | 24        |       1    |   0.00014 |      21 |
 | JSON::Decode::Marpa::from_json     |        49 | 20        |       1.2  | 7.2e-05   |      20 |
 | JSON::PP::decode_json              |       302 |  3.31     |       7.36 | 8.5e-07   |      20 |
 | JSON::Decode::Regexp::from_json    |       470 |  2.1      |      11    | 3.4e-06   |      22 |
 | JSON::Tiny::decode_json            |       720 |  1.4      |      18    | 2.9e-06   |      20 |
 | PERLANCAR::JSON::Match::match_json |       850 |  1.2      |      21    | 1.1e-05   |      20 |
 | JSON::Parse::parse_json            |     33000 |  0.03     |     810    | 5.2e-08   |      21 |
 | JSON::MaybeXS::decode_json         |     34000 |  0.029    |     830    | 5.3e-08   |      20 |
 | Cpanel::JSON::XS::decode_json      |     34100 |  0.0293   |     831    | 1.3e-08   |      21 |
 | JSON::XS::decode_json              |     35356 |  0.028284 |     861.35 | 3.4e-11   |      20 |
 +------------------------------------+-----------+-----------+------------+-----------+---------+

 #table15#
 {dataset=>"json:array_str1k_10"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Marpa::from_json     |       100 | 9.5       |      1     | 3.4e-05 |      20 |
 | JSON::PP::decode_json              |       197 | 5.06      |      1.88  | 4.5e-06 |      20 |
 | Pegex::JSON                        |       810 | 1.2       |      7.8   | 9.4e-06 |      21 |
 | JSON::Tiny::decode_json            |      1300 | 0.78      |     12     | 5.6e-06 |      20 |
 | JSON::Decode::Regexp::from_json    |     13000 | 0.075     |    130     | 9.2e-08 |      27 |
 | PERLANCAR::JSON::Match::match_json |     17479 | 0.0572114 |    166.828 | 3.8e-11 |      21 |
 | JSON::Parse::parse_json            |     54200 | 0.0185    |    517     | 6.5e-09 |      21 |
 | Cpanel::JSON::XS::decode_json      |     59942 | 0.016683  |    572.11  | 4.3e-11 |      20 |
 | JSON::MaybeXS::decode_json         |     60000 | 0.017     |    570     | 2.5e-08 |      23 |
 | JSON::XS::decode_json              |     76694 | 0.013039  |    732     | 3.4e-11 |      22 |
 +------------------------------------+-----------+-----------+------------+---------+---------+

 #table16#
 {dataset=>"json:hash_int_10"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Marpa::from_json     |      1000 |   1000    |       1    | 6.4e-07 |      20 |
 | Pegex::JSON                        |      1290 |    775    |       1.29 | 6.9e-07 |      20 |
 | JSON::PP::decode_json              |     16000 |     63    |      16    | 1.1e-07 |      20 |
 | JSON::Decode::Regexp::from_json    |     20000 |     50    |      20    | 8.8e-08 |      37 |
 | JSON::Tiny::decode_json            |     24000 |     42    |      24    |   5e-08 |      23 |
 | PERLANCAR::JSON::Match::match_json |     52600 |     19    |      52.6  | 6.1e-09 |      24 |
 | Cpanel::JSON::XS::decode_json      |    848000 |      1.18 |     848    | 3.3e-10 |      32 |
 | JSON::MaybeXS::decode_json         |    849000 |      1.18 |     849    |   4e-10 |      22 |
 | JSON::XS::decode_json              |    900000 |      1.1  |     900    | 1.7e-09 |      20 |
 | JSON::Parse::parse_json            |    930000 |      1.1  |     930    | 1.2e-09 |      21 |
 +------------------------------------+-----------+-----------+------------+---------+---------+

 #table17#
 {dataset=>"json:hash_int_100"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Marpa::from_json     |       200 |    5      |        1   | 6.6e-05 |      20 |
 | Pegex::JSON                        |       210 |    4.8    |        1   |   4e-05 |      20 |
 | JSON::PP::decode_json              |      1600 |    0.64   |        7.7 | 4.1e-06 |      20 |
 | JSON::Decode::Regexp::from_json    |      2000 |    0.5    |        9.9 | 8.5e-07 |      20 |
 | JSON::Tiny::decode_json            |      3000 |    0.34   |       15   | 4.3e-07 |      20 |
 | PERLANCAR::JSON::Match::match_json |      5600 |    0.18   |       28   |   2e-07 |      23 |
 | JSON::MaybeXS::decode_json         |     79000 |    0.013  |      390   | 1.3e-08 |      20 |
 | Cpanel::JSON::XS::decode_json      |     89500 |    0.0112 |      444   | 3.3e-09 |      20 |
 | JSON::Parse::parse_json            |     92600 |    0.0108 |      459   |   1e-08 |      20 |
 | JSON::XS::decode_json              |     93400 |    0.0107 |      463   | 3.3e-09 |      20 |
 +------------------------------------+-----------+-----------+------------+---------+---------+

 #table18#
 {dataset=>"json:hash_int_1000"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | Pegex::JSON                        |        23 |     44    |        1   | 5.6e-05 |      20 |
 | JSON::Decode::Marpa::from_json     |        23 |     43    |        1   | 7.5e-05 |      20 |
 | JSON::PP::decode_json              |       140 |      6.9  |        6.3 | 9.4e-06 |      20 |
 | JSON::Decode::Regexp::from_json    |       170 |      5.8  |        7.5 | 5.6e-05 |      20 |
 | JSON::Tiny::decode_json            |       270 |      3.7  |       12   |   5e-06 |      20 |
 | PERLANCAR::JSON::Match::match_json |       450 |      2.2  |       20   | 3.1e-06 |      20 |
 | JSON::Parse::parse_json            |      6300 |      0.16 |      280   | 2.1e-07 |      20 |
 | JSON::MaybeXS::decode_json         |      6300 |      0.16 |      280   | 2.1e-07 |      20 |
 | Cpanel::JSON::XS::decode_json      |      7000 |      0.14 |      310   | 2.1e-07 |      20 |
 | JSON::XS::decode_json              |      7200 |      0.14 |      320   | 2.1e-07 |      20 |
 +------------------------------------+-----------+-----------+------------+---------+---------+

 #table19#
 {dataset=>"json:null"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | Pegex::JSON                        |      2900 |  340      |        1   | 6.2e-07 |      21 |
 | JSON::Tiny::decode_json            |    190000 |    5.3    |       65   | 6.7e-09 |      20 |
 | JSON::PP::decode_json              |    235000 |    4.25   |       81.1 | 1.7e-09 |      20 |
 | JSON::Decode::Regexp::from_json    |    410000 |    2.5    |      140   | 3.3e-09 |      20 |
 | PERLANCAR::JSON::Match::match_json |    666000 |    1.5    |      230   | 4.2e-10 |      20 |
 | JSON::MaybeXS::decode_json         |   7200000 |    0.14   |     2500   | 9.5e-10 |      30 |
 | Cpanel::JSON::XS::decode_json      |   8270000 |    0.121  |     2850   | 6.2e-11 |      33 |
 | JSON::XS::decode_json              |   8570000 |    0.117  |     2950   | 6.9e-11 |      21 |
 | JSON::Parse::parse_json            |  13400000 |    0.0744 |     4630   | 6.9e-11 |      20 |
 +------------------------------------+-----------+-----------+------------+---------+---------+

 #table20#
 {dataset=>"json:num"}
 +------------------------------------+-----------+------------+------------+---------+---------+
 | participant                        | rate (/s) | time (μs)  | vs_slowest |  errors | samples |
 +------------------------------------+-----------+------------+------------+---------+---------+
 | Pegex::JSON                        |      3100 | 320        |      1     | 6.4e-07 |      20 |
 | JSON::PP::decode_json              |    130000 |   7.9      |     41     | 1.2e-08 |      24 |
 | JSON::Tiny::decode_json            |    130000 |   7.5      |     43     | 1.3e-08 |      22 |
 | JSON::Decode::Regexp::from_json    |    290000 |   3.5      |     93     | 6.7e-09 |      20 |
 | PERLANCAR::JSON::Match::match_json |    440000 |   2.3      |    140     | 3.3e-09 |      20 |
 | Cpanel::JSON::XS::decode_json      |   1200000 |   0.83     |    390     | 2.8e-09 |      28 |
 | JSON::MaybeXS::decode_json         |   1318860 |   0.758228 |    427.945 |   0     |      20 |
 | JSON::XS::decode_json              |   1370000 |   0.731    |    444     | 3.8e-10 |      24 |
 | JSON::Parse::parse_json            |   1446000 |   0.6917   |    469.1   | 1.1e-11 |      20 |
 +------------------------------------+-----------+------------+------------+---------+---------+

 #table21#
 {dataset=>"json:str1k"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | JSON::PP::decode_json              |      2000 | 501       |      1     | 4.2e-07 |      21 |
 | Pegex::JSON                        |      2650 | 377       |      1.33  | 2.7e-07 |      20 |
 | JSON::Tiny::decode_json            |     13000 |  80       |      6.3   | 9.7e-08 |      24 |
 | JSON::Decode::Regexp::from_json    |    130000 |   7.7     |     65     | 9.3e-09 |      23 |
 | PERLANCAR::JSON::Match::match_json |    160000 |   6.2     |     81     | 6.7e-09 |      20 |
 | Cpanel::JSON::XS::decode_json      |    530000 |   1.89    |    266     | 6.6e-10 |      32 |
 | JSON::Parse::parse_json            |    548000 |   1.83    |    274     | 8.7e-10 |      20 |
 | JSON::MaybeXS::decode_json         |    595036 |   1.68057 |    298.123 |   0     |      20 |
 | JSON::XS::decode_json              |    762000 |   1.31    |    382     | 3.2e-10 |      33 |
 +------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m Serializers --module-startup >>):

 #table22#
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant          | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | JSON::Decode::Marpa  | 1.32                         | 4.84               | 20.5           |     111   |                  105.2 |        1   | 9.5e-05   |      20 |
 | YAML::XS             | 2.4                          | 5.8                | 20             |      46   |                   40.2 |        2.4 | 5.7e-05   |      20 |
 | JSON::PP             | 3.1                          | 6.7                | 22             |      23   |                   17.2 |        4.8 |   0.00012 |      21 |
 | Pegex::JSON          | 1.9                          | 5.4                | 23             |      22   |                   16.2 |        5.1 | 5.8e-05   |      20 |
 | JSON::Tiny           | 2.3                          | 5.7                | 22             |      20   |                   14.2 |        5.5 | 5.2e-05   |      20 |
 | JSON::MaybeXS        | 1.3                          | 4.7                | 20             |      17   |                   11.2 |        6.4 | 4.6e-05   |      20 |
 | Storable             | 1                            | 4.4                | 18             |      15   |                    9.2 |        7.6 | 4.6e-05   |      20 |
 | Sereal               | 1.3                          | 4.7                | 18             |      14   |                    8.2 |        7.8 | 2.4e-05   |      21 |
 | YAML::Old            | 0.82                         | 4.1                | 16             |      14   |                    8.2 |        8   | 4.9e-05   |      20 |
 | JSON::XS             | 2.3                          | 5.7                | 22             |      13   |                    7.2 |        8.6 | 3.4e-05   |      20 |
 | Cpanel::JSON::XS     | 1.3                          | 4.7                | 20             |      12   |                    6.2 |        9   | 3.8e-05   |      20 |
 | JSON::Parse          | 0.98                         | 4.3                | 16             |      12   |                    6.2 |        9.6 |   3e-05   |      20 |
 | YAML::Syck           | 16                           | 20                 | 42             |      11   |                    5.2 |        9.8 | 4.6e-05   |      21 |
 | JSON::Decode::Regexp | 1.3                          | 4.7                | 20             |       9.4 |                    3.6 |       12   | 4.9e-05   |      20 |
 | JSON::Create         | 1.9                          | 5.4                | 23             |       9.3 |                    3.5 |       12   | 1.6e-05   |      20 |
 | Data::MessagePack    | 1.6                          | 4.9                | 17             |       8.7 |                    2.9 |       13   | 1.7e-05   |      20 |
 | perl -e1 (baseline)  | 3.1                          | 6.7                | 22             |       5.8 |                    0   |       19   | 2.2e-05   |      21 |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Serializers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Serializers>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Serializers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

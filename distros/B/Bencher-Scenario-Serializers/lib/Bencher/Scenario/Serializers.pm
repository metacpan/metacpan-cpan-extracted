package Bencher::Scenario::Serializers;

our $DATE = '2017-05-17'; # DATE
our $VERSION = '0.15'; # VERSION

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
            tags => ['json', 'deserialize'],
            module => 'MarpaX::ESLIF::ECMA404',
            function => 'decode',
            code_template => 'state $ecma404 = MarpaX::ESLIF::ECMA404->new; $ecma404->decode(<data>)',
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

This document describes version 0.15 of Bencher::Scenario::Serializers (from Perl distribution Bencher-Scenario-Serializers), released on 2017-05-17.

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

L<Cpanel::JSON::XS> 3.0213

L<JSON::MaybeXS> 1.003005

L<JSON::Decode::Regexp> 0.09

L<JSON::Decode::Marpa> 0.02

L<Pegex::JSON> 0.27

L<JSON::Create> 0.22

L<JSON::Parse> 0.42

L<MarpaX::ESLIF::ECMA404> 0.003

L<YAML::Old> 1.07

L<YAML::Syck> 1.29

L<YAML::XS> 0.63

L<Storable> 2.56

L<Sereal> 3.015

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



=item * JSON::Parse::parse_json (perl_code) [json, deserialize]

Code template:

 state $ecma404 = MarpaX::ESLIF::ECMA404->new; $ecma404->decode(<data>)



=item * MarpaX::ESLIF::ECMA404::decode (perl_code) [yaml, serialize]

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark serializing (C<< bencher -m Serializers --include-participant-tags serialize >>):

 #table1#
 {dataset=>"array_int_10"}
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | p_tags                                | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize                       |      2910 |   344     |        1   | 2.1e-07 |      20 |
 | JSON::PP::encode_json         | json, serialize                       |     47800 |    20.9   |       16.4 | 6.5e-09 |      21 |
 | JSON::Tiny::encode_json       | json, serialize                       |     61000 |    16.4   |       21   | 6.7e-09 |      20 |
 | YAML::Syck::Dump              | yaml, serialize                       |     89000 |    11     |       30   | 1.3e-08 |      20 |
 | YAML::XS::Dump                | yaml, serialize                       |    110000 |     8.9   |       38   | 1.3e-08 |      20 |
 | Storable::freeze              | binary, serialize, cant_handle_scalar |    240000 |     4.1   |       83   | 8.3e-09 |      20 |
 | Sereal::encode_sereal         | binary, serialize                     |   1240000 |     0.809 |      425   |   4e-10 |      26 |
 | JSON::MaybeXS::encode_json    | json, serialize                       |   1200000 |     0.81  |      430   | 1.7e-09 |      20 |
 | Cpanel::JSON::XS::encode_json | json, serialize                       |   1290000 |     0.776 |      443   | 4.5e-10 |      20 |
 | JSON::XS::encode_json         | json, serialize                       |   1383000 |     0.723 |      475.4 | 1.1e-11 |      27 |
 | Data::MessagePack::pack       | binary, serialize                     |   1600000 |     0.63  |      540   | 8.1e-10 |      21 |
 | JSON::Create::create_json     | json, serialize                       |   1640000 |     0.611 |      562   |   2e-10 |      22 |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"array_int_100"}
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | p_tags                                | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize                       |    360    |  2.78     |     1      | 2.7e-06 |      20 |
 | JSON::PP::encode_json         | json, serialize                       |   5950    |  0.168    |    16.5    | 1.6e-07 |      20 |
 | JSON::Tiny::encode_json       | json, serialize                       |   9656.91 |  0.103553 |    26.8362 | 1.2e-11 |      27 |
 | YAML::Syck::Dump              | yaml, serialize                       |  17000    |  0.06     |    47      |   1e-07 |      22 |
 | YAML::XS::Dump                | yaml, serialize                       |  17000    |  0.0589   |    47.2    | 2.5e-08 |      22 |
 | Storable::freeze              | binary, serialize, cant_handle_scalar | 110000    |  0.0091   |   310      | 1.7e-08 |      20 |
 | JSON::MaybeXS::encode_json    | json, serialize                       | 200000    |  0.0051   |   540      | 1.3e-08 |      20 |
 | Cpanel::JSON::XS::encode_json | json, serialize                       | 200000    |  0.005    |   560      | 6.7e-09 |      20 |
 | JSON::XS::encode_json         | json, serialize                       | 210000    |  0.0048   |   580      | 6.7e-09 |      20 |
 | JSON::Create::create_json     | json, serialize                       | 260000    |  0.00385  |   722      | 1.6e-09 |      23 |
 | Sereal::encode_sereal         | binary, serialize                     | 275700    |  0.003627 |   766.2    | 5.8e-11 |      27 |
 | Data::MessagePack::pack       | binary, serialize                     | 280000    |  0.00357  |   779      | 1.5e-09 |      26 |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"array_int_1000"}
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | p_tags                                | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize                       |      37.1 | 26.9      |       1    | 9.4e-06 |      20 |
 | JSON::PP::encode_json         | json, serialize                       |     630   |  1.6      |      17    | 4.7e-06 |      20 |
 | JSON::Tiny::encode_json       | json, serialize                       |     992   |  1.01     |      26.7  | 6.9e-07 |      20 |
 | YAML::Syck::Dump              | yaml, serialize                       |    1700   |  0.59     |      46    | 1.1e-06 |      20 |
 | YAML::XS::Dump                | yaml, serialize                       |    1800   |  0.56     |      48    | 1.8e-06 |      21 |
 | Storable::freeze              | binary, serialize, cant_handle_scalar |   15000   |  0.067    |     400    | 1.1e-07 |      20 |
 | JSON::MaybeXS::encode_json    | json, serialize                       |   21500   |  0.0466   |     578    | 1.3e-08 |      21 |
 | Cpanel::JSON::XS::encode_json | json, serialize                       |   22300   |  0.0448   |     601    | 1.3e-08 |      20 |
 | JSON::XS::encode_json         | json, serialize                       |   22357   |  0.044728 |     602.44 | 4.6e-11 |      20 |
 | JSON::Create::create_json     | json, serialize                       |   25000   |  0.04     |     680    | 5.3e-08 |      20 |
 | Sereal::encode_sereal         | binary, serialize                     |   30000   |  0.033    |     820    |   4e-08 |      20 |
 | Data::MessagePack::pack       | binary, serialize                     |   30500   |  0.0327   |     823    | 1.2e-08 |      23 |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"array_str1k_10"}
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | p_tags                                | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize                       |    2300   |  430      |    1       | 4.8e-07 |      20 |
 | YAML::XS::Dump                | yaml, serialize                       |    7170   |  139      |    3.05    | 4.7e-08 |      26 |
 | JSON::PP::encode_json         | json, serialize                       |   11200   |   89.5    |    4.76    | 2.5e-08 |      22 |
 | JSON::Tiny::encode_json       | json, serialize                       |   18000   |   55.6    |    7.65    | 2.4e-08 |      24 |
 | YAML::Syck::Dump              | yaml, serialize                       |   20477.2 |   48.8347 |    8.71691 | 1.1e-11 |      20 |
 | JSON::Create::create_json     | json, serialize                       |   41300   |   24.2    |   17.6     | 6.1e-09 |      24 |
 | JSON::MaybeXS::encode_json    | json, serialize                       |   44000   |   23      |   19       | 2.7e-08 |      20 |
 | Cpanel::JSON::XS::encode_json | json, serialize                       |   45000   |   22      |   19       | 2.7e-08 |      20 |
 | JSON::XS::encode_json         | json, serialize                       |   47100   |   21.2    |   20       | 5.4e-09 |      30 |
 | Storable::freeze              | binary, serialize, cant_handle_scalar |  182000   |    5.48   |   77.7     |   5e-09 |      20 |
 | Sereal::encode_sereal         | binary, serialize                     |  330000   |    3.03   |  140       | 8.3e-10 |      20 |
 | Data::MessagePack::pack       | binary, serialize                     |  349000   |    2.87   |  148       | 2.4e-09 |      22 |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"array_ustr1k_10"}
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | p_tags                                | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize                       |    1000   |  999      |     1      | 4.8e-07 |      20 |
 | JSON::Tiny::encode_json       | json, serialize                       |    1090   |  916      |     1.09   | 6.9e-07 |      20 |
 | JSON::PP::encode_json         | json, serialize                       |    2050   |  488      |     2.05   | 5.3e-08 |      20 |
 | YAML::XS::Dump                | yaml, serialize                       |    3100   |  330      |     3.1    | 1.2e-06 |      25 |
 | JSON::MaybeXS::encode_json    | json, serialize                       |    3520   |  284      |     3.52   | 2.1e-07 |      20 |
 | JSON::XS::encode_json         | json, serialize                       |    3520   |  284      |     3.52   | 2.1e-07 |      20 |
 | Cpanel::JSON::XS::encode_json | json, serialize                       |    3620   |  276      |     3.62   | 5.3e-08 |      20 |
 | YAML::Syck::Dump              | yaml, serialize                       |    7350   |  136      |     7.34   | 4.4e-08 |      30 |
 | JSON::Create::create_json     | json, serialize                       |   14807.4 |   67.5336 |    14.7914 | 1.1e-11 |      22 |
 | Storable::freeze              | binary, serialize, cant_handle_scalar |  125000   |    8.02   |   125      | 3.3e-09 |      20 |
 | Sereal::encode_sereal         | binary, serialize                     |  182000   |    5.49   |   182      |   5e-09 |      20 |
 | Data::MessagePack::pack       | binary, serialize                     |  240000   |    4.3    |   240      | 6.7e-09 |      20 |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"hash_int_10"}
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | p_tags                                | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize                       |      2350 |   426     |      1     | 2.7e-07 |      20 |
 | JSON::PP::encode_json         | json, serialize                       |     21000 |    48     |      8.9   | 5.3e-08 |      20 |
 | JSON::Tiny::encode_json       | json, serialize                       |     30959 |    32.301 |     13.187 | 5.8e-11 |      23 |
 | YAML::Syck::Dump              | yaml, serialize                       |     55300 |    18.1   |     23.5   | 6.7e-09 |      20 |
 | YAML::XS::Dump                | yaml, serialize                       |     61000 |    16     |     26     |   6e-08 |      20 |
 | Storable::freeze              | binary, serialize, cant_handle_scalar |    149000 |     6.72  |     63.4   | 3.3e-09 |      20 |
 | JSON::MaybeXS::encode_json    | json, serialize                       |    400000 |     2.5   |    170     | 3.3e-09 |      20 |
 | Cpanel::JSON::XS::encode_json | json, serialize                       |    412000 |     2.43  |    175     | 7.8e-10 |      23 |
 | Data::MessagePack::pack       | binary, serialize                     |    440000 |     2.3   |    190     | 3.3e-09 |      20 |
 | Sereal::encode_sereal         | binary, serialize                     |    440000 |     2.2   |    190     | 3.3e-09 |      20 |
 | JSON::XS::encode_json         | json, serialize                       |    538000 |     1.86  |    229     | 7.9e-10 |      22 |
 | JSON::Create::create_json     | json, serialize                       |    580000 |     1.7   |    250     | 2.5e-09 |      20 |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"hash_int_100"}
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | p_tags                                | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize                       |       282 |     3.54  |        1   | 2.5e-06 |      20 |
 | JSON::PP::encode_json         | json, serialize                       |      2400 |     0.42  |        8.4 | 1.1e-06 |      20 |
 | JSON::Tiny::encode_json       | json, serialize                       |      3930 |     0.255 |       13.9 | 2.1e-07 |      21 |
 | YAML::Syck::Dump              | yaml, serialize                       |      7310 |     0.137 |       25.9 | 5.3e-08 |      20 |
 | YAML::XS::Dump                | yaml, serialize                       |      7500 |     0.13  |       26   | 2.1e-07 |      20 |
 | Storable::freeze              | binary, serialize, cant_handle_scalar |     43000 |     0.023 |      150   | 2.7e-08 |      20 |
 | JSON::MaybeXS::encode_json    | json, serialize                       |     45000 |     0.022 |      160   | 2.3e-08 |      26 |
 | Cpanel::JSON::XS::encode_json | json, serialize                       |     47000 |     0.021 |      170   | 4.6e-08 |      21 |
 | Sereal::encode_sereal         | binary, serialize                     |     47000 |     0.021 |      170   | 5.2e-08 |      21 |
 | Data::MessagePack::pack       | binary, serialize                     |     48000 |     0.021 |      170   | 2.4e-08 |      25 |
 | JSON::XS::encode_json         | json, serialize                       |     59000 |     0.017 |      210   |   2e-08 |      21 |
 | JSON::Create::create_json     | json, serialize                       |     64000 |     0.016 |      230   | 2.7e-08 |      20 |
 +-------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"hash_int_1000"}
 +-------------------------------+---------------------------------------+-----------+------------+------------+---------+---------+
 | participant                   | p_tags                                | rate (/s) | time (ms)  | vs_slowest |  errors | samples |
 +-------------------------------+---------------------------------------+-----------+------------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize                       |    28.8   | 34.7       |     1      | 1.8e-05 |      20 |
 | JSON::PP::encode_json         | json, serialize                       |   246     |  4.07      |     8.53   | 3.4e-06 |      20 |
 | JSON::Tiny::encode_json       | json, serialize                       |   398     |  2.51      |    13.8    | 1.3e-06 |      20 |
 | YAML::Syck::Dump              | yaml, serialize                       |   692     |  1.44      |    24      | 1.1e-06 |      21 |
 | YAML::XS::Dump                | yaml, serialize                       |   720     |  1.4       |    25      | 3.6e-06 |      20 |
 | Sereal::encode_sereal         | binary, serialize                     |  3900     |  0.257     |   135      |   2e-07 |      23 |
 | Cpanel::JSON::XS::encode_json | json, serialize                       |  4100     |  0.25      |   140      | 2.6e-07 |      21 |
 | JSON::MaybeXS::encode_json    | json, serialize                       |  4080     |  0.245     |   142      | 1.6e-07 |      20 |
 | Storable::freeze              | binary, serialize, cant_handle_scalar |  4387.74  |  0.2279078 |   152.1144 | 1.1e-11 |      20 |
 | Data::MessagePack::pack       | binary, serialize                     |  4450     |  0.225     |   154      | 1.6e-07 |      20 |
 | JSON::XS::encode_json         | json, serialize                       |  5100     |  0.2       |   180      | 2.1e-07 |      20 |
 | JSON::Create::create_json     | json, serialize                       |  5360.643 |  0.1865448 |   185.8431 | 1.1e-11 |      21 |
 +-------------------------------+---------------------------------------+-----------+------------+------------+---------+---------+

 #table9#
 {dataset=>"num"}
 +-------------------------------+-------------------+-----------+-----------+------------+---------+---------+
 | participant                   | p_tags            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize   |   14380.5 |   69.5385 |        1   | 1.2e-11 |      22 |
 | JSON::Tiny::encode_json       | json, serialize   |  151000   |    6.61   |       10.5 | 2.8e-09 |      28 |
 | YAML::Syck::Dump              | yaml, serialize   |  152000   |    6.58   |       10.6 | 3.2e-09 |      22 |
 | YAML::XS::Dump                | yaml, serialize   |  230000   |    4.4    |       16   | 6.7e-09 |      20 |
 | JSON::PP::encode_json         | json, serialize   |  240000   |    4.16   |       16.7 | 1.7e-09 |      20 |
 | JSON::MaybeXS::encode_json    | json, serialize   | 1500000   |    0.67   |      100   | 8.4e-10 |      20 |
 | JSON::XS::encode_json         | json, serialize   | 1500000   |    0.65   |      110   | 8.1e-10 |      21 |
 | Cpanel::JSON::XS::encode_json | json, serialize   | 1500000   |    0.65   |      110   | 8.3e-10 |      20 |
 | JSON::Create::create_json     | json, serialize   | 2300000   |    0.434  |      160   | 2.1e-10 |      20 |
 | Sereal::encode_sereal         | binary, serialize | 3000000   |    0.34   |      210   |   9e-10 |      27 |
 | Data::MessagePack::pack       | binary, serialize | 4210000   |    0.238  |      293   |   1e-10 |      20 |
 +-------------------------------+-------------------+-----------+-----------+------------+---------+---------+

 #table10#
 {dataset=>"str1k"}
 +-------------------------------+--------------------+-------------------+-----------+------------+------------+---------+---------+
 | participant                   | ds_tags            | p_tags            | rate (/s) | time (μs)  | vs_slowest |  errors | samples |
 +-------------------------------+--------------------+-------------------+-----------+------------+------------+---------+---------+
 | YAML::Old::Dump               | serialize, unicode | yaml, serialize   |      7790 | 128        |      1     |   5e-08 |      23 |
 | JSON::Tiny::encode_json       | serialize, unicode | json, serialize   |     10300 |  97.3      |      1.32  |   8e-08 |      20 |
 | YAML::Old::Dump               | serialize          | yaml, serialize   |     14000 |  70        |      1.8   | 1.1e-07 |      20 |
 | JSON::PP::encode_json         | serialize, unicode | json, serialize   |     20100 |  49.8      |      2.58  |   4e-08 |      20 |
 | JSON::XS::encode_json         | serialize, unicode | json, serialize   |     22000 |  45        |      2.9   | 2.7e-07 |      20 |
 | JSON::MaybeXS::encode_json    | serialize, unicode | json, serialize   |     23000 |  43.5      |      2.95  | 1.3e-08 |      21 |
 | Cpanel::JSON::XS::encode_json | serialize, unicode | json, serialize   |     23800 |  41.9      |      3.06  |   4e-08 |      20 |
 | YAML::XS::Dump                | serialize, unicode | yaml, serialize   |     30000 |  34        |      3.8   | 5.2e-08 |      21 |
 | YAML::Syck::Dump              | serialize, unicode | yaml, serialize   |     56400 |  17.7      |      7.24  | 5.7e-09 |      27 |
 | YAML::XS::Dump                | serialize          | yaml, serialize   |     63400 |  15.8      |      8.14  | 5.5e-09 |      29 |
 | JSON::PP::encode_json         | serialize          | json, serialize   |     98600 |  10.1      |     12.7   | 3.1e-09 |      23 |
 | YAML::Syck::Dump              | serialize          | yaml, serialize   |    109000 |   9.21     |     13.9   | 3.2e-09 |      22 |
 | JSON::Tiny::encode_json       | serialize          | json, serialize   |    121000 |   8.27     |     15.5   | 2.8e-09 |      28 |
 | JSON::Create::create_json     | serialize, unicode | json, serialize   |    147000 |   6.82     |     18.8   | 3.3e-09 |      20 |
 | JSON::Create::create_json     | serialize          | json, serialize   |    382000 |   2.62     |     49     | 8.3e-10 |      20 |
 | JSON::MaybeXS::encode_json    | serialize          | json, serialize   |    410000 |   2.5      |     52     | 3.2e-09 |      22 |
 | Cpanel::JSON::XS::encode_json | serialize          | json, serialize   |    420000 |   2.4      |     54     | 3.3e-09 |      20 |
 | JSON::XS::encode_json         | serialize          | json, serialize   |    440000 |   2.3      |     56     | 3.3e-09 |      20 |
 | Sereal::encode_sereal         | serialize, unicode | binary, serialize |   2040000 |   0.489    |    262     | 2.1e-10 |      21 |
 | Data::MessagePack::pack       | serialize, unicode | binary, serialize |   2198930 |   0.454767 |    282.13  |   0     |      20 |
 | Sereal::encode_sereal         | serialize          | binary, serialize |   2460000 |   0.407    |    315     | 5.8e-11 |      20 |
 | Data::MessagePack::pack       | serialize          | binary, serialize |   2501780 |   0.399716 |    320.987 |   0     |      21 |
 +-------------------------------+--------------------+-------------------+-----------+------------+------------+---------+---------+

 #table11#
 {dataset=>"undef"}
 +-------------------------------+-------------------+-----------+-----------+------------+---------+---------+
 | participant                   | p_tags            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-------------------+-----------+-----------+------------+---------+---------+
 | YAML::Old::Dump               | yaml, serialize   |     17000 |   59      |        1   |   8e-08 |      20 |
 | YAML::Syck::Dump              | yaml, serialize   |    194000 |    5.15   |       11.5 | 1.7e-09 |      20 |
 | JSON::Tiny::encode_json       | json, serialize   |    278000 |    3.6    |       16.4 | 1.3e-09 |      32 |
 | JSON::PP::encode_json         | json, serialize   |    420000 |    2.4    |       25   | 3.4e-09 |      20 |
 | YAML::XS::Dump                | yaml, serialize   |    427000 |    2.34   |       25.2 | 8.3e-10 |      20 |
 | Sereal::encode_sereal         | binary, serialize |   3400000 |    0.3    |      200   | 4.2e-10 |      20 |
 | JSON::MaybeXS::encode_json    | json, serialize   |   4100000 |    0.244  |      242   | 1.1e-10 |      24 |
 | Cpanel::JSON::XS::encode_json | json, serialize   |   4280000 |    0.233  |      253   | 1.1e-10 |      20 |
 | Data::MessagePack::pack       | binary, serialize |   4850000 |    0.206  |      286   |   1e-10 |      20 |
 | JSON::XS::encode_json         | json, serialize   |   5044000 |    0.1983 |      297.6 | 1.1e-11 |      20 |
 | JSON::Create::create_json     | json, serialize   |   5900000 |    0.17   |      350   | 3.9e-10 |      36 |
 +-------------------------------+-------------------+-----------+-----------+------------+---------+---------+


Benchmark deserializing (C<< bencher -m Serializers --include-participant-tags deserialize >>):

 #table12#
 {dataset=>"json:array_int_10"}
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | p_tags                                | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Marpa::from_json     | json, deserialize, cant_handle_scalar |      1090 |  914      |       1    | 8.5e-07 |      20 |
 | Pegex::JSON                        | json, deserialize                     |      1390 |  717      |       1.27 | 4.3e-07 |      20 |
 | MarpaX::ESLIF::ECMA404::decode     | json, deserialize                     |      4700 |  210      |       4.3  | 6.2e-07 |      21 |
 | JSON::PP::decode_json              | json, deserialize                     |     20600 |   48.6    |      18.8  | 1.3e-08 |      20 |
 | JSON::Tiny::decode_json            | json, deserialize                     |     30500 |   32.8    |      27.9  | 1.3e-08 |      20 |
 | JSON::Decode::Regexp::from_json    | json, deserialize                     |     30800 |   32.5    |      28.1  | 1.3e-08 |      20 |
 | PERLANCAR::JSON::Match::match_json | json, deserialize                     |     65300 |   15.3    |      59.7  | 6.5e-09 |      21 |
 | JSON::MaybeXS::decode_json         | json, deserialize                     |   1520000 |    0.658  |    1390    | 2.1e-10 |      20 |
 | JSON::XS::decode_json              | json, deserialize                     |   1530000 |    0.653  |    1400    | 1.9e-10 |      24 |
 | Cpanel::JSON::XS::decode_json      | json, deserialize                     |   1540000 |    0.651  |    1400    | 6.2e-10 |      20 |
 | JSON::Parse::parse_json            | json, deserialize                     |   1547000 |    0.6465 |    1414    | 1.2e-11 |      21 |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table13#
 {dataset=>"json:array_int_100"}
 +------------------------------------+---------------------------------------+------------+-----------+------------+---------+---------+
 | participant                        | p_tags                                | rate (/s)  | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+---------------------------------------+------------+-----------+------------+---------+---------+
 | Pegex::JSON                        | json, deserialize                     |    282     | 3.54      |    1       | 1.6e-06 |      20 |
 | JSON::Decode::Marpa::from_json     | json, deserialize, cant_handle_scalar |    360     | 2.8       |    1.3     | 3.1e-06 |      20 |
 | MarpaX::ESLIF::ECMA404::decode     | json, deserialize                     |    790     | 1.3       |    2.8     | 3.8e-06 |      20 |
 | JSON::PP::decode_json              | json, deserialize                     |   2230     | 0.449     |    7.9     | 2.1e-07 |      20 |
 | JSON::Decode::Regexp::from_json    | json, deserialize                     |   3801.717 | 0.263039  |   13.46595 | 1.1e-11 |      20 |
 | JSON::Tiny::decode_json            | json, deserialize                     |   4800     | 0.21      |   17       | 2.5e-07 |      22 |
 | PERLANCAR::JSON::Match::match_json | json, deserialize                     |   7620     | 0.131     |   27       | 4.7e-08 |      26 |
 | JSON::Parse::parse_json            | json, deserialize                     | 253140     | 0.0039504 |  896.65    | 1.1e-11 |      30 |
 | Cpanel::JSON::XS::decode_json      | json, deserialize                     | 265000     | 0.00378   |  938       | 1.7e-09 |      20 |
 | JSON::XS::decode_json              | json, deserialize                     | 266180     | 0.0037569 |  942.81    | 3.5e-11 |      28 |
 | JSON::MaybeXS::decode_json         | json, deserialize                     | 273000     | 0.00366   |  967       | 1.7e-09 |      20 |
 +------------------------------------+---------------------------------------+------------+-----------+------------+---------+---------+

 #table14#
 {dataset=>"json:array_int_1000"}
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | p_tags                                | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | Pegex::JSON                        | json, deserialize                     |      30.8 | 32.5      |       1    | 1.5e-05 |      20 |
 | JSON::Decode::Marpa::from_json     | json, deserialize, cant_handle_scalar |      44.3 | 22.6      |       1.44 |   1e-05 |      20 |
 | MarpaX::ESLIF::ECMA404::decode     | json, deserialize                     |      87   | 11.5      |       2.83 | 4.7e-06 |      20 |
 | JSON::PP::decode_json              | json, deserialize                     |     205   |  4.88     |       6.66 | 2.7e-06 |      20 |
 | JSON::Decode::Regexp::from_json    | json, deserialize                     |     390   |  2.56     |      12.7  | 1.6e-06 |      20 |
 | JSON::Tiny::decode_json            | json, deserialize                     |     510   |  2        |      17    | 2.5e-06 |      20 |
 | PERLANCAR::JSON::Match::match_json | json, deserialize                     |     780   |  1.3      |      25    | 1.5e-06 |      20 |
 | Cpanel::JSON::XS::decode_json      | json, deserialize                     |   31300   |  0.032    |    1020    | 9.8e-09 |      37 |
 | JSON::MaybeXS::decode_json         | json, deserialize                     |   31281   |  0.031968 |    1016    | 3.5e-11 |      30 |
 | JSON::XS::decode_json              | json, deserialize                     |   31500   |  0.0318   |    1020    | 1.2e-08 |      24 |
 | JSON::Parse::parse_json            | json, deserialize                     |   31916   |  0.031332 |    1036.6  | 3.5e-11 |      22 |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table15#
 {dataset=>"json:array_str1k_10"}
 +------------------------------------+---------------------------------------+-----------+------------+------------+---------+---------+
 | participant                        | p_tags                                | rate (/s) | time (ms)  | vs_slowest |  errors | samples |
 +------------------------------------+---------------------------------------+-----------+------------+------------+---------+---------+
 | MarpaX::ESLIF::ECMA404::decode     | json, deserialize                     |      25.4 | 39.4       |      1     | 2.4e-05 |      21 |
 | JSON::Decode::Marpa::from_json     | json, deserialize, cant_handle_scalar |      97   | 10         |      3.8   | 1.1e-05 |      20 |
 | JSON::PP::decode_json              | json, deserialize                     |     144   |  6.94      |      5.68  | 5.8e-06 |      20 |
 | Pegex::JSON                        | json, deserialize                     |     765   |  1.31      |     30.1   | 4.3e-07 |      20 |
 | JSON::Tiny::decode_json            | json, deserialize                     |    1440   |  0.694     |     56.8   | 2.7e-07 |      20 |
 | JSON::Decode::Regexp::from_json    | json, deserialize                     |   11114.6 |  0.0899721 |    438.126 | 1.1e-11 |      22 |
 | PERLANCAR::JSON::Match::match_json | json, deserialize                     |   15300   |  0.0652    |    604     | 2.7e-08 |      20 |
 | JSON::Parse::parse_json            | json, deserialize                     |   37033   |  0.027003  |   1459.8   | 2.4e-10 |      31 |
 | Cpanel::JSON::XS::decode_json      | json, deserialize                     |   52488.4 |  0.0190518 |   2069.05  | 1.2e-11 |      22 |
 | JSON::MaybeXS::decode_json         | json, deserialize                     |   52700   |  0.019     |   2080     | 6.1e-09 |      24 |
 | JSON::XS::decode_json              | json, deserialize                     |   68400   |  0.0146    |   2700     | 6.4e-09 |      22 |
 +------------------------------------+---------------------------------------+-----------+------------+------------+---------+---------+

 #table16#
 {dataset=>"json:hash_int_10"}
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | p_tags                                | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | JSON::Decode::Marpa::from_json     | json, deserialize, cant_handle_scalar |     822   | 1220      |     1      | 4.8e-07 |      20 |
 | Pegex::JSON                        | json, deserialize                     |    1020   |  980      |     1.24   | 8.5e-07 |      20 |
 | MarpaX::ESLIF::ECMA404::decode     | json, deserialize                     |    2300   |  430      |     2.8    | 9.1e-07 |      20 |
 | JSON::PP::decode_json              | json, deserialize                     |   10300   |   96.8    |    12.6    | 2.7e-08 |      20 |
 | JSON::Decode::Regexp::from_json    | json, deserialize                     |   14902.4 |   67.1033 |    18.1268 |   1e-11 |      21 |
 | JSON::Tiny::decode_json            | json, deserialize                     |   14946   |   66.909  |    18.18   | 1.8e-10 |      21 |
 | PERLANCAR::JSON::Match::match_json | json, deserialize                     |   42100   |   23.8    |    51.2    | 6.7e-09 |      20 |
 | JSON::MaybeXS::decode_json         | json, deserialize                     |  806000   |    1.24   |   980      | 4.2e-10 |      20 |
 | Cpanel::JSON::XS::decode_json      | json, deserialize                     |  810000   |    1.23   |   985      | 4.2e-10 |      20 |
 | JSON::XS::decode_json              | json, deserialize                     |  860000   |    1.2    |  1100      | 1.2e-09 |      20 |
 | JSON::Parse::parse_json            | json, deserialize                     |  883000   |    1.13   |  1070      | 3.9e-10 |      23 |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table17#
 {dataset=>"json:hash_int_100"}
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | p_tags                                | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | Pegex::JSON                        | json, deserialize                     |       163 |     6.15  |       1    | 4.6e-06 |      21 |
 | JSON::Decode::Marpa::from_json     | json, deserialize, cant_handle_scalar |       179 |     5.59  |       1.1  | 4.4e-06 |      20 |
 | MarpaX::ESLIF::ECMA404::decode     | json, deserialize                     |       280 |     3.57  |       1.72 | 2.5e-06 |      20 |
 | JSON::PP::decode_json              | json, deserialize                     |      1030 |     0.97  |       6.34 | 6.4e-07 |      20 |
 | JSON::Decode::Regexp::from_json    | json, deserialize                     |      1640 |     0.611 |      10.1  | 2.7e-07 |      20 |
 | JSON::Tiny::decode_json            | json, deserialize                     |      1820 |     0.55  |      11.2  | 2.1e-07 |      20 |
 | PERLANCAR::JSON::Match::match_json | json, deserialize                     |      4500 |     0.22  |      28    | 2.7e-07 |      20 |
 | Cpanel::JSON::XS::decode_json      | json, deserialize                     |     85000 |     0.012 |     520    | 5.7e-08 |      20 |
 | JSON::Parse::parse_json            | json, deserialize                     |     88000 |     0.011 |     540    | 1.3e-08 |      20 |
 | JSON::MaybeXS::decode_json         | json, deserialize                     |     88000 |     0.011 |     540    | 1.2e-08 |      26 |
 | JSON::XS::decode_json              | json, deserialize                     |     90600 |     0.011 |     557    |   1e-08 |      20 |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table18#
 {dataset=>"json:hash_int_1000"}
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | p_tags                                | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+
 | Pegex::JSON                        | json, deserialize                     |      17.1 |     58.5  |       1    | 5.8e-05 |      20 |
 | JSON::Decode::Marpa::from_json     | json, deserialize, cant_handle_scalar |      20   |     51    |       1.1  | 6.1e-05 |      21 |
 | MarpaX::ESLIF::ECMA404::decode     | json, deserialize                     |      25   |     41    |       1.4  | 5.1e-05 |      21 |
 | JSON::PP::decode_json              | json, deserialize                     |      98   |     10.2  |       5.73 | 6.7e-06 |      20 |
 | JSON::Decode::Regexp::from_json    | json, deserialize                     |     150   |      6.6  |       8.8  | 8.1e-06 |      20 |
 | JSON::Tiny::decode_json            | json, deserialize                     |     186   |      5.39 |      10.8  | 2.2e-06 |      20 |
 | PERLANCAR::JSON::Match::match_json | json, deserialize                     |     440   |      2.3  |      26    | 3.1e-06 |      20 |
 | Cpanel::JSON::XS::decode_json      | json, deserialize                     |    6800   |      0.15 |     400    | 4.8e-07 |      20 |
 | JSON::MaybeXS::decode_json         | json, deserialize                     |    6900   |      0.15 |     400    | 2.1e-07 |      20 |
 | JSON::Parse::parse_json            | json, deserialize                     |    7000   |      0.14 |     410    | 2.1e-07 |      20 |
 | JSON::XS::decode_json              | json, deserialize                     |    7200   |      0.14 |     420    | 1.9e-07 |      24 |
 +------------------------------------+---------------------------------------+-----------+-----------+------------+---------+---------+

 #table19#
 {dataset=>"json:null"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | Pegex::JSON                        |      2540 |  394      |        1   | 2.6e-07 |      21 |
 | MarpaX::ESLIF::ECMA404::decode     |     13000 |   77      |        5.1 | 1.3e-07 |      22 |
 | JSON::Tiny::decode_json            |    110000 |    9.4    |       42   | 1.7e-08 |      20 |
 | JSON::PP::decode_json              |    160000 |    6.1    |       64   | 1.5e-08 |      20 |
 | JSON::Decode::Regexp::from_json    |    248000 |    4.04   |       97.6 | 1.7e-09 |      20 |
 | PERLANCAR::JSON::Match::match_json |    456000 |    2.19   |      180   | 8.3e-10 |      20 |
 | JSON::MaybeXS::decode_json         |   7289000 |    0.1372 |     2875   | 1.2e-11 |      22 |
 | Cpanel::JSON::XS::decode_json      |   7330000 |    0.136  |     2890   | 9.6e-11 |      24 |
 | JSON::XS::decode_json              |   7518000 |    0.133  |     2965   | 1.1e-11 |      20 |
 | JSON::Parse::parse_json            |   9000000 |    0.111  |     3550   | 6.6e-11 |      26 |
 +------------------------------------+-----------+-----------+------------+---------+---------+

 #table20#
 {dataset=>"json:num"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | Pegex::JSON                        |      2640 |    379    |        1   | 2.1e-07 |      21 |
 | MarpaX::ESLIF::ECMA404::decode     |     13000 |     79    |        4.8 | 1.3e-07 |      20 |
 | JSON::Tiny::decode_json            |     78800 |     12.7  |       29.8 | 6.5e-09 |      21 |
 | JSON::PP::decode_json              |     84000 |     11.9  |       31.8 | 3.2e-09 |      22 |
 | JSON::Decode::Regexp::from_json    |    150000 |      6.6  |       57   | 1.1e-08 |      27 |
 | PERLANCAR::JSON::Match::match_json |    259000 |      3.86 |       98.1 | 1.7e-09 |      20 |
 | Cpanel::JSON::XS::decode_json      |    960000 |      1    |      360   | 1.7e-09 |      20 |
 | JSON::MaybeXS::decode_json         |    970000 |      1    |      370   | 1.2e-09 |      20 |
 | JSON::XS::decode_json              |    980000 |      1    |      370   | 1.7e-09 |      20 |
 | JSON::Parse::parse_json            |   1200000 |      0.87 |      440   | 1.7e-09 |      20 |
 +------------------------------------+-----------+-----------+------------+---------+---------+

 #table21#
 {dataset=>"json:str1k"}
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | MarpaX::ESLIF::ECMA404::decode     |       269 | 3.71      |      1     | 3.7e-06 |      21 |
 | JSON::PP::decode_json              |      1430 | 0.699     |      5.31  |   2e-07 |      22 |
 | Pegex::JSON                        |      2300 | 0.44      |      8.5   | 1.6e-06 |      20 |
 | JSON::Tiny::decode_json            |     12900 | 0.077517  |     47.911 | 1.4e-10 |      33 |
 | JSON::Decode::Regexp::from_json    |     96901 | 0.01032   |    359.88  | 1.2e-11 |      22 |
 | PERLANCAR::JSON::Match::match_json |    136000 | 0.00736   |    505     | 2.8e-09 |      29 |
 | JSON::Parse::parse_json            |    372700 | 0.002683  |   1384     | 5.5e-11 |      22 |
 | JSON::MaybeXS::decode_json         |    525000 | 0.001905  |   1950     | 3.4e-11 |      20 |
 | Cpanel::JSON::XS::decode_json      |    527370 | 0.0018962 |   1958.6   | 1.1e-11 |      26 |
 | JSON::XS::decode_json              |    684590 | 0.0014607 |   2542.5   | 1.1e-11 |      20 |
 +------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m Serializers --module-startup >>):

 #table22#
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant            | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | JSON::Decode::Marpa    | 1                            | 5                  | 20             |       200 |                    190 |        1   |   0.0069  |      20 |
 | YAML::XS               | 1                            | 4.5                | 22             |        58 |                     48 |        2.9 |   0.00051 |      20 |
 | JSON::PP               | 3                            | 7                  | 30             |        40 |                     30 |        4   |   0.0007  |      20 |
 | Pegex::JSON            | 1.9                          | 5.4                | 27             |        28 |                     18 |        6   |   0.00016 |      20 |
 | JSON::Tiny             | 2.3                          | 5.7                | 25             |        25 |                     15 |        6.8 | 9.7e-05   |      20 |
 | JSON::MaybeXS          | 1                            | 5                  | 20             |        20 |                     10 |        7   |   0.00031 |      21 |
 | Sereal                 | 1.5                          | 6                  | 29             |        19 |                      9 |        8.6 |   0.00017 |      20 |
 | YAML::Old              | 20                           | 20                 | 50             |        20 |                     10 |        9   |   0.00026 |      21 |
 | Storable               | 1.3                          | 4.8                | 22             |        19 |                      9 |        8.8 |   5e-05   |      20 |
 | MarpaX::ESLIF::ECMA404 | 0.82                         | 4.1                | 20             |        19 |                      9 |        8.9 |   0.00016 |      21 |
 | JSON::Parse            | 1                            | 4                  | 20             |        20 |                     10 |       10   |   0.00026 |      21 |
 | YAML::Syck             | 2                            | 6                  | 20             |        20 |                     10 |       10   |   0.00021 |      21 |
 | JSON::Create           | 2                            | 5                  | 30             |        20 |                     10 |       10   |   0.0002  |      20 |
 | Cpanel::JSON::XS       | 1.3                          | 4.8                | 24             |        16 |                      6 |       10   |   0.00015 |      20 |
 | JSON::XS               | 2.3                          | 5.8                | 25             |        16 |                      6 |       10   | 4.5e-05   |      21 |
 | JSON::Decode::Regexp   | 1.3                          | 4.8                | 24             |        12 |                      2 |       13   |   5e-05   |      20 |
 | Data::MessagePack      | 1.6                          | 5                  | 21             |        12 |                      2 |       14   | 2.6e-05   |      20 |
 | perl -e1 (baseline)    | 3                            | 7                  | 30             |        10 |                      0 |       20   |   0.00014 |      21 |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


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

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

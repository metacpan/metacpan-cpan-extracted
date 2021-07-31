package Bencher::Scenario::Serializers;

our $DATE = '2021-07-31'; # DATE
our $VERSION = '0.160'; # VERSION

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
            tags => ['json', 'serialize'],
            fcall_template => 'MarpaX::ESLIF::ECMA404->encode(<data>)',
        },
        {
            tags => ['json', 'deserialize'],
            fcall_template => 'MarpaX::ESLIF::ECMA404->decode(<data>)',
        },

        {
            tags => ['yaml', 'serialize'],
            fcall_template => 'YAML::Dump(<data>)',
        },
        {
            tags => ['yaml', 'deserialize'],
            fcall_template => 'YAML::Load(<data>)',
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
            tags => ['binary', 'storable', 'serialize', 'cant_handle_scalar'],
            fcall_template => 'Storable::freeze(<data>)',
        },
        {
            tags => ['binary', 'storable', 'deserialize', 'cant_handle_scalar'],
            fcall_template => 'Storable::thaw(<data>)',
        },

        {
            tags => ['binary', 'sereal', 'serialize'],
            fcall_template => 'Sereal::encode_sereal(<data>)',
        },
        {
            tags => ['binary', 'sereal', 'deserialize'],
            fcall_template => 'Sereal::decode_sereal(<data>)',
        },

        {
            name => 'Data::MessagePack::pack',
            tags => ['binary', 'msgpack', 'serialize'],
            module => 'Data::MessagePack',
            function => 'pack',
            code_template => 'state $obj = Data::MessagePack->new; $obj->pack(<data>)',
        },
        {
            name => 'Data::MessagePack::unpack',
            tags => ['binary', 'msgpack', 'deserialize'],
            module => 'Data::MessagePack',
            function => 'unpack',
            code_template => 'state $obj = Data::MessagePack->new; $obj->unpack(<data>)',
        },

        {
            name => 'eval()',
            tags => ['perl', 'deserialize'],
            code_template => 'eval(<data>)',
        },
        {
            name => 'Data::Undump',
            tags => ['perl', 'deserialize'],
            fcall_template => 'Data::Undump::undump(<data>)',
        },
        {
            name => 'Data::Undump::PPI',
            tags => ['perl', 'deserialize'],
            fcall_template => 'Data::Undump::PPI::Undump(<data>)',
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

        {
            name => 'sereal:hash_int_100',
            summary => 'A 100-key hash {1=>0, ..., 100=>0}',
            args => {data=>"=\xF3rl\3\0(*db26\0b63\0b95\0b35\0b13\0b41\0b33\0b73\0b84\0b85\0b94\0b24\0b12\0b72\0b99\0b71\0a6\0b64\0b70\0b50\0b83\0b68\0a8\0b15\0a9\0a5\0b67\0b25\0b10\0a4\0b56\0b89\0b16\0b90\0b66\0b59\0b29\0b54\0b44\0b27\0b77\0b81\0b32\0b37\0b74\0b65\0b36\0b11\0b18\0b86\0a7\0b17\0b21\0b14\0b28\0b47\0b20\0b76\0b98\0b40\0b91\0b75\0b97\0b31\0b55\0b80\0b19\0b92\0b82\0b43\0b30\0b78\0b57\0b38\0b23\0a3\0b69\0b88\0b61\0b51\0b39\0b42\0b58\0b93\0a2\0b62\0a1\0b79\0b34\0b45\0b87\0c100\0b96\0b22\0b49\0b60\0b52\0b53\0b46\0b48\0"},
            tags => ['deserialize'],
            include_participant_tags => ['sereal & deserialize'],
        },

        {
            name => 'perl:hash_int_100',
            summary => 'A 100-key hash {1=>0, ..., 100=>0}',
            args => {data=>'{'.join(',', map {qq($_=>0)} 1..100).'}'},
            tags => ['deserialize'],
            include_participant_tags => ['perl & deserialize'],
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

This document describes version 0.160 of Bencher::Scenario::Serializers (from Perl distribution Bencher-Scenario-Serializers), released on 2021-07-31.

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

L<JSON::PP> 4.06

L<JSON::Tiny> 0.58

L<JSON::XS> 4.03

L<Cpanel::JSON::XS> 4.26

L<JSON::MaybeXS> 1.004003

L<JSON::Decode::Regexp> 0.101

L<JSON::Decode::Marpa> 0.02

L<Pegex::JSON> 0.31

L<JSON::Create> 0.35

L<JSON::Parse> 0.61

L<MarpaX::ESLIF::ECMA404> 0.014

L<YAML> 1.30

L<YAML::Old> 1.23

L<YAML::Syck> 1.34

L<YAML::XS> 0.83

L<Storable> 3.23

L<Sereal> 4.018

L<Data::MessagePack> 1.01

L<Data::Undump> 0.15

L<Data::Undump::PPI> 0.06

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



=item * JSON::Decode::Marpa::from_json (perl_code) [json, deserialize, cant_handle_scalar]

Function call template:

 JSON::Decode::Marpa::from_json(<data>)



=item * Pegex::JSON (perl_code) [json, deserialize]

Code template:

 state $obj = Pegex::JSON->new; $obj->load(<data>);



=item * JSON::Create::create_json (perl_code) [json, serialize]

Function call template:

 JSON::Create::create_json(<data>)



=item * JSON::Parse::parse_json (perl_code) [json, deserialize]

Function call template:

 JSON::Parse::parse_json(<data>)



=item * MarpaX::ESLIF::ECMA404::encode (perl_code) [json, serialize]

Function call template:

 MarpaX::ESLIF::ECMA404->encode(<data>)



=item * MarpaX::ESLIF::ECMA404::decode (perl_code) [json, deserialize]

Function call template:

 MarpaX::ESLIF::ECMA404->decode(<data>)



=item * YAML::Dump (perl_code) [yaml, serialize]

Function call template:

 YAML::Dump(<data>)



=item * YAML::Load (perl_code) [yaml, deserialize]

Function call template:

 YAML::Load(<data>)



=item * YAML::Old::Dump (perl_code) [yaml, serialize]

Function call template:

 YAML::Old::Dump(<data>)



=item * YAML::Old::Load (perl_code) [yaml, deserialize]

Function call template:

 YAML::Old::Load(<data>)



=item * YAML::Syck::Dump (perl_code) [yaml, serialize]

Function call template:

 YAML::Syck::Dump(<data>)



=item * YAML::Syck::Load (perl_code) [yaml, deserialize]

Function call template:

 YAML::Syck::Load(<data>)



=item * YAML::XS::Dump (perl_code) [yaml, serialize]

Function call template:

 YAML::XS::Dump(<data>)



=item * YAML::XS::Load (perl_code) [yaml, deserialize]

Function call template:

 YAML::XS::Load(<data>)



=item * Storable::freeze (perl_code) [binary, storable, serialize, cant_handle_scalar]

Function call template:

 Storable::freeze(<data>)



=item * Storable::thaw (perl_code) [binary, storable, deserialize, cant_handle_scalar]

Function call template:

 Storable::thaw(<data>)



=item * Sereal::encode_sereal (perl_code) [binary, sereal, serialize]

Function call template:

 Sereal::encode_sereal(<data>)



=item * Sereal::decode_sereal (perl_code) [binary, sereal, deserialize]

Function call template:

 Sereal::decode_sereal(<data>)



=item * Data::MessagePack::pack (perl_code) [binary, msgpack, serialize]

Code template:

 state $obj = Data::MessagePack->new; $obj->pack(<data>)



=item * Data::MessagePack::unpack (perl_code) [binary, msgpack, deserialize]

Code template:

 state $obj = Data::MessagePack->new; $obj->unpack(<data>)



=item * eval() (perl_code) [perl, deserialize]

Code template:

 eval(<data>)



=item * Data::Undump (perl_code) [perl, deserialize]

Function call template:

 Data::Undump::undump(<data>)



=item * Data::Undump::PPI (perl_code) [perl, deserialize]

Function call template:

 Data::Undump::PPI::Undump(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * undef [serialize]

undef.

=item * num [serialize]

A single number (-1.23).

=item * str1k [serialize]

A non-Unicode string 1024 charactersE<sol>bytes long.

=item * str1k [serialize, unicode]

A Unicode string 1024 characters (3072-bytes) long.

=item * array_int_10 [serialize]

A 10-element array containing ints.

=item * array_int_100 [serialize]

A 100-element array containing ints.

=item * array_int_1000 [serialize]

A 1000-element array containing ints.

=item * array_str1k_10 [serialize]

A 10-element array containing 1024-charactersE<sol>bytes-long non-Unicode strings.

=item * array_ustr1k_10 [serialize, json]

A 10-element array containing 1024-characters-long (3072-bytes long) Unicode strings.

=item * hash_int_10 [serialize]

A 10-key hash {1=E<gt>0, ..., 10=E<gt>0}.

=item * hash_int_100 [serialize]

A 100-key hash {1=E<gt>0, ..., 100=E<gt>0}.

=item * hash_int_1000 [serialize]

A 1000-key hash {1=E<gt>0, ..., 1000=E<gt>0}.

=item * json:null [deserialize]

null.

=item * json:num [deserialize]

A single number (-1.23).

=item * json:str1k [deserialize]

A non-Unicode (ASCII) string 1024-charactersE<sol>bytes long.

=item * json:array_int_10 [deserialize]

A 10-element array containing ints.

=item * json:array_int_100 [deserialize]

A 10-element array containing ints.

=item * json:array_int_1000 [deserialize]

A 1000-element array containing ints.

=item * json:array_str1k_10 [deserialize]

A 10-element array containing 1024-charactersE<sol>bytes-long non-Unicode strings.

=item * json:hash_int_10 [deserialize]

A 10-key hash {"1":0, ..., "10":0}.

=item * json:hash_int_100 [deserialize]

A 100-key hash {"1":0, ..., "100":0}.

=item * json:hash_int_1000 [deserialize]

A 1000-key hash {"1":0, ..., "1000":0}.

=item * sereal:hash_int_100 [deserialize]

A 100-key hash {1=E<gt>0, ..., 100=E<gt>0}.

=item * perl:hash_int_100 [deserialize]

A 100-key hash {1=E<gt>0, ..., 100=E<gt>0}.

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (serializing):

 % bencher -m Serializers --include-participant-tags serialize

Result formatted as table (split, part 1 of 11):

 #table1#
 {dataset=>"array_int_10"}
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                                          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | YAML::Old::Dump                | yaml, serialize                                 |      4900 |  200      |                 0.00% |             43810.74% | 1.1e-06 |      20 |
 | YAML::Dump                     | yaml, serialize                                 |      5000 |  200      |                 2.81% |             42610.29% | 6.9e-07 |      20 |
 | JSON::PP::encode_json          | json, serialize                                 |     94157 |   10.621  |              1829.73% |              2175.48% | 2.9e-11 |      20 |
 | MarpaX::ESLIF::ECMA404::encode | json, serialize                                 |    110000 |    9.1    |              2161.37% |              1841.77% | 1.3e-08 |      20 |
 | JSON::Tiny::encode_json        | json, serialize                                 |    115290 |    8.6739 |              2262.80% |              1758.42% | 1.7e-11 |      29 |
 | YAML::Syck::Dump               | yaml, serialize                                 |    120000 |    8.1    |              2435.38% |              1631.92% | 1.3e-08 |      20 |
 | YAML::XS::Dump                 | yaml, serialize                                 |    170000 |    5.8    |              3459.09% |              1133.76% |   4e-08 |      20 |
 | Storable::freeze               | binary, storable, serialize, cant_handle_scalar |    365000 |    2.74   |              7390.70% |               486.20% | 7.5e-10 |      25 |
 | Cpanel::JSON::XS::encode_json  | json, serialize                                 |   1800000 |    0.57   |             35979.99% |                21.70% | 8.3e-10 |      20 |
 | JSON::MaybeXS::encode_json     | json, serialize                                 |   1820000 |    0.55   |             37166.84% |                17.83% | 2.1e-10 |      20 |
 | Sereal::encode_sereal          | binary, sereal, serialize                       |   1840000 |    0.544  |             37591.64% |                16.50% | 2.1e-10 |      20 |
 | JSON::XS::encode_json          | json, serialize                                 |   1900000 |    0.52   |             39137.76% |                11.91% | 8.3e-10 |      20 |
 | Data::MessagePack::pack        | binary, msgpack, serialize                      |   2100000 |    0.477  |             42897.07% |                 2.12% | 1.7e-10 |      31 |
 | JSON::Create::create_json      | json, serialize                                 |   2140000 |    0.467  |             43810.74% |                 0.00% | 1.9e-10 |      24 |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                            Rate  YO:D yaml, serialize  Y:D yaml, serialize  JP:e_j json, serialize  MEE:e json, serialize  JT:e_j json, serialize  YS:D yaml, serialize  YX:D yaml, serialize  S:f binary, storable, serialize, cant_handle_scalar  CJX:e_j json, serialize  JM:e_j json, serialize  S:e_s binary, sereal, serialize  JX:e_j json, serialize  DM:p binary, msgpack, serialize  JC:c_j json, serialize 
  YO:D yaml, serialize                                    4900/s                    --                   0%                    -94%                   -95%                    -95%                  -95%                  -97%                                                 -98%                     -99%                    -99%                             -99%                    -99%                             -99%                    -99% 
  Y:D yaml, serialize                                     5000/s                    0%                   --                    -94%                   -95%                    -95%                  -95%                  -97%                                                 -98%                     -99%                    -99%                             -99%                    -99%                             -99%                    -99% 
  JP:e_j json, serialize                                 94157/s                 1783%                1783%                      --                   -14%                    -18%                  -23%                  -45%                                                 -74%                     -94%                    -94%                             -94%                    -95%                             -95%                    -95% 
  MEE:e json, serialize                                 110000/s                 2097%                2097%                     16%                     --                     -4%                  -10%                  -36%                                                 -69%                     -93%                    -93%                             -94%                    -94%                             -94%                    -94% 
  JT:e_j json, serialize                                115290/s                 2205%                2205%                     22%                     4%                      --                   -6%                  -33%                                                 -68%                     -93%                    -93%                             -93%                    -94%                             -94%                    -94% 
  YS:D yaml, serialize                                  120000/s                 2369%                2369%                     31%                    12%                      7%                    --                  -28%                                                 -66%                     -92%                    -93%                             -93%                    -93%                             -94%                    -94% 
  YX:D yaml, serialize                                  170000/s                 3348%                3348%                     83%                    56%                     49%                   39%                    --                                                 -52%                     -90%                    -90%                             -90%                    -91%                             -91%                    -91% 
  S:f binary, storable, serialize, cant_handle_scalar   365000/s                 7199%                7199%                    287%                   232%                    216%                  195%                  111%                                                   --                     -79%                    -79%                             -80%                    -81%                             -82%                    -82% 
  CJX:e_j json, serialize                              1800000/s                34987%               34987%                   1763%                  1496%                   1421%                 1321%                  917%                                                 380%                       --                     -3%                              -4%                     -8%                             -16%                    -18% 
  JM:e_j json, serialize                               1820000/s                36263%               36263%                   1831%                  1554%                   1477%                 1372%                  954%                                                 398%                       3%                      --                              -1%                     -5%                             -13%                    -15% 
  S:e_s binary, sereal, serialize                      1840000/s                36664%               36664%                   1852%                  1572%                   1494%                 1388%                  966%                                                 403%                       4%                      1%                               --                     -4%                             -12%                    -14% 
  JX:e_j json, serialize                               1900000/s                38361%               38361%                   1942%                  1650%                   1568%                 1457%                 1015%                                                 426%                       9%                      5%                               4%                      --                              -8%                    -10% 
  DM:p binary, msgpack, serialize                      2100000/s                41828%               41828%                   2126%                  1807%                   1718%                 1598%                 1115%                                                 474%                      19%                     15%                              14%                      9%                               --                     -2% 
  JC:c_j json, serialize                               2140000/s                42726%               42726%                   2174%                  1848%                   1757%                 1634%                 1141%                                                 486%                      22%                     17%                              16%                     11%                               2%                      -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   S:f binary, storable, serialize, cant_handle_scalar: p_tags=binary, storable, serialize, cant_handle_scalar participant=Storable::freeze
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 2 of 11):

 #table2#
 {dataset=>"array_int_100"}
 +--------------------------------+-------------------------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                                          | rate (/s) |  time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-------------------------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | YAML::Old::Dump                | yaml, serialize                                 |    600    | 2          |                 0.00% |             63145.55% | 1.7e-05 |      20 |
 | YAML::Dump                     | yaml, serialize                                 |    670    | 1.5        |                11.68% |             56530.80% |   4e-06 |      20 |
 | JSON::PP::encode_json          | json, serialize                                 |  12000    | 0.085      |              1847.57% |              3147.41% | 1.1e-07 |      20 |
 | JSON::Tiny::encode_json        | json, serialize                                 |  15713.94 | 0.06363778 |              2513.17% |              2320.27% | 5.8e-12 |      24 |
 | YAML::Syck::Dump               | yaml, serialize                                 |  22000    | 0.046      |              3486.11% |              1663.63% | 6.7e-08 |      20 |
 | YAML::XS::Dump                 | yaml, serialize                                 |  26000    | 0.039      |              4148.51% |              1388.65% | 5.3e-08 |      20 |
 | MarpaX::ESLIF::ECMA404::encode | json, serialize                                 |  29000    | 0.035      |              4665.99% |              1227.02% | 2.1e-07 |      20 |
 | Storable::freeze               | binary, storable, serialize, cant_handle_scalar | 170000    | 0.0058     |             28547.37% |               120.77% | 6.5e-09 |      21 |
 | Cpanel::JSON::XS::encode_json  | json, serialize                                 | 245000    | 0.00407    |             40716.50% |                54.95% | 1.7e-09 |      20 |
 | JSON::MaybeXS::encode_json     | json, serialize                                 | 250480    | 0.0039924  |             41553.32% |                51.84% | 1.7e-11 |      22 |
 | JSON::XS::encode_json          | json, serialize                                 | 280000    | 0.0036     |             46563.38% |                35.54% | 4.9e-09 |      21 |
 | JSON::Create::create_json      | json, serialize                                 | 360000    | 0.0028     |             60027.77% |                 5.19% | 3.3e-09 |      20 |
 | Data::MessagePack::pack        | binary, msgpack, serialize                      | 374000    | 0.00267    |             62151.31% |                 1.60% | 7.5e-10 |      25 |
 | Sereal::encode_sereal          | binary, sereal, serialize                       | 380000    | 0.00263    |             63145.55% |                 0.00% | 8.3e-10 |      20 |
 +--------------------------------+-------------------------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                             Rate  YO:D yaml, serialize  Y:D yaml, serialize  JP:e_j json, serialize  JT:e_j json, serialize  YS:D yaml, serialize  YX:D yaml, serialize  MEE:e json, serialize  S:f binary, storable, serialize, cant_handle_scalar  CJX:e_j json, serialize  JM:e_j json, serialize  JX:e_j json, serialize  JC:c_j json, serialize  DM:p binary, msgpack, serialize  S:e_s binary, sereal, serialize 
  YO:D yaml, serialize                                      600/s                    --                 -25%                    -95%                    -96%                  -97%                  -98%                   -98%                                                 -99%                     -99%                    -99%                    -99%                    -99%                             -99%                             -99% 
  Y:D yaml, serialize                                       670/s                   33%                   --                    -94%                    -95%                  -96%                  -97%                   -97%                                                 -99%                     -99%                    -99%                    -99%                    -99%                             -99%                             -99% 
  JP:e_j json, serialize                                  12000/s                 2252%                1664%                      --                    -25%                  -45%                  -54%                   -58%                                                 -93%                     -95%                    -95%                    -95%                    -96%                             -96%                             -96% 
  JT:e_j json, serialize                               15713.94/s                 3042%                2257%                     33%                      --                  -27%                  -38%                   -45%                                                 -90%                     -93%                    -93%                    -94%                    -95%                             -95%                             -95% 
  YS:D yaml, serialize                                    22000/s                 4247%                3160%                     84%                     38%                    --                  -15%                   -23%                                                 -87%                     -91%                    -91%                    -92%                    -93%                             -94%                             -94% 
  YX:D yaml, serialize                                    26000/s                 5028%                3746%                    117%                     63%                   17%                    --                   -10%                                                 -85%                     -89%                    -89%                    -90%                    -92%                             -93%                             -93% 
  MEE:e json, serialize                                   29000/s                 5614%                4185%                    142%                     81%                   31%                   11%                     --                                                 -83%                     -88%                    -88%                    -89%                    -92%                             -92%                             -92% 
  S:f binary, storable, serialize, cant_handle_scalar    170000/s                34382%               25762%                   1365%                    997%                  693%                  572%                   503%                                                   --                     -29%                    -31%                    -37%                    -51%                             -53%                             -54% 
  CJX:e_j json, serialize                                245000/s                49040%               36755%                   1988%                   1463%                 1030%                  858%                   759%                                                  42%                       --                     -1%                    -11%                    -31%                             -34%                             -35% 
  JM:e_j json, serialize                                 250480/s                49995%               37471%                   2029%                   1493%                 1052%                  876%                   776%                                                  45%                       1%                      --                     -9%                    -29%                             -33%                             -34% 
  JX:e_j json, serialize                                 280000/s                55455%               41566%                   2261%                   1667%                 1177%                  983%                   872%                                                  61%                      13%                     10%                      --                    -22%                             -25%                             -26% 
  JC:c_j json, serialize                                 360000/s                71328%               53471%                   2935%                   2172%                 1542%                 1292%                  1150%                                                 107%                      45%                     42%                     28%                      --                              -4%                              -6% 
  DM:p binary, msgpack, serialize                        374000/s                74806%               56079%                   3083%                   2283%                 1622%                 1360%                  1210%                                                 117%                      52%                     49%                     34%                      4%                               --                              -1% 
  S:e_s binary, sereal, serialize                        380000/s                75945%               56934%                   3131%                   2319%                 1649%                 1382%                  1230%                                                 120%                      54%                     51%                     36%                      6%                               1%                               -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   S:f binary, storable, serialize, cant_handle_scalar: p_tags=binary, storable, serialize, cant_handle_scalar participant=Storable::freeze
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 3 of 11):

 #table3#
 {dataset=>"array_int_1000"}
 +--------------------------------+-------------------------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                                          | rate (/s) | time (ms)  | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-------------------------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | YAML::Old::Dump                | yaml, serialize                                 |      69   | 15         |                 0.00% |             61116.92% | 2.5e-05 |      20 |
 | YAML::Dump                     | yaml, serialize                                 |      71.3 | 14         |                 3.91% |             58813.86% | 1.3e-05 |      20 |
 | JSON::PP::encode_json          | json, serialize                                 |    1200   |  0.84      |              1644.37% |              3409.41% | 1.8e-06 |      20 |
 | JSON::Tiny::encode_json        | json, serialize                                 |    1500   |  0.67      |              2061.00% |              2732.80% | 6.9e-07 |      20 |
 | YAML::Syck::Dump               | yaml, serialize                                 |    2100   |  0.48      |              2931.74% |              1919.20% | 8.5e-07 |      20 |
 | YAML::XS::Dump                 | yaml, serialize                                 |    2600   |  0.38      |              3715.12% |              1504.59% |   2e-06 |      20 |
 | MarpaX::ESLIF::ECMA404::encode | json, serialize                                 |    3300   |  0.31      |              4654.65% |              1187.52% | 4.8e-07 |      20 |
 | Storable::freeze               | binary, storable, serialize, cant_handle_scalar |   21000   |  0.048     |             30112.00% |               102.62% | 5.3e-08 |      20 |
 | JSON::MaybeXS::encode_json     | json, serialize                                 |   27200   |  0.0368    |             39515.35% |                54.53% | 1.3e-08 |      20 |
 | Cpanel::JSON::XS::encode_json  | json, serialize                                 |   27000   |  0.037     |             39727.22% |                53.71% | 5.2e-08 |      21 |
 | JSON::XS::encode_json          | json, serialize                                 |   29761.2 |  0.0336008 |             43272.95% |                41.14% | 5.7e-12 |      25 |
 | JSON::Create::create_json      | json, serialize                                 |   33900   |  0.0295    |             49361.08% |                23.77% | 1.3e-08 |      22 |
 | Data::MessagePack::pack        | binary, msgpack, serialize                      |   41500   |  0.0241    |             60333.23% |                 1.30% |   6e-09 |      25 |
 | Sereal::encode_sereal          | binary, sereal, serialize                       |   42000   |  0.0238    |             61116.92% |                 0.00% |   6e-09 |      25 |
 +--------------------------------+-------------------------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                            Rate  YO:D yaml, serialize  Y:D yaml, serialize  JP:e_j json, serialize  JT:e_j json, serialize  YS:D yaml, serialize  YX:D yaml, serialize  MEE:e json, serialize  S:f binary, storable, serialize, cant_handle_scalar  CJX:e_j json, serialize  JM:e_j json, serialize  JX:e_j json, serialize  JC:c_j json, serialize  DM:p binary, msgpack, serialize  S:e_s binary, sereal, serialize 
  YO:D yaml, serialize                                      69/s                    --                  -6%                    -94%                    -95%                  -96%                  -97%                   -97%                                                 -99%                     -99%                    -99%                    -99%                    -99%                             -99%                             -99% 
  Y:D yaml, serialize                                     71.3/s                    7%                   --                    -94%                    -95%                  -96%                  -97%                   -97%                                                 -99%                     -99%                    -99%                    -99%                    -99%                             -99%                             -99% 
  JP:e_j json, serialize                                  1200/s                 1685%                1566%                      --                    -20%                  -42%                  -54%                   -63%                                                 -94%                     -95%                    -95%                    -95%                    -96%                             -97%                             -97% 
  JT:e_j json, serialize                                  1500/s                 2138%                1989%                     25%                      --                  -28%                  -43%                   -53%                                                 -92%                     -94%                    -94%                    -94%                    -95%                             -96%                             -96% 
  YS:D yaml, serialize                                    2100/s                 3025%                2816%                     75%                     39%                    --                  -20%                   -35%                                                 -90%                     -92%                    -92%                    -92%                    -93%                             -94%                             -95% 
  YX:D yaml, serialize                                    2600/s                 3847%                3584%                    121%                     76%                   26%                    --                   -18%                                                 -87%                     -90%                    -90%                    -91%                    -92%                             -93%                             -93% 
  MEE:e json, serialize                                   3300/s                 4738%                4416%                    170%                    116%                   54%                   22%                     --                                                 -84%                     -88%                    -88%                    -89%                    -90%                             -92%                             -92% 
  S:f binary, storable, serialize, cant_handle_scalar    21000/s                31150%               29066%                   1650%                   1295%                  900%                  691%                   545%                                                   --                     -22%                    -23%                    -29%                    -38%                             -49%                             -50% 
  CJX:e_j json, serialize                                27000/s                40440%               37737%                   2170%                   1710%                 1197%                  927%                   737%                                                  29%                       --                      0%                     -9%                    -20%                             -34%                             -35% 
  JM:e_j json, serialize                                 27200/s                40660%               37943%                   2182%                   1720%                 1204%                  932%                   742%                                                  30%                       0%                      --                     -8%                    -19%                             -34%                             -35% 
  JX:e_j json, serialize                               29761.2/s                44541%               41565%                   2399%                   1894%                 1328%                 1030%                   822%                                                  42%                      10%                      9%                      --                    -12%                             -28%                             -29% 
  JC:c_j json, serialize                                 33900/s                50747%               47357%                   2747%                   2171%                 1527%                 1188%                   950%                                                  62%                      25%                     24%                     13%                      --                             -18%                             -19% 
  DM:p binary, msgpack, serialize                        41500/s                62140%               57991%                   3385%                   2680%                 1891%                 1476%                  1186%                                                  99%                      53%                     52%                     39%                     22%                               --                              -1% 
  S:e_s binary, sereal, serialize                        42000/s                62925%               58723%                   3429%                   2715%                 1916%                 1496%                  1202%                                                 101%                      55%                     54%                     41%                     23%                               1%                               -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   S:f binary, storable, serialize, cant_handle_scalar: p_tags=binary, storable, serialize, cant_handle_scalar participant=Storable::freeze
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 4 of 11):

 #table4#
 {dataset=>"array_str1k_10"}
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                                          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | MarpaX::ESLIF::ECMA404::encode | json, serialize                                 |    1600   |  640      |                 0.00% |             34132.30% | 6.9e-07 |      20 |
 | YAML::Old::Dump                | yaml, serialize                                 |    4000   |  300      |               145.93% |             13819.55% |   3e-06 |      21 |
 | YAML::Dump                     | yaml, serialize                                 |    4200   |  240      |               169.11% |             12620.67% | 4.8e-07 |      20 |
 | YAML::XS::Dump                 | yaml, serialize                                 |   12000   |   85      |               650.05% |              4464.01% | 1.1e-07 |      20 |
 | JSON::PP::encode_json          | json, serialize                                 |   31300   |   32      |              1905.71% |              1606.74% | 1.1e-08 |      29 |
 | YAML::Syck::Dump               | yaml, serialize                                 |   32482.6 |   30.7857 |              1983.07% |              1543.35% | 1.7e-11 |      20 |
 | JSON::Tiny::encode_json        | json, serialize                                 |   40100   |   24.9    |              2470.87% |              1231.54% | 6.7e-09 |      20 |
 | JSON::Create::create_json      | json, serialize                                 |   49800   |   20.1    |              3091.91% |               972.47% | 6.7e-09 |      20 |
 | Cpanel::JSON::XS::encode_json  | json, serialize                                 |   53000   |   19      |              3302.10% |               906.21% | 2.7e-08 |      20 |
 | JSON::MaybeXS::encode_json     | json, serialize                                 |   53000   |   19      |              3326.20% |               899.13% | 2.7e-08 |      20 |
 | JSON::XS::encode_json          | json, serialize                                 |   57299.7 |   17.4521 |              3574.57% |               831.60% | 1.7e-11 |      20 |
 | Storable::freeze               | binary, storable, serialize, cant_handle_scalar |  270000   |    3.7    |             17128.76% |                98.69% | 6.7e-09 |      20 |
 | Data::MessagePack::pack        | binary, msgpack, serialize                      |  520000   |    1.9    |             33497.52% |                 1.89% | 1.2e-08 |      30 |
 | Sereal::encode_sereal          | binary, sereal, serialize                       |  530000   |    1.9    |             34132.30% |                 0.00% | 7.5e-09 |      20 |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                            Rate  MEE:e json, serialize  YO:D yaml, serialize  Y:D yaml, serialize  YX:D yaml, serialize  JP:e_j json, serialize  YS:D yaml, serialize  JT:e_j json, serialize  JC:c_j json, serialize  CJX:e_j json, serialize  JM:e_j json, serialize  JX:e_j json, serialize  S:f binary, storable, serialize, cant_handle_scalar  DM:p binary, msgpack, serialize  S:e_s binary, sereal, serialize 
  MEE:e json, serialize                                   1600/s                     --                  -53%                 -62%                  -86%                    -95%                  -95%                    -96%                    -96%                     -97%                    -97%                    -97%                                                 -99%                             -99%                             -99% 
  YO:D yaml, serialize                                    4000/s                   113%                    --                 -19%                  -71%                    -89%                  -89%                    -91%                    -93%                     -93%                    -93%                    -94%                                                 -98%                             -99%                             -99% 
  Y:D yaml, serialize                                     4200/s                   166%                   25%                   --                  -64%                    -86%                  -87%                    -89%                    -91%                     -92%                    -92%                    -92%                                                 -98%                             -99%                             -99% 
  YX:D yaml, serialize                                   12000/s                   652%                  252%                 182%                    --                    -62%                  -63%                    -70%                    -76%                     -77%                    -77%                    -79%                                                 -95%                             -97%                             -97% 
  JP:e_j json, serialize                                 31300/s                  1900%                  837%                 650%                  165%                      --                   -3%                    -22%                    -37%                     -40%                    -40%                    -45%                                                 -88%                             -94%                             -94% 
  YS:D yaml, serialize                                 32482.6/s                  1978%                  874%                 679%                  176%                      3%                    --                    -19%                    -34%                     -38%                    -38%                    -43%                                                 -87%                             -93%                             -93% 
  JT:e_j json, serialize                                 40100/s                  2470%                 1104%                 863%                  241%                     28%                   23%                      --                    -19%                     -23%                    -23%                    -29%                                                 -85%                             -92%                             -92% 
  JC:c_j json, serialize                                 49800/s                  3084%                 1392%                1094%                  322%                     59%                   53%                     23%                      --                      -5%                     -5%                    -13%                                                 -81%                             -90%                             -90% 
  CJX:e_j json, serialize                                53000/s                  3268%                 1478%                1163%                  347%                     68%                   62%                     31%                      5%                       --                      0%                     -8%                                                 -80%                             -90%                             -90% 
  JM:e_j json, serialize                                 53000/s                  3268%                 1478%                1163%                  347%                     68%                   62%                     31%                      5%                       0%                      --                     -8%                                                 -80%                             -90%                             -90% 
  JX:e_j json, serialize                               57299.7/s                  3567%                 1618%                1275%                  387%                     83%                   76%                     42%                     15%                       8%                      8%                      --                                                 -78%                             -89%                             -89% 
  S:f binary, storable, serialize, cant_handle_scalar   270000/s                 17197%                 8008%                6386%                 2197%                    764%                  732%                    572%                    443%                     413%                    413%                    371%                                                   --                             -48%                             -48% 
  DM:p binary, msgpack, serialize                       520000/s                 33584%                15689%               12531%                 4373%                   1584%                 1520%                   1210%                    957%                     900%                    900%                    818%                                                  94%                               --                               0% 
  S:e_s binary, sereal, serialize                       530000/s                 33584%                15689%               12531%                 4373%                   1584%                 1520%                   1210%                    957%                     900%                    900%                    818%                                                  94%                               0%                               -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   S:f binary, storable, serialize, cant_handle_scalar: p_tags=binary, storable, serialize, cant_handle_scalar participant=Storable::freeze
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 5 of 11):

 #table5#
 {dataset=>"array_ustr1k_10"}
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                                          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | MarpaX::ESLIF::ECMA404::encode | json, serialize                                 |       832 | 1200      |                 0.00% |             38018.05% | 1.1e-06 |      20 |
 | YAML::Old::Dump                | yaml, serialize                                 |      1870 |  535      |               124.86% |             16851.70% | 4.7e-07 |      21 |
 | YAML::Dump                     | yaml, serialize                                 |      1880 |  533      |               125.54% |             16801.05% | 2.1e-07 |      20 |
 | JSON::PP::encode_json          | json, serialize                                 |      3570 |  280      |               329.64% |              8772.16% | 5.3e-08 |      20 |
 | JSON::Tiny::encode_json        | json, serialize                                 |      4000 |  250      |               383.98% |              7775.92% | 4.3e-07 |      20 |
 | YAML::XS::Dump                 | yaml, serialize                                 |      6100 |  170      |               627.94% |              5136.41% | 2.1e-07 |      20 |
 | JSON::MaybeXS::encode_json     | json, serialize                                 |      7900 |  130      |               853.36% |              3898.28% | 2.1e-07 |      20 |
 | Cpanel::JSON::XS::encode_json  | json, serialize                                 |      8000 |  130      |               856.62% |              3884.68% | 1.6e-07 |      20 |
 | JSON::XS::encode_json          | json, serialize                                 |      8980 |  111      |               979.74% |              3430.29% | 4.1e-08 |      34 |
 | YAML::Syck::Dump               | yaml, serialize                                 |     14900 |   67.3    |              1687.40% |              2032.60% | 2.7e-08 |      20 |
 | JSON::Create::create_json      | json, serialize                                 |     21000 |   48      |              2405.02% |              1421.66% | 5.3e-08 |      20 |
 | Storable::freeze               | binary, storable, serialize, cant_handle_scalar |    193000 |    5.17   |             23158.05% |                63.89% | 1.6e-09 |      21 |
 | Sereal::encode_sereal          | binary, sereal, serialize                       |    258000 |    3.88   |             30904.54% |                22.94% | 1.7e-09 |      20 |
 | Data::MessagePack::pack        | binary, msgpack, serialize                      |    317040 |    3.1542 |             38018.05% |                 0.00% | 1.7e-11 |      22 |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                           Rate  MEE:e json, serialize  YO:D yaml, serialize  Y:D yaml, serialize  JP:e_j json, serialize  JT:e_j json, serialize  YX:D yaml, serialize  JM:e_j json, serialize  CJX:e_j json, serialize  JX:e_j json, serialize  YS:D yaml, serialize  JC:c_j json, serialize  S:f binary, storable, serialize, cant_handle_scalar  S:e_s binary, sereal, serialize  DM:p binary, msgpack, serialize 
  MEE:e json, serialize                                   832/s                     --                  -55%                 -55%                    -76%                    -79%                  -85%                    -89%                     -89%                    -90%                  -94%                    -96%                                                 -99%                             -99%                             -99% 
  YO:D yaml, serialize                                   1870/s                   124%                    --                   0%                    -47%                    -53%                  -68%                    -75%                     -75%                    -79%                  -87%                    -91%                                                 -99%                             -99%                             -99% 
  Y:D yaml, serialize                                    1880/s                   125%                    0%                   --                    -47%                    -53%                  -68%                    -75%                     -75%                    -79%                  -87%                    -90%                                                 -99%                             -99%                             -99% 
  JP:e_j json, serialize                                 3570/s                   328%                   91%                  90%                      --                    -10%                  -39%                    -53%                     -53%                    -60%                  -75%                    -82%                                                 -98%                             -98%                             -98% 
  JT:e_j json, serialize                                 4000/s                   380%                  114%                 113%                     12%                      --                  -31%                    -48%                     -48%                    -55%                  -73%                    -80%                                                 -97%                             -98%                             -98% 
  YX:D yaml, serialize                                   6100/s                   605%                  214%                 213%                     64%                     47%                    --                    -23%                     -23%                    -34%                  -60%                    -71%                                                 -96%                             -97%                             -98% 
  JM:e_j json, serialize                                 7900/s                   823%                  311%                 309%                    115%                     92%                   30%                      --                       0%                    -14%                  -48%                    -63%                                                 -96%                             -97%                             -97% 
  CJX:e_j json, serialize                                8000/s                   823%                  311%                 309%                    115%                     92%                   30%                      0%                       --                    -14%                  -48%                    -63%                                                 -96%                             -97%                             -97% 
  JX:e_j json, serialize                                 8980/s                   981%                  381%                 380%                    152%                    125%                   53%                     17%                      17%                      --                  -39%                    -56%                                                 -95%                             -96%                             -97% 
  YS:D yaml, serialize                                  14900/s                  1683%                  694%                 691%                    316%                    271%                  152%                     93%                      93%                     64%                    --                    -28%                                                 -92%                             -94%                             -95% 
  JC:c_j json, serialize                                21000/s                  2400%                 1014%                1010%                    483%                    420%                  254%                    170%                     170%                    131%                   40%                      --                                                 -89%                             -91%                             -93% 
  S:f binary, storable, serialize, cant_handle_scalar  193000/s                 23110%                10248%               10209%                   5315%                   4735%                 3188%                   2414%                    2414%                   2047%                 1201%                    828%                                                   --                             -24%                             -38% 
  S:e_s binary, sereal, serialize                      258000/s                 30827%                13688%               13637%                   7116%                   6343%                 4281%                   3250%                    3250%                   2760%                 1634%                   1137%                                                  33%                               --                             -18% 
  DM:p binary, msgpack, serialize                      317040/s                 37944%                16861%               16798%                   8777%                   7825%                 5289%                   4021%                    4021%                   3419%                 2033%                   1421%                                                  63%                              23%                               -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   S:f binary, storable, serialize, cant_handle_scalar: p_tags=binary, storable, serialize, cant_handle_scalar participant=Storable::freeze
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 6 of 11):

 #table6#
 {dataset=>"hash_int_10"}
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                                          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | YAML::Old::Dump                | yaml, serialize                                 |    3700   |  270      |                 0.00% |             21932.42% | 4.6e-07 |      22 |
 | YAML::Dump                     | yaml, serialize                                 |    3750   |  267      |                 2.01% |             21497.46% | 2.1e-07 |      20 |
 | JSON::PP::encode_json          | json, serialize                                 |   53000   |   19      |              1346.87% |              1422.76% | 2.7e-08 |      20 |
 | MarpaX::ESLIF::ECMA404::encode | json, serialize                                 |   61000   |   16      |              1550.77% |              1234.68% | 2.7e-08 |      20 |
 | JSON::Tiny::encode_json        | json, serialize                                 |   65277   |   15.319  |              1676.38% |              1140.30% | 2.3e-11 |      20 |
 | YAML::Syck::Dump               | yaml, serialize                                 |   77692.2 |   12.8713 |              2014.24% |               942.10% | 5.7e-12 |      23 |
 | YAML::XS::Dump                 | yaml, serialize                                 |   91000   |   11      |              2368.39% |               792.58% | 1.3e-08 |      21 |
 | Storable::freeze               | binary, storable, serialize, cant_handle_scalar |  267000   |    3.74   |              7178.24% |               202.72% | 1.7e-09 |      20 |
 | Data::MessagePack::pack        | binary, msgpack, serialize                      |  591000   |    1.69   |             15975.71% |                37.05% | 7.5e-10 |      25 |
 | Cpanel::JSON::XS::encode_json  | json, serialize                                 |  600000   |    2      |             16286.32% |                34.46% | 3.7e-08 |      21 |
 | JSON::MaybeXS::encode_json     | json, serialize                                 |  670000   |    1.5    |             18206.23% |                20.35% | 5.4e-09 |      20 |
 | Sereal::encode_sereal          | binary, sereal, serialize                       |  680000   |    1.5    |             18532.92% |                18.24% | 1.7e-09 |      31 |
 | JSON::XS::encode_json          | json, serialize                                 |  761000   |    1.31   |             20609.00% |                 6.39% | 1.2e-09 |      22 |
 | JSON::Create::create_json      | json, serialize                                 |  810000   |    1.2    |             21932.42% |                 0.00% | 1.7e-09 |      31 |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                            Rate  YO:D yaml, serialize  Y:D yaml, serialize  JP:e_j json, serialize  MEE:e json, serialize  JT:e_j json, serialize  YS:D yaml, serialize  YX:D yaml, serialize  S:f binary, storable, serialize, cant_handle_scalar  CJX:e_j json, serialize  DM:p binary, msgpack, serialize  JM:e_j json, serialize  S:e_s binary, sereal, serialize  JX:e_j json, serialize  JC:c_j json, serialize 
  YO:D yaml, serialize                                    3700/s                    --                  -1%                    -92%                   -94%                    -94%                  -95%                  -95%                                                 -98%                     -99%                             -99%                    -99%                             -99%                    -99%                    -99% 
  Y:D yaml, serialize                                     3750/s                    1%                   --                    -92%                   -94%                    -94%                  -95%                  -95%                                                 -98%                     -99%                             -99%                    -99%                             -99%                    -99%                    -99% 
  JP:e_j json, serialize                                 53000/s                 1321%                1305%                      --                   -15%                    -19%                  -32%                  -42%                                                 -80%                     -89%                             -91%                    -92%                             -92%                    -93%                    -93% 
  MEE:e json, serialize                                  61000/s                 1587%                1568%                     18%                     --                     -4%                  -19%                  -31%                                                 -76%                     -87%                             -89%                    -90%                             -90%                    -91%                    -92% 
  JT:e_j json, serialize                                 65277/s                 1662%                1642%                     24%                     4%                      --                  -15%                  -28%                                                 -75%                     -86%                             -88%                    -90%                             -90%                    -91%                    -92% 
  YS:D yaml, serialize                                 77692.2/s                 1997%                1974%                     47%                    24%                     19%                    --                  -14%                                                 -70%                     -84%                             -86%                    -88%                             -88%                    -89%                    -90% 
  YX:D yaml, serialize                                   91000/s                 2354%                2327%                     72%                    45%                     39%                   17%                    --                                                 -65%                     -81%                             -84%                    -86%                             -86%                    -88%                    -89% 
  S:f binary, storable, serialize, cant_handle_scalar   267000/s                 7119%                7039%                    408%                   327%                    309%                  244%                  194%                                                   --                     -46%                             -54%                    -59%                             -59%                    -64%                    -67% 
  CJX:e_j json, serialize                               600000/s                13400%               13250%                    850%                   700%                    665%                  543%                  450%                                                  87%                       --                             -15%                    -25%                             -25%                    -34%                    -40% 
  DM:p binary, msgpack, serialize                       591000/s                15876%               15698%                   1024%                   846%                    806%                  661%                  550%                                                 121%                      18%                               --                    -11%                             -11%                    -22%                    -28% 
  JM:e_j json, serialize                                670000/s                17900%               17700%                   1166%                   966%                    921%                  758%                  633%                                                 149%                      33%                              12%                      --                               0%                    -12%                    -20% 
  S:e_s binary, sereal, serialize                       680000/s                17900%               17700%                   1166%                   966%                    921%                  758%                  633%                                                 149%                      33%                              12%                      0%                               --                    -12%                    -20% 
  JX:e_j json, serialize                                761000/s                20510%               20281%                   1350%                  1121%                   1069%                  882%                  739%                                                 185%                      52%                              29%                     14%                              14%                      --                     -8% 
  JC:c_j json, serialize                                810000/s                22400%               22150%                   1483%                  1233%                   1176%                  972%                  816%                                                 211%                      66%                              40%                     25%                              25%                      9%                      -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   S:f binary, storable, serialize, cant_handle_scalar: p_tags=binary, storable, serialize, cant_handle_scalar participant=Storable::freeze
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 7 of 11):

 #table7#
 {dataset=>"hash_int_100"}
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                                          | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | YAML::Old::Dump                | yaml, serialize                                 |       400 |    2      |                 0.00% |             20697.57% | 4.8e-05 |      20 |
 | YAML::Dump                     | yaml, serialize                                 |       466 |    2.15   |                13.34% |             18250.41% |   2e-06 |      21 |
 | JSON::PP::encode_json          | json, serialize                                 |      5000 |    0.2    |              1057.11% |              1697.38% | 5.4e-06 |      20 |
 | JSON::Tiny::encode_json        | json, serialize                                 |      7200 |    0.14   |              1646.94% |              1090.52% |   2e-07 |      22 |
 | MarpaX::ESLIF::ECMA404::encode | json, serialize                                 |      8800 |    0.11   |              2051.40% |               866.70% | 2.7e-07 |      20 |
 | YAML::Syck::Dump               | yaml, serialize                                 |      9500 |    0.11   |              2211.96% |               799.57% | 2.1e-07 |      20 |
 | YAML::XS::Dump                 | yaml, serialize                                 |      9700 |    0.1    |              2250.55% |               784.79% | 2.1e-07 |      20 |
 | Sereal::encode_sereal          | binary, sereal, serialize                       |     61000 |    0.016  |             14665.56% |                40.85% | 3.3e-08 |      20 |
 | Data::MessagePack::pack        | binary, msgpack, serialize                      |     64200 |    0.0156 |             15515.46% |                33.19% | 6.7e-09 |      20 |
 | Storable::freeze               | binary, storable, serialize, cant_handle_scalar |     66000 |    0.015  |             15855.66% |                30.35% | 2.7e-08 |      20 |
 | Cpanel::JSON::XS::encode_json  | json, serialize                                 |     74000 |    0.014  |             17790.46% |                16.25% | 2.7e-08 |      20 |
 | JSON::MaybeXS::encode_json     | json, serialize                                 |     74000 |    0.013  |             18018.07% |                14.79% | 2.5e-08 |      23 |
 | JSON::XS::encode_json          | json, serialize                                 |     79200 |    0.0126 |             19182.47% |                 7.86% | 6.4e-09 |      22 |
 | JSON::Create::create_json      | json, serialize                                 |     85500 |    0.0117 |             20697.57% |                 0.00% |   1e-08 |      20 |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                          Rate  Y:D yaml, serialize  YO:D yaml, serialize  JP:e_j json, serialize  JT:e_j json, serialize  MEE:e json, serialize  YS:D yaml, serialize  YX:D yaml, serialize  S:e_s binary, sereal, serialize  DM:p binary, msgpack, serialize  S:f binary, storable, serialize, cant_handle_scalar  CJX:e_j json, serialize  JM:e_j json, serialize  JX:e_j json, serialize  JC:c_j json, serialize 
  Y:D yaml, serialize                                    466/s                   --                   -6%                    -90%                    -93%                   -94%                  -94%                  -95%                             -99%                             -99%                                                 -99%                     -99%                    -99%                    -99%                    -99% 
  YO:D yaml, serialize                                   400/s                   7%                    --                    -90%                    -93%                   -94%                  -94%                  -95%                             -99%                             -99%                                                 -99%                     -99%                    -99%                    -99%                    -99% 
  JP:e_j json, serialize                                5000/s                 974%                  900%                      --                    -29%                   -45%                  -45%                  -50%                             -92%                             -92%                                                 -92%                     -93%                    -93%                    -93%                    -94% 
  JT:e_j json, serialize                                7200/s                1435%                 1328%                     42%                      --                   -21%                  -21%                  -28%                             -88%                             -88%                                                 -89%                     -90%                    -90%                    -91%                    -91% 
  MEE:e json, serialize                                 8800/s                1854%                 1718%                     81%                     27%                     --                    0%                   -9%                             -85%                             -85%                                                 -86%                     -87%                    -88%                    -88%                    -89% 
  YS:D yaml, serialize                                  9500/s                1854%                 1718%                     81%                     27%                     0%                    --                   -9%                             -85%                             -85%                                                 -86%                     -87%                    -88%                    -88%                    -89% 
  YX:D yaml, serialize                                  9700/s                2049%                 1900%                    100%                     40%                     9%                    9%                    --                             -84%                             -84%                                                 -85%                     -86%                    -87%                    -87%                    -88% 
  S:e_s binary, sereal, serialize                      61000/s               13337%                12400%                   1150%                    775%                   587%                  587%                  525%                               --                              -2%                                                  -6%                     -12%                    -18%                    -21%                    -26% 
  DM:p binary, msgpack, serialize                      64200/s               13682%                12720%                   1182%                    797%                   605%                  605%                  541%                               2%                               --                                                  -3%                     -10%                    -16%                    -19%                    -24% 
  S:f binary, storable, serialize, cant_handle_scalar  66000/s               14233%                13233%                   1233%                    833%                   633%                  633%                  566%                               6%                               4%                                                   --                      -6%                    -13%                    -15%                    -21% 
  CJX:e_j json, serialize                              74000/s               15257%                14185%                   1328%                    900%                   685%                  685%                  614%                              14%                              11%                                                   7%                       --                     -7%                     -9%                    -16% 
  JM:e_j json, serialize                               74000/s               16438%                15284%                   1438%                    976%                   746%                  746%                  669%                              23%                              19%                                                  15%                       7%                      --                     -3%                     -9% 
  JX:e_j json, serialize                               79200/s               16963%                15773%                   1487%                   1011%                   773%                  773%                  693%                              26%                              23%                                                  19%                      11%                      3%                      --                     -7% 
  JC:c_j json, serialize                               85500/s               18276%                16994%                   1609%                   1096%                   840%                  840%                  754%                              36%                              33%                                                  28%                      19%                     11%                      7%                      -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   S:f binary, storable, serialize, cant_handle_scalar: p_tags=binary, storable, serialize, cant_handle_scalar participant=Storable::freeze
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 8 of 11):

 #table8#
 {dataset=>"hash_int_1000"}
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                                          | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | YAML::Old::Dump                | yaml, serialize                                 |      46   |     22    |                 0.00% |             14672.84% | 2.8e-05 |      20 |
 | YAML::Dump                     | yaml, serialize                                 |      47.8 |     20.9  |                 3.08% |             14232.10% |   2e-05 |      20 |
 | JSON::PP::encode_json          | json, serialize                                 |     600   |      1.7  |              1190.67% |              1044.59% | 4.1e-06 |      20 |
 | JSON::Tiny::encode_json        | json, serialize                                 |     710   |      1.4  |              1432.56% |               863.94% |   6e-06 |      20 |
 | MarpaX::ESLIF::ECMA404::encode | json, serialize                                 |     910   |      1.1  |              1852.34% |               656.67% | 5.5e-06 |      20 |
 | YAML::Syck::Dump               | yaml, serialize                                 |     957   |      1.05 |              1962.69% |               616.19% | 8.5e-07 |      20 |
 | YAML::XS::Dump                 | yaml, serialize                                 |     960   |      1    |              1968.45% |               614.20% | 4.8e-06 |      21 |
 | Sereal::encode_sereal          | binary, sereal, serialize                       |    4800   |      0.21 |             10269.16% |                42.47% | 2.7e-07 |      20 |
 | Data::MessagePack::pack        | binary, msgpack, serialize                      |    5800   |      0.17 |             12332.27% |                18.83% | 2.1e-07 |      20 |
 | Storable::freeze               | binary, storable, serialize, cant_handle_scalar |    5800   |      0.17 |             12510.83% |                17.14% | 2.1e-07 |      20 |
 | Cpanel::JSON::XS::encode_json  | json, serialize                                 |    6300   |      0.16 |             13523.23% |                 8.44% | 2.1e-07 |      20 |
 | JSON::MaybeXS::encode_json     | json, serialize                                 |    6300   |      0.16 |             13559.24% |                 8.15% | 2.7e-07 |      20 |
 | JSON::XS::encode_json          | json, serialize                                 |    6600   |      0.15 |             14095.89% |                 4.06% |   2e-07 |      22 |
 | JSON::Create::create_json      | json, serialize                                 |    6900   |      0.15 |             14672.84% |                 0.00% |   2e-07 |      23 |
 +--------------------------------+-------------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                         Rate  YO:D yaml, serialize  Y:D yaml, serialize  JP:e_j json, serialize  JT:e_j json, serialize  MEE:e json, serialize  YS:D yaml, serialize  YX:D yaml, serialize  S:e_s binary, sereal, serialize  DM:p binary, msgpack, serialize  S:f binary, storable, serialize, cant_handle_scalar  CJX:e_j json, serialize  JM:e_j json, serialize  JX:e_j json, serialize  JC:c_j json, serialize 
  YO:D yaml, serialize                                   46/s                    --                  -5%                    -92%                    -93%                   -95%                  -95%                  -95%                             -99%                             -99%                                                 -99%                     -99%                    -99%                    -99%                    -99% 
  Y:D yaml, serialize                                  47.8/s                    5%                   --                    -91%                    -93%                   -94%                  -94%                  -95%                             -98%                             -99%                                                 -99%                     -99%                    -99%                    -99%                    -99% 
  JP:e_j json, serialize                                600/s                 1194%                1129%                      --                    -17%                   -35%                  -38%                  -41%                             -87%                             -90%                                                 -90%                     -90%                    -90%                    -91%                    -91% 
  JT:e_j json, serialize                                710/s                 1471%                1392%                     21%                      --                   -21%                  -24%                  -28%                             -85%                             -87%                                                 -87%                     -88%                    -88%                    -89%                    -89% 
  MEE:e json, serialize                                 910/s                 1900%                1799%                     54%                     27%                     --                   -4%                   -9%                             -80%                             -84%                                                 -84%                     -85%                    -85%                    -86%                    -86% 
  YS:D yaml, serialize                                  957/s                 1995%                1890%                     61%                     33%                     4%                    --                   -4%                             -80%                             -83%                                                 -83%                     -84%                    -84%                    -85%                    -85% 
  YX:D yaml, serialize                                  960/s                 2100%                1989%                     70%                     39%                    10%                    5%                    --                             -79%                             -83%                                                 -83%                     -84%                    -84%                    -85%                    -85% 
  S:e_s binary, sereal, serialize                      4800/s                10376%                9852%                    709%                    566%                   423%                  400%                  376%                               --                             -19%                                                 -19%                     -23%                    -23%                    -28%                    -28% 
  DM:p binary, msgpack, serialize                      5800/s                12841%               12194%                    899%                    723%                   547%                  517%                  488%                              23%                               --                                                   0%                      -5%                     -5%                    -11%                    -11% 
  S:f binary, storable, serialize, cant_handle_scalar  5800/s                12841%               12194%                    899%                    723%                   547%                  517%                  488%                              23%                               0%                                                   --                      -5%                     -5%                    -11%                    -11% 
  CJX:e_j json, serialize                              6300/s                13650%               12962%                    962%                    775%                   587%                  556%                  525%                              31%                               6%                                                   6%                       --                      0%                     -6%                     -6% 
  JM:e_j json, serialize                               6300/s                13650%               12962%                    962%                    775%                   587%                  556%                  525%                              31%                               6%                                                   6%                       0%                      --                     -6%                     -6% 
  JX:e_j json, serialize                               6600/s                14566%               13833%                   1033%                    833%                   633%                  600%                  566%                              39%                              13%                                                  13%                       6%                      6%                      --                      0% 
  JC:c_j json, serialize                               6900/s                14566%               13833%                   1033%                    833%                   633%                  600%                  566%                              39%                              13%                                                  13%                       6%                      6%                      0%                      -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   S:f binary, storable, serialize, cant_handle_scalar: p_tags=binary, storable, serialize, cant_handle_scalar participant=Storable::freeze
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 9 of 11):

 #table9#
 {dataset=>"num"}
 +--------------------------------+----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                     | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | YAML::Dump                     | yaml, serialize            |     23000 | 43        |                 0.00% |             26302.08% | 2.3e-07 |      20 |
 | YAML::Old::Dump                | yaml, serialize            |     24000 | 42        |                 3.16% |             25493.61% | 6.2e-08 |      23 |
 | MarpaX::ESLIF::ECMA404::encode | json, serialize            |    162000 |  6.19     |               600.69% |              3668.02% |   5e-09 |      20 |
 | JSON::PP::encode_json          | json, serialize            |    200000 |  4        |               863.76% |              2639.48% | 7.4e-08 |      20 |
 | YAML::Syck::Dump               | yaml, serialize            |    230640 |  4.3358   |               899.90% |              2540.47% | 5.8e-12 |      20 |
 | JSON::Tiny::encode_json        | json, serialize            |    315850 |  3.166    |              1269.32% |              1828.11% | 1.7e-11 |      20 |
 | YAML::XS::Dump                 | yaml, serialize            |    300000 |  3        |              1390.81% |              1670.99% | 8.1e-08 |      20 |
 | Cpanel::JSON::XS::encode_json  | json, serialize            |   2390000 |  0.418    |             10272.15% |               154.55% | 1.8e-10 |      26 |
 | JSON::MaybeXS::encode_json     | json, serialize            |   2404000 |  0.416    |             10321.60% |               153.34% | 2.3e-11 |      21 |
 | JSON::XS::encode_json          | json, serialize            |   2595000 |  0.3853   |             11150.38% |               134.68% | 5.8e-12 |      21 |
 | JSON::Create::create_json      | json, serialize            |   3600000 |  0.278    |             15520.48% |                69.02% |   1e-10 |      20 |
 | Sereal::encode_sereal          | binary, sereal, serialize  |   4500000 |  0.222    |             19422.44% |                35.24% | 1.1e-10 |      20 |
 | Data::MessagePack::pack        | binary, msgpack, serialize |   6089990 |  0.164204 |             26302.08% |                 0.00% |   0     |      20 |
 +--------------------------------+----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                        Rate  Y:D yaml, serialize  YO:D yaml, serialize  MEE:e json, serialize  YS:D yaml, serialize  JP:e_j json, serialize  JT:e_j json, serialize  YX:D yaml, serialize  CJX:e_j json, serialize  JM:e_j json, serialize  JX:e_j json, serialize  JC:c_j json, serialize  S:e_s binary, sereal, serialize  DM:p binary, msgpack, serialize 
  Y:D yaml, serialize                23000/s                   --                   -2%                   -85%                  -89%                    -90%                    -92%                  -93%                     -99%                    -99%                    -99%                    -99%                             -99%                             -99% 
  YO:D yaml, serialize               24000/s                   2%                    --                   -85%                  -89%                    -90%                    -92%                  -92%                     -99%                    -99%                    -99%                    -99%                             -99%                             -99% 
  MEE:e json, serialize             162000/s                 594%                  578%                     --                  -29%                    -35%                    -48%                  -51%                     -93%                    -93%                    -93%                    -95%                             -96%                             -97% 
  YS:D yaml, serialize              230640/s                 891%                  868%                    42%                    --                     -7%                    -26%                  -30%                     -90%                    -90%                    -91%                    -93%                             -94%                             -96% 
  JP:e_j json, serialize            200000/s                 975%                  950%                    54%                    8%                      --                    -20%                  -25%                     -89%                    -89%                    -90%                    -93%                             -94%                             -95% 
  JT:e_j json, serialize            315850/s                1258%                 1226%                    95%                   36%                     26%                      --                   -5%                     -86%                    -86%                    -87%                    -91%                             -92%                             -94% 
  YX:D yaml, serialize              300000/s                1333%                 1300%                   106%                   44%                     33%                      5%                    --                     -86%                    -86%                    -87%                    -90%                             -92%                             -94% 
  CJX:e_j json, serialize          2390000/s               10187%                 9947%                  1380%                  937%                    856%                    657%                  617%                       --                      0%                     -7%                    -33%                             -46%                             -60% 
  JM:e_j json, serialize           2404000/s               10236%                 9996%                  1387%                  942%                    861%                    661%                  621%                       0%                      --                     -7%                    -33%                             -46%                             -60% 
  JX:e_j json, serialize           2595000/s               11060%                10800%                  1506%                 1025%                    938%                    721%                  678%                       8%                      7%                      --                    -27%                             -42%                             -57% 
  JC:c_j json, serialize           3600000/s               15367%                15007%                  2126%                 1459%                   1338%                   1038%                  979%                      50%                     49%                     38%                      --                             -20%                             -40% 
  S:e_s binary, sereal, serialize  4500000/s               19269%                18818%                  2688%                 1853%                   1701%                   1326%                 1251%                      88%                     87%                     73%                     25%                               --                             -26% 
  DM:p binary, msgpack, serialize  6089990/s               26086%                25477%                  3669%                 2540%                   2335%                   1828%                 1726%                     154%                    153%                    134%                     69%                              35%                               -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 10 of 11):

 #table10#
 {dataset=>"str1k"}
 +--------------------------------+--------------------+----------------------------+------------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | ds_tags            | p_tags                     | rate (/s)  | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+--------------------+----------------------------+------------+-----------+-----------------------+-----------------------+---------+---------+
 | MarpaX::ESLIF::ECMA404::encode | serialize, unicode | json, serialize            |    7980.61 |  125.304  |                 0.00% |             56507.76% | 1.7e-11 |      20 |
 | YAML::Dump                     | serialize, unicode | yaml, serialize            |   13000    |   75      |                67.18% |             33759.57% | 1.3e-07 |      20 |
 | YAML::Old::Dump                | serialize, unicode | yaml, serialize            |   13500    |   73.9    |                69.54% |             33288.40% | 2.7e-08 |      20 |
 | MarpaX::ESLIF::ECMA404::encode | serialize          | json, serialize            |   15000    |   68      |                84.90% |             30514.88% |   8e-08 |      20 |
 | YAML::Dump                     | serialize          | yaml, serialize            |   22000    |   45      |               175.56% |             20442.73% | 1.7e-07 |      20 |
 | YAML::Old::Dump                | serialize          | yaml, serialize            |   23000    |   44      |               182.36% |             19947.80% | 9.4e-08 |      26 |
 | JSON::PP::encode_json          | serialize, unicode | json, serialize            |   34000    |   29      |               327.94% |             13127.96% | 5.3e-08 |      20 |
 | JSON::Tiny::encode_json        | serialize, unicode | json, serialize            |   38300    |   26.1    |               380.13% |             11690.03% | 1.3e-08 |      20 |
 | YAML::XS::Dump                 | serialize, unicode | yaml, serialize            |   55000    |   18      |               583.66% |              8180.08% | 9.3e-08 |      20 |
 | JSON::MaybeXS::encode_json     | serialize, unicode | json, serialize            |   80000    |   13      |               902.04% |              5549.28% | 2.7e-08 |      20 |
 | Cpanel::JSON::XS::encode_json  | serialize, unicode | json, serialize            |   80000    |   12      |               907.74% |              5517.30% |   3e-08 |      20 |
 | JSON::XS::encode_json          | serialize, unicode | json, serialize            |   90719.5  |   11.023  |              1036.75% |              4879.80% | 5.8e-12 |      20 |
 | YAML::XS::Dump                 | serialize          | yaml, serialize            |  100000    |    9.7    |              1186.09% |              4301.54% | 1.3e-08 |      20 |
 | YAML::Syck::Dump               | serialize, unicode | yaml, serialize            |  110000    |    9.05   |              1284.04% |              3990.05% | 3.4e-09 |      20 |
 | YAML::Syck::Dump               | serialize          | yaml, serialize            |  180000    |    5.4    |              2212.12% |              2348.31% | 6.7e-09 |      20 |
 | JSON::Create::create_json      | serialize, unicode | json, serialize            |  212460    |    4.7067 |              2562.24% |              2026.32% | 2.3e-11 |      20 |
 | JSON::PP::encode_json          | serialize          | json, serialize            |  239000    |    4.19   |              2892.46% |              1791.68% | 1.4e-09 |      30 |
 | JSON::Tiny::encode_json        | serialize          | json, serialize            |  255000    |    3.92   |              3099.43% |              1669.31% | 1.4e-09 |      28 |
 | JSON::Create::create_json      | serialize          | json, serialize            |  495600    |    2.018  |              6109.95% |               811.57% | 2.3e-11 |      20 |
 | Cpanel::JSON::XS::encode_json  | serialize          | json, serialize            |  520000    |    1.9    |              6428.93% |               767.03% | 2.4e-09 |      22 |
 | JSON::MaybeXS::encode_json     | serialize          | json, serialize            |  522890    |    1.9124 |              6452.04% |               763.97% | 5.7e-12 |      20 |
 | JSON::XS::encode_json          | serialize          | json, serialize            |  560920    |    1.7828 |              6928.53% |               705.40% | 5.7e-12 |      20 |
 | Sereal::encode_sereal          | serialize, unicode | binary, sereal, serialize  | 3690000    |    0.271  |             46173.05% |                22.33% |   1e-10 |      20 |
 | Sereal::encode_sereal          | serialize          | binary, sereal, serialize  | 3900000    |    0.26   |             48209.48% |                17.18% | 4.2e-10 |      20 |
 | Data::MessagePack::pack        | serialize, unicode | binary, msgpack, serialize | 4240000    |    0.236  |             52983.86% |                 6.64% | 1.1e-10 |      20 |
 | Data::MessagePack::pack        | serialize          | binary, msgpack, serialize | 4500000    |    0.22   |             56507.76% |                 0.00% | 3.1e-10 |      20 |
 +--------------------------------+--------------------+----------------------------+------------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                           Rate  MEE:e json, serialize serialize, unicode  Y:D yaml, serialize serialize, unicode  YO:D yaml, serialize serialize, unicode  MEE:e json, serialize serialize  Y:D yaml, serialize serialize  YO:D yaml, serialize serialize  JP:e_j json, serialize serialize, unicode  JT:e_j json, serialize serialize, unicode  YX:D yaml, serialize serialize, unicode  JM:e_j json, serialize serialize, unicode  CJX:e_j json, serialize serialize, unicode  JX:e_j json, serialize serialize, unicode  YX:D yaml, serialize serialize  YS:D yaml, serialize serialize, unicode  YS:D yaml, serialize serialize  JC:c_j json, serialize serialize, unicode  JP:e_j json, serialize serialize  JT:e_j json, serialize serialize  JC:c_j json, serialize serialize  JM:e_j json, serialize serialize  CJX:e_j json, serialize serialize  JX:e_j json, serialize serialize  S:e_s binary, sereal, serialize serialize, unicode  S:e_s binary, sereal, serialize serialize  DM:p binary, msgpack, serialize serialize, unicode  DM:p binary, msgpack, serialize serialize 
  MEE:e json, serialize serialize, unicode            7980.61/s                                        --                                    -40%                                     -41%                             -45%                           -64%                            -64%                                       -76%                                       -79%                                     -85%                                       -89%                                        -90%                                       -91%                            -92%                                     -92%                            -95%                                       -96%                              -96%                              -96%                              -98%                              -98%                               -98%                              -98%                                                -99%                                       -99%                                                -99%                                       -99% 
  Y:D yaml, serialize serialize, unicode                13000/s                                       67%                                      --                                      -1%                              -9%                           -40%                            -41%                                       -61%                                       -65%                                     -76%                                       -82%                                        -84%                                       -85%                            -87%                                     -87%                            -92%                                       -93%                              -94%                              -94%                              -97%                              -97%                               -97%                              -97%                                                -99%                                       -99%                                                -99%                                       -99% 
  YO:D yaml, serialize serialize, unicode               13500/s                                       69%                                      1%                                       --                              -7%                           -39%                            -40%                                       -60%                                       -64%                                     -75%                                       -82%                                        -83%                                       -85%                            -86%                                     -87%                            -92%                                       -93%                              -94%                              -94%                              -97%                              -97%                               -97%                              -97%                                                -99%                                       -99%                                                -99%                                       -99% 
  MEE:e json, serialize serialize                       15000/s                                       84%                                     10%                                       8%                               --                           -33%                            -35%                                       -57%                                       -61%                                     -73%                                       -80%                                        -82%                                       -83%                            -85%                                     -86%                            -92%                                       -93%                              -93%                              -94%                              -97%                              -97%                               -97%                              -97%                                                -99%                                       -99%                                                -99%                                       -99% 
  Y:D yaml, serialize serialize                         22000/s                                      178%                                     66%                                      64%                              51%                             --                             -2%                                       -35%                                       -41%                                     -60%                                       -71%                                        -73%                                       -75%                            -78%                                     -79%                            -88%                                       -89%                              -90%                              -91%                              -95%                              -95%                               -95%                              -96%                                                -99%                                       -99%                                                -99%                                       -99% 
  YO:D yaml, serialize serialize                        23000/s                                      184%                                     70%                                      67%                              54%                             2%                              --                                       -34%                                       -40%                                     -59%                                       -70%                                        -72%                                       -74%                            -77%                                     -79%                            -87%                                       -89%                              -90%                              -91%                              -95%                              -95%                               -95%                              -95%                                                -99%                                       -99%                                                -99%                                       -99% 
  JP:e_j json, serialize serialize, unicode             34000/s                                      332%                                    158%                                     154%                             134%                            55%                             51%                                         --                                        -9%                                     -37%                                       -55%                                        -58%                                       -61%                            -66%                                     -68%                            -81%                                       -83%                              -85%                              -86%                              -93%                              -93%                               -93%                              -93%                                                -99%                                       -99%                                                -99%                                       -99% 
  JT:e_j json, serialize serialize, unicode             38300/s                                      380%                                    187%                                     183%                             160%                            72%                             68%                                        11%                                         --                                     -31%                                       -50%                                        -54%                                       -57%                            -62%                                     -65%                            -79%                                       -81%                              -83%                              -84%                              -92%                              -92%                               -92%                              -93%                                                -98%                                       -99%                                                -99%                                       -99% 
  YX:D yaml, serialize serialize, unicode               55000/s                                      596%                                    316%                                     310%                             277%                           150%                            144%                                        61%                                        45%                                       --                                       -27%                                        -33%                                       -38%                            -46%                                     -49%                            -70%                                       -73%                              -76%                              -78%                              -88%                              -89%                               -89%                              -90%                                                -98%                                       -98%                                                -98%                                       -98% 
  JM:e_j json, serialize serialize, unicode             80000/s                                      863%                                    476%                                     468%                             423%                           246%                            238%                                       123%                                       100%                                      38%                                         --                                         -7%                                       -15%                            -25%                                     -30%                            -58%                                       -63%                              -67%                              -69%                              -84%                              -85%                               -85%                              -86%                                                -97%                                       -98%                                                -98%                                       -98% 
  CJX:e_j json, serialize serialize, unicode            80000/s                                      944%                                    525%                                     515%                             466%                           275%                            266%                                       141%                                       117%                                      50%                                         8%                                          --                                        -8%                            -19%                                     -24%                            -55%                                       -60%                              -65%                              -67%                              -83%                              -84%                               -84%                              -85%                                                -97%                                       -97%                                                -98%                                       -98% 
  JX:e_j json, serialize serialize, unicode           90719.5/s                                     1036%                                    580%                                     570%                             516%                           308%                            299%                                       163%                                       136%                                      63%                                        17%                                          8%                                         --                            -12%                                     -17%                            -51%                                       -57%                              -61%                              -64%                              -81%                              -82%                               -82%                              -83%                                                -97%                                       -97%                                                -97%                                       -98% 
  YX:D yaml, serialize serialize                       100000/s                                     1191%                                    673%                                     661%                             601%                           363%                            353%                                       198%                                       169%                                      85%                                        34%                                         23%                                        13%                              --                                      -6%                            -44%                                       -51%                              -56%                              -59%                              -79%                              -80%                               -80%                              -81%                                                -97%                                       -97%                                                -97%                                       -97% 
  YS:D yaml, serialize serialize, unicode              110000/s                                     1284%                                    728%                                     716%                             651%                           397%                            386%                                       220%                                       188%                                      98%                                        43%                                         32%                                        21%                              7%                                       --                            -40%                                       -47%                              -53%                              -56%                              -77%                              -78%                               -79%                              -80%                                                -97%                                       -97%                                                -97%                                       -97% 
  YS:D yaml, serialize serialize                       180000/s                                     2220%                                   1288%                                    1268%                            1159%                           733%                            714%                                       437%                                       383%                                     233%                                       140%                                        122%                                       104%                             79%                                      67%                              --                                       -12%                              -22%                              -27%                              -62%                              -64%                               -64%                              -66%                                                -94%                                       -95%                                                -95%                                       -95% 
  JC:c_j json, serialize serialize, unicode            212460/s                                     2562%                                   1493%                                    1470%                            1344%                           856%                            834%                                       516%                                       454%                                     282%                                       176%                                        154%                                       134%                            106%                                      92%                             14%                                         --                              -10%                              -16%                              -57%                              -59%                               -59%                              -62%                                                -94%                                       -94%                                                -94%                                       -95% 
  JP:e_j json, serialize serialize                     239000/s                                     2890%                                   1689%                                    1663%                            1522%                           973%                            950%                                       592%                                       522%                                     329%                                       210%                                        186%                                       163%                            131%                                     115%                             28%                                        12%                                --                               -6%                              -51%                              -54%                               -54%                              -57%                                                -93%                                       -93%                                                -94%                                       -94% 
  JT:e_j json, serialize serialize                     255000/s                                     3096%                                   1813%                                    1785%                            1634%                          1047%                           1022%                                       639%                                       565%                                     359%                                       231%                                        206%                                       181%                            147%                                     130%                             37%                                        20%                                6%                                --                              -48%                              -51%                               -51%                              -54%                                                -93%                                       -93%                                                -93%                                       -94% 
  JC:c_j json, serialize serialize                     495600/s                                     6109%                                   3616%                                    3562%                            3269%                          2129%                           2080%                                      1337%                                      1193%                                     791%                                       544%                                        494%                                       446%                            380%                                     348%                            167%                                       133%                              107%                               94%                                --                               -5%                                -5%                              -11%                                                -86%                                       -87%                                                -88%                                       -89% 
  JM:e_j json, serialize serialize                     522890/s                                     6452%                                   3821%                                    3764%                            3455%                          2253%                           2200%                                      1416%                                      1264%                                     841%                                       579%                                        527%                                       476%                            407%                                     373%                            182%                                       146%                              119%                              104%                                5%                                --                                 0%                               -6%                                                -85%                                       -86%                                                -87%                                       -88% 
  CJX:e_j json, serialize serialize                    520000/s                                     6494%                                   3847%                                    3789%                            3478%                          2268%                           2215%                                      1426%                                      1273%                                     847%                                       584%                                        531%                                       480%                            410%                                     376%                            184%                                       147%                              120%                              106%                                6%                                0%                                 --                               -6%                                                -85%                                       -86%                                                -87%                                       -88% 
  JX:e_j json, serialize serialize                     560920/s                                     6928%                                   4106%                                    4045%                            3714%                          2424%                           2368%                                      1526%                                      1363%                                     909%                                       629%                                        573%                                       518%                            444%                                     407%                            202%                                       164%                              135%                              119%                               13%                                7%                                 6%                                --                                                -84%                                       -85%                                                -86%                                       -87% 
  S:e_s binary, sereal, serialize serialize, unicode  3690000/s                                    46137%                                  27575%                                   27169%                           24992%                         16505%                          16136%                                     10601%                                      9530%                                    6542%                                      4697%                                       4328%                                      3967%                           3479%                                    3239%                           1892%                                      1636%                             1446%                             1346%                              644%                              605%                               601%                              557%                                                  --                                        -4%                                                -12%                                       -18% 
  S:e_s binary, sereal, serialize serialize           3900000/s                                    48093%                                  28746%                                   28323%                           26053%                         17207%                          16823%                                     11053%                                      9938%                                    6823%                                      4900%                                       4515%                                      4139%                           3630%                                    3380%                           1976%                                      1710%                             1511%                             1407%                              676%                              635%                               630%                              585%                                                  4%                                         --                                                 -9%                                       -15% 
  DM:p binary, msgpack, serialize serialize, unicode  4240000/s                                    52994%                                  31679%                                   31213%                           28713%                         18967%                          18544%                                     12188%                                     10959%                                    7527%                                      5408%                                       4984%                                      4570%                           4010%                                    3734%                           2188%                                      1894%                             1675%                             1561%                              755%                              710%                               705%                              655%                                                 14%                                        10%                                                  --                                        -6% 
  DM:p binary, msgpack, serialize serialize           4500000/s                                    56856%                                  33990%                                   33490%                           30809%                         20354%                          19900%                                     13081%                                     11763%                                    8081%                                      5809%                                       5354%                                      4910%                           4309%                                    4013%                           2354%                                      2039%                             1804%                             1681%                              817%                              769%                               763%                              710%                                                 23%                                        18%                                                  7%                                         -- 
 
 Legends:
   CJX:e_j json, serialize serialize: ds_tags=serialize p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   CJX:e_j json, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize serialize: ds_tags=serialize p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   DM:p binary, msgpack, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize serialize: ds_tags=serialize p_tags=json, serialize participant=JSON::Create::create_json
   JC:c_j json, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize serialize: ds_tags=serialize p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JM:e_j json, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize serialize: ds_tags=serialize p_tags=json, serialize participant=JSON::PP::encode_json
   JP:e_j json, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize serialize: ds_tags=serialize p_tags=json, serialize participant=JSON::Tiny::encode_json
   JT:e_j json, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize serialize: ds_tags=serialize p_tags=json, serialize participant=JSON::XS::encode_json
   JX:e_j json, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize serialize: ds_tags=serialize p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   MEE:e json, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize serialize: ds_tags=serialize p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   S:e_s binary, sereal, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   Y:D yaml, serialize serialize: ds_tags=serialize p_tags=yaml, serialize participant=YAML::Dump
   Y:D yaml, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize serialize: ds_tags=serialize p_tags=yaml, serialize participant=YAML::Old::Dump
   YO:D yaml, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize serialize: ds_tags=serialize p_tags=yaml, serialize participant=YAML::Syck::Dump
   YS:D yaml, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize serialize: ds_tags=serialize p_tags=yaml, serialize participant=YAML::XS::Dump
   YX:D yaml, serialize serialize, unicode: ds_tags=serialize, unicode p_tags=yaml, serialize participant=YAML::XS::Dump

Result formatted as table (split, part 11 of 11):

 #table11#
 {dataset=>"undef"}
 +--------------------------------+----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | p_tags                     | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | YAML::Old::Dump                | yaml, serialize            |     27000 |   37      |                 0.00% |             35200.11% | 6.4e-08 |      22 |
 | YAML::Dump                     | yaml, serialize            |     27000 |   36      |                 0.26% |             35108.86% | 1.7e-07 |      21 |
 | MarpaX::ESLIF::ECMA404::encode | json, serialize            |    176000 |    5.68   |               544.71% |              5375.31% | 4.8e-09 |      22 |
 | YAML::Syck::Dump               | yaml, serialize            |    282520 |    3.5395 |               933.84% |              3314.45% | 1.7e-11 |      25 |
 | JSON::Tiny::encode_json        | json, serialize            |    510000 |    2      |              1755.06% |              1802.91% | 1.1e-08 |      20 |
 | JSON::PP::encode_json          | json, serialize            |    666000 |    1.5    |              2336.54% |              1348.78% | 4.2e-10 |      20 |
 | YAML::XS::Dump                 | yaml, serialize            |    690000 |    1.5    |              2417.74% |              1302.05% |   1e-08 |      20 |
 | Sereal::encode_sereal          | binary, sereal, serialize  |   5130000 |    0.195  |             18664.60% |                88.12% |   1e-10 |      21 |
 | Data::MessagePack::pack        | binary, msgpack, serialize |   7100000 |    0.14   |             25872.75% |                35.91% | 2.1e-10 |      20 |
 | Cpanel::JSON::XS::encode_json  | json, serialize            |   7300000 |    0.14   |             26778.60% |                31.33% | 2.1e-10 |      20 |
 | JSON::MaybeXS::encode_json     | json, serialize            |   7420000 |    0.135  |             27048.85% |                30.02% | 1.7e-11 |      20 |
 | JSON::XS::encode_json          | json, serialize            |   7800000 |    0.13   |             28555.77% |                23.19% | 2.5e-10 |      20 |
 | JSON::Create::create_json      | json, serialize            |   9600000 |    0.1    |             35200.11% |                 0.00% | 1.6e-10 |      20 |
 +--------------------------------+----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                        Rate  YO:D yaml, serialize  Y:D yaml, serialize  MEE:e json, serialize  YS:D yaml, serialize  JT:e_j json, serialize  JP:e_j json, serialize  YX:D yaml, serialize  S:e_s binary, sereal, serialize  DM:p binary, msgpack, serialize  CJX:e_j json, serialize  JM:e_j json, serialize  JX:e_j json, serialize  JC:c_j json, serialize 
  YO:D yaml, serialize               27000/s                    --                  -2%                   -84%                  -90%                    -94%                    -95%                  -95%                             -99%                             -99%                     -99%                    -99%                    -99%                    -99% 
  Y:D yaml, serialize                27000/s                    2%                   --                   -84%                  -90%                    -94%                    -95%                  -95%                             -99%                             -99%                     -99%                    -99%                    -99%                    -99% 
  MEE:e json, serialize             176000/s                  551%                 533%                     --                  -37%                    -64%                    -73%                  -73%                             -96%                             -97%                     -97%                    -97%                    -97%                    -98% 
  YS:D yaml, serialize              282520/s                  945%                 917%                    60%                    --                    -43%                    -57%                  -57%                             -94%                             -96%                     -96%                    -96%                    -96%                    -97% 
  JT:e_j json, serialize            510000/s                 1750%                1700%                   184%                   76%                      --                    -25%                  -25%                             -90%                             -93%                     -93%                    -93%                    -93%                    -95% 
  JP:e_j json, serialize            666000/s                 2366%                2300%                   278%                  135%                     33%                      --                    0%                             -87%                             -90%                     -90%                    -91%                    -91%                    -93% 
  YX:D yaml, serialize              690000/s                 2366%                2300%                   278%                  135%                     33%                      0%                    --                             -87%                             -90%                     -90%                    -91%                    -91%                    -93% 
  S:e_s binary, sereal, serialize  5130000/s                18874%               18361%                  2812%                 1715%                    925%                    669%                  669%                               --                             -28%                     -28%                    -30%                    -33%                    -48% 
  DM:p binary, msgpack, serialize  7100000/s                26328%               25614%                  3957%                 2428%                   1328%                    971%                  971%                              39%                               --                       0%                     -3%                     -7%                    -28% 
  CJX:e_j json, serialize          7300000/s                26328%               25614%                  3957%                 2428%                   1328%                    971%                  971%                              39%                               0%                       --                     -3%                     -7%                    -28% 
  JM:e_j json, serialize           7420000/s                27307%               26566%                  4107%                 2521%                   1381%                   1011%                 1011%                              44%                               3%                       3%                      --                     -3%                    -25% 
  JX:e_j json, serialize           7800000/s                28361%               27592%                  4269%                 2622%                   1438%                   1053%                 1053%                              50%                               7%                       7%                      3%                      --                    -23% 
  JC:c_j json, serialize           9600000/s                36900%               35900%                  5580%                 3439%                   1900%                   1400%                 1400%                              95%                              40%                      40%                     35%                     30%                      -- 
 
 Legends:
   CJX:e_j json, serialize: p_tags=json, serialize participant=Cpanel::JSON::XS::encode_json
   DM:p binary, msgpack, serialize: p_tags=binary, msgpack, serialize participant=Data::MessagePack::pack
   JC:c_j json, serialize: p_tags=json, serialize participant=JSON::Create::create_json
   JM:e_j json, serialize: p_tags=json, serialize participant=JSON::MaybeXS::encode_json
   JP:e_j json, serialize: p_tags=json, serialize participant=JSON::PP::encode_json
   JT:e_j json, serialize: p_tags=json, serialize participant=JSON::Tiny::encode_json
   JX:e_j json, serialize: p_tags=json, serialize participant=JSON::XS::encode_json
   MEE:e json, serialize: p_tags=json, serialize participant=MarpaX::ESLIF::ECMA404::encode
   S:e_s binary, sereal, serialize: p_tags=binary, sereal, serialize participant=Sereal::encode_sereal
   Y:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Dump
   YO:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Old::Dump
   YS:D yaml, serialize: p_tags=yaml, serialize participant=YAML::Syck::Dump
   YX:D yaml, serialize: p_tags=yaml, serialize participant=YAML::XS::Dump


=head2 Sample benchmark #2

Benchmark command (deserializing):

 % bencher -m Serializers --include-participant-tags deserialize

Result formatted as table (split, part 1 of 12):

 #table12#
 {dataset=>"json:array_int_10"}
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                     | p_tags                                | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | JSON::Decode::Marpa::from_json  | json, deserialize, cant_handle_scalar |      1700 |   580     |                 0.00% |            122116.71% | 6.9e-07 |      20 |
 | Pegex::JSON                     | json, deserialize                     |      2300 |   440     |                30.25% |             93731.16% | 2.3e-06 |      20 |
 | MarpaX::ESLIF::ECMA404::decode  | json, deserialize                     |     15000 |    69     |               740.91% |             14433.89% | 1.3e-07 |      20 |
 | JSON::PP::decode_json           | json, deserialize                     |     43000 |    23     |              2361.60% |              4864.93% | 2.5e-08 |      23 |
 | JSON::Decode::Regexp::from_json | json, deserialize                     |     53000 |    18.9   |              2959.66% |              3894.46% | 6.2e-09 |      23 |
 | JSON::Tiny::decode_json         | json, deserialize                     |     63000 |    16     |              3534.70% |              3262.50% | 2.7e-08 |      20 |
 | JSON::XS::decode_json           | json, deserialize                     |   1000000 |     0.9   |             67482.69% |                80.84% | 3.6e-08 |      29 |
 | JSON::MaybeXS::decode_json      | json, deserialize                     |   2040000 |     0.491 |            117371.78% |                 4.04% |   2e-10 |      22 |
 | Cpanel::JSON::XS::decode_json   | json, deserialize                     |   2070000 |     0.484 |            119207.04% |                 2.44% | 1.2e-10 |      22 |
 | JSON::Parse::parse_json         | json, deserialize                     |   2120000 |     0.472 |            122116.71% |                 0.00% | 2.1e-10 |      20 |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                      Rate  JDM:f_j json, deserialize, cant_handle_scalar  P:J json, deserialize  MEE:d json, deserialize  JP:d_j json, deserialize  JDR:f_j json, deserialize  JT:d_j json, deserialize  JX:d_j json, deserialize  JM:d_j json, deserialize  CJX:d_j json, deserialize  JP:p_j json, deserialize 
  JDM:f_j json, deserialize, cant_handle_scalar     1700/s                                             --                   -24%                     -88%                      -96%                       -96%                      -97%                      -99%                      -99%                       -99%                      -99% 
  P:J json, deserialize                             2300/s                                            31%                     --                     -84%                      -94%                       -95%                      -96%                      -99%                      -99%                       -99%                      -99% 
  MEE:d json, deserialize                          15000/s                                           740%                   537%                       --                      -66%                       -72%                      -76%                      -98%                      -99%                       -99%                      -99% 
  JP:d_j json, deserialize                         43000/s                                          2421%                  1813%                     200%                        --                       -17%                      -30%                      -96%                      -97%                       -97%                      -97% 
  JDR:f_j json, deserialize                        53000/s                                          2968%                  2228%                     265%                       21%                         --                      -15%                      -95%                      -97%                       -97%                      -97% 
  JT:d_j json, deserialize                         63000/s                                          3525%                  2650%                     331%                       43%                        18%                        --                      -94%                      -96%                       -96%                      -97% 
  JX:d_j json, deserialize                       1000000/s                                         64344%                 48788%                    7566%                     2455%                      1999%                     1677%                        --                      -45%                       -46%                      -47% 
  JM:d_j json, deserialize                       2040000/s                                        118026%                 89513%                   13952%                     4584%                      3749%                     3158%                       83%                        --                        -1%                       -3% 
  CJX:d_j json, deserialize                      2070000/s                                        119734%                 90809%                   14156%                     4652%                      3804%                     3205%                       85%                        1%                         --                       -2% 
  JP:p_j json, deserialize                       2120000/s                                        122781%                 93120%                   14518%                     4772%                      3904%                     3289%                       90%                        4%                         2%                        -- 
 
 Legends:
   CJX:d_j json, deserialize: p_tags=json, deserialize participant=Cpanel::JSON::XS::decode_json
   JDM:f_j json, deserialize, cant_handle_scalar: p_tags=json, deserialize, cant_handle_scalar participant=JSON::Decode::Marpa::from_json
   JDR:f_j json, deserialize: p_tags=json, deserialize participant=JSON::Decode::Regexp::from_json
   JM:d_j json, deserialize: p_tags=json, deserialize participant=JSON::MaybeXS::decode_json
   JP:d_j json, deserialize: p_tags=json, deserialize participant=JSON::PP::decode_json
   JP:p_j json, deserialize: p_tags=json, deserialize participant=JSON::Parse::parse_json
   JT:d_j json, deserialize: p_tags=json, deserialize participant=JSON::Tiny::decode_json
   JX:d_j json, deserialize: p_tags=json, deserialize participant=JSON::XS::decode_json
   MEE:d json, deserialize: p_tags=json, deserialize participant=MarpaX::ESLIF::ECMA404::decode
   P:J json, deserialize: p_tags=json, deserialize participant=Pegex::JSON

Result formatted as table (split, part 2 of 12):

 #table13#
 {dataset=>"json:array_int_100"}
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                     | p_tags                                | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Pegex::JSON                     | json, deserialize                     |    520    |  1.9      |                 0.00% |             65528.56% | 7.1e-06 |      20 |
 | JSON::Decode::Marpa::from_json  | json, deserialize, cant_handle_scalar |    580    |  1.7      |                11.16% |             58940.08% | 3.3e-06 |      20 |
 | MarpaX::ESLIF::ECMA404::decode  | json, deserialize                     |   2210    |  0.453    |               321.94% |             15454.17% | 2.1e-07 |      20 |
 | JSON::PP::decode_json           | json, deserialize                     |   4270    |  0.234    |               715.61% |              7946.53% | 2.1e-07 |      20 |
 | JSON::Decode::Regexp::from_json | json, deserialize                     |   5900    |  0.17     |              1020.03% |              5759.52% | 2.1e-07 |      20 |
 | JSON::Tiny::decode_json         | json, deserialize                     |   8475.08 |  0.117993 |              1518.66% |              3954.50% |   0     |      26 |
 | JSON::XS::decode_json           | json, deserialize                     | 173000    |  0.0058   |             32852.48% |                99.16% | 1.6e-09 |      21 |
 | JSON::Parse::parse_json         | json, deserialize                     | 330000    |  0.003    |             62810.62% |                 4.32% | 6.7e-09 |      20 |
 | Cpanel::JSON::XS::decode_json   | json, deserialize                     | 330000    |  0.003    |             63859.32% |                 2.61% | 3.9e-09 |      23 |
 | JSON::MaybeXS::decode_json      | json, deserialize                     | 344000    |  0.00291  |             65528.56% |                 0.00% | 2.5e-09 |      20 |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                      Rate  P:J json, deserialize  JDM:f_j json, deserialize, cant_handle_scalar  MEE:d json, deserialize  JP:d_j json, deserialize  JDR:f_j json, deserialize  JT:d_j json, deserialize  JX:d_j json, deserialize  JP:p_j json, deserialize  CJX:d_j json, deserialize  JM:d_j json, deserialize 
  P:J json, deserialize                              520/s                     --                                           -10%                     -76%                      -87%                       -91%                      -93%                      -99%                      -99%                       -99%                      -99% 
  JDM:f_j json, deserialize, cant_handle_scalar      580/s                    11%                                             --                     -73%                      -86%                       -90%                      -93%                      -99%                      -99%                       -99%                      -99% 
  MEE:d json, deserialize                           2210/s                   319%                                           275%                       --                      -48%                       -62%                      -73%                      -98%                      -99%                       -99%                      -99% 
  JP:d_j json, deserialize                          4270/s                   711%                                           626%                      93%                        --                       -27%                      -49%                      -97%                      -98%                       -98%                      -98% 
  JDR:f_j json, deserialize                         5900/s                  1017%                                           899%                     166%                       37%                         --                      -30%                      -96%                      -98%                       -98%                      -98% 
  JT:d_j json, deserialize                       8475.08/s                  1510%                                          1340%                     283%                       98%                        44%                        --                      -95%                      -97%                       -97%                      -97% 
  JX:d_j json, deserialize                        173000/s                 32658%                                         29210%                    7710%                     3934%                      2831%                     1934%                        --                      -48%                       -48%                      -49% 
  JP:p_j json, deserialize                        330000/s                 63233%                                         56566%                   15000%                     7700%                      5566%                     3833%                       93%                        --                         0%                       -3% 
  CJX:d_j json, deserialize                       330000/s                 63233%                                         56566%                   15000%                     7700%                      5566%                     3833%                       93%                        0%                         --                       -3% 
  JM:d_j json, deserialize                        344000/s                 65192%                                         58319%                   15467%                     7941%                      5741%                     3954%                       99%                        3%                         3%                        -- 
 
 Legends:
   CJX:d_j json, deserialize: p_tags=json, deserialize participant=Cpanel::JSON::XS::decode_json
   JDM:f_j json, deserialize, cant_handle_scalar: p_tags=json, deserialize, cant_handle_scalar participant=JSON::Decode::Marpa::from_json
   JDR:f_j json, deserialize: p_tags=json, deserialize participant=JSON::Decode::Regexp::from_json
   JM:d_j json, deserialize: p_tags=json, deserialize participant=JSON::MaybeXS::decode_json
   JP:d_j json, deserialize: p_tags=json, deserialize participant=JSON::PP::decode_json
   JP:p_j json, deserialize: p_tags=json, deserialize participant=JSON::Parse::parse_json
   JT:d_j json, deserialize: p_tags=json, deserialize participant=JSON::Tiny::decode_json
   JX:d_j json, deserialize: p_tags=json, deserialize participant=JSON::XS::decode_json
   MEE:d json, deserialize: p_tags=json, deserialize participant=MarpaX::ESLIF::ECMA404::decode
   P:J json, deserialize: p_tags=json, deserialize participant=Pegex::JSON

Result formatted as table (split, part 3 of 12):

 #table14#
 {dataset=>"json:array_int_1000"}
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                     | p_tags                                | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Pegex::JSON                     | json, deserialize                     |      60   |   17      |                 0.00% |             71707.54% | 7.8e-05 |      23 |
 | JSON::Decode::Marpa::from_json  | json, deserialize, cant_handle_scalar |      72.6 |   13.8    |                21.38% |             59059.20% | 8.3e-06 |      21 |
 | MarpaX::ESLIF::ECMA404::decode  | json, deserialize                     |     220   |    4.5    |               274.55% |             19071.88% | 9.4e-06 |      20 |
 | JSON::PP::decode_json           | json, deserialize                     |     384   |    2.6    |               542.66% |             11073.57% | 1.4e-06 |      20 |
 | JSON::Decode::Regexp::from_json | json, deserialize                     |     594   |    1.68   |               893.99% |              7124.20% | 4.8e-07 |      20 |
 | JSON::Tiny::decode_json         | json, deserialize                     |     900   |    1.11   |              1405.94% |              4668.30% | 2.7e-07 |      20 |
 | JSON::XS::decode_json           | json, deserialize                     |   42000   |    0.024  |             70879.28% |                 1.17% | 2.3e-07 |      20 |
 | Cpanel::JSON::XS::decode_json   | json, deserialize                     |   42000   |    0.024  |             70902.78% |                 1.13% | 2.7e-08 |      20 |
 | JSON::MaybeXS::decode_json      | json, deserialize                     |   43000   |    0.023  |             71120.78% |                 0.82% | 5.1e-08 |      22 |
 | JSON::Parse::parse_json         | json, deserialize                     |   42900   |    0.0233 |             71707.54% |                 0.00% |   2e-08 |      20 |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                    Rate  P:J json, deserialize  JDM:f_j json, deserialize, cant_handle_scalar  MEE:d json, deserialize  JP:d_j json, deserialize  JDR:f_j json, deserialize  JT:d_j json, deserialize  JX:d_j json, deserialize  CJX:d_j json, deserialize  JP:p_j json, deserialize  JM:d_j json, deserialize 
  P:J json, deserialize                             60/s                     --                                           -18%                     -73%                      -84%                       -90%                      -93%                      -99%                       -99%                      -99%                      -99% 
  JDM:f_j json, deserialize, cant_handle_scalar   72.6/s                    23%                                             --                     -67%                      -81%                       -87%                      -91%                      -99%                       -99%                      -99%                      -99% 
  MEE:d json, deserialize                          220/s                   277%                                           206%                       --                      -42%                       -62%                      -75%                      -99%                       -99%                      -99%                      -99% 
  JP:d_j json, deserialize                         384/s                   553%                                           430%                      73%                        --                       -35%                      -57%                      -99%                       -99%                      -99%                      -99% 
  JDR:f_j json, deserialize                        594/s                   911%                                           721%                     167%                       54%                         --                      -33%                      -98%                       -98%                      -98%                      -98% 
  JT:d_j json, deserialize                         900/s                  1431%                                          1143%                     305%                      134%                        51%                        --                      -97%                       -97%                      -97%                      -97% 
  JX:d_j json, deserialize                       42000/s                 70733%                                         57400%                   18650%                    10733%                      6900%                     4525%                        --                         0%                       -2%                       -4% 
  CJX:d_j json, deserialize                      42000/s                 70733%                                         57400%                   18650%                    10733%                      6900%                     4525%                        0%                         --                       -2%                       -4% 
  JP:p_j json, deserialize                       42900/s                 72861%                                         59127%                   19213%                    11058%                      7110%                     4663%                        3%                         3%                        --                       -1% 
  JM:d_j json, deserialize                       43000/s                 73813%                                         59900%                   19465%                    11204%                      7204%                     4726%                        4%                         4%                        1%                        -- 
 
 Legends:
   CJX:d_j json, deserialize: p_tags=json, deserialize participant=Cpanel::JSON::XS::decode_json
   JDM:f_j json, deserialize, cant_handle_scalar: p_tags=json, deserialize, cant_handle_scalar participant=JSON::Decode::Marpa::from_json
   JDR:f_j json, deserialize: p_tags=json, deserialize participant=JSON::Decode::Regexp::from_json
   JM:d_j json, deserialize: p_tags=json, deserialize participant=JSON::MaybeXS::decode_json
   JP:d_j json, deserialize: p_tags=json, deserialize participant=JSON::PP::decode_json
   JP:p_j json, deserialize: p_tags=json, deserialize participant=JSON::Parse::parse_json
   JT:d_j json, deserialize: p_tags=json, deserialize participant=JSON::Tiny::decode_json
   JX:d_j json, deserialize: p_tags=json, deserialize participant=JSON::XS::decode_json
   MEE:d json, deserialize: p_tags=json, deserialize participant=MarpaX::ESLIF::ECMA404::decode
   P:J json, deserialize: p_tags=json, deserialize participant=Pegex::JSON

Result formatted as table (split, part 4 of 12):

 #table15#
 {dataset=>"json:array_str1k_10"}
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                     | p_tags                                | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | JSON::Decode::Marpa::from_json  | json, deserialize, cant_handle_scalar |       130 |    7.5    |                 0.00% |             73814.20% | 3.1e-05 |      20 |
 | JSON::PP::decode_json           | json, deserialize                     |       272 |    3.67   |               103.49% |             36223.78% | 1.1e-06 |      20 |
 | Pegex::JSON                     | json, deserialize                     |      1120 |    0.896  |               734.18% |              8760.75% | 4.8e-07 |      20 |
 | JSON::Tiny::decode_json         | json, deserialize                     |      2020 |    0.494  |              1413.58% |              4783.42% | 1.9e-07 |      25 |
 | MarpaX::ESLIF::ECMA404::decode  | json, deserialize                     |      4900 |    0.2    |              3596.19% |              1899.74% | 4.3e-07 |      20 |
 | JSON::Decode::Regexp::from_json | json, deserialize                     |     35900 |    0.0279 |             26731.91% |               175.47% | 1.3e-08 |      20 |
 | JSON::Parse::parse_json         | json, deserialize                     |     70600 |    0.0142 |             52687.91% |                40.02% | 6.5e-09 |      21 |
 | Cpanel::JSON::XS::decode_json   | json, deserialize                     |     84000 |    0.012  |             62893.46% |                17.34% | 5.9e-08 |      28 |
 | JSON::MaybeXS::decode_json      | json, deserialize                     |     92600 |    0.0108 |             69151.19% |                 6.73% | 3.3e-09 |      20 |
 | JSON::XS::decode_json           | json, deserialize                     |    100000 |    0.01   |             73814.20% |                 0.00% | 1.4e-07 |      20 |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                     Rate  JDM:f_j json, deserialize, cant_handle_scalar  JP:d_j json, deserialize  P:J json, deserialize  JT:d_j json, deserialize  MEE:d json, deserialize  JDR:f_j json, deserialize  JP:p_j json, deserialize  CJX:d_j json, deserialize  JM:d_j json, deserialize  JX:d_j json, deserialize 
  JDM:f_j json, deserialize, cant_handle_scalar     130/s                                             --                      -51%                   -88%                      -93%                     -97%                       -99%                      -99%                       -99%                      -99%                      -99% 
  JP:d_j json, deserialize                          272/s                                           104%                        --                   -75%                      -86%                     -94%                       -99%                      -99%                       -99%                      -99%                      -99% 
  P:J json, deserialize                            1120/s                                           737%                      309%                     --                      -44%                     -77%                       -96%                      -98%                       -98%                      -98%                      -98% 
  JT:d_j json, deserialize                         2020/s                                          1418%                      642%                    81%                        --                     -59%                       -94%                      -97%                       -97%                      -97%                      -97% 
  MEE:d json, deserialize                          4900/s                                          3650%                     1734%                   347%                      146%                       --                       -86%                      -92%                       -94%                      -94%                      -95% 
  JDR:f_j json, deserialize                       35900/s                                         26781%                    13054%                  3111%                     1670%                     616%                         --                      -49%                       -56%                      -61%                      -64% 
  JP:p_j json, deserialize                        70600/s                                         52716%                    25745%                  6209%                     3378%                    1308%                        96%                        --                       -15%                      -23%                      -29% 
  CJX:d_j json, deserialize                       84000/s                                         62400%                    30483%                  7366%                     4016%                    1566%                       132%                       18%                         --                       -9%                      -16% 
  JM:d_j json, deserialize                        92600/s                                         69344%                    33881%                  8196%                     4474%                    1751%                       158%                       31%                        11%                        --                       -7% 
  JX:d_j json, deserialize                       100000/s                                         74900%                    36600%                  8860%                     4840%                    1900%                       179%                       42%                        19%                        8%                        -- 
 
 Legends:
   CJX:d_j json, deserialize: p_tags=json, deserialize participant=Cpanel::JSON::XS::decode_json
   JDM:f_j json, deserialize, cant_handle_scalar: p_tags=json, deserialize, cant_handle_scalar participant=JSON::Decode::Marpa::from_json
   JDR:f_j json, deserialize: p_tags=json, deserialize participant=JSON::Decode::Regexp::from_json
   JM:d_j json, deserialize: p_tags=json, deserialize participant=JSON::MaybeXS::decode_json
   JP:d_j json, deserialize: p_tags=json, deserialize participant=JSON::PP::decode_json
   JP:p_j json, deserialize: p_tags=json, deserialize participant=JSON::Parse::parse_json
   JT:d_j json, deserialize: p_tags=json, deserialize participant=JSON::Tiny::decode_json
   JX:d_j json, deserialize: p_tags=json, deserialize participant=JSON::XS::decode_json
   MEE:d json, deserialize: p_tags=json, deserialize participant=MarpaX::ESLIF::ECMA404::decode
   P:J json, deserialize: p_tags=json, deserialize participant=Pegex::JSON

Result formatted as table (split, part 5 of 12):

 #table16#
 {dataset=>"json:hash_int_10"}
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                     | p_tags                                | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | JSON::Decode::Marpa::from_json  | json, deserialize, cant_handle_scalar |    1300   |  760      |                 0.00% |             93869.56% | 3.1e-06 |      20 |
 | Pegex::JSON                     | json, deserialize                     |    1790   |  558      |                36.16% |             68916.58% | 3.7e-07 |      20 |
 | MarpaX::ESLIF::ECMA404::decode  | json, deserialize                     |    7300   |  140      |               451.75% |             16931.20% | 2.1e-07 |      20 |
 | JSON::PP::decode_json           | json, deserialize                     |   23000   |   43      |              1681.74% |              5174.02% | 6.7e-08 |      20 |
 | JSON::Decode::Regexp::from_json | json, deserialize                     |   25500   |   39.2    |              1837.21% |              4750.77% | 1.3e-08 |      20 |
 | JSON::Tiny::decode_json         | json, deserialize                     |   32149.6 |   31.1045 |              2342.03% |              3748.01% |   0     |      25 |
 | JSON::XS::decode_json           | json, deserialize                     |  800000   |    1      |             60130.33% |                56.02% | 3.1e-08 |      30 |
 | JSON::MaybeXS::decode_json      | json, deserialize                     |  990000   |    1      |             75350.03% |                24.55% | 1.7e-09 |      20 |
 | Cpanel::JSON::XS::decode_json   | json, deserialize                     | 1000000   |    0.99   |             76706.83% |                22.35% | 1.7e-09 |      20 |
 | JSON::Parse::parse_json         | json, deserialize                     | 1237000   |    0.8083 |             93869.56% |                 0.00% | 2.2e-11 |      21 |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                      Rate  JDM:f_j json, deserialize, cant_handle_scalar  P:J json, deserialize  MEE:d json, deserialize  JP:d_j json, deserialize  JDR:f_j json, deserialize  JT:d_j json, deserialize  JX:d_j json, deserialize  JM:d_j json, deserialize  CJX:d_j json, deserialize  JP:p_j json, deserialize 
  JDM:f_j json, deserialize, cant_handle_scalar     1300/s                                             --                   -26%                     -81%                      -94%                       -94%                      -95%                      -99%                      -99%                       -99%                      -99% 
  P:J json, deserialize                             1790/s                                            36%                     --                     -74%                      -92%                       -92%                      -94%                      -99%                      -99%                       -99%                      -99% 
  MEE:d json, deserialize                           7300/s                                           442%                   298%                       --                      -69%                       -72%                      -77%                      -99%                      -99%                       -99%                      -99% 
  JP:d_j json, deserialize                         23000/s                                          1667%                  1197%                     225%                        --                        -8%                      -27%                      -97%                      -97%                       -97%                      -98% 
  JDR:f_j json, deserialize                        25500/s                                          1838%                  1323%                     257%                        9%                         --                      -20%                      -97%                      -97%                       -97%                      -97% 
  JT:d_j json, deserialize                       32149.6/s                                          2343%                  1693%                     350%                       38%                        26%                        --                      -96%                      -96%                       -96%                      -97% 
  JX:d_j json, deserialize                        800000/s                                         75900%                 55700%                   13900%                     4200%                      3820%                     3010%                        --                        0%                        -1%                      -19% 
  JM:d_j json, deserialize                        990000/s                                         75900%                 55700%                   13900%                     4200%                      3820%                     3010%                        0%                        --                        -1%                      -19% 
  CJX:d_j json, deserialize                      1000000/s                                         76667%                 56263%                   14041%                     4243%                      3859%                     3041%                        1%                        1%                         --                      -18% 
  JP:p_j json, deserialize                       1237000/s                                         93924%                 68933%                   17220%                     5219%                      4749%                     3748%                       23%                       23%                        22%                        -- 
 
 Legends:
   CJX:d_j json, deserialize: p_tags=json, deserialize participant=Cpanel::JSON::XS::decode_json
   JDM:f_j json, deserialize, cant_handle_scalar: p_tags=json, deserialize, cant_handle_scalar participant=JSON::Decode::Marpa::from_json
   JDR:f_j json, deserialize: p_tags=json, deserialize participant=JSON::Decode::Regexp::from_json
   JM:d_j json, deserialize: p_tags=json, deserialize participant=JSON::MaybeXS::decode_json
   JP:d_j json, deserialize: p_tags=json, deserialize participant=JSON::PP::decode_json
   JP:p_j json, deserialize: p_tags=json, deserialize participant=JSON::Parse::parse_json
   JT:d_j json, deserialize: p_tags=json, deserialize participant=JSON::Tiny::decode_json
   JX:d_j json, deserialize: p_tags=json, deserialize participant=JSON::XS::decode_json
   MEE:d json, deserialize: p_tags=json, deserialize participant=MarpaX::ESLIF::ECMA404::decode
   P:J json, deserialize: p_tags=json, deserialize participant=Pegex::JSON

Result formatted as table (split, part 6 of 12):

 #table17#
 {dataset=>"json:hash_int_100"}
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                     | p_tags                                | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | JSON::Decode::Marpa::from_json  | json, deserialize, cant_handle_scalar |       290 |   3.5     |                 0.00% |             43938.89% | 1.9e-05 |      20 |
 | Pegex::JSON                     | json, deserialize                     |       310 |   3.2     |                 8.98% |             40311.55% | 3.4e-06 |      22 |
 | MarpaX::ESLIF::ECMA404::decode  | json, deserialize                     |       924 |   1.08    |               220.94% |             13621.65% | 6.4e-07 |      20 |
 | JSON::PP::decode_json           | json, deserialize                     |      2400 |   0.42    |               725.64% |              5233.91% | 6.4e-07 |      20 |
 | JSON::Decode::Regexp::from_json | json, deserialize                     |      2600 |   0.384   |               804.82% |              4767.14% | 2.1e-07 |      20 |
 | JSON::Tiny::decode_json         | json, deserialize                     |      3790 |   0.264   |              1217.10% |              3243.62% | 2.1e-07 |      20 |
 | JSON::XS::decode_json           | json, deserialize                     |     69000 |   0.014   |             23965.84% |                82.99% | 2.7e-08 |      20 |
 | Cpanel::JSON::XS::decode_json   | json, deserialize                     |    100000 |   0.0095  |             36321.86% |                20.91% | 1.2e-08 |      23 |
 | JSON::MaybeXS::decode_json      | json, deserialize                     |    106000 |   0.00944 |             36694.09% |                19.69% | 3.3e-09 |      20 |
 | JSON::Parse::parse_json         | json, deserialize                     |    130000 |   0.0079  |             43938.89% |                 0.00% |   1e-08 |      20 |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                     Rate  JDM:f_j json, deserialize, cant_handle_scalar  P:J json, deserialize  MEE:d json, deserialize  JP:d_j json, deserialize  JDR:f_j json, deserialize  JT:d_j json, deserialize  JX:d_j json, deserialize  CJX:d_j json, deserialize  JM:d_j json, deserialize  JP:p_j json, deserialize 
  JDM:f_j json, deserialize, cant_handle_scalar     290/s                                             --                    -8%                     -69%                      -88%                       -89%                      -92%                      -99%                       -99%                      -99%                      -99% 
  P:J json, deserialize                             310/s                                             9%                     --                     -66%                      -86%                       -88%                      -91%                      -99%                       -99%                      -99%                      -99% 
  MEE:d json, deserialize                           924/s                                           224%                   196%                       --                      -61%                       -64%                      -75%                      -98%                       -99%                      -99%                      -99% 
  JP:d_j json, deserialize                         2400/s                                           733%                   661%                     157%                        --                        -8%                      -37%                      -96%                       -97%                      -97%                      -98% 
  JDR:f_j json, deserialize                        2600/s                                           811%                   733%                     181%                        9%                         --                      -31%                      -96%                       -97%                      -97%                      -97% 
  JT:d_j json, deserialize                         3790/s                                          1225%                  1112%                     309%                       59%                        45%                        --                      -94%                       -96%                      -96%                      -97% 
  JX:d_j json, deserialize                        69000/s                                         24900%                 22757%                    7614%                     2900%                      2642%                     1785%                        --                       -32%                      -32%                      -43% 
  CJX:d_j json, deserialize                      100000/s                                         36742%                 33584%                   11268%                     4321%                      3942%                     2678%                       47%                         --                        0%                      -16% 
  JM:d_j json, deserialize                       106000/s                                         36976%                 33798%                   11340%                     4349%                      3967%                     2696%                       48%                         0%                        --                      -16% 
  JP:p_j json, deserialize                       130000/s                                         44203%                 40406%                   13570%                     5216%                      4760%                     3241%                       77%                        20%                       19%                        -- 
 
 Legends:
   CJX:d_j json, deserialize: p_tags=json, deserialize participant=Cpanel::JSON::XS::decode_json
   JDM:f_j json, deserialize, cant_handle_scalar: p_tags=json, deserialize, cant_handle_scalar participant=JSON::Decode::Marpa::from_json
   JDR:f_j json, deserialize: p_tags=json, deserialize participant=JSON::Decode::Regexp::from_json
   JM:d_j json, deserialize: p_tags=json, deserialize participant=JSON::MaybeXS::decode_json
   JP:d_j json, deserialize: p_tags=json, deserialize participant=JSON::PP::decode_json
   JP:p_j json, deserialize: p_tags=json, deserialize participant=JSON::Parse::parse_json
   JT:d_j json, deserialize: p_tags=json, deserialize participant=JSON::Tiny::decode_json
   JX:d_j json, deserialize: p_tags=json, deserialize participant=JSON::XS::decode_json
   MEE:d json, deserialize: p_tags=json, deserialize participant=MarpaX::ESLIF::ECMA404::decode
   P:J json, deserialize: p_tags=json, deserialize participant=Pegex::JSON

Result formatted as table (split, part 7 of 12):

 #table18#
 {dataset=>"json:hash_int_1000"}
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                     | p_tags                                | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | JSON::Decode::Marpa::from_json  | json, deserialize, cant_handle_scalar |      32   |     32    |                 0.00% |             29397.65% |   0.00014 |      22 |
 | Pegex::JSON                     | json, deserialize                     |      34   |     30    |                 6.64% |             27560.03% | 3.4e-05   |      20 |
 | MarpaX::ESLIF::ECMA404::decode  | json, deserialize                     |      84.6 |     11.8  |               166.57% |             10965.65% | 1.1e-05   |      20 |
 | JSON::PP::decode_json           | json, deserialize                     |     220   |      4.5  |               602.35% |              4099.85% | 4.7e-06   |      20 |
 | JSON::Decode::Regexp::from_json | json, deserialize                     |     230   |      4.3  |               631.56% |              3932.16% | 1.4e-05   |      20 |
 | JSON::Tiny::decode_json         | json, deserialize                     |     380   |      2.6  |              1094.96% |              2368.50% | 5.3e-06   |      20 |
 | JSON::XS::decode_json           | json, deserialize                     |    7000   |      0.1  |             20937.57% |                40.21% | 4.9e-06   |      32 |
 | JSON::MaybeXS::decode_json      | json, deserialize                     |    8300   |      0.12 |             26197.51% |                12.17% | 1.5e-07   |      22 |
 | Cpanel::JSON::XS::decode_json   | json, deserialize                     |    8350   |      0.12 |             26210.60% |                12.11% | 5.3e-08   |      20 |
 | JSON::Parse::parse_json         | json, deserialize                     |    9400   |      0.11 |             29397.65% |                 0.00% | 2.1e-07   |      20 |
 +---------------------------------+---------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                   Rate  JDM:f_j json, deserialize, cant_handle_scalar  P:J json, deserialize  MEE:d json, deserialize  JP:d_j json, deserialize  JDR:f_j json, deserialize  JT:d_j json, deserialize  JM:d_j json, deserialize  CJX:d_j json, deserialize  JP:p_j json, deserialize  JX:d_j json, deserialize 
  JDM:f_j json, deserialize, cant_handle_scalar    32/s                                             --                    -6%                     -63%                      -85%                       -86%                      -91%                      -99%                       -99%                      -99%                      -99% 
  P:J json, deserialize                            34/s                                             6%                     --                     -60%                      -85%                       -85%                      -91%                      -99%                       -99%                      -99%                      -99% 
  MEE:d json, deserialize                        84.6/s                                           171%                   154%                       --                      -61%                       -63%                      -77%                      -98%                       -98%                      -99%                      -99% 
  JP:d_j json, deserialize                        220/s                                           611%                   566%                     162%                        --                        -4%                      -42%                      -97%                       -97%                      -97%                      -97% 
  JDR:f_j json, deserialize                       230/s                                           644%                   597%                     174%                        4%                         --                      -39%                      -97%                       -97%                      -97%                      -97% 
  JT:d_j json, deserialize                        380/s                                          1130%                  1053%                     353%                       73%                        65%                        --                      -95%                       -95%                      -95%                      -96% 
  JM:d_j json, deserialize                       8300/s                                         26566%                 24900%                    9733%                     3650%                      3483%                     2066%                        --                         0%                       -8%                      -16% 
  CJX:d_j json, deserialize                      8350/s                                         26566%                 24900%                    9733%                     3650%                      3483%                     2066%                        0%                         --                       -8%                      -16% 
  JP:p_j json, deserialize                       9400/s                                         28990%                 27172%                   10627%                     3990%                      3809%                     2263%                        9%                         9%                        --                       -9% 
  JX:d_j json, deserialize                       7000/s                                         31900%                 29900%                   11700%                     4400%                      4199%                     2500%                       19%                        19%                        9%                        -- 
 
 Legends:
   CJX:d_j json, deserialize: p_tags=json, deserialize participant=Cpanel::JSON::XS::decode_json
   JDM:f_j json, deserialize, cant_handle_scalar: p_tags=json, deserialize, cant_handle_scalar participant=JSON::Decode::Marpa::from_json
   JDR:f_j json, deserialize: p_tags=json, deserialize participant=JSON::Decode::Regexp::from_json
   JM:d_j json, deserialize: p_tags=json, deserialize participant=JSON::MaybeXS::decode_json
   JP:d_j json, deserialize: p_tags=json, deserialize participant=JSON::PP::decode_json
   JP:p_j json, deserialize: p_tags=json, deserialize participant=JSON::Parse::parse_json
   JT:d_j json, deserialize: p_tags=json, deserialize participant=JSON::Tiny::decode_json
   JX:d_j json, deserialize: p_tags=json, deserialize participant=JSON::XS::decode_json
   MEE:d json, deserialize: p_tags=json, deserialize participant=MarpaX::ESLIF::ECMA404::decode
   P:J json, deserialize: p_tags=json, deserialize participant=Pegex::JSON

Result formatted as table (split, part 8 of 12):

 #table19#
 {dataset=>"json:null"}
 +---------------------------------+-----------+-------------+-----------------------+-----------------------+---------+---------+
 | participant                     | rate (/s) | time (μs)   | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------------+-----------+-------------+-----------------------+-----------------------+---------+---------+
 | Pegex::JSON                     |      3000 | 300         |                 0.00% |            428562.13% | 4.5e-06 |      20 |
 | MarpaX::ESLIF::ECMA404::decode  |     44000 |  23         |              1181.50% |             33350.00% | 2.7e-08 |      20 |
 | JSON::Tiny::decode_json         |    250000 |   3.9       |              7245.87% |              5735.41% | 6.7e-09 |      20 |
 | JSON::PP::decode_json           |    386199 |   2.58934   |             11085.72% |              3732.23% |   0     |      21 |
 | JSON::Decode::Regexp::from_json |    551101 |   1.81455   |             15861.88% |              2585.54% |   0     |      20 |
 | JSON::XS::decode_json           |   9900000 |   0.1       |            287624.64% |                48.98% | 6.2e-10 |      20 |
 | Cpanel::JSON::XS::decode_json   |  10189700 |   0.0981381 |            295031.08% |                45.24% |   0     |      20 |
 | JSON::MaybeXS::decode_json      |  10000000 |   0.098     |            295403.44% |                45.06% | 2.1e-10 |      20 |
 | JSON::Parse::parse_json         |  14800000 |   0.0675675 |            428562.13% |                 0.00% |   0     |      20 |
 +---------------------------------+-----------+-------------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                 Rate      P:J   MEE:d  JT:d_j  JP:d_j  JDR:f_j  JX:d_j  CJX:d_j  JM:d_j  JP:p_j 
  P:J          3000/s       --    -92%    -98%    -99%     -99%    -99%     -99%    -99%    -99% 
  MEE:d       44000/s    1204%      --    -83%    -88%     -92%    -99%     -99%    -99%    -99% 
  JT:d_j     250000/s    7592%    489%      --    -33%     -53%    -97%     -97%    -97%    -98% 
  JP:d_j     386199/s   11485%    788%     50%      --     -29%    -96%     -96%    -96%    -97% 
  JDR:f_j    551101/s   16433%   1167%    114%     42%       --    -94%     -94%    -94%    -96% 
  JX:d_j    9900000/s  299900%  22900%   3800%   2489%    1714%      --      -1%     -2%    -32% 
  CJX:d_j  10189700/s  305591%  23336%   3873%   2538%    1748%      1%       --      0%    -31% 
  JM:d_j   10000000/s  306022%  23369%   3879%   2542%    1751%      2%       0%      --    -31% 
  JP:p_j   14800000/s  443900%  33940%   5672%   3732%    2585%     48%      45%     45%      -- 
 
 Legends:
   CJX:d_j: participant=Cpanel::JSON::XS::decode_json
   JDR:f_j: participant=JSON::Decode::Regexp::from_json
   JM:d_j: participant=JSON::MaybeXS::decode_json
   JP:d_j: participant=JSON::PP::decode_json
   JP:p_j: participant=JSON::Parse::parse_json
   JT:d_j: participant=JSON::Tiny::decode_json
   JX:d_j: participant=JSON::XS::decode_json
   MEE:d: participant=MarpaX::ESLIF::ECMA404::decode
   P:J: participant=Pegex::JSON

Result formatted as table (split, part 9 of 12):

 #table20#
 {dataset=>"json:num"}
 +---------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | participant                     | rate (/s) | time (μs)  | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | Pegex::JSON                     |      3900 | 250        |                 0.00% |             48889.84% | 1.1e-06 |      20 |
 | MarpaX::ESLIF::ECMA404::decode  |     17000 |  58        |               341.49% |             10996.41% | 2.3e-07 |      21 |
 | JSON::Tiny::decode_json         |    189000 |   5.3      |              4706.47% |               919.25% | 1.5e-09 |      24 |
 | JSON::PP::decode_json           |    200000 |   5.1      |              4872.07% |               885.30% | 6.5e-09 |      21 |
 | JSON::Decode::Regexp::from_json |    370600 |   2.698    |              9341.85% |               418.86% | 2.2e-10 |      24 |
 | JSON::XS::decode_json           |   2000000 |   0.6      |             41603.77% |                17.47% | 7.7e-09 |      21 |
 | Cpanel::JSON::XS::decode_json   |   1706040 |   0.586151 |             43364.45% |                12.71% |   0     |      20 |
 | JSON::MaybeXS::decode_json      |   1717000 |   0.5824   |             43645.95% |                11.99% | 5.2e-11 |      22 |
 | JSON::Parse::parse_json         |   1922920 |   0.520041 |             48889.84% |                 0.00% |   0     |      20 |
 +---------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                Rate     P:J   MEE:d  JT:d_j  JP:d_j  JDR:f_j  JX:d_j  CJX:d_j  JM:d_j  JP:p_j 
  P:J         3900/s      --    -76%    -97%    -97%     -98%    -99%     -99%    -99%    -99% 
  MEE:d      17000/s    331%      --    -90%    -91%     -95%    -98%     -98%    -98%    -99% 
  JT:d_j    189000/s   4616%    994%      --     -3%     -49%    -88%     -88%    -89%    -90% 
  JP:d_j    200000/s   4801%   1037%      3%      --     -47%    -88%     -88%    -88%    -89% 
  JDR:f_j   370600/s   9166%   2049%     96%     89%       --    -77%     -78%    -78%    -80% 
  JX:d_j   2000000/s  41566%   9566%    783%    750%     349%      --      -2%     -2%    -13% 
  CJX:d_j  1706040/s  42551%   9795%    804%    770%     360%      2%       --      0%    -11% 
  JM:d_j   1717000/s  42825%   9858%    810%    775%     363%      3%       0%      --    -10% 
  JP:p_j   1922920/s  47973%  11052%    919%    880%     418%     15%      12%     11%      -- 
 
 Legends:
   CJX:d_j: participant=Cpanel::JSON::XS::decode_json
   JDR:f_j: participant=JSON::Decode::Regexp::from_json
   JM:d_j: participant=JSON::MaybeXS::decode_json
   JP:d_j: participant=JSON::PP::decode_json
   JP:p_j: participant=JSON::Parse::parse_json
   JT:d_j: participant=JSON::Tiny::decode_json
   JX:d_j: participant=JSON::XS::decode_json
   MEE:d: participant=MarpaX::ESLIF::ECMA404::decode
   P:J: participant=Pegex::JSON

Result formatted as table (split, part 10 of 12):

 #table21#
 {dataset=>"json:str1k"}
 +---------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                     | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | JSON::PP::decode_json           |      3000 | 400       |                 0.00% |             40419.17% | 5.8e-06 |      20 |
 | Pegex::JSON                     |      3300 | 300       |                30.34% |             30986.38% | 6.8e-07 |      21 |
 | JSON::Tiny::decode_json         |     19600 |  50.9     |               678.32% |              5105.98% | 2.7e-08 |      20 |
 | MarpaX::ESLIF::ECMA404::decode  |     27100 |  36.9     |               973.84% |              3673.29% | 1.3e-08 |      20 |
 | JSON::Decode::Regexp::from_json |    350000 |   2.9     |             13743.87% |               192.69% | 3.3e-09 |      20 |
 | JSON::Parse::parse_json         |    830980 |   1.2034  |             32833.09% |                23.03% |   0     |      34 |
 | Cpanel::JSON::XS::decode_json   |    911268 |   1.09737 |             36015.06% |                12.19% |   0     |      20 |
 | JSON::MaybeXS::decode_json      |    913920 |   1.09419 |             36120.16% |                11.87% |   0     |      20 |
 | JSON::XS::decode_json           |   1000000 |   0.98    |             40419.17% |                 0.00% | 1.5e-09 |      24 |
 +---------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                Rate  JP:d_j     P:J  JT:d_j  MEE:d  JDR:f_j  JP:p_j  CJX:d_j  JM:d_j  JX:d_j 
  JP:d_j      3000/s      --    -25%    -87%   -90%     -99%    -99%     -99%    -99%    -99% 
  P:J         3300/s     33%      --    -83%   -87%     -99%    -99%     -99%    -99%    -99% 
  JT:d_j     19600/s    685%    489%      --   -27%     -94%    -97%     -97%    -97%    -98% 
  MEE:d      27100/s    984%    713%     37%     --     -92%    -96%     -97%    -97%    -97% 
  JDR:f_j   350000/s  13693%  10244%   1655%  1172%       --    -58%     -62%    -62%    -66% 
  JP:p_j    830980/s  33139%  24829%   4129%  2966%     140%      --      -8%     -9%    -18% 
  CJX:d_j   911268/s  36350%  27238%   4538%  3262%     164%      9%       --      0%    -10% 
  JM:d_j    913920/s  36456%  27317%   4551%  3272%     165%      9%       0%      --    -10% 
  JX:d_j   1000000/s  40716%  30512%   5093%  3665%     195%     22%      11%     11%      -- 
 
 Legends:
   CJX:d_j: participant=Cpanel::JSON::XS::decode_json
   JDR:f_j: participant=JSON::Decode::Regexp::from_json
   JM:d_j: participant=JSON::MaybeXS::decode_json
   JP:d_j: participant=JSON::PP::decode_json
   JP:p_j: participant=JSON::Parse::parse_json
   JT:d_j: participant=JSON::Tiny::decode_json
   JX:d_j: participant=JSON::XS::decode_json
   MEE:d: participant=MarpaX::ESLIF::ECMA404::decode
   P:J: participant=Pegex::JSON

Result formatted as table (split, part 11 of 12):

 #table22#
 {dataset=>"perl:hash_int_100"}
 +-------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant       | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Undump::PPI |        52 |   19      |                 0.00% |            205461.94% | 4.3e-05 |      20 |
 | eval()            |     21000 |    0.047  |             40848.39% |               402.00% | 6.7e-08 |      20 |
 | Data::Undump      |    110000 |    0.0093 |            205461.94% |                 0.00% | 1.3e-08 |      20 |
 +-------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

            Rate     DU:P     e   D:U 
  DU:P      52/s       --  -99%  -99% 
  e      21000/s   40325%    --  -80% 
  D:U   110000/s  204201%  405%    -- 
 
 Legends:
   D:U: participant=Data::Undump
   DU:P: participant=Data::Undump::PPI
   e: participant=eval()

Result formatted as table (split, part 12 of 12):

 #table23#
 {dataset=>"sereal:hash_int_100"}
 +-----------------------+---------------------+-------------+-----------------------------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | dataset             | ds_tags     | p_tags                      | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+---------------------+-------------+-----------------------------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Sereal::decode_sereal | sereal:hash_int_100 | deserialize | binary, sereal, deserialize | perl |    160000 |       6.2 |                 0.00% |                 0.00% | 6.7e-09 |      20 |
 +-----------------------+---------------------+-------------+-----------------------------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

         Rate     
     160000/s  -- 
 
 Legends:
   : dataset=sereal:hash_int_100 ds_tags=deserialize p_tags=binary, sereal, deserialize participant=Sereal::decode_sereal perl=perl


=head2 Sample benchmark #3

Benchmark command (benchmarking module startup overhead):

 % bencher -m Serializers --module-startup

Result formatted as table:

 #table24#
 +------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant            | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | JSON::Decode::Marpa    |      81   |              75   |                 0.00% |              1169.17% |   0.00019 |      21 |
 | MarpaX::ESLIF::ECMA404 |      71   |              65   |                14.51% |              1008.35% |   0.00016 |      21 |
 | Data::Undump::PPI      |      51   |              45   |                59.08% |               697.84% | 9.5e-05   |      23 |
 | JSON::Tiny             |      23   |              17   |               259.39% |               253.15% |   0.00014 |      21 |
 | JSON::PP               |      20   |              14   |               315.40% |               205.53% | 9.8e-05   |      20 |
 | Pegex::JSON            |      19   |              13   |               326.18% |               197.80% |   0.00016 |      20 |
 | JSON::MaybeXS          |      16   |              10   |               408.64% |               149.52% |   0.00015 |      20 |
 | Storable               |      10   |               4   |               446.25% |               132.34% |   0.00026 |      20 |
 | Sereal                 |      10   |               4   |               461.10% |               126.19% |   0.00017 |      20 |
 | YAML                   |      10   |               4   |               461.66% |               125.97% |   0.00027 |      20 |
 | YAML::Old              |      14   |               8   |               472.01% |               121.88% |   0.00013 |      20 |
 | JSON::Parse            |      10   |               4   |               535.83% |                99.61% |   0.00025 |      21 |
 | YAML::XS               |      10   |               4   |               553.01% |                94.36% |   0.00023 |      20 |
 | JSON::XS               |      10   |               4   |               589.88% |                83.97% |   0.00022 |      21 |
 | Cpanel::JSON::XS       |      10   |               4   |               600.88% |                81.08% |   0.00021 |      20 |
 | YAML::Syck             |      10   |               4   |               641.43% |                71.18% |   0.00021 |      21 |
 | Data::MessagePack      |      10   |               4   |               706.73% |                57.32% |   0.00015 |      20 |
 | JSON::Decode::Regexp   |      10   |               4   |               711.42% |                56.41% |   0.00011 |      20 |
 | JSON::Create           |      10   |               4   |               733.49% |                52.27% |   0.00019 |      20 |
 | Data::Undump           |       7.7 |               1.7 |               954.80% |                20.32% | 3.5e-05   |      20 |
 | perl -e1 (baseline)    |       6   |               0   |              1169.17% |                 0.00% |   0.00021 |      20 |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                             Rate  JSON::Decode::Marpa  MarpaX::ESLIF::ECMA404  Data::Undump::PPI  JSON::Tiny  JSON::PP  Pegex::JSON  JSON::MaybeXS  YAML::Old  Storable  Sereal  YAML  JSON::Parse  YAML::XS  JSON::XS  Cpanel::JSON::XS  YAML::Syck  Data::MessagePack  JSON::Decode::Regexp  JSON::Create  Data::Undump  perl -e1 (baseline) 
  JSON::Decode::Marpa      12.3/s                   --                    -12%               -37%        -71%      -75%         -76%           -80%       -82%      -87%    -87%  -87%         -87%      -87%      -87%              -87%        -87%               -87%                  -87%          -87%          -90%                 -92% 
  MarpaX::ESLIF::ECMA404   14.1/s                  14%                      --               -28%        -67%      -71%         -73%           -77%       -80%      -85%    -85%  -85%         -85%      -85%      -85%              -85%        -85%               -85%                  -85%          -85%          -89%                 -91% 
  Data::Undump::PPI        19.6/s                  58%                     39%                 --        -54%      -60%         -62%           -68%       -72%      -80%    -80%  -80%         -80%      -80%      -80%              -80%        -80%               -80%                  -80%          -80%          -84%                 -88% 
  JSON::Tiny               43.5/s                 252%                    208%               121%          --      -13%         -17%           -30%       -39%      -56%    -56%  -56%         -56%      -56%      -56%              -56%        -56%               -56%                  -56%          -56%          -66%                 -73% 
  JSON::PP                 50.0/s                 305%                    254%               154%         14%        --          -5%           -19%       -30%      -50%    -50%  -50%         -50%      -50%      -50%              -50%        -50%               -50%                  -50%          -50%          -61%                 -70% 
  Pegex::JSON              52.6/s                 326%                    273%               168%         21%        5%           --           -15%       -26%      -47%    -47%  -47%         -47%      -47%      -47%              -47%        -47%               -47%                  -47%          -47%          -59%                 -68% 
  JSON::MaybeXS            62.5/s                 406%                    343%               218%         43%       25%          18%             --       -12%      -37%    -37%  -37%         -37%      -37%      -37%              -37%        -37%               -37%                  -37%          -37%          -51%                 -62% 
  YAML::Old                71.4/s                 478%                    407%               264%         64%       42%          35%            14%         --      -28%    -28%  -28%         -28%      -28%      -28%              -28%        -28%               -28%                  -28%          -28%          -44%                 -57% 
  Storable                100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        --      0%    0%           0%        0%        0%                0%          0%                 0%                    0%            0%          -23%                 -40% 
  Sereal                  100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      --    0%           0%        0%        0%                0%          0%                 0%                    0%            0%          -23%                 -40% 
  YAML                    100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      0%    --           0%        0%        0%                0%          0%                 0%                    0%            0%          -23%                 -40% 
  JSON::Parse             100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      0%    0%           --        0%        0%                0%          0%                 0%                    0%            0%          -23%                 -40% 
  YAML::XS                100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      0%    0%           0%        --        0%                0%          0%                 0%                    0%            0%          -23%                 -40% 
  JSON::XS                100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      0%    0%           0%        0%        --                0%          0%                 0%                    0%            0%          -23%                 -40% 
  Cpanel::JSON::XS        100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      0%    0%           0%        0%        0%                --          0%                 0%                    0%            0%          -23%                 -40% 
  YAML::Syck              100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      0%    0%           0%        0%        0%                0%          --                 0%                    0%            0%          -23%                 -40% 
  Data::MessagePack       100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      0%    0%           0%        0%        0%                0%          0%                 --                    0%            0%          -23%                 -40% 
  JSON::Decode::Regexp    100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      0%    0%           0%        0%        0%                0%          0%                 0%                    --            0%          -23%                 -40% 
  JSON::Create            100.0/s                 710%                    610%               409%        129%      100%          89%            60%        39%        0%      0%    0%           0%        0%        0%                0%          0%                 0%                    0%            --          -23%                 -40% 
  Data::Undump            129.9/s                 951%                    822%               562%        198%      159%         146%           107%        81%       29%     29%   29%          29%       29%       29%               29%         29%                29%                   29%           29%            --                 -22% 
  perl -e1 (baseline)     166.7/s                1250%                   1083%               750%        283%      233%         216%           166%       133%       66%     66%   66%          66%       66%       66%               66%         66%                66%                   66%           66%           28%                   -- 
 
 Legends:
   Cpanel::JSON::XS: mod_overhead_time=4 participant=Cpanel::JSON::XS
   Data::MessagePack: mod_overhead_time=4 participant=Data::MessagePack
   Data::Undump: mod_overhead_time=1.7 participant=Data::Undump
   Data::Undump::PPI: mod_overhead_time=45 participant=Data::Undump::PPI
   JSON::Create: mod_overhead_time=4 participant=JSON::Create
   JSON::Decode::Marpa: mod_overhead_time=75 participant=JSON::Decode::Marpa
   JSON::Decode::Regexp: mod_overhead_time=4 participant=JSON::Decode::Regexp
   JSON::MaybeXS: mod_overhead_time=10 participant=JSON::MaybeXS
   JSON::PP: mod_overhead_time=14 participant=JSON::PP
   JSON::Parse: mod_overhead_time=4 participant=JSON::Parse
   JSON::Tiny: mod_overhead_time=17 participant=JSON::Tiny
   JSON::XS: mod_overhead_time=4 participant=JSON::XS
   MarpaX::ESLIF::ECMA404: mod_overhead_time=65 participant=MarpaX::ESLIF::ECMA404
   Pegex::JSON: mod_overhead_time=13 participant=Pegex::JSON
   Sereal: mod_overhead_time=4 participant=Sereal
   Storable: mod_overhead_time=4 participant=Storable
   YAML: mod_overhead_time=4 participant=YAML
   YAML::Old: mod_overhead_time=8 participant=YAML::Old
   YAML::Syck: mod_overhead_time=4 participant=YAML::Syck
   YAML::XS: mod_overhead_time=4 participant=YAML::XS
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

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

This software is copyright (c) 2021, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

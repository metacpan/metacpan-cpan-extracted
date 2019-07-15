use 5.010001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep qw/!blessed/;

# Hijack the JSON::PP::USE_B constant to enable svtype detection
BEGIN {
    no warnings 'redefine';

    require constant;
    my $orig = constant->can('import');
    local *constant::import = sub {
        if ($_[1] eq 'USE_B') {
            pop(@_);
            push(@_, 1)
        }
        goto &$orig;
    };

    require JSON::PP;
    die "TOO LATE"
        unless JSON::PP::USE_B();
}

use JSON::PP 2.97001;

use BSON;
use BSON::Types ':all';
use Config;
use Path::Tiny 0.054; # better basename
use Data::Dumper;

# from t/lib
use TestUtils;

use constant {
    IS_JSON_PP => 1,
};

use base 'Exporter';
our @EXPORT = qw/test_corpus_file/;

binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

# overridden to allow Tie::IxHash hashes to be created by JSON::PP
my $orig = JSON::PP->can("object")
    or die "Unable to find JSON::PP::object to override";
do {
    no warnings 'redefine';
    *JSON::PP::object = sub {
        tie my %hash, 'Tie::IxHash';
        my $value = $orig->(\%hash);
        return $value;
    };
};

my $JSON = JSON::PP
    ->new
    ->ascii
    ->allow_bignum
    ->allow_blessed
    ->convert_blessed;

sub test_corpus_file {
    my ($file) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $f = path( "corpus", $file );
    my $base = $f->basename;

    my $json = eval { decode_json( $f->slurp ) };
    if ( my $err = $@ ) {
        fail("$base failed to load");
        diag($err);
        return;
    }

    subtest 'JSON::PP Tie::IxHash injection' => sub {
        my $data = $JSON->decode('{"x":23}');
        ok defined(tied %$data), 'JSON::PP returns tied objects';
    };

    _validity_tests($json);
    _decode_error_tests($json);
    _parse_error_tests($json);
}

sub _validity_tests {
    my ($json) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # suppress caching that throws off Test::Deep
    local $BSON::Types::NoCache = 1;

    my $bson_type = $json->{bson_type};
    my $deprecated = $json->{deprecated};

    for my $case ( @{ $json->{valid} } ) {
        subtest 'case: '.$case->{description} => sub {
            local $Data::Dumper::Useqq = 1;

            my $wrap = $bson_type =~ /\A(?:0x00|0x01|0x10|0x12)\z/;
            my $codec = BSON->new( prefer_numeric => 1, wrap_numbers => $wrap, ordered => 1 );
            my $lossy = $case->{lossy};

            my $canonical_bson = $case->{canonical_bson};
            my $converted_bson = $case->{converted_bson};
            my $degenerate_bson = $case->{degenerate_bson};

            $canonical_bson = pack('H*', $canonical_bson);
            $converted_bson = pack('H*', $converted_bson)
                if defined $converted_bson;
            $degenerate_bson = pack('H*', $degenerate_bson)
                if defined $degenerate_bson;

            my $canonical_json = $case->{canonical_extjson};
            my $converted_json = $case->{converted_extjson};
            my $degenerate_json = $case->{degenerate_extjson};
            my $relaxed_json = $case->{relaxed_extjson};

            $canonical_json = _normalize(
                $canonical_json,
                '$desc: normalizing canonical extjson',
            );
            $converted_json = _normalize(
                $converted_json,
                '$desc: normalizing converted extjson',
            );
            $degenerate_json = _normalize(
                $degenerate_json,
                '$desc: normalizing degenerate extjson',
            );
            $relaxed_json = _normalize(
                $relaxed_json,
                '$desc: normalizing relaxed extjson',
            );

            ##
            ## for cB input (canonical BSON)
            ##

            bytes_are(
                _native_to_bson($codec,
                    _bson_to_native($codec, $canonical_bson),
                ),
                $deprecated
                    ? $converted_bson
                    : $canonical_bson,
                'native_to_bson(bson_to_native(cB)) = cB',
            );

            is(
                _normalize_numbers(
                    _native_to_canonical_extended_json($codec,
                        _bson_to_native($codec, $canonical_bson),
                    )
                ),
                _normalize_numbers(
                    $deprecated
                        ? $converted_json
                        : $canonical_json,
                ),
                'native_to_canonical_extended_json(bson_to_native(cB)) = cEJ',
            );

            is(
                _normalize_numbers(
                    _native_to_relaxed_extended_json($codec,
                        _bson_to_native($codec, $canonical_bson),
                    )
                ),
                _normalize_numbers($relaxed_json),
                'native_to_relaxed_extended_json(bson_to_native(cB)) = rEJ',
            ) unless not defined $relaxed_json;

            ##
            ## for cEJ input (canonical Extended JSON)
            ##

            is(
                _normalize_numbers(
                    _native_to_canonical_extended_json($codec,
                        _extjson_to_native($codec, $canonical_json),
                    )
                ),
                _normalize_numbers(
                    $deprecated
                        ? $converted_json
                        : $canonical_json,
                ),
                'native_to_canonical_extended_json(json_to_native(cEJ)) = cEJ',
            );

            bytes_are(
                _native_to_bson($codec,
                    _extjson_to_native($codec, $canonical_json),
                ),
                $deprecated
                    ? $converted_bson
                    : $canonical_bson,
                'native_to_bson(json_to_native(cEJ)) = cB'
            ) unless $lossy;

            ##
            ## for dB input (degenerate BSON)
            ##

            if (defined $degenerate_bson) {
                bytes_are(
                    _native_to_bson($codec,
                        _bson_to_native($codec, $degenerate_bson),
                    ),
                    $canonical_bson,
                    'native_to_bson(bson_to_native(dB)) = cB',
                )
            }

            ##
            ## for dEJ input (degenerate Extended JSON)
            ##

            if (defined $degenerate_json) {

                is(
                    _normalize_numbers(
                        _native_to_canonical_extended_json($codec,
                            _extjson_to_native($codec, $degenerate_json),
                        )
                    ),
                    _normalize_numbers(
                        $deprecated
                            ? $converted_json
                            : $canonical_json,
                    ),
                    'native_to_canonical_extended_json(json_to_native(dEJ)) = cEJ',
                );

                bytes_are(
                    _native_to_bson($codec,
                        _extjson_to_native($codec, $degenerate_json),
                    ),
                    $deprecated
                        ? $converted_bson
                        : $canonical_bson,
                    'native_to_bson(json_to_native(dEJ)) = cB'
                ) unless $lossy;
            }

            ##
            ## for rEJ input (relaxed Extended JSON)
            ##

            if (defined $relaxed_json) {
                is(
                    _normalize_numbers(
                        _native_to_relaxed_extended_json($codec,
                            _extjson_to_native($codec, $relaxed_json),
                        )
                    ),
                    _normalize_numbers($relaxed_json),
                    'native_to_relaxed_extended_json(json_to_native(rEJ)) = rEJ',
                );
            }
        };
    }

    return;
}

sub _normalize {
    my ($json, $desc) = @_;
    return unless defined $json;

    try_or_fail(
        sub {
            $json = to_myjson( $JSON->decode( $json ) );
        },
        $desc
    ) or next;

    return $json;
}

sub _normalize_numbers {
    my ($value) = @_;
    return undef unless defined $value;

    $value =~ s{"0.0"}{"0"}g;
    $value =~ s{"-0.0"}{"0"}g;
    $value =~ s{"-0"}{"0"}g;
    $value =~ s{"1.0"}{"1"}g;
    $value =~ s{"-1.0"}{"-1"}g;

    $value =~ s[{"d":-0.0}][{"d":0}]g;
    $value =~ s[{"d":-0}][{"d":0}]g;
    $value =~ s[{"d":0.0}][{"d":0}]g;

    $value =~ s[(-?)1\.2345\d+(?:[eE]\+\d+)?][${1}1234567890...]g;
    $value =~ s[-1234567890123456768][-1234567890...]g;
    $value =~ s[1234567890123456768][1234567890...]g;

    # Power8 specific normalization
    $value =~ s[-1234567890123456770][-1234567890...]g;
    $value =~ s[1234567890123456770][1234567890...]g;

    return $value;
}

sub _native_to_bson {
    my ($codec, $native) = @_;

    my $bson;
    try_or_fail(
        sub { $bson = $codec->encode_one($native) },
        q{Couldn't convert from native Perl to BSON},
    ) or return undef;

    return $bson;
}

sub _bson_to_native {
    my ($codec, $bson) = @_;

    my $native;
    try_or_fail(
        sub { $native = $codec->decode_one($bson) },
        q{Couldn't convert from BSON to native Perl},
    ) or return undef;

    return $native;
}

sub _extjson_to_native {
    my ($codec, $extjson) = @_;

    my $native_extjson;
    try_or_fail(
        sub { $native_extjson = $JSON->decode($extjson) },
        q{Couldn't decode JSON to native ExtJSON},
    ) or return undef;

    my $native;
    try_or_fail(
        sub { $native = $codec->extjson_to_perl($native_extjson) },
        q{Couldn't convert from native ExtJSON to native Perl},
    ) or return undef;

    return $native;
}

sub _native_to_relaxed_extended_json {
    my ($codec, $native) = @_;

    my $native_extjson;
    try_or_fail(
        sub { $native_extjson = $codec->perl_to_extjson($native, {relaxed => 1}) },
        q{Couldn't convert from native Perl to native relaxed ExtJSON},
    ) or return undef;

    my $extjson;
    try_or_fail(
        sub { $extjson = $JSON->encode($native_extjson) },
        q{Couldn't encode native ExtJSON as JSON},
    ) or return undef;

    return $extjson;
}

sub _native_to_canonical_extended_json {
    my ($codec, $native) = @_;

    my $native_extjson;
    try_or_fail(
        sub { $native_extjson = $codec->perl_to_extjson($native, {relaxed => 0}) },
        q{Couldn't convert from native Perl to native canonical ExtJSON},
    ) or return undef;

    my $extjson;
    try_or_fail(
        sub { $extjson = $JSON->encode($native_extjson) },
        q{Couldn't encode native ExtJSON as JSON},
    ) or return undef;

    return $extjson;
}

sub _decode_error_tests {
    my ($json) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return unless $json->{decodeErrors};
    for my $case ( @{ $json->{decodeErrors} } ) {
        my $desc = $case->{description};
        my $bson = pack( "H*", $case->{bson} );

        eval { BSON::decode($bson) };
        ok( length($@), "Decode error: $desc:" );
    }
}

my %PARSER = (
    '0x00' => sub { bson_doc(shift) },
    '0x13' => sub { bson_decimal128(shift) },
);

sub _parse_error_tests {
    my ($json) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $parser = $PARSER{$json->{bson_type}};
    if ( $json->{parseErrors} && !$parser  ) {
        BAIL_OUT("No parseError parser available for $json->{bson_type}");
    }

    for my $case ( @{ $json->{parseErrors} } ) {
        eval { $parser->($case->{string}) };
        ok( $@, "$case->{description}: parse should throw an error " )
            or diag "Input was: $case->{string}";
    }
}

1;
#
# This file is part of BSON
#
# This software is Copyright (c) 2019 by Stefan G. and MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: set ts=4 sts=4 sw=4 et tw=75:

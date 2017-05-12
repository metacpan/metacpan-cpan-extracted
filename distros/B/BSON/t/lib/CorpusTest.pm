use 5.010001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep qw/!blessed/;

use BSON;
use BSON::Types ':all';
use Config;
use Path::Tiny 0.054; # better basename
use JSON::MaybeXS;
use Data::Dumper;

# from t/lib
use TestUtils;

use constant {
    IS_JSON_PP => ref( JSON::MaybeXS->new ) eq 'JSON::PP'
};

use base 'Exporter';
our @EXPORT = qw/test_corpus_file/;

binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

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

    if ( $json->{deprecated} ) {
        $f = path( "corpus", "deprecated", $file );
        $json = eval { decode_json( $f->slurp ) };
        if ( my $err = $@ ) {
            fail("deprecaed/$base failed to load");
            diag($err);
            return;
        }
    }

    _validity_tests($json);
    _decode_error_tests($json);
    _parse_error_tests($json);
}

sub _validity_tests {
    my ($json) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # suppress caching that throws off Test::Deep
    local $BSON::Types::NoCache = 1;

    # aggressively force ext-json representation, even for int32 and double
    local $ENV{BSON_EXTJSON_FORCE} = 1;

    my $bson_type = $json->{bson_type};

    for my $case ( @{ $json->{valid} } ) {
        local $Data::Dumper::Useqq = 1;

        my $desc = $case->{description};
        my $wrap = $bson_type =~ /\A(?:0x01|0x10|0x12)\z/;
        my $codec = BSON->new( prefer_numeric => 1, wrap_numbers => $wrap, ordered => 1 );
        my $lossy = $case->{lossy};

        my $B = $case->{bson};
        my $E = $case->{extjson}; # could be undef

        my $cB = exists($case->{canonical_bson}) ? $case->{canonical_bson} : $B;
        my $cE = exists($case->{canonical_extjson}) ? $case->{canonical_extjson} : $E;

        my $skip_extjson = !(defined($E) && _extjson_ok($bson_type, $E));

        $B = pack( "H*", $B );
        $cB = pack( "H*", $cB );

        $E = _normalize( $E, "$desc: normalizing E"  );
        $cE = _normalize( $cE, "$desc: normalizing cE"  );

        _bson_to_bson( $codec, $B, $cB, "$desc: B->cB" );

        if ($B ne $cB) {
            _bson_to_bson( $codec, $cB, $cB, "$desc: cB->cB" );
        }

        if ( ! $skip_extjson ) {
            _bson_to_extjson( $codec, $B, $cE, "$desc: B->cE" );
            _extjson_to_extjson( $codec, $E, $cE, "$desc: E->cE" );

            if ($B ne $cB) {
                _bson_to_extjson( $codec, $cB, $cE, "$desc: cB->cE" );
            }

            if ($E ne $cE) {
                _extjson_to_extjson( $codec, $cE, $cE, "$desc: cE->cE" );
            }

            if ( ! $lossy ) {
                _extjson_to_bson( $codec, $E, $cB, "$desc: E->cB" );

                if ($E ne $cE) {
                    _extjson_to_bson( $codec, $E, $cB, "$desc: cE->cB" );
                }

            }
        }
    }

    return;
}

# this handle special cases that just don't work will in perl
sub _extjson_ok {
    my ($type, $E) = @_;

    if ( $type eq "0x01" ) {
        return if $E =~ /\d\.0\D/; # trailing zeros wind up as integers
        return if $E =~ '-0(\.0)?'; # negative zero not preserved in Perl
    }

    # JSON::PP has trouble when TO_JSON returns a false value; in our case
    # it could stringify 0 as "0" rather than treat it as a number; see
    # https://github.com/makamaka/JSON-PP/pull/23
    if ( ( $type eq "0x10" || $type eq "0x12" ) && IS_JSON_PP ) {
        return if $E =~ /:\s*0/;
    }

    return 1;
}

sub _normalize {
    my ($json, $desc) = @_;
    return unless defined $json;

    try_or_fail(
        sub {
            $json = to_myjson( decode_json( $json ) );
        },
        $desc
    ) or next;

    return $json;
}

sub _bson_to_bson {
    my ($codec, $input, $expected, $label) = @_;

    my ($decoded,$got);

    try_or_fail(
        sub { $decoded = $codec->decode_one( $input ) },
        "$label: Couldn't decode BSON"
    ) or return;

    try_or_fail(
        sub { $got = $codec->encode_one( $decoded ) },
        "$label: Couldn't encode BSON from BSON"
    ) or return;

    return bytes_are( $got, $expected, $label );
}

sub _bson_to_extjson {
    my ($codec, $input, $expected, $label) = @_;

    my ($decoded,$got);

    try_or_fail(
        sub { $decoded = $codec->decode_one( $input ) },
        "$label: Couldn't decode BSON"
    ) or return;

    try_or_fail(
        sub { $got = to_extjson( $decoded ) },
        "$label: Couldn't encode ExtJSON from BSON"
    ) or return;

    return is($got, $expected, $label);
}

sub _extjson_to_bson {
    my ($codec, $input, $expected, $label) = @_;

    my ($decoded,$got);

    try_or_fail(
        sub { $decoded = $codec->inflate_extjson( decode_json( $input ) ) },
        "$label: Couldn't decode ExtJSON"
    ) or return;

    try_or_fail(
        sub { $got = $codec->encode_one( $decoded ) },
        "$label: Couldn't encode BSON from BSON"
    ) or return;

    return bytes_are( $got, $expected, $label );
}

sub _extjson_to_extjson {
    my ($codec, $input, $expected, $label) = @_;

    my ($decoded,$got);

    try_or_fail(
        sub { $decoded = $codec->inflate_extjson( decode_json( $input ) ) },
        "$label: Couldn't decode ExtJSON"
    ) or return;

    try_or_fail(
        sub { $got = to_extjson( $decoded ) },
        "$label: Couldn't encode ExtJSON from BSON"
    ) or return;

    return is($got, $expected, $label);
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
# This software is Copyright (c) 2017 by Stefan G. and MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: set ts=4 sts=4 sw=4 et tw=75:

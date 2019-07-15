use 5.008001;
use strict;
use warnings;
use utf8;

use Test::More 0.96;

binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;
use TestUtils;

use BSON;
use BSON::Types ':all';

sub _BSON { BSON->new(@_) }

subtest "error_callback" => sub {
    my $bad = "\x05\x00\x00\x00\x01";
    my @errs;
    my $obj = _BSON( error_callback => sub { push @errs, [@_] } );
    $obj->decode_one($bad);
    is( 0+ @errs, 1, "error_callback ran" );
    # 'error reading' is from BSON::XS
    like( $errs[0][0], qr/error reading|not null terminated/i, "error_callback arg 0" );
    is( ${ $errs[0][1] }, $bad,         "error_callback arg 1" );
    is( $errs[0][2],      'decode_one', "error_callback arg 2" );
};

subtest "invalid_char" => sub {
    my $obj = _BSON( invalid_chars => '.' );
    eval { $obj->encode_one( { "example.com" => 1 } ) };
    like(
        $@,
        qr/key 'example\.com' has invalid character\(s\) '\.'/,
        "invalid char throws exception"
    );

    $obj = _BSON( invalid_chars => '.$' );
    eval { $obj->encode_one( { "example.c\$om" => 1 } ) };
    like(
        $@,
        qr/key 'example\.c\$om' has invalid character\(s\) '\.\$'/,
        "multi-invalid chars throws exception"
    );
};

subtest "max_length" => sub {
    my $obj = _BSON( max_length => 20 );

    my $hash = { "example.com" => "a" x 100 };
    my $encoded = _BSON->encode_one($hash);

    eval { $obj->encode_one($hash) };
    like(
        $@,
        qr/encode_one.*Document exceeds maximum size 20/,
        "max_length exceeded during encode_one"
    );

    eval { $obj->decode_one($encoded) };
    like(
        $@,
        qr/decode_one.*Document exceeds maximum size 20/,
        "max_length exceeded during decode_one"
    );
};

subtest "op-char" => sub {
    my $obj = _BSON( op_char => '-' );

    my $hash   = { -inc   => { x => 1 } };
    my $expect = { '$inc' => { x => 1 } };
    my $got    = $obj->decode_one( $obj->encode_one($hash) );

    is_deeply( $got, $expect, "op-char converts to '\$'" )
      or diag explain $got;
};

subtest "prefer_numeric" => sub {
    my $hash = { x => "42" };

    my $pn0 = _BSON( prefer_numeric => 0 );
    my $pn1 = _BSON( prefer_numeric => 1 );
    my $dec = _BSON( wrap_numbers   => 1, wrap_strings => 1 );

    is( ref( $dec->decode_one( $pn1->encode_one($hash) )->{x} ),
        'BSON::Int32', 'prefer_numeric => 1' );
    is( ref( $dec->decode_one( $pn0->encode_one($hash) )->{x} ),
        'BSON::String', 'prefer_numeric => 0' );
};

subtest "first_key" => sub {
    my @doc = ( x => 42, y => 23, z => { a => 1, b => 2 } );

    my $obj = _BSON( ordered => 1 );

    my $got =
      $obj->decode_one(
        $obj->encode_one( bson_doc(@doc), { first_key => 'y', first_value => 32 } ) );

    my ( $k, $v ) = each %$got;

    is( $k, 'y', "first_key put first" );
    is( $v, 32,  "first_value overrode existing value" );
    ok( !exists $got->{z}{_id}, "first_key doesn't propagate" );

    # empty doc with first_key
    $got =
      $obj->decode_one(
        $obj->encode_one( bson_doc(), { first_key => 'y', first_value => 32 } ) );
    ( $k, $v ) = each %$got;

    is( $k, 'y', "first_key put first" );
    is( $v, 32,  "first_value overrode existing value" );
};

subtest "dt_type" => sub {
    my $now = time;

    # undef
    {
        my $obj = _BSON( dt_type => undef );
        my $bson = $obj->encode_one( { A => bson_time() } );
        my $hash = $obj->decode_one($bson);
        is( ref( $hash->{A} ), 'BSON::Time', "dt_type = undef" );
    }

    # BSON::Time
    {
        my $obj = _BSON( dt_type => "BSON::Time" );
        my $bson = $obj->encode_one( { A => bson_time() } );
        my $hash = $obj->decode_one($bson);
        is( ref( $hash->{A} ), 'BSON::Time', "dt_type = BSON::Time" );
    }

    # DateTime
    SKIP: {
        eval { require DateTime };
        skip( "DateTime not installed", 1 )
          unless $INC{'DateTime.pm'};

        my $obj = _BSON( dt_type => "DateTime" );
        my $bson = $obj->encode_one( { A => bson_time() } );
        my $hash = $obj->decode_one($bson);
        is( ref( $hash->{A} ), 'DateTime', "dt_type = DateTime" );
    }

    # DateTime::Tiny
    SKIP: {
        eval { require DateTime::Tiny };
        skip( "DateTime::Tiny not installed", 1 )
          unless $INC{'DateTime/Tiny.pm'};

        my $obj = _BSON( dt_type => "DateTime::Tiny" );
        my $bson = $obj->encode_one( { A => bson_time() } );
        my $hash = $obj->decode_one($bson);
        is( ref( $hash->{A} ), 'DateTime::Tiny', "dt_type = DateTime::Tiny" );
    }

    # Time::Moment
    SKIP: {
        eval { require Time::Moment };
        skip( "Time::Moment not installed", 1 )
          unless $INC{'Time/Moment.pm'};

        my $obj = _BSON( dt_type => "Time::Moment" );
        my $bson = $obj->encode_one( { A => bson_time() } );
        my $hash = $obj->decode_one($bson);
        is( ref( $hash->{A} ), 'Time::Moment', "dt_type = Time::Moment" );
    }

    # Mango::BSON::Time
    SKIP: {
        eval { require Mango::BSON::Time };
        skip( "Mango::BSON::Time not installed", 1 )
          unless $INC{'Mango/BSON/Time.pm'};

        my $obj = _BSON( dt_type => "Mango::BSON::Time" );
        my $bson = $obj->encode_one( { A => bson_time() } );
        my $hash = $obj->decode_one($bson);
        is( ref( $hash->{A} ), 'Mango::BSON::Time', "dt_type = Mango::BSON::Time" );
    }

    # unknown
    {
        my $obj = _BSON( dt_type => 'BOGUS' );
        my $bson = $obj->encode_one( { A => bson_time() } );
        eval { $obj->decode_one($bson) };
        like( $@, qr/unsupported dt_type/i, "dt_type = BOGUS" );
    }

};

done_testing;

#
# This file is part of BSON-XS
#
# This software is Copyright (c) 2019 by MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:


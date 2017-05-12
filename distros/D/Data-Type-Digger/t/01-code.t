#!/usr/bin/perl

use 5.14.0;
use Modern::Perl;
use Test::Spec;

plan tests => 15;

use Data::Type::Digger qw/dig/;

describe 'scalar' => sub {
    my $data1 = '1';

    my $res1 = dig(
        $data1,
        do_scalar => sub { ++$_[0] },
        do_array  => sub { die     },
        do_hash   => sub { die     },
        do_all    => sub { ++$_[0] },
    );

    is( $res1, 3, 'simple scalar ok' );


    my $data2    = { a1 => 1, a2 => { b1 => 1 }, a3 => [ 10, 20, 30, { c1 => 100, d1 => [ 1000 ] } ] };
    my $res_exp2 = { a1 => 2, a2 => { b1 => 2 }, a3 => [ 11, 21, 31, { c1 => 101, d1 => [ 1001 ] } ] };

    my $res2 = dig(
        $data2,
        do_all => sub { ref $_[0] ? $_[0] : ++$_[0] },
    );

    is_deeply( $res2, $res_exp2, 'simple scalar in deep nodes do_all ok' );


    my $data3    = { a1 => 1, a2 => { b1 => 1 }, a3 => [ 10, 20, 30, { c1 => 100, d1 => [ 1000 ] } ] };
    my $res_exp3 = { a1 => 2, a2 => { b1 => 2 }, a3 => [ 11, 21, 31, { c1 => 101, d1 => [ 1001 ] } ] };

    my $res3 = dig(
        $data3,
        do_scalar => sub { ++$_[0] },
    );

    is_deeply( $res3, $res_exp3, 'simple scalar in deep nodes do_scalar ok' );

};


describe 'hash' => sub {
    my $data1    = { a1 => 1, a2 => { b1 => 1 } };
    my $res_exp1 = { a1 => 1, a2 => { b1 => 2, b2 => 3 } };

    my $res1 = dig(
        $data1,
        do_hash => sub { my $n = $_[0]; return $n unless $n->{b1}; $n->{b1}++; return { %$n, b2 => 3 } },
    );

    is_deeply( $res1, $res_exp1, 'hash in deep nodes do_hash ok' );

};


describe 'array' => sub {
    my $data1    = { a1 => 1, a2 => [ 10, 20, 30, { c1 => [ 100, 200 ] } ] };
    my $res_exp1 = { a1 => 1, a2 => [ 10, 20, 30, { c1 => [ 101, 201 ] } ] };

    my $res1 = dig(
        $data1,
        do_array => sub { my $n = $_[0]; return $n unless $_[1] eq 'c1'; $n->[0]++; $n->[1]++; return $n },
    );

    is_deeply( $res1, $res_exp1, 'array in deep nodes do_array ok' );

};


describe 'max_deep' => sub {
    my $data1    = { a1 => 1, a2 => { b1 => 1 } };
    my $res_exp1 = { a1 => 1, a2 => { b1 => 1 } };

    my $res1 = dig(
        $data1,
        do_scalar => sub { return $_[0] },
        max_deep => 1,
    );

    is_deeply( $res1, $res_exp1, 'max_deep ok' );


    my $data2    = { a1 => 1, a2 => { b1 => 1     }, a3 => [ 1, 2, 3       ] };
    my $res_exp2 = { a1 => 1, a2 => { b1 => undef }, a3 => [ ( undef ) x 3 ] };

    my $res2 = dig(
        $data2,
        do_scalar => sub { return $_[0] },
        max_deep => 2,
        max_deep_cut => 1,
    );

    is_deeply( $res2, $res_exp2, 'max_deep + max_deep_cut ok' );

};


describe 'do_object+unbless' => sub {
    my $data1    = { a1 => bless { b1 => 1 }, 'xxx' };
    my $res_exp1 = { a1 =>       { b1 => 2 }        };

    my $res1 = dig(
        $data1,
        do_xxx => sub { my( $ref, $key ) = @_; $ref->{b1}++; return $ref },
        unbless => 1
    );

    is_deeply( $res1, $res_exp1, 'max_deep ok' );


    my $data2    = { a1 => bless { b1 => 1 }, 'xxx',         };
    my $res_exp2 = { a1 =>       { b1 => 2 },        b1 => 1 };

    my $res2 = dig(
        $data2,
        do_hash => sub { my( $ref, $key ) = @_; $ref->{b1}++; return $ref },
    );

    is_deeply( $res2, $res_exp2, 'max_deep ok' );


    my $data3    = { a1 => bless { b1 => 1 }, 'xxx' };
    my $res_exp3 = { a1 =>       { b1 => 2 }        };

    my $res3 = dig(
        $data3,
        do_xxx => sub { my( $ref, $key ) = @_; $ref->{b1}++; return $ref },
        unbless => 1,
    );

    is_deeply( $res3, $res_exp3, 'max_deep ok' );
};

describe 'do_object+NOunbless' => sub {
    my $data1    = { a1 => bless { b1 => 1 }, 'xxx' };
    my $res_exp1 = { a1 => bless { b1 => 2 }, 'xxx' };

    my $res1 = dig(
        $data1,
        do_xxx => sub { my( $ref, $key ) = @_; $ref->{b1}++; return $ref },
        unbless => 0,
    );

    is_deeply( $res1, $res_exp1, 'max_deep ok' );


    my $data2    = { a1 => bless { b1 => 1 }, 'xxx',         };
    my $res_exp2 = { a1 =>       { b1 => 2 },        b1 => 1 };

    my $res2 = dig(
        $data2,
        do_hash => sub { my( $ref, $key ) = @_; $ref->{b1}++; return $ref },
    );

    is_deeply( $res2, $res_exp2, 'max_deep ok' );


    my $data3    = { a1 => bless { b1 => 1 }, 'xxx' };
    my $res_exp3 = { a1 =>       { b1 => 2 }        };

    my $res3 = dig(
        $data3,
        do_xxx => sub { my( $ref, $key ) = @_; $ref->{b1}++; return $ref },
        unbless => 1,
    );

    is_deeply( $res3, $res_exp3, 'max_deep ok' );
};

describe 'clone' => sub {
    my $data1    = { a1 => 1, a2 => [ 10, 20, 30, { c1 => [ 100, 200 ] } ] };

    my $res1 = dig(
        $data1,
        do_array => sub { my $a = $_[0]; return $a }, # do nothing
        clone => 1,
    );

    ok( $data1            ne $res1,            'root HASH was cloned'      );
    ok( $data1->{a2}->[3] ne $res1->{a2}->[3], 'deep array was cloned too' );
};

done_testing();

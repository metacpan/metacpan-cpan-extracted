#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use App::lntree;
use File::Spec;

my ( $from, $to, $from_path, $to_path );

sub path { return File::Spec->canonpath( join '/', @_ ) }

$from = 'src';
$to = 'dst';

( $from_path, $to_path ) = App::lntree->resolve( $from, $to, path(qw/ src a /) );
is( $from_path, path(qw/ .. src a /) );
is( $to_path, path(qw/ a /) );

( $from_path, $to_path ) = App::lntree->resolve( $from, $to, 'src/b/c' );
is( $from_path, path(qw/ .. .. src b c /) );
is( $to_path, path(qw/ b c /) );

( $from_path, $to_path ) = App::lntree->resolve( $from, $to, 'src/b/c/d' );
is( $from_path, path(qw/ .. .. .. src b c d /) );
is( $to_path, path(qw/ b c d /) );

( $from_path, $to_path ) = App::lntree->resolve( $from, path( '/', $to ), 'src/b/c' );
is( $from_path, File::Spec->rel2abs( path(qw/ src b c /) ) );
is( $to_path, path(qw/ b c /) );

( $from_path, $to_path ) = App::lntree->resolve( $from, $to, path(qw/ src a /) );
is( $from_path, path(qw/ .. src a /) );
is( $to_path, path(qw/ a /) );

( $from_path, $to_path ) = App::lntree->resolve( path( 'src/a/b' ), path( 'b' ), path( 'src/a/b/c' ) );
is( $from_path, path(qw/ .. src a b c /) );
is( $to_path, path(qw/ c /) );

done_testing;

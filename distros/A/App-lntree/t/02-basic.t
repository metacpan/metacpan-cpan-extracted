#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use App::lntree;
use File::Temp qw/ tempfile tempdir /;
use Path::Class;

my ( $source, $target, $readlink, $file, $directory );

$source = dir(qw/ t assets source1 /);

$target = dir tempdir;
App::lntree->lntree( $source, $target );
ok( -l file $target, qw/ a / );
is( file( $target, qw/ a /)->stat->size, 14 );
ok( -d dir $target, qw/ b / );
ok( -l file $target, qw/ b c / );
is( file( $target, qw/ b c /)->stat->size, 0 );
ok( -l file $target, qw/ b d / );
is( file( $target, qw/ b d /)->stat->size, 12 );
$readlink = readlink file $target, qw/ b d /;

App::lntree->lntree( dir(qw/ t assets source2 /), $target );
ok( -l file $target, qw/ a / );
is( file( $target, qw/ a /)->stat->size, 6 );
is( $readlink, readlink file $target, qw/ b d / );

$target = dir tempdir;
$file = $target->file(qw/ overwrite /)->openw->print( "A file.\n" );
$directory = $target->subdir(qw/ b overwrite /)->mkpath;
App::lntree->lntree( dir(qw/ t assets source1 /), $target );
ok( !-l file $target, qw/ overwrite / );
is( file( $target, qw/ overwrite /)->stat->size, 8 );
ok( !-l file $target, qw/ b overwrite / );
ok( -l file $target, qw/ b d / );
is( file( $target, qw/ b d /)->stat->size, 12 );

$target = file( File::Temp->new->filename );
$target->openw->print( '' );
throws_ok { App::lntree->lntree( dir(qw/ t assets source1 /), $target ) } qr/already exists and is a file/;

$source = dir(qw/ t assets source1 b /);
$target = dir tempdir, 'b';
App::lntree->lntree( $source, $target );
ok( -l file( $target, qw/ c / ) );

done_testing;

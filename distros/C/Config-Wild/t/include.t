#!perl

use strict;
use warnings;

use Test::More;

use Config::Wild;
use Path::Tiny qw[ path cwd ];
use File::pushd;

use Test::TempDir::Tiny;

my $cwd       = cwd;
my $data_dir  = path( $cwd, qw[ t data include ] );
my $decoy_dir = $data_dir->child( 'decoy' );

# ensure that decoy configuration files are where they should be
subtest 'test path decoy' => sub {

    for my $file ( qw[ secondary.cnf l1/secondary.cnf ] ) {
        my $cfg = Config::Wild->new( $file, { path => [$decoy_dir] } );
        is( $cfg->value( 'secondary' ), "decoy/$file", "decoy/$file exists" );
    }


};

subtest 'absolute' => sub {

    my $tempdir = path( tempdir() );

    $tempdir->mkpath;
    my $primary   = $tempdir->child( 'primary.cnf' );
    my $secondary = $tempdir->child( 'secondary.cnf' );

    $primary->spew(
        "primary = $tempdir/primary.cnf\n",
        "%include $tempdir/secondary.cnf\n"
    );
    $secondary->spew( "secondary = $tempdir/secondary.cnf\n" );


    {
        my $cfg = Config::Wild->new( $primary, { dir => $cwd } );
        is( $cfg->value( 'primary' ),   $primary,   "dir: primary" );
        is( $cfg->value( 'secondary' ), $secondary, "dir: secondary" );
    }

    {
        my $cfg = Config::Wild->new( $primary, { path => [ $data_dir ] } );
        is( $cfg->value( 'primary' ),   $primary,   "path: primary" );
        is( $cfg->value( 'secondary' ), $secondary, "path: secondary" );
    }

    {
        my $cfg = Config::Wild->new( $primary );
        is( $cfg->value( 'primary' ),   $primary,   "default: primary" );
        is( $cfg->value( 'secondary' ), $secondary, "default: secondary" );
    }

};



subtest 'relative to dir' => sub {


    {
        my $cfg = Config::Wild->new( 'dir.cnf', { dir => $data_dir } );
        is( $cfg->value( 'primary' ), 'dir.cnf', "dir: top level config" );
        is(
            $cfg->value( 'secondary' ),
            'secondary.cnf',
            "dir: dir-relative config"
        );
    }

    {
# add decoy directory first to ensure we're not just following the path when looking for
# the file
        my $cfg = Config::Wild->new( 'dir.cnf',
            { path => [ $decoy_dir, $data_dir ] } );
        is( $cfg->value( 'primary' ), 'dir.cnf', "path: top level config" );
        is(
            $cfg->value( 'secondary' ),
            'secondary.cnf',
            "path: dir-relative config"
        );
    }

    {
        my $cfg = Config::Wild->new( $data_dir->child( 'dir.cnf' ) );
        is( $cfg->value( 'primary' ), 'dir.cnf', "default: top level config" );
        is( $cfg->value( 'secondary' ),
            'secondary.cnf', "default: dir-relative config" );
    }


};

subtest 'relative to parent' => sub {

    {
        my $cfg = Config::Wild->new( 'parent.cnf', { dir => $data_dir } );
        is( $cfg->value( 'primary' ), 'parent.cnf', "dir: top level config" );
        is( $cfg->value( 'secondary' ),
            'secondary.cnf', "dir: parent-relative config" );
    }

    {
# add decoy directory first to ensure we're not just following the path when looking for
# the file
        my $cfg = Config::Wild->new( 'parent.cnf',
            { path => [ $decoy_dir, $data_dir ] } );
        is( $cfg->value( 'primary' ), 'parent.cnf', "path: top level config" );
        is( $cfg->value( 'secondary' ),
            'secondary.cnf', "path: parent-relative config" );
    }

    {
        my $cfg = Config::Wild->new( $data_dir->child( 'parent.cnf' ) );
        is( $cfg->value( 'primary' ),
            'parent.cnf', "default: top level config" );
        is( $cfg->value( 'secondary' ),
            'secondary.cnf', "default: parent-relative config" );
    }

};


subtest 'other' => sub {

    {
        my $cfg = Config::Wild->new( 'other0.cnf', { dir => $data_dir } );
        is( $cfg->value( 'primary' ),
            'other0.cnf', "dir: simple path top level config" );
        is( $cfg->value( 'secondary' ),
            'secondary.cnf', "dir: simple path secondary config" );
    }

    {
        my $cfg = Config::Wild->new( 'other1.cnf', { dir => $data_dir } );
        is( $cfg->value( 'primary' ),
            'other1.cnf', "dir: copmlex path top level config" );
        is( $cfg->value( 'secondary' ),
            'l1/secondary.cnf', "dir: complex path secondary config" );
    }

    {
        my $cfg = Config::Wild->new( 'other0.cnf',
            { path => [ $decoy_dir, $data_dir ] } );
        is( $cfg->value( 'primary' ),
            'other0.cnf', "dir: simple path top level config" );
        is( $cfg->value( 'secondary' ),
            'decoy/secondary.cnf', "dir: simple path secondary config" );
    }

    {
        my $cfg = Config::Wild->new( 'other1.cnf',
            { path => [ $decoy_dir, $data_dir ] } );
        is( $cfg->value( 'primary' ),
            'other1.cnf', "path: complex path top level config" );
        is( $cfg->value( 'secondary' ),
            'decoy/l1/secondary.cnf', "path: complex path secondary config" );
    }


    {
        my $dir = pushd( $data_dir );
        my $cfg = Config::Wild->new( 'other0.cnf' );
        is( $cfg->value( 'primary' ),
            'other0.cnf', "default: simple path top level config" );
        is( $cfg->value( 'secondary' ),
            'secondary.cnf', "default: simple path secondary config" );
    }

    {
        my $dir = pushd( $data_dir );
        my $cfg = Config::Wild->new( 'other1.cnf' );
        is( $cfg->value( 'primary' ),
            'other1.cnf', "default: copmlex path top level config" );
        is( $cfg->value( 'secondary' ),
            'l1/secondary.cnf', "default: complex path secondary config" );
    }

};


done_testing;

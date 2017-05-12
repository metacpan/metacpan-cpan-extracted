#!perl

use strict;
use warnings;

use Test::More;

use Config::Wild;
use Path::Tiny qw[ path cwd ];
use File::pushd;

my %method = (
    constructor => sub { Config::Wild->new( @_ ) },
    load        => sub {
        my $file = shift;
        my $cfg  = Config::Wild->new( @_ );
        $cfg->load( $file );
        return $cfg;
    } );

my $cwd = cwd;
my $data_dir = path( $cwd, qw[ t data method ] );

subtest 'absolute' => sub {

    for my $mth ( keys %method ) {

        my $file = 'data/method/conf';
        my $path = path( $data_dir, 'conf' );

        # set options to point at the wrong place to
        # make sure absolute actually works
        for my $options ( { dir => path( $data_dir, 'b' ) },
            { path => [ path( $data_dir, 'b' ) ] }, {}, )
        {

            my $cfg = $method{$mth}->( $path, $options );

            my $opt = ( keys %$options )[0] || 'default';

            is( $cfg->value( 'file' ), $file, "$mth($opt): $file" );
        }

    }


};


subtest 'relative to dir' => sub {

    my $file = 'data/method/conf';

    for my $mth ( keys %method ) {

        {
            my $cfg = $method{$mth}->( './conf', { dir => $data_dir } );
            is( $cfg->value( 'file' ), $file, "$mth(dir): ./" );
        }

        {
            my $cfg = $method{$mth}
              ->( '../conf', { dir => $data_dir->child( 'b' ) } );
            is( $cfg->value( 'file' ), $file, "$mth(dir): ../" );
        }


        {
            my $dir = pushd( $data_dir );
            my $cfg = $method{$mth}->( './conf', { path => [$cwd] } );
            is( $cfg->value( 'file' ), $file, "$mth(path): ./" );
        }

        {
            my $dir = pushd( $data_dir->child( 'b' ) );
            my $cfg = $method{$mth}->( '../conf', { path => [$cwd] } );
            is( $cfg->value( 'file' ), $file, "$mth(path): ../" );
        }

        {
            my $dir = pushd( $data_dir );
            my $cfg = $method{$mth}->( './conf' );
            is( $cfg->value( 'file' ), $file, "$mth(default): ./" );
        }

        {
            my $dir = pushd( $data_dir->child( 'b' ) );
            my $cfg = $method{$mth}->( '../conf' );
            is( $cfg->value( 'file' ), $file, "$mth(default): ../" );
        }
    }


};

subtest 'other' => sub {

    my $dir = 'data/method';

    for my $path ( ['conf'], [ 'b', 'conf' ] ) {

        my $file = join( '/', @$path );
        my $file_s = join( '/', $dir, $file );


        for my $mth ( keys %method ) {

            {
                my $cfg = $method{$mth}->( $file, { dir => $data_dir } );
                is( $cfg->value( 'file' ), $file_s, "$mth(dir): $file" );
            }

            {
                my $cfg = $method{$mth}->( $file, { path => [$data_dir] } );
                is( $cfg->value( 'file' ), $file_s, "$mth(path): $file" );
            }

            {
                my $dir = pushd( $data_dir );
                my $cfg = $method{$mth}->( $file );
                is( $cfg->value( 'file' ), $file_s, "$mth(default): $file" );
            }

        }

    }

    # multiple paths, same name

    for my $mth ( keys %method ) {

	{
	    my $cfg = $method{$mth}->( 'conf', { path => [ cwd, $data_dir, $data_dir->child('b') ] } );
	    is( $cfg->value( 'file' ), 'data/method/conf', "$mth(path): duplicate conf entries in path, element 1" );
	}

	{
	    my $cfg = $method{$mth}->( 'conf', { path => [ cwd, $data_dir->child('b'), $data_dir  ] } );
	    is( $cfg->value( 'file' ), 'data/method/b/conf', "$mth(path): duplicate conf entries in path, alternate order" );
	}

	{
	    my $cfg = $method{$mth}->( 'a.cnf', { path => [ $data_dir ] } );
	    is( $cfg->value( 'file' ), 'data/method/a.cnf', "$mth(path): first in path" );
	}

	{
	    my $cfg = $method{$mth}->( 'c.cnf', { path => [ $data_dir, $data_dir->child('b'), $data_dir->child('b')->child('c') ] } );
	    is( $cfg->value( 'file' ), 'data/method/b/c/c.cnf', "$mth(path): last in path" );
	}
    }



};


done_testing;

#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most 'no_plan';

use App::PAUSE::cleanup;

cmp_deeply( [ App::PAUSE::cleanup->expand_filelist( [qw/
    A-1.0
    A-2.0
    A-3
    B-4.0_1
    B-5_2
/] ) ], [qw/
    A-1.0.meta
    A-1.0.readme
    A-1.0.tar.gz
    A-2.0.meta
    A-2.0.readme
    A-2.0.tar.gz
    A-3.meta
    A-3.readme
    A-3.tar.gz
    B-4.0_1.tar.gz
    B-5_2.tar.gz
/]
);

sub _file {
    my ( $package, $version ) = @_;

    return { package => $package,
             version => $version,
             package_version => "${package}-${version}",
    };
}

{
    my ( @filelist, @latest );
    push @filelist,
        _file( qw/ A 1_2 / ),
        _file( qw/ A 1_1 / ),
        _file( qw/ A 2 / ),
        _file( qw/ A 1 / ),
    ;
    @latest = App::PAUSE::cleanup->extract_latest( \@filelist );

    cmp_deeply( [ map { $_->{package_version} } @latest ], [qw/ A-1_2 A-2 /] );
    cmp_deeply( [ map { $_->{package_version} } @filelist ], [qw/ A-1_1 A-1 /] );
}

{
    my ( @filelist, @latest );
    push @filelist,
        _file( qw/ A 1_1 / ),
        _file( qw/ A 2 / ),
        _file( qw/ A 1 / ),
    ;
    @latest = App::PAUSE::cleanup->extract_latest( \@filelist );

    cmp_deeply( [ map { $_->{package_version} } @latest ], [qw/ A-1_1 A-2 /] );
    cmp_deeply( [ map { $_->{package_version} } @filelist ], [qw/ A-1 /] );
}

{
    my ( @filelist, @latest );
    push @filelist,
        _file( qw/ A 2 / ),
        _file( qw/ A 1 / ),
    ;
    @latest = App::PAUSE::cleanup->extract_latest( \@filelist );

    cmp_deeply( [ map { $_->{package_version} } @latest ], [qw/ A-2 /] );
    cmp_deeply( [ map { $_->{package_version} } @filelist ], [qw/ A-1 /] );
}

{
    my ( @filelist, @latest );
    push @filelist,
        _file( qw/ A 2 / ),
        _file( qw/ A 1_1 / ),
    ;
    @latest = App::PAUSE::cleanup->extract_latest( \@filelist );

    cmp_deeply( [ map { $_->{package_version} } @latest ], [qw/ A-2 /] );
    cmp_deeply( [ map { $_->{package_version} } @filelist ], [qw/ A-1_1 /] );
}

{
    my ( @filelist, @latest );
    push @filelist,
        _file( qw/ A 1_1 / ),
        _file( qw/ A 2 / ),
    ;
    @latest = App::PAUSE::cleanup->extract_latest( \@filelist );

    cmp_deeply( [ map { $_->{package_version} } @latest ], [qw/ A-1_1 A-2 /] );
    cmp_deeply( [ map { $_->{package_version} } @filelist ], [] );
}

#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan skip_all => "Only go out to the Internet for author" unless -e 'inc/.author';

plan qw/no_plan/;

use App::GitHub::FixRepositoryName;

my ($content);
$content = <<'_END_';
[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
[remote "origin"]
        url = git@github.com:robertkrimen/aPp-giTHUb-finDreposItory.git
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
        remote = origin
        merge = refs/heads/master
_END_

is( App::GitHub::FixRepositoryName->fix( $content ), <<'_END_' );
[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
[remote "origin"]
        url = git@github.com:robertkrimen/App-GitHub-FindRepository.git
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
        remote = origin
        merge = refs/heads/master
_END_

use Directory::Scratch;
use Path::Class;
use Digest::SHA1 qw/sha1_hex/;

sub sha1_file($) {
    my $file = shift;
    return sha1_hex scalar $file->slurp;
}

my $good_config = Path::Class::File->new( "t/assets/good-config" );
my $bad_config = Path::Class::File->new( "t/assets/bad-config" );
my $good_sha1 = sha1_file $good_config;
my $bad_sha1 = sha1_file $bad_config;
my ($file, $backup, %options);
%options = ( silent => 1, always_yes => 1 );

sub scratch($;$) {
    my $bad_file = shift;
    my $good_file = shift;
    my $scratch = Directory::Scratch->new;
    if ($good_file) { $good_file = $scratch->file( $good_file ); $good_file->parent->mkpath; $good_file->openw->print( scalar $good_config->slurp ) }
    if ($bad_file) { $bad_file = $scratch->file( $bad_file ); $bad_file->parent->mkpath; $bad_file->openw->print( scalar $bad_config->slurp ) }
    return $scratch;
}

{
    my $scratch = scratch '.git/config';
    eval {
        App::GitHub::FixRepositoryName->_try_to_fix_file_or_directory( $scratch->base, %options, backup_to => '/mnt' );
    };
    ok( $@ );
    is( sha1_file $scratch->file( '.git/config' ), $bad_sha1 ); # File should be unchanged
}

{
    my $scratch = scratch '.git/config';
    ($file, $backup) = App::GitHub::FixRepositoryName->_try_to_fix_file_or_directory( $scratch->base, %options );
    ok( $file );
    ok( $backup );
    like( $backup, qr{\.git/\.backup-config-20\d{2}-.*-.{6}} );
}

{
    my $scratch = scratch 'a/.git/config';
    ($file, $backup) = App::GitHub::FixRepositoryName->_try_to_fix_file_or_directory( $scratch->dir(qw/ a /), %options );
    ok( $file );
    is( sha1_file $file, $good_sha1 );
    ok( $backup );
    is( sha1_file $backup, $bad_sha1 );
    like( $backup, qr{a/\.git/\.backup-config-20\d{2}-.*-.{6}} );
}

{
    my $scratch = scratch 'a/.git/config';
    ($file, $backup) = App::GitHub::FixRepositoryName->_try_to_fix_file_or_directory( $scratch->dir(qw/ a /), %options );
    ok( $file );
    is( sha1_file $file, $good_sha1 );
    ok( $backup );
    is( sha1_file $backup, $bad_sha1 );
    like( $backup, qr{a/\.git/\.backup-config-20\d{2}-.*-.{6}} );
}

{
    my $scratch = scratch undef, '.git/config';
    ok( ! App::GitHub::FixRepositoryName->_try_to_fix_file_or_directory( $scratch->base, %options ) );
}

{
    my $scratch = scratch '.git/config';
    ($file, $backup) = App::GitHub::FixRepositoryName->_try_to_fix_file_or_directory( $scratch->base, %options, backup_to => $scratch->dir( 'somewhere/over/there' ) );
    ok( $file );
    is( sha1_file $file, $good_sha1 );
    ok( $backup );
    is( sha1_file $backup, $bad_sha1 );
    like( $backup, qr{somewhere/over/there/\.backup-config-20\d{2}-.*-.{6}} );
}

{
    my $scratch = scratch 'config';
    $scratch->touch( $_ ) for qw/branches hooks info objects refs/;
    ($file, $backup) = App::GitHub::FixRepositoryName->_try_to_fix_file_or_directory( $scratch->base, %options );
    ok( $file );
    is( sha1_file $file, $good_sha1 );
    ok( $backup );
    is( sha1_file $backup, $bad_sha1 );
    like( $backup, qr{\.backup-config-20\d{2}-.*-.{6}} );
}

{
    my $scratch = scratch 'config';
    eval {
        App::GitHub::FixRepositoryName->_try_to_fix_file_or_directory( $scratch->base, %options );
    };
    like( $@, qr/Don't know how to fix directory/ );
}

{
    my $scratch = scratch '.git/config';
    ($file, $backup) = App::GitHub::FixRepositoryName->_try_to_fix_file_or_directory( $scratch->base->file( '.git/config' ), %options );
    ok( $file );
    ok( $backup );
    like( $backup, qr{\.git/\.backup-config-20\d{2}-.*-.{6}} );
}


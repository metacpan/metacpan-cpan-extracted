#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Differences;

use lib 't/lib';
use AETest;

{
    my $return = AETest->test( [qw{ install-vim --print --dest x }], '' );
    is( $return->stdout, '', 'Install-Vim w/ too many opts' );
    like( $return->error, qr/cannot be combined/, '... too many opts' );
}

{
    my $return = AETest->test( [qw{ install-vim --print }], '' );
    like( $return->stdout,
        qr/" App::EditorTools::Command::InstallVim generated script/,
        '--print' );
    like( $return->stderr, qr/STDOUT/, '... good location' );
    is( $return->error, undef, '... no error' );
}

{
    my $return = AETest->test( [qw{ install-vim --local --dryrun }], '' );
    is( $return->stdout, '', '--local' );
    like( $return->stderr, qr{.ftplugin.perl.editortools.vim}, '... good location' );
    is( $return->error, undef, '... no error' );
}

{
    my $return = AETest->test( [qw{ install-vim --dryrun }], '' );
    is( $return->stdout, '', 'default' );
    like( $return->stderr, qr{.ftplugin.perl.editortools.vim}, '... good location' );
    is( $return->error, undef, '... no error' );
}


{
    my $return = AETest->test( [qw{ install-vim --dest '/tmp/script.vim' --dryrun }], '' );
    is( $return->stdout, '', '--dest' );
    like( $return->stderr, qr{\Q/tmp/script.vim\E}, '... good location' );
    is( $return->error, undef, '... no error' );
}

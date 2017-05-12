#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Differences;

use lib 't/lib';
use AETest;

{
    my $return = AETest->test( [qw{ install-emacs --print --dest x }], '' );
    is( $return->stdout, '', 'Install-Emacs w/ too many opts' );
    like( $return->error, qr/cannot be combined/, '... too many opts' );
}

{
    my $return = AETest->test( [qw{ install-emacs --print }], '' );
    like( $return->stdout,
        qr/App::EditorTools::Command::InstallEmacs generated script/,
        '--print' );
    like( $return->stderr, qr/STDOUT/, '... good location' );
    is( $return->error, undef, '... no error' );
}

{
    my $return = AETest->test( [qw{ install-emacs --local --dryrun }], '' );
    is( $return->stdout, '', '--local' );
    like( $return->stderr, qr{..emacs\.d.editortools.el}, '... good location' );
    is( $return->error, undef, '... no error' );
}

{
    my $return = AETest->test( [qw{ install-emacs --dryrun }], '' );
    is( $return->stdout, '', 'default' );
    like( $return->stderr, qr{..emacs\.d.editortools.el}, '... good location' );
    is( $return->error, undef, '... no error' );
}


{
    my $return = AETest->test( [qw{ install-emacs --dest '/tmp/script.el' --dryrun }], '' );
    is( $return->stdout, '', '--dest' );
    like( $return->stderr, qr{\Q/tmp/script.el\E}, '... good location' );
    is( $return->error, undef, '... no error' );
}

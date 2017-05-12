use Test::Requires qw(Test::Cmd);
use Test::Cmd;
use Test::More tests => 8;

use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );

my $cmd = Test::Cmd->new(
    workdir => '',
    prog    => File::Spec->catfile( 'bin', 'changelog-run' ),
);

ok( $cmd->run( args => '-h' ),     'changelog-run help ok' );
ok( $cmd->run( args => '--help' ), 'changelog-run help ok' );
ok( $cmd->run( args => '-?' ),     'changelog-run help ok' );

ok( !$cmd->run( args => '--version' ), 'changelog-run current version' );
ok( !$cmd->run( args => '-v' ),        'changelog-run current version' );

my $chglgs = File::Spec->catfile( $FindBin::Bin, 'data', 'changelog' );
ok( !$cmd->run( args => '-db=.tmp.cmdtest.sqlite -r -d=' . $chglgs ), 'changelog-run run ok' );
ok( !$cmd->run( args => '-db=.tmp.cmdtest.sqlite -r -d=' . $chglgs ), 'changelog-run run ok' );
ok( !$cmd->run( args => '-db=.tmp.cmdtest.sqlite -r -d=' . $chglgs ), 'changelog-run run ok' );

my $file = File::Spec->catfile( $FindBin::Bin, '..', '.tmp.cmdtest.sqlite' );
unlink $file or warn "Could not unlink $file: $!";

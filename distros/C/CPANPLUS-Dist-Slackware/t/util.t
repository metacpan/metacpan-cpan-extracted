#!perl

use strict;
use warnings;

use Test::More tests => 7;

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Scalar::Util qw(tainted);

my $tempdir = tempdir( CLEANUP => 1 );

BEGIN {
    my @subs = qw(can_run run slurp spurt filetype gzip strip);
    use_ok( 'CPANPLUS::Dist::Slackware::Util', @subs ) || print "Bail out!\n";
}

my $filename = catfile( $tempdir, 'hello.txt' );
my $text = "hello, world";
ok( spurt( $filename, $text ), 'write to file' );
is( slurp($filename), $text, 'read from file' );
ok( gzip($filename), 'compress file' );
can_ok( __PACKAGE__, 'strip' );

my $perl = can_run('perl');
SKIP:
{
    skip( 'taint mode enabled', 2 ) if tainted( $ENV{PWD} );
    ok( filetype($filename), 'get file type' );
SKIP:
    {
        skip( 'perl interpreter not found', 1 ) if !$perl;
        ok( run( [ $perl, '-v' ], { dir => $tempdir } ), 'run perl' );
    }
}

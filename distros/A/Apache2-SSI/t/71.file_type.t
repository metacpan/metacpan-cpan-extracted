#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
    use lib './lib';
    use vars qw( $DEBUG );
    use_ok( 'Apache2::SSI::File::Type' ) || BAIL_OUT( "Unable to load Apache2::SSI::File" );
    use URI::file;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

## my $m = Apache2::SSI::File::Type->new( '/etc/apache2/magic', debug => $DEBUG );
my $m = Apache2::SSI::File::Type->new( debug => $DEBUG );
isa_ok( $m, 'Apache2::SSI::File::Type' );
BAIL_OUT( "Unable to instantiate an Apache2::SSI::File::Type object: " . Apache2::SSI::File::Type->error ) if( !defined( $m ) );
my $win_file = URI::file->new( './t/htdocs/ssi/include_win32.cgi' )->file( $^O );
my $mime = $m->file( $win_file );
diag( "$win_file => $mime" ) if( $DEBUG );
diag( "An error occured: ", $m->error ) if( $DEBUG && !defined( $mime ) );
is( $mime, 'text/x-perl', 'Mime type on Windows' );
$mime = $m->file( __FILE__ );
diag( __FILE__, " => $mime" ) if( $DEBUG );
is( $mime, 'text/x-perl', 'Mime type of Linux perl script' );

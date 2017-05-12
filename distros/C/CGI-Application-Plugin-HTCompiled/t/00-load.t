#!perl
use Test::More tests => 3;
use Test::Exception;
use Scalar::Util;

BEGIN {
	use_ok( 'CGI::Application', 4.31 );
	use_ok( 'CGI::Application::Plugin::HTCompiled' );
	require_ok('CGI::Application::Plugin::HTCompiled');
};

use lib './t';
use strict;
use warnings;

{
    package TestAppBasic;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::HTCompiled;
}


__END__
##!perl -T
#
#use Test::More tests => 1;
#
#BEGIN {
#	use_ok( 'CGI::Application::Plugin::HTCompiled' );
#}
#
#diag( "Testing CGI::Application::Plugin::HTCompiled $CGI::Application::Plugin::HTCompiled::VERSION, Perl $], $^X" );

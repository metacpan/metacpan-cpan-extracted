use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'CGI::Easy::SendFile' ) or BAIL_OUT('unable to load module') }

diag( "Testing CGI::Easy::SendFile $CGI::Easy::SendFile::VERSION, Perl $], $^X" );

use strict;
use warnings;

use lib qw(. ./lib ../lib);


use CGI::Application::Server;


use MyCGI;



my $server = CGI::Application::Server->new( 5050 );
$server->entry_points(
    {
        '/test.cgi' => 'MyCGI',
    }
);

$server->run( );

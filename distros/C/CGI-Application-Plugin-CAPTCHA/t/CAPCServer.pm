package CAPCServer;

use strict;
use warnings;

use base 'HTTP::Server::Simple::CGI';
use lib './t';
use TestApp2;

sub handle_request 
{
    my ($self, $cgi) = @_;

    print "HTTP/1.0 200 OK\r\n";
    my $webapp = TestApp2->new();
    return $webapp->run;
}

1;

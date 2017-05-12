=head1 NAME

Template development server for CGI::Application::Structured apps.

=cut 

use warnings;
use strict;
use CGI::Application::Server;
use lib 'lib';
use <tmpl_var main_module>::Dispatch;

my $server = CGI::Application::Server->new(8060);
$server->document_root('./t/www');
$server->entry_points({
    '/cgi-bin/index.cgi' => "<tmpl_var main_module>::Dispatch",
});

print "access your default runmode at /cgi-bin/index.cgi\n";
$server->run;





package CPAN::Mini::Inject::REST::Client::Command;

use 5.010;
use strict;
use warnings;
use App::Cmd::Setup -command;
use CPAN::Mini::Inject::REST::Client::API;


#--Define default options for all commands--------------------------------------

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ 'protocol=s' => "Network protocol ('http' or 'https')", {default => $app->config->{protocol} || 'http'} ],
        [ 'host=s'     => "Hostname of your CPAN server",         {default => $app->config->{host} || '127.0.0.1'} ],
        [ 'port=i'     => "CPAN server port number",              {default => $app->config->{port} || '80'} ],
        [ 'username=s' => "Username (if using HTTP basic auth)",  {default => $app->config->{username} || undef} ],
        [ 'password=s' => "Password (if using HTTP basic auth)",  {default => $app->config->{password} || undef} ],
        $class->options($app),
    );
}


#--Build the API object---------------------------------------------------------

sub api {
    my ($self, $opt) = @_;
    
    my $api_options = {
        protocol => $opt->{protocol},
        host     => $opt->{host},
        port     => $opt->{port},
    };
    
    $opt->{username} && do {$api_options->{username} = $opt->{username}};
    $opt->{password} && do {$api_options->{password} = $opt->{password}};
    
    return CPAN::Mini::Inject::REST::Client::API->new($api_options);
}


#-------------------------------------------------------------------------------

1;
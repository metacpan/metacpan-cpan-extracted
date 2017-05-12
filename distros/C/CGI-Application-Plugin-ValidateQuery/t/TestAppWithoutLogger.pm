package TestAppWithoutLogger;

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use base 'CGI::Application';
use CGI::Application::Plugin::ValidateQuery qw(
            validate_query_config
            validate_query
            validate_app_params
);

sub setup {
    my $self = shift; 
    $self->start_mode('test_mode');
    $self->run_modes(
            test_mode => 'test_mode',
            fail_mode => 'fail_mode'
    );
}

sub test_mode {
    my $self = shift;
    return "normal output";
}

sub fail_mode {
    my $self = shift;
    return "There has been an error!";
}

1; 

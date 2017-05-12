package TestCGIBin::Controller::CGIHandler;

use parent 'Catalyst::Controller::CGIBin';

# Turn off log for the non-zero exit test
sub auto : Private {
    my ($self, $c) = @_;
    $c->log->levels() unless $c->debug;
    1;
}

sub cgi_path {
    my ($self, $cgi) = @_;
    return "my-bin/$cgi";
}

# try resolved forward
sub mtfnpy : Local Args(0) {
    my ($self, $c) = @_;
    $c->forward($self->cgi_action('path/test.pl'));
}

1;

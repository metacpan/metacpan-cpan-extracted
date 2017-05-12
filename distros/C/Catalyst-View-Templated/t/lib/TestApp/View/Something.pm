package TestApp::View::Something;
use strict;
use warnings;

use base 'Catalyst::View::Templated';
use Storable qw/freeze/;

sub _render {
    my $self = shift;
    my $template = shift;
    my $stash = shift;
    
    $self->context->response->content_type('application/octet-stream');
    
    return freeze({ $template => $stash });
}

1;

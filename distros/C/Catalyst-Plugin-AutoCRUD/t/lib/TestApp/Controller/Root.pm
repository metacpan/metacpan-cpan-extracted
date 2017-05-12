package TestApp::Controller::Root;

use strict;
use warnings;

use base 'Catalyst::Controller';

sub testpage : Chained('/') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{current_view} = 'TT';
    $c->stash->{template} = 'testpage.tt';
}

sub end : ActionClass('RenderView') {}

1;
__END__

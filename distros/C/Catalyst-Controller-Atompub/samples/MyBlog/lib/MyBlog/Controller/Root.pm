package # hide from PAUSE
    MyBlog::Controller::Root;

use strict;
use warnings;
use base qw(Catalyst::Controller);

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

sub auto :Private {
    my($self, $c) = @_;

    # authentication not required, if GET
    return 1 if $c->req->method eq 'GET' || $c->req->method eq 'HEAD';

    my $realm = $c->config->{authentication}{http}{realm};
    $c->authorization_required(realm => $realm);

    1;
}

sub default : Private {
    my($self, $c) = @_;
    $c->res->redirect('html');
}

sub end : ActionClass('RenderView') {}

1;

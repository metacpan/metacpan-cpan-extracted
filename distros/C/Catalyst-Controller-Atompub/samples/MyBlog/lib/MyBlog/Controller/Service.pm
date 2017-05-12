package # hide from PAUSE
    MyBlog::Controller::Service;

use strict;
use warnings;

use base qw(Catalyst::Controller::Atompub::Service);

sub modify_service {
    my($self, $c, $service) = @_;

    # Edit $service (XML::Atom::Service) if you'd like to modify the
    # Service Document

    $service;
}

1;

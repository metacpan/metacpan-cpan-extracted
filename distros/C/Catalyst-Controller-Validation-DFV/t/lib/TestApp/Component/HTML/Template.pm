package # hide from PAUSE
    TestApp::Component::HTML::Template;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use base 'Catalyst::View::HTML::Template';

use Class::C3;

sub new {
    my $self = shift;

    # force stringification, Moose validation only accepts a Str
    my $path = TestApp->path_to( 'root', 'src', 'tmpl' ) . q{};

    $self->config(
        {
            die_on_bad_params => 0,
            path              => $path,
        },
    );

    return $self = $self->next::method(@_) if $self->next::can;

    return $self;
}

1;

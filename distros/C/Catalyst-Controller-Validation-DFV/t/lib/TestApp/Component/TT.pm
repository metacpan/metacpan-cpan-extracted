package # hide from PAUSE
    TestApp::Component::TT;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use base 'Catalyst::View::TT';

use Class::C3;

sub new {
    my $self = shift;
    $self->config(
        {
            INCLUDE_PATH => [
                TestApp->path_to( 'root', 'src', 'tt2' ),
                TestApp->path_to( 'root', 'lib', 'tt2' ),
            ],
            TEMPLATE_EXTENSION => '.tt',
            CATALYST_VAR       => 'Catalyst',
            TIMER              => 0,
        }
    );

    return $self = $self->next::method(@_) if $self->next::can;

    return $self;
}

1;

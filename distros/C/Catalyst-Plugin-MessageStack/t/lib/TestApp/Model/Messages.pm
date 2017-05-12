package TestApp::Model::Messages;

use base 'Catalyst::Model';

use Message::Stack;

__PACKAGE__->config( namespace => '' );

sub messages {
    my $self = shift;
    return Message::Stack->new;
}

1;


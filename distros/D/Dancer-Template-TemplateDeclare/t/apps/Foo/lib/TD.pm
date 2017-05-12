package TD;

use Template::Declare::Tags; # defaults to 'HTML'
use base 'Template::Declare';

template simple => sub {
    my ( $self, $args ) = @_;

    h1 { 'hi there' };
};

template with_vars => sub {
    my ( $self, $args ) = @_;

    h1 { 'hi '.  $args->{name} };
};

template '/layout/foo' => sub {
    my ( $self, $args ) = @_;

    html { outs_raw $args->{content} } 
};



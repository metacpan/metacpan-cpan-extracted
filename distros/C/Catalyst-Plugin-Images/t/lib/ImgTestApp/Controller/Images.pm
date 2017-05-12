package ImgTestApp::Controller::Images;

use base qw/Catalyst::Controller/;

sub first : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->image_tag("foo.png", custom_attr => "blah") );
}

sub second : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->image_tag("bar.png", width => 1234 ) );
}

sub third : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->image_tag("la.png", alt => "blah") );
}

sub fourth : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->image_tag("gorch.png") );
}

sub fifth : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->image_tag("bah/oink") );
}

1;

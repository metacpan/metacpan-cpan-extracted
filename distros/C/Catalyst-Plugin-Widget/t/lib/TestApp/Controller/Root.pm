package TestApp::Controller::Root;

use Moose;

BEGIN { extends 'Catalyst::Controller' }


__PACKAGE__->config( namespace => '' );


=head1 METHODS

=head2 index

=cut

sub plain :Local :Args(0) {
    my ( $self, $c ) = @_;

	$c->res->body( '' . $c->widget('~Plain', value => 'ok') );
}

sub button :Local :Args(0) {
    my ( $self, $c ) = @_;

	$c->res->body( '' . $c->widget('~Button', $c->req->params ) );
}

sub ns1 :Local :Args(0) {
    my ( $self, $c ) = @_;

	$c->res->body( '' . $c->widget('+TestApp::Widget::Button', value => 'ok') );
}

sub ns2 :Local :Args(0) {
    my ( $self, $c ) = @_;

	$c->res->body( '' . $c->widget('+TestApp::WidgetX::Submit', value => 'ok') );
}

sub ns3 :Local :Args(0) {
    my ( $self, $c ) = @_;

	$c->config->{ widget }{ default_namespace } = ref( $c ) . '::WidgetX::';

	$c->res->body( '' . $c->widget('Submit', value => 'ok') );
}

sub ns4 :Local :Args(0) {
    my ( $self, $c ) = @_;

	undef $c->config->{ widget }{ default_namespace };
	$c->res->body( '' . $c->widget('Another', value => 'ok') );
}



sub default :Private {
    my ( $self, $c ) = @_;

    $c->res->body( 'not found' );
    $c->res->status(404);
}

#sub end : ActionClass('RenderView') {
#}


__PACKAGE__->meta->make_immutable;

1;


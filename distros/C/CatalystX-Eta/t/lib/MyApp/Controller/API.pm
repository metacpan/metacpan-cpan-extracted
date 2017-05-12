package MyApp::Controller::API;
use utf8;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }
__PACKAGE__->config( default => 'application/json', );

sub api_key_check : Private {
    my ( $self, $c ) = @_;

    my $without_user_is_fine = $c->stash->{without_user_is_fine};

    my $api_key =
         $c->req->param('api_key')
      || ( $c->req->headers->header('x-api-key') )
      || ( $c->req->data ? $c->req->data->{api_key} : undef );

    unless ($without_user_is_fine) {
        $self->status_forbidden( $c, message => "access denied" ), $c->detach
          unless $api_key;
    }

    if ($api_key) {
        my $user_session = $c->model('DB::UserSession')->search(
            {
                api_key     => $api_key,
                # this is no real application and dbd::sqlite seems to be confused sometimes..
                # valid_until => { '>=' => \'current_timestamp' },

                #valid_for_ip => $c->req->address
            }
        )->next;
        my $user = $user_session ? $c->find_user( { id => $user_session->user_id } ) : undef;

        $self->status_forbidden( $c, message => "access denied", ),

          $c->detach unless defined $api_key && $user;

        $c->set_authenticated($user);
    }

}

sub root : Chained('/') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->response->headers->header( 'charset' => 'utf-8' );
}

sub login : Chained('root') : PathPart('login') : Args(0) : ActionClass('REST') {
}

sub login_POST {
    my ( $self, $c ) = @_;

    $c->model('DB::User')->execute( $c, for => 'login', with => $c->req->params );

    if ( $c->authenticate( $c->req->params ) ) {
        my $item = $c->user->sessions->create(
            {
                api_key      => 'test-key-' . int(rand(time)), # for test-only!
                valid_for_ip => $c->req->address
            }
        );

        $c->user->discard_changes;

        my %attrs = $c->user->get_inflated_columns;
        $attrs{api_key} = $item->api_key;

        $attrs{roles} = [ map { $_->name } $c->model('DB::User')->search( { id => $c->user->id } )->next->roles ];

        delete $attrs{password};
        $attrs{created_at} = $attrs{created_at}->datetime;

        $self->status_ok( $c, entity => \%attrs );
    }
    else {

        $self->status_bad_request( $c, message => 'Login invalid(2)' );
    }

}

sub logout : Chained('base') : PathPart('logout') : Args(0) : ActionClass('REST') {
}

sub logout_GET {
    my ( $self, $c ) = @_;
    $c->logout;
    $self->status_ok( $c, entity => { logout => 'ok' } );
}

sub logged_in : Chained('root') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->forward('api_key_check');
}

sub base : Chained('logged_in') : PathPart('') : CaptureArgs(0) {
}

__PACKAGE__->config( default => 'application/json' );

1;


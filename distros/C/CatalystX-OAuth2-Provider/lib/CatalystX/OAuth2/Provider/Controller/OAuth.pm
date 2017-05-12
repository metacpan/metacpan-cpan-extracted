package CatalystX::OAuth2::Provider::Controller::OAuth;
use Moose;
use Moose::Autobox;
use MooseX::Types::Moose qw/ HashRef ArrayRef ClassName Object Str /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use JSON::XS ();
use CatalystX::OAuth2::Provider::Error;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole'; }

with 'CatalystX::Component::Traits';

has '+_trait_merge' => ( default => 1 );

__PACKAGE__->config( traits => [qw/AuthorizationCode/] );

=head2 get_client
=cut
# TODO: Generic AUTH_INFO Model
sub _get_client : Private {
    my ( $self, $ctx ) = @_;
    foreach my $k ( values %{ $self->{auth_info} } ) {
        return $k if ( $k->{client_id} eq $ctx->req->param('client_id') )
    }
}

=head2 base
  Base for those chains
=cut
sub base :Chained('/') :PathPart('oauth') :CaptureArgs(0) {
    my ( $self, $ctx ) = @_;

    CatalystX::OAuth2::Provider::Error::InvalidRequest->throw( description => 'Invalid request' )
       if ! $ctx->req->param("client_id");
    my $client    = $ctx->forward('_get_client');
    $ctx->stash( client => $client ); #use this client for testing
    CatalystX::OAuth2::Provider::Error::InvalidClient->throw( description => "Invalid client id" )
       if ! $ctx->stash->{client};
}

=head2 logged_in_required
 Let's chained this function to make require to log in
=cut
sub logged_in_required
    :Chained('base')
    :PathPart('')
    :CaptureArgs(0)
{
    my ( $self, $ctx ) = @_;
    $ctx->forward( 'user_existed_or_authenticated' ); #CHECK USER
}

=head2 user_existed_or_authenticated
  See if user is logged in or not
  If not try to authenticate, otherwise failed.
=cut
sub user_existed_or_authenticated
    :Private
{
    my ( $self, $ctx ) = @_;
    return 1 if $ctx->user_exists();
    return 1 if $ctx->authenticate(
                  { username => $ctx->req->param('username')
                                || $ctx->req->param($self->{login_form}->{field_names}->{username}),
                    password => $ctx->req->param('password')
                                || $ctx->req->param($self->{login_form}->{field_names}->{password}),
                  } );
    $ctx->stash( template => $self->{login_form}->{template}
                              || 'user/login.tt' );
    #$ctx->res->status( 403 ); #This doesn't work when running with fastcgi
    $ctx->detach();
}

=head2 logged_in_not_required
  An empty function, just for those who wanna chain this. Doesn't matter.
=cut
sub logged_in_not_required
    :Chained('base')
    :PathPart('')
    :CaptureArgs(0)
{}

=head2 token
    Token enpoint
=cut
sub token
    :Chained('logged_in_not_required')
    :PathPart('token')  #Configurable?
    :Args(0)
{
    my ( $self, $ctx ) = @_;
      my $grant_type = $ctx->req->param('grant_type');
      $ctx->forward( 'handle_grant_type', [ $grant_type ] );
      my %data = ( error  =>  'unsupported_grant_type',
                   error_description => 'Invalid grant type');
      $ctx->res->body( JSON::XS->new->pretty(1)->encode( \%data ) );
}

sub handle_grant_type : Private {
    my ( $self, $ctx, $grant_type ) = @_;
}


=head2 authorize
    Authorize endpoint
=cut
sub authorize
    :Chained('logged_in_required')
    :PathPart('authorize') #Configurable?
    :Args(0)
{
    my ( $self, $ctx ) = @_;

    if ( $ctx->req->method eq 'GET' ) {
       $ctx->stash( authorize_endpoint => $ctx->uri_for_action($ctx->action) );
       $ctx->stash( template => $self->{authorize_form}->{template}
                                 || 'oauth/authorize.tt' );
    }

    if ( $ctx->req->method eq 'POST' ) {

        my $uri  = $ctx->uri_for( $ctx->req->param("redirect_uri"),
                                      { code         => $ctx->sessionid,
                                        redirect_uri => $ctx->req->param("redirect_uri"),
                                      } );
        $uri     =~ m,/(?<http>http://)(?<url>[\w\d:#@%/;$()~_?\+-=\\\.&]*),; #to external URI
        $ctx->res->redirect( $+{http} . $+{url} );
    }
    $ctx->detach();
}

=pod
=cut
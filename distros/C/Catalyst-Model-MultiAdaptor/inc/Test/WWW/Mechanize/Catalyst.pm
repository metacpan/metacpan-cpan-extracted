#line 1
package Test::WWW::Mechanize::Catalyst;

use Moose;

use Carp qw/croak/;
require Catalyst::Test; # Do not call import
use Encode qw();
use HTML::Entities;
use Test::WWW::Mechanize;

extends 'Test::WWW::Mechanize', 'Moose::Object';

#use namespace::clean -execept => 'meta';

our $VERSION = '0.51';
our $APP_CLASS;
my $Test = Test::Builder->new();

has catalyst_app => (
  is => 'ro',
  predicate => 'has_catalyst_app',
);

has allow_external => (
  is => 'rw',
  isa => 'Bool',
  default => 0
);

has host => (
  is => 'rw',
  isa => 'Str',
  clearer => 'clear_host',
  predicate => 'has_host',
);

sub new {
  my $class = shift;

  my $args = ref $_[0] ? $_[0] : { @_ };
  
  # Dont let LWP complain about options for our attributes
  my %attr_options = map {
    my $n = $_->init_arg;
    defined $n && exists $args->{$n} 
        ? ( $n => delete $args->{$n} )
        : ( );
  } $class->meta->get_all_attributes;

  my $obj = $class->SUPER::new(%$args);
  my $self = $class->meta->new_object(
    __INSTANCE__ => $obj,
    ($APP_CLASS ? (catalyst_app => $APP_CLASS) : () ),
    %attr_options
  );

  $self->BUILDALL;


  return $self;
}

sub BUILD {
  my ($self) = @_;

  unless ($ENV{CATALYST_SERVER}) {
    croak "catalyst_app attribute is required unless CATALYST_SERVER env variable is set"
      unless $self->has_catalyst_app;
    Class::MOP::load_class($self->catalyst_app)
      unless (Class::MOP::is_class_loaded($self->catalyst_app));
  }
}

sub _make_request {
    my ( $self, $request ) = @_;

    my $response = $self->_do_catalyst_request($request);
    $response->header( 'Content-Base', $response->request->uri )
      unless $response->header('Content-Base');

    $self->cookie_jar->extract_cookies($response) if $self->cookie_jar;

    # fail tests under the Catalyst debug screen
    if (  !$self->{catalyst_debug}
        && $response->code == 500
        && $response->content =~ /on Catalyst \d+\.\d+/ )
    {
        my ($error)
            = ( $response->content =~ /<code class="error">(.*?)<\/code>/s );
        $error ||= "unknown error";
        decode_entities($error);
        $Test->diag("Catalyst error screen: $error");
        $response->content('');
        $response->content_type('');
    }

    # check if that was a redirect
    if (   $response->header('Location')
        && $response->is_redirect
        && $self->redirect_ok( $request, $response ) )
    {

        # remember the old response
        my $old_response = $response;

        # *where* do they want us to redirect to?
        my $location = $old_response->header('Location');

        # no-one *should* be returning non-absolute URLs, but if they
        # are then we'd better cope with it.  Let's create a new URI, using
        # our request as the base.
        my $uri = URI->new_abs( $location, $request->uri )->as_string;

        # make a new response, and save the old response in it
        $response = $self->_make_request( HTTP::Request->new( GET => $uri ) );
        my $end_of_chain = $response;
        while ( $end_of_chain->previous )    # keep going till the end
        {
            $end_of_chain = $end_of_chain->previous;
        }                                          #   of the chain...
        $end_of_chain->previous($old_response);    # ...and add us to it
    } else {
        $response->{_raw_content} = $response->content;
    }

    return $response;
}

sub _do_catalyst_request {
    my ($self, $request) = @_;

    my $uri = $request->uri;
    $uri->scheme('http') unless defined $uri->scheme;
    $uri->host('localhost') unless defined $uri->host;

    $request = $self->prepare_request($request);
    $self->cookie_jar->add_cookie_header($request) if $self->cookie_jar;

    # Woe betide anyone who unsets CATALYST_SERVER
    return $self->_do_remote_request($request)
      if $ENV{CATALYST_SERVER};

    # If there's no Host header, set one.
    unless ($request->header('Host')) {
      my $host = $self->has_host
               ? $self->host
               : $uri->host;

      $request->header('Host', $host);
    }
 
    my $res = $self->_check_external_request($request);
    return $res if $res;

    my @creds = $self->get_basic_credentials( "Basic", $uri );
    $request->authorization_basic( @creds ) if @creds;

    my $response =Catalyst::Test::local_request($self->{catalyst_app}, $request);

    # LWP would normally do this, but we dont get down that far.
    $response->request($request);

    return $response
}

sub _check_external_request {
    my ($self, $request) = @_;

    # If there's no host then definatley not an external request.
    $request->uri->can('host_port') or return;

    if ( $self->allow_external && $request->uri->host_port ne 'localhost:80' ) {
        return $self->SUPER::_make_request($request);
    }
    return undef;
}

sub _do_remote_request {
    my ($self, $request) = @_;

    my $res = $self->_check_external_request($request);
    return $res if $res;

    my $server  = URI->new( $ENV{CATALYST_SERVER} );

    if ( $server->path =~ m|^(.+)?/$| ) {
        my $path = $1;
        $server->path("$path") if $path;    # need to be quoted
    }

    # the request path needs to be sanitised if $server is using a
    # non-root path due to potential overlap between request path and
    # response path.
    if ($server->path) {
        # If request path is '/', we have to add a trailing slash to the
        # final request URI
        my $add_trailing = $request->uri->path eq '/';
        
        my @sp = split '/', $server->path;
        my @rp = split '/', $request->uri->path;
        shift @sp;shift @rp; # leading /
        if (@rp) {
            foreach my $sp (@sp) {
                $sp eq $rp[0] ? shift @rp : last
            }
        }
        $request->uri->path(join '/', @rp);
        
        if ( $add_trailing ) {
            $request->uri->path( $request->uri->path . '/' );
        }
    }

    $request->uri->scheme( $server->scheme );
    $request->uri->host( $server->host );
    $request->uri->port( $server->port );
    $request->uri->path( $server->path . $request->uri->path );
    return $self->SUPER::_make_request($request);
}

sub import {
  my ($class, $app) = @_;

  if (defined $app) {
    Class::MOP::load_class($app)
      unless (Class::MOP::is_class_loaded($app));
    $APP_CLASS = $app; 
  }

}


1;

__END__


package Bot::Cobalt::Plugin::WWW;
$Bot::Cobalt::Plugin::WWW::VERSION = '0.021003';
use strictures 2;
use Scalar::Util 'reftype';

use Bot::Cobalt;
use Bot::Cobalt::Common;

use POE qw/
  Component::Client::HTTP
  Component::Client::Keepalive
/;


sub opts {
  my $opts = core->get_plugin_cfg($_[0])->{Opts};
  return +{} unless ref $opts and reftype $opts eq 'HASH';
  $opts
}

sub bindaddr {
  $_[0]->opts->{BindAddr}
}

sub proxy {
  $_[0]->opts->{Proxy}
}

sub timeout {
  $_[0]->opts->{Timeout}    || 90
}

sub max_per_host {
  $_[0]->opts->{MaxPerHost} || 5
}

sub max_workers {
  $_[0]->opts->{MaxWorkers} || 25
}

sub Requests {
  return($_[0]->{REQS}//={})
}

sub new { bless {}, shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  register( $self, 'SERVER',
     'www_request',
  );
    
  POE::Session->create(
    object_states => [
      $self => [
        '_start',
        'ht_response',
        'ht_post_request',
      ],
    ],
  );

  logger->info("Loaded WWW interface");

  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  delete $core->Provided->{www_request};

  my $ht_alias = 'ht_'.$core->get_plugin_alias($self);
  $poe_kernel->call( $ht_alias, 'shutdown' );

  my $sess_alias = 'www_'.$core->get_plugin_alias($self);  
  $poe_kernel->alias_remove( $sess_alias );

  logger->info("Unregistered");

  return PLUGIN_EAT_NONE
}

sub Bot_www_request {
  my ($self, $core) = splice @_, 0, 2;
  my $request = ${ $_[0] };
  my $event   = defined $_[1] ? ${$_[1]} : undef ;
  my $args    = defined $_[2] ? ${$_[2]} : undef ;

  unless ($request && $request->isa('HTTP::Request')) {
    logger->warn(
      "www_request received but no request at "
      .join ' ', (caller)[0,2]
    );
  }
  
  unless ($event) {
    ## no event at all is legitimate
    $event = 'www_not_handled';
  }
  
  $args = [] unless $args;
  my @p = ( 'a' .. 'f', 1 .. 9 );
  my $tag = join '', map { $p[rand@p] } 1 .. 5;
  $tag .= $p[rand@p] while exists $self->Requests->{$tag};

  $self->Requests->{$tag} = {
    Event     => $event,
    Args      => $args,
    Request   => $request,
    Time      => time(),
  };

  logger->debug("www_request issue $tag -> $event");
  
  my $sess_alias = 'www_'.$core->get_plugin_alias($self);
  $poe_kernel->call( $sess_alias, 
      'ht_post_request',
      $request, $tag
  );

  return PLUGIN_EAT_ALL
}

sub ht_post_request {
  ## Bridge to make sure response gets delivered to correct session
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  my ($request, $tag) = @_[ARG0, ARG1];
  ## Post the ::Request
  my $ht_alias = 'ht_'. core()->get_plugin_alias($self);
  $kernel->post( $ht_alias, 
      'request', 'ht_response', 
      $request, $tag
  );
}

sub ht_response {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  my ($req_pk, $resp_pk) = @_[ARG0, ARG1];

  my $response = $resp_pk->[0];
  my $tag      = $req_pk->[1];

  my $this_req = delete $self->Requests->{$tag};
  return unless $this_req;
  
  my $event = $this_req->{Event};
  my $args  = $this_req->{Args};
  
  core->log->debug("ht_response dispatch: $event ($tag)");

  my $content = $response->is_success ?
      $response->decoded_content
      : $response->message;

  broadcast($event, $content, $response, $args);
}

sub _start {
  my ($self, $kernel) = @_[OBJECT, KERNEL];

  my $sess_alias = 'www_'. core()->get_plugin_alias($self);
  $kernel->alias_set( $sess_alias );

  my %opts;
  $opts{BindAddr} = $self->bindaddr if $self->bindaddr;
  $opts{Proxy}    = $self->proxy    if $self->proxy;
  $opts{Timeout}  = $self->timeout;

  ## Create "ht_${plugin_alias}" session
  POE::Component::Client::HTTP->spawn(

    FollowRedirects => 5,

    Agent => __PACKAGE__,

    Alias => 'ht_'. core()->get_plugin_alias($self),

    ConnectionManager => POE::Component::Client::Keepalive->new(
      keep_alive   => 1,
      max_per_host => $self->max_per_host,
      max_open     => $self->max_workers,
      timeout      => $self->timeout,
    ),
    
    %opts,

  );
  
  core()->Provided->{www_request} = __PACKAGE__ ;
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::WWW - Asynchronous HTTP requests from Cobalt plugins

=head1 SYNOPSIS

  ## Send your request, specify an event to handle response:
  use HTTP::Request;
  my $request = HTTP::Request->new(
    'GET',
    'http://www.cobaltirc.org'
  );
  
  broadcast( 'www_request',
    $request,
    'myplugin_resp_recv',
    [ $some, $args ]
  );
  
  ## Handle the response:
  sub Bot_myplugin_resp_recv {
    my ($self, $core) = splice @_, 0, 2;
    
    ## Content:
    my $content  = ${ $_[0] };
    ## HTTP::Response object:
    my $response = ${ $_[1] };
    ## Attached arguments array reference:
    my $args_arr = ${ $_[2] };
    
    return PLUGIN_EAT_ALL
  }

=head1 DESCRIPTION

This plugin provides an easy interface to asynchronous HTTP requests; it 
bridges Cobalt's plugin pipeline and L<POE::Component::Client::HTTP> to 
provide responses to B<Bot_www_request> events.

The request should be a L<HTTP::Request> object.

Inside the response handler, $_[1] will contain the L<HTTP::Response> 
object; $_[0] is the undecoded content if the request was successful or 
some error from L<HTTP::Status> if not.

Arguments can be attached to the request event and retrieved in the 
handler via $_[2] -- this is usually an array reference, but anything 
that fits in a scalar will do.

Plugin authors should check for the boolean value of B<< 
$core->Provided->{www_request} >> and possibly fall back to using LWP 
with a short timeout if they'd like to continue to function if this 
plugin is B<not> loaded.

=head1 SEE ALSO

L<POE::Component::Client::HTTP>

L<HTTP::Request>

L<HTTP::Response>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut

package Bot::Cobalt::Plugin::YouTube;
$Bot::Cobalt::Plugin::YouTube::VERSION = '0.003001';
use Bot::Cobalt;
use Bot::Cobalt::Common;

use strictures 2;

use HTML::TokeParser;
use HTTP::Request;

sub REGEX () { 0 }

sub new {
  bless [
    qr{(youtu\.be|youtube\.com)/(\S+)},  ## ->[REGEX]
  ], shift
}

sub Cobalt_register {
  my ($self, $core) = @_;

  register( $self, 'SERVER', qw/
    public_msg
    ctcp_action
    youtube_plug_resp_recv
  / );

  logger->info("YouTube plugin registered");

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = @_;
  logger->info("YouTube plugin unregistered.");
  PLUGIN_EAT_NONE
}

sub _create_yt_link {
  my ($self, $base, $id) = @_;
  'http://www.youtube.com/'
      . ($base eq 'youtu.be' ? 'watch?v=' : '')
      . $id
}

sub _issue_yt_request {
  my ($self, $msg, $base, $id) = @_;

  unless (core()->Provided->{www_request}) {
    logger->warn(
      "We appear to be missing Bot::Cobalt::Plugin::WWW; ",
      "it may not be possible to issue async HTTP requests."
    );
  }

  my $chcfg = core->get_channels_cfg( $msg->context );
  my $this_chcfg = $chcfg->{ $msg->channel } // {};
  return if $this_chcfg->{no_yt_retrieve};

  my $req_url = $self->_create_yt_link($base, $id);

  logger->debug("dispatching request to $req_url");

  broadcast( 'www_request',
    HTTP::Request->new( GET => $req_url ),
    'youtube_plug_resp_recv',
    [ $req_url, $msg ],
  );

  1
}

sub Bot_public_msg {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };

  my ($base, $id) = $msg->stripped =~ $self->[REGEX] ;

  if ($base && defined $id) {
    $self->_issue_yt_request($msg, $base, $id)
  }

  PLUGIN_EAT_NONE
}

sub Bot_ctcp_action {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };

  return PLUGIN_EAT_NONE unless $msg->channel;

  my ($base, $id) = $msg->stripped =~ $self->[REGEX];

  if ($base && defined $id) {
    $self->_issue_yt_request($msg, $base, $id) 
  }

  PLUGIN_EAT_NONE
}

sub Bot_youtube_plug_resp_recv {
  my ($self, $core) = splice @_, 0, 2;

  my $response = ${ $_[1] };
  my $args     = ${ $_[2] };
  my ($req_url, $msg) = @$args;

  logger->debug("youtube_plug_resp_recv for $req_url");

  return PLUGIN_EAT_ALL unless $response->is_success;

  my $content = $response->decoded_content;

  my $html = HTML::TokeParser->new( \$content );

  my ($title, $short_url);

  TAG: while (my $tok = $html->get_tag('meta', 'link') ) {
    my $args = ref $tok->[1] eq 'HASH' ? $tok->[1] : next TAG ;

    if (defined $args->{name} && $args->{name} eq 'title') {
      $title = $args->{content}
    }

    if (defined $args->{rel} && $args->{rel} eq 'shortlink') {
      $short_url = $args->{href}
    }

    if (defined $title && defined $short_url) {
      last TAG
    }
  }

  if (defined $title && $short_url) {
    my $irc_resp =
      color('bold', 'YouTube:')
      . " $title ( $short_url )" ;

    broadcast( 'message',
      $msg->context,
      $msg->channel,
      $irc_resp
    );
  } else {
    logger->warn("Failed YouTube info retrieval for $req_url");
  }

  PLUGIN_EAT_ALL
}

1;

=pod

=head1 NAME

Bot::Cobalt::Plugin::YouTube - YouTube plugin for Bot::Cobalt

=head1 SYNOPSIS

  !plugin load YT Bot::Cobalt::Plugin::YouTube

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

Retrieves YouTube links pasted to an IRC channel and reports titles
(as well as shorter urls) to IRC.

Operates on both 'youtube.com' and 'youtu.be' links.

Disregards channels with a 'no_yt_retrieve' flag enabled.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

package Bot::Cobalt::IRC;
$Bot::Cobalt::IRC::VERSION = '0.021003';
use strictures 2;
use Scalar::Util 'reftype';

use Bot::Cobalt;
use Bot::Cobalt::Common;

use Bot::Cobalt::IRC::FloodChk;

use Bot::Cobalt::IRC::Server;

use Bot::Cobalt::IRC::Message;
use Bot::Cobalt::IRC::Message::Public;

use Bot::Cobalt::IRC::Event::Channel;
use Bot::Cobalt::IRC::Event::Kick;
use Bot::Cobalt::IRC::Event::Mode;
use Bot::Cobalt::IRC::Event::Nick;
use Bot::Cobalt::IRC::Event::Quit;
use Bot::Cobalt::IRC::Event::Topic;

use POE qw/
  Component::IRC::State
  Component::IRC::Plugin::CTCP
  Component::IRC::Plugin::AutoJoin
  Component::IRC::Plugin::Connector
  Component::IRC::Plugin::NickServID
  Component::IRC::Plugin::NickReclaim
/;

## Bot::Cobalt::Common pulls the rest of these:
use IRC::Utils 'parse_mode_line';


use Moo;

has NON_RELOADABLE => (
  ## Well, really, it's sort-of unloadable.
  ##  ... but life usually sucks when you do.
  ## Call _set_NON_RELOADABLE if you really need to
  isa       => Bool,
  is        => 'rwp',
  default   => sub { 1 },
);

## We keep references to our ircobjs; core tracks these also,
## but there is no guarantee that we're the only IRC plugin loaded.
has ircobjs => (
  lazy      => 1,
  is        => 'rw',
  isa       => HashObj,
  coerce    => 1,
  default   => sub { {} },
);

has flood => (
  is        => 'ro',
  isa       => Object,
  lazy      => 1,
  predicate => 'has_flood',
  default   => sub {
    my $ccfg  = core->get_core_cfg;
    my $count = $ccfg->opts->{FloodCount} || 5;
    my $secs  = $ccfg->opts->{FloodTime}  || 6;
    Bot::Cobalt::IRC::FloodChk->new(
      count => $count,
      in    => $secs,
    )
  },
);

## Outgoing IRC traffic is handled by UserEvents role:
with 'Bot::Cobalt::IRC::Role::UserEvents';

## Administrative commands:
with 'Bot::Cobalt::IRC::Role::AdminCmds';

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  register($self, SERVER => 'all' );
  broadcast( 'initialize_irc' );

  ## Start a lazy cleanup timer for flood->expire
  $core->timer_set( 180,
    +{ Event => 'ircplug_chk_floodkey_expire' },
    'IRCPLUG_CHK_FLOODKEY_EXPIRE'
  );

  logger->info("Loaded");

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  logger->info("Unregistering and dropping servers.");
  $self->_clear_context($_) for keys %{ $self->ircobjs };
  logger->debug("Clean unload");
  PLUGIN_EAT_NONE
}

sub Bot_initialize_irc {
  my ($self, $core) = splice @_, 0, 2;

  ## The IRC: directive in cobalt.conf provides context 'Main'
  ## (This will override any 'Main' specified in multiserv.conf)
  ## Munge core->irc() hash into our plugin's opts()
  my $p_cfg = $core->cfg->plugins->plugin( plugin_alias($self) );
  $p_cfg->opts->{Networks}->{Main} = $core->cfg->core->irc;

  if (exists $p_cfg->opts->{Networks}->{'-ALL'}) {
    ## Reserved by core Auth plugin
    logger->error("-ALL is not a valid context name, disregarding.");
    delete $p_cfg->opts->{Networks}->{'-ALL'}
  }

  my $active_contexts = 0;
  for my $context (keys %{ $p_cfg->opts->{Networks} } ) {
    ++$active_contexts;
    next if defined $p_cfg->opts->{Networks}->{$context}->{Enabled}
         and $p_cfg->opts->{Networks}->{$context}->{Enabled} == 0;
    logger->debug("Found configured context $context");
    broadcast( 'ircplug_connect', $context );
  }

  unless ($active_contexts) {
    logger->error("No contexts configured/enabled!");
  }
  logger->info("Connecting to $active_contexts contexts");
  
  PLUGIN_EAT_ALL
}

sub Bot_ircplug_connect {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${ $_[0] };

  ## Spawn an IRC Component and a Session to manage it.
  ##
  ## Called for each configured context.
  ##
  ## The sessions call the same object with different contexts in HEAP;
  ## the handlers do some processing and relay the event from the
  ## PoCo::IRC syndicator to the Bot::Cobalt::Core pipeline.

  if ($core->Servers->{$context}) {
    if ( $core->Servers->{$context}->has_irc ) {
      $core->Servers->{$context}->irc->call('shutdown',
        'Reconnecting'
      );

      $core->Servers->{$context}->clear_irc;
    }

    ## Just in case ...
    $core->auth->clear($context);
    $core->ignore->clear($context);
  }

  logger->debug("ircplug_connect issued for $context");

  my $pcfg    = core->cfg->plugins->plugin( plugin_alias($self) );
  my $thiscfg = $pcfg->opts->{Networks}->{$context};

  unless (ref $thiscfg && reftype $thiscfg eq 'HASH' && keys %$thiscfg) {
    logger->error("Connect issued for context without valid cfg ($context)");
    return PLUGIN_EAT_ALL
  }

  my $server = $thiscfg->{ServerAddr};

  unless (defined $server) {
    logger->error("Context $context has no defined ServerAddr");
    return PLUGIN_EAT_ALL
  }

  my $port   = $thiscfg->{ServerPort} || 6667;
  my $nick   = $thiscfg->{Nickname}   || 'cobalt2' ;

  my $usessl = $thiscfg->{UseSSL} ? 1 : 0;
  my $use_v6 = $thiscfg->{IPv6}   ? 1 : 0;

  logger->info(
    "Spawning IRC for $context ($nick on $server : $port)"
  );
  logger->debug(
    "Context $context; SSL $usessl ; V6 $use_v6"
  );

  # FIXME at least optionally disable outgoing flood queue,
  #   probably better to reimplement on top of IRC::FloodChk
  my %spawn_opts = (
      resolver => core->resolver,

      alias    => $context,
      nick     => $nick,
      username => $thiscfg->{Username} // 'cobalt',
      ircname  => $thiscfg->{Realname} // 'http://cobaltirc.org',
      server   => $server,
      port     => $port,
      useipv6  => $use_v6,
      usessl   => $usessl,
      raw      => 0,
  );

  $spawn_opts{localaddr} = $thiscfg->{BindAddr}
    if defined $thiscfg->{BindAddr};

  $spawn_opts{password} = $thiscfg->{ServerPass}
    if defined $thiscfg->{ServerPass};

  my $irc = POE::Component::IRC::State->spawn(%spawn_opts)
    or logger->error("IRC component spawn() for $context failed")
    and return PLUGIN_EAT_ALL;

  my $server_obj = Bot::Cobalt::IRC::Server->new(
    name => $server,
    irc  => $irc,
    prefer_nick => $nick,
  );

  $core->Servers->{$context} = $server_obj;
  $self->ircobjs->{$context} = $irc;

  ## Attempt to spin up a session.
  if ( $self->_spawn_for_context($context) ) {
    logger->debug("Successful session creation for context $context");
  }

  return PLUGIN_EAT_ALL
}

sub _spawn_for_context {
  my ($self, $context) = @_;

  POE::Session->create(
    ## track this session's context name in HEAP
    heap =>  { Context => $context },
    object_states => [
      $self => [ qw/
        _start

        irc_001
        irc_connected
        irc_disconnected
        irc_error
        irc_socketerr

        irc_chan_sync

        irc_public
        irc_msg
        irc_notice
        irc_ctcp_action

        irc_kick
        irc_mode
        irc_topic
        irc_invite

        irc_nick
        irc_join
        irc_part
        irc_quit
      / ],
    ],
  ) or
     logger->error("Session creation failed for context $context")
     and return;
}

sub Bot_ircplug_disconnect {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${ $_[0] };

  logger->debug("ircplug_disconnect event caught for $context");

  $self->_clear_context($context);

  return PLUGIN_EAT_ALL
}

sub _clear_context {
  my ($self, $context) = @_;

  logger->debug("_clear_context called for $context");

  core->auth->clear($context);
  core->ignore->clear($context);

  core->Servers->{$context}->clear_irc;

  my $irc = delete $self->ircobjs->{$context}
    or logger->error(
       "ircplug_disconnect called for nonexistant context $context"
     ) and return PLUGIN_EAT_ALL;

  $irc->call('shutdown', "IRC component shut down");

  logger->info("Called shutdown for context $context");

  return $context
}

sub _start {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $ccfg = core->get_core_cfg;
  my $pcfg = core->cfg->plugins->plugin( plugin_alias($self) );

  logger->debug("pocoirc plugin load");

  ## autoreconn plugin:
  my %connector;

  $connector{delay}     = $ccfg->opts->{StonedCheck}    || 300;
  $connector{reconnect} = $ccfg->opts->{ReconnectDelay} || 60;

  $irc->plugin_add('Connector' =>
    POE::Component::IRC::Plugin::Connector->new(
      %connector
    ),
  );

  ## attempt to regain primary nickname:
  $irc->plugin_add('NickReclaim' =>
    POE::Component::IRC::Plugin::NickReclaim->new(
        poll => $ccfg->opts->{NickRegainDelay} // 30,
      ),
    );

  if (defined $pcfg->opts->{Networks}->{$context}->{NickServPass}) {
    logger->debug("Adding NickServ ID for $context");
    $irc->plugin_add('NickServID' =>
      POE::Component::IRC::Plugin::NickServID->new(
        Password => $pcfg->opts->{Networks}->{$context}->{NickServPass},
      ),
    );
  }

  my $chanhash = core->cfg->channels->context($context) // {};
  ## AutoJoin plugin takes a hash in form of { $channel => $passwd }:
  my %ajoin;
  for my $chan (%$chanhash) {
    my $key = $chanhash->{$chan}->{password} // '';
    $ajoin{$chan} = $key;
  }

  $irc->plugin_add('AutoJoin' =>
    POE::Component::IRC::Plugin::AutoJoin->new(
      Channels     => \%ajoin,
      RejoinOnKick => $ccfg->opts->{Chan_RetryAfterKick} // 1,
      Rejoin_delay => $ccfg->opts->{Chan_RejoinDelay}    // 5,
      NickServ_delay    => $ccfg->opts->{Chan_NickServDelay} // 1,
      Retry_when_banned => $ccfg->opts->{Chan_RetryAfterBan} // 60,
    ),
  );

  ## define ctcp responses
  $irc->plugin_add('CTCP' =>
    POE::Component::IRC::Plugin::CTCP->new(
      version  => "Bot::Cobalt ".core->version." (perl $^V) ".core->url,
      userinfo   => "I'm a teapot",
      clientinfo => __PACKAGE__.'-'.(__PACKAGE__->VERSION // 'vcs'),
      source     => core->url,
    ),
  );

  ## register for all events from the component
  $irc->yield(register => 'all');
  ## initiate ze connection:
  $irc->yield(connect => {});

  logger->debug("irc component connect issued");
}


### IRC event 'relay' to our pipeline.

sub irc_connected {
  my ($self, $kernel, $server) = @_[OBJECT, KERNEL, ARG0];

  ##  irc_connected indicates we're connected to the server
  ##  however, irc_001 is the server welcome message
  ##  irc_connected happens before auth, no guarantee we can send yet.
  ##  (we don't broadcast Bot_connected until irc_001)
  logger->debug("Received irc_connected for $server");
}

sub irc_001 {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  ## set up some stuff relevant to our server context:
  irc_context($context)->connected(1);
  irc_context($context)->connectedat( time );
  irc_context($context)->maxmodes( $irc->isupport('MODES') // 4 );
  irc_context($context)->maxtargets( $irc->isupport('MAXTARGETS') // 4 );

  ## irc comes with odd case-mapping rules.
  ## []\~ are considered uppercase equivalents of {}|^
  ##
  ## this may vary by server
  ## (most servers are rfc1459, some are -strict, some are ascii)
  ##
  ## we can tell eq_irc/uc_irc/lc_irc to do the right thing by
  ## checking ISUPPORT and setting the casemapping if available
  my $casemap = lc( $irc->isupport('CASEMAPPING') || 'rfc1459' );
  irc_context($context)->casemap( $casemap );

  ## if the server returns a fubar value IRC::Utils automagically
  ## defaults to rfc1459 casemapping rules
  ##
  ## this is unavoidable in some situations, however:
  ## misconfigured inspircd on paradoxirc gave a codepage for CASEMAPPING
  ## and a casemapping for CHARSET (which is supposed to be deprecated)
  ##
  ## I strongly suspect there are other similarly broken servers around.
  ## para has since fixed this after extensive whining on my part \o/
  ##
  ## we can try to check for this, but it's still a crapshoot.
  ##
  ## this 'fix' will still break when CASEMAPPING is nonsense and CHARSET
  ## is set to 'ascii' but other casemapping rules are being followed.
  ##
  ## the better fix is to smack your admins with a hammer.
  my @valid_casemaps = qw/ rfc1459 ascii strict-rfc1459 /;
  unless (grep { $_ eq $casemap } @valid_casemaps) {
    my $charset = lc( $irc->isupport('CHARSET') || '' );
    if ($charset && grep { $_ eq $charset } @valid_casemaps) {
      irc_context($context)->casemap( $charset );
    }
    ## we don't save CHARSET, it's deprecated per the spec
    ## also mostly unreliable and meaningless
    ## you're on your own for handling fubar encodings.
    ## http://www.irc.org/tech_docs/draft-brocklesby-irc-isupport-03.txt
  }

  ## May have configured umodes to set:
  my $pcfg    = core->cfg->plugins->plugin( plugin_alias($self) );
  my $thiscfg = $pcfg->opts->{Networks}->{$context};

  if (my $umode = $thiscfg->{Umodes}) {
    logger->debug("Setting umode $umode on $context");
    $irc->yield('mode', $irc->nick_name => $umode)
  }

  my $server = $irc->server_name;
  logger->info("Connected: $context: $server");

  ## send a Bot_connected event with context and visible server name:
  broadcast( 'connected', $context, $server );
}

sub irc_disconnected {
  my ($self, $kernel, $server) = @_[OBJECT, KERNEL, ARG0];
  my $context = $_[HEAP]->{Context};

  logger->warn("Disconnected: $context ($server)");

  if ( irc_context($context) ) {
    irc_context($context)->connected(0);
    broadcast( 'disconnected', $context, $server );
  }
}

sub irc_socketerr {
  my ($self, $kernel, $err) = @_[OBJECT, KERNEL, ARG0];
  my $context = $_[HEAP]->{Context};

  logger->warn("Socket error: $context: $err");

  if ( irc_context($context) ) {
    irc_context($context)->connected(0);
    broadcast( 'server_error', $context, $err );
  }
}

sub irc_error {
  my ($self, $kernel, $reason) = @_[OBJECT, KERNEL, ARG0];
  my $context = $_[HEAP]->{Context};

  logger->warn("IRC error: $context: $reason");

  if ( irc_context($context) ) {
    irc_context($context)->connected(0);
    broadcast( 'server_error', $context, $reason );
  }
}

sub irc_chan_sync {
  my ($self, $heap, $chan) = @_[OBJECT, HEAP, ARG0];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $resp = core->rpl( q{RPL_CHAN_SYNC},
    { 'chan' => $chan }
  );

  broadcast( 'chan_sync', $context, $chan );

  my $cf_core = core->get_core_cfg();
  my $notify  = ($cf_core->opts->{NotifyOnSync} //= 1) ? 1 : 0 ;
  my $chan_h = core->cfg->channels->context( $context ) || {};
  ## check if we have a specific setting for this channel (override):
  $notify = $chan_h->{$chan}->{notify_on_sync}
    if exists $chan_h->{$chan}
    and reftype $chan_h->{$chan} eq 'HASH'
    and exists $chan_h->{$chan}->{notify_on_sync};

  $irc->yield(privmsg => $chan => $resp) if $notify;
}

sub irc_ctcp_action {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];
  my ($src, $target, $txt) = @_[ARG0 .. ARG2];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $casemap = core->get_irc_casemap($context);
  for my $mask ( core->ignore->list($context) ) {
    return if matches_mask( $mask, $src, $casemap );
  }

  my $msg_obj = Bot::Cobalt::IRC::Message->new(
    context => $context,
    src     => $src,
    targets => $target,
    message => $txt,
  );

  broadcast( 'ctcp_action', $msg_obj );
}

sub irc_invite {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($src, $channel) = @_[ARG0, ARG1];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $invite = Bot::Cobalt::IRC::Event::Channel->new(
    context => $context,
    src     => $src,
    channel => $channel,
  );

  ## Bot_invited
  broadcast( 'invited', $invite );
}

sub irc_join {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($src, $channel) = @_[ARG0, ARG1];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $join = Bot::Cobalt::IRC::Event::Channel->new(
    context => $context,
    src     => $src,
    channel => $channel,
  );

  my $me = $irc->nick_name();
  my $casemap = core->get_irc_casemap($context);
  if ( eq_irc($me, $join->src_nick, $casemap) ) {
    broadcast( 'self_joined', $context, $channel );
  }

  ## Bot_user_joined
  broadcast( 'user_joined', $join );
}

sub irc_kick {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($src, $channel, $target, $reason) = @_[ARG0 .. ARG3];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $kick = Bot::Cobalt::IRC::Event::Kick->new(
    context => $context,
    channel => $channel,
    src     => $src,
    kicked  => $target,
    reason  => $reason,
  );

  my $me = $irc->nick_name();
  my $casemap = core->get_irc_casemap($context);
  if ( eq_irc($me, $kick->src_nick, $casemap) ) {
    ## Bot_self_kicked:
    broadcast( 'self_kicked', $context, $src, $channel, $reason );
  }

  ## Bot_user_kicked:
  broadcast( 'user_kicked', $kick );
}

sub irc_mode {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($src, $changed_on, $modestr, @modeargs) = @_[ ARG0 .. $#_ ];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $mode_obj = Bot::Cobalt::IRC::Event::Mode->new(
    context => $context,
    src     => $src,
    target  => $changed_on,
    mode    => $modestr,
    args    => [ @modeargs ],
  );

  if ( $mode_obj->is_umode ) {
    broadcast( 'umode_changed', $mode_obj );
    return
  }
  ## otherwise it's mostly safe to assume mode changed on a channel
  ## could check by grabbing isupport('CHANTYPES') and checking against
  ## is_valid_chan_name from IRC::Utils, f.ex:
  ## my $chantypes = $self->irc->isupport('CHANTYPES') || '#&';
  ## is_valid_chan_name($changed_on, [ split '', $chantypes ]) ? 1 : 0;
  ## ...but afaik this Should Be Fine:
  broadcast( 'mode_changed', $mode_obj);
}

sub irc_msg {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];
  my ($src, $target, $txt) = @_[ARG0 .. ARG2];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $casemap = core->get_irc_casemap( $context );
  for my $mask ( core->ignore->list($context) ) {
    return if matches_mask( $mask, $src, $casemap );
  }

  if ( $self->flood->check($context, $src) ) {
    my $nick = parse_user($src);
    $self->flood_ignore($context, $src)
      unless core->auth->level($context, $nick);
    return
  }

  my $msg_obj = Bot::Cobalt::IRC::Message->new(
    context => $context,
    src     => $src,
    targets => $target,
    message => $txt,
  );

  broadcast( 'private_msg', $msg_obj );
}

sub irc_nick {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($src, $new, $common) = @_[ARG0 .. ARG2];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  ## see if it's our nick that changed, send event:
  if ($new eq $irc->nick_name) {
    broadcast( 'self_nick_changed', $context, $new );
    return
  }

  my $nchg = Bot::Cobalt::IRC::Event::Nick->new(
    context  => $context,
    src      => $src,
    new_nick => $new,
    channels => $common,
  );

  ## Bot_nick_changed
  broadcast( 'nick_changed', $nchg );
}

sub irc_notice {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];
  my ($src, $target, $txt) = @_[ARG0 .. ARG2];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $casemap = core->get_irc_casemap($context);
  for my $mask ( core->ignore->list($context) ) {
    return if matches_mask( $mask, $src, $casemap );
  }

  my $msg_obj = Bot::Cobalt::IRC::Message->new(
    context => $context,
    src     => $src,
    targets => $target,
    message => $txt,
  );

  broadcast( 'got_notice', $msg_obj );
}

sub irc_part {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($src, $channel, $msg) = @_[ARG0 .. ARG2];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $part = Bot::Cobalt::IRC::Event::Channel->new(
    context => $context,
    src     => $src,
    channel => $channel,
  );

  my $me = $irc->nick_name();
  my $casemap = core->get_irc_casemap($context);
  ## shouldfix? we could try an 'eq' here ... but is a part issued by
  ## force methods going to be guaranteed the same case ... ?
  if ( eq_irc($me, $part->src_nick, $casemap) ) {
    ## we were the issuer of the part -- possibly via /remove, perhaps?
    ## (autojoin might bring back us back, though)
    broadcast( 'self_left', $context, $channel );
  }

  ## Bot_user_left
  broadcast( 'user_left', $part );
}

sub irc_public {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];
  my ($src, $where, $txt) = @_[ ARG0 .. ARG2 ];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $casemap = core->get_irc_casemap( $context );
  for my $mask ( core->ignore->list($context) ) {
    ## Check against ignore list
    ## (Ignore list should be keyed by hostmask)
    return if matches_mask( $mask, $src, $casemap );
  }

  my $msg_obj = Bot::Cobalt::IRC::Message::Public->new(
    context => $context,
    src     => $src,
    targets => $where,
    message => $txt,
  );

  my $floodchk = sub {
    if ( $self->flood->check(@_) ) {
      $self->flood_ignore($context, $src);
      return 1
    }
  };

  ## Bot_public_msg / Bot_public_cmd_$cmd
  ## FloodChk cmds and highlights
  if (my $cmd = $msg_obj->cmd) {

    $floodchk->($context, $src) ?
      return
      : broadcast( 'public_cmd_'.$cmd, $msg_obj);

  } elsif ($msg_obj->highlight) {

    $floodchk->($context, $src) ?
      return
      : broadcast( 'public_msg', $msg_obj);

  } else {
    ## In the interests of keeping memory usage low on a
    ## large channel, we don't flood-check every incoming public
    ## message; plugins that respond to these may want to create
    ## their own Bot::Cobalt::IRC::FloodChk
    broadcast( 'public_msg', $msg_obj );
  }
}

sub irc_quit {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($src, $msg, $common) = @_[ARG0 .. ARG2];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $quit = Bot::Cobalt::IRC::Event::Quit->new(
    context => $context,
    src     => $src,
    reason  => $msg,
    common  => $common,
  );

  ## Bot_user_quit
  broadcast( 'user_quit', $quit );
}

sub irc_snotice {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];

  my $context = $heap->{Context};

  ## These are weird.
  ## There should be at least a string.
  my ($string, $target, $sender) = @_[ARG0 .. ARG2];

  ## FIXME test / POD
  broadcast( 'server_notice', $context, $string, $target, $sender );
}

sub irc_topic {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($src, $channel, $topic) = @_[ARG0 .. ARG2];

  my $context = $heap->{Context};
  my $irc     = $self->ircobjs->{$context};

  my $topic_obj = Bot::Cobalt::IRC::Event::Topic->new(
    context => $context,
    src     => $src,
    channel => $channel,
    topic   => $topic,
  );

  ## Bot_topic_changed
  broadcast( 'topic_changed', $topic_obj );
}


### Internals.

sub Bot_rehashed {
  my ($self, $core) = splice @_, 0, 2;
  my $type = ${ $_[0] };

  if ($type eq 'core' || $type eq 'channels') {
    logger->info("Rehash received ($type), resetting ajoins");
    $self->_reset_ajoins;
  }

  ## FIXME nickservid rehash if needed

  return PLUGIN_EAT_NONE
}

sub Bot_ircplug_chk_floodkey_expire {
  my ($self, $core) = splice @_, 0, 2;

  ## Lazy flood tracker cleanup.
  ## These are just arrays of timestamps, but they gotta be cleaned up
  ## when they're stale.

  $self->flood->expire if $self->has_flood;

  $core->timer_set( 60,
    { Event => 'ircplug_chk_floodkey_expire' },
    'IRCPLUG_CHK_FLOODKEY_EXPIRE'
  );

  return PLUGIN_EAT_ALL
}

sub Bot_ircplug_flood_rem_ignore {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${ $_[0] };
  my $mask    = ${ $_[1] };
  ## Internal timer-fired event to remove temp ignores.

  logger->info("Clearing temp ignore: $mask ($context)");

  $core->ignore->del( $context, $mask );

  broadcast( 'flood_ignore_deleted', $context, $mask );

  return PLUGIN_EAT_ALL
}

sub flood_ignore {
  ## Pass me a context and a mask
  ## Set a temporary ignore and a timer to remove it
  my ($self, $context, $mask) = @_;

  my $corecf = core->get_core_cfg;
  my $ignore_time = $corecf->opts->{FloodIgnore} || 20;

  $self->flood->clear($context, $mask);

  logger->info(
    "Issuing temporary ignore due to flood: $mask ($context)"
  );

  my $added = core->ignore->add(
    $context, $mask, "flood_ignore", __PACKAGE__
  );

  broadcast( 'flood_ignore_added', $context, $mask );

  core->timer_set( $ignore_time,
    {
      Event => 'ircplug_flood_rem_ignore',
      Args  => [ $context, $mask ],
    },
  );
}

sub _reset_ajoins {
  my ($self) = @_;

  my $corecf  = core->get_core_cfg;
  my $servers = core->Servers;

  CONTEXT: for my $context (keys %$servers) {
    my $chanscf = core->get_channels_cfg($context) // {};

    my $irc = core->get_irc_obj($context) || next CONTEXT;

    my %ajoin;

    CHAN: for my $channel (keys %$chanscf) {
      my $key = $chanscf->{$channel}->{password} // '';
      $ajoin{$channel} = $key;
    }

    logger->debug("Removing AutoJoin plugin for $context");
    $irc->plugin_del('AutoJoin');

    logger->debug("Loading new AutoJoin plugin for $context");
    $irc->plugin_add('AutoJoin' =>
      POE::Component::IRC::Plugin::AutoJoin->new(
        Channels => \%ajoin,
        RejoinOnKick => $corecf->opts->{Chan_RetryAfterKick} // 1,
        Rejoin_delay => $corecf->opts->{Chan_RejoinDelay}    // 5,
        NickServ_delay    => $corecf->opts->{Chan_NickServDelay} // 1,
        Retry_when_banned => $corecf->opts->{Chan_RetryAfterBan} // 60,
      ),
    );

  }

}

1;
__END__


=pod

=head1 NAME

Bot::Cobalt::IRC -- Bot::Cobalt IRC bridge

=head1 DESCRIPTION

For a description of the commands provided by the IRC bridge, see 
L<Bot::Cobalt::IRC::Role::AdminCmds>.

This is the core plugin providing IRC functionality to 
L<Bot::Cobalt>; incoming and outgoing IRC activity 
is handled just like any other plugin pipeline event.

This core IRC plugin provides a multi-server IRC interface via
L<POE::Component::IRC>. Subclasses or other IRC plugins should follow 
this pattern and provide a compatible event interface.

The IRC plugin does various work on incoming events we consider important 
enough to re-broadcast from the IRC component. This makes life easier on 
plugins and reduces code redundancy.

Arguments may vary by event. See below.

If you're trying to write Cobalt plugins, you probably want to start off 
with L<Bot::Cobalt::Manual::Plugins> -- this is a reference for IRC-related 
events specifically.


=head1 EMITTED EVENTS

=head2 Connection state events

=head3 Bot_connected

Issued when an irc_001 (welcome msg) event is received.

Indicates the bot is now talking to an IRC server.

  my ($self, $core) = splice @_, 0, 2;
  my $context     = ${$_[0]};
  my $server_name = ${$_[1]};

The relevant $core->Servers->{$context} object is updated prior to
broadcasting this event. This means that 'maxmodes' and 'casemap'
are now available for retrieval. You might use these to properly
compare two nicknames, for example:

  ## grab eq_irc() from IRC::Utils
  ## also available if you "use Bot::Cobalt::Common;"
  ## see perldoc Bot::Cobalt::Common and Bot::Cobalt::Manual::Plugins
  use IRC::Utils qw/ eq_irc /;
  my $context = ${$_[0]};
  ## most servers are 'rfc1459', some may be ascii or -strict
  ## (some return totally fubar values, and we'll default to rfc1459)
  my $casemap = $core->Servers->{$context}->casemap;
  my $is_equal = IRC::Utils::eq_irc($nick_a, $nick_b, $casemap);

See L<Bot::Cobalt::IRC::Server> for details on using a Server object.

=head3 Bot_disconnected

Broadcast when irc_disconnected is received.

  my ($self, $core) = splice @_, 0, 2;
  my $context     = ${$_[0]};
  my $server_name = ${$_[1]};

$core->Servers->{$context}->connected will be false until a reconnect.

=head3 Bot_server_error

Issued on unknown ERROR : events. Not a socket error, but connecting failed.

The IRC component will provide a maybe-not-useful reason:

  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};
  my $reason  = ${$_[1]};


=head2 Incoming message events

=head3 Bot_public_msg

Broadcast upon receiving public text (text in a channel).

  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${$_[0]};
  my $context  = $msg->context;
  my $stripped = $msg->stripped;
  ...

$msg is a L<Bot::Cobalt::IRC::Message> object; in the case of public 
messages it is a L<Bot::Cobalt::IRC::Message::Public> object.

See L<Bot::Cobalt::IRC::Message> for complete documentation regarding 
available methods.

B<IMPORTANT:> We don't automatically decode any character encodings.
This means that text may be a byte-string of unknown encoding.
Storing or displaying the text may present complications.
You may want decode_irc from L<IRC::Utils> for these applications.
See L<IRC::Utils/ENCODING> for more on encodings + IRC.

Also see:

=over

=item *

L<perluniintro>

=item *

L<perlunitut>

=item *

L<perlunicode>

=back


=head3 Bot_public_cmd_CMD

Broadcast when a public command is triggered.

Plugins can catch these events to respond to specific commands.

CMD is the public command triggered; ie the first "word" of something
like (if CmdChar is '!'): I<!kick> --> I<Bot_public_cmd_kick>

Syntax is precisely the same as L</Bot_public_msg>, with one major 
caveat: B<< $msg->message_array will not contain the command. >>

This event is pushed to the pipeline before _public_msg.


=head3 Bot_private_msg

Broadcast when a private message is received.

Syntax is the same as L</Bot_public_msg>, B<except> the first spotted 
destination is stored in key C<target>

The default IRC interface plugins only spawn a single client per server.
It's fairly safe to assume that C<target> is the bot's current nickname.


=head3 Bot_got_notice

Broadcast when a /NOTICE is received.

Syntax is the same as L</Bot_public_msg>.


=head3 Bot_ctcp_action

Broadcast when a CTCP ACTION (/ME in most clients) is received.

Syntax is similar to L</Bot_public_msg>.

If the ACTION appears to have been directed at a channel, the B<channel> 
method will return the same value as B<target> -- otherwise it will 
return an empty string.


=head2 Sent notification events

=head3 Bot_message_sent

Broadcast when a PRIVMSG has been sent to the server via an event;
in other words, when a 'message' event was sent.

Carries a copy of the target and text:

  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};
  my $target = ${$_[1]};
  my $string = ${$_[2]};

This being IRC, there is no guarantee that the message actually made it 
to its intended destination ;-)

=head3 Bot_notice_sent

Broadcast when a NOTICE has been sent out via a 'notice' event.

Same syntax as L</Bot_message_sent>.

=head3 Bot_ctcp_sent

Broadcast when a CTCP has been sent via a CTCP handler such as 
L</action>.

  my $context   = ${$_[0]};
  my $ctcp_type = ${$_[1]};  ## 'ACTION' for example
  my $target    = ${$_[2]};
  my $content   = ${$_[3]};

=head3 Bot_raw_sent

Broadcast when a raw string has been sent via L</send_raw>.

Arguments are the server context name and the raw string sent.


=head2 Channel state events

=head3 Bot_chan_sync

Broadcast when we've finished receiving channel status info.
This generally indicates we're ready to talk to the channel.

Carries the channel name:

  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};
  my $channel = ${$_[1]};


=head3 Bot_topic_changed

Broadcast when a channel topic has changed.

Carries a L<Bot::Cobalt::IRC::Event::Topic> object:

  my ($self, $core) = @splice @_, 0, 2;
  my $topic_obj = ${$_[0]};
  
  my $context   = $topic_obj->context;
  my $setter    = $topic_obj->src_nick;
  my $new_topic = $topic_obj->topic;

L<Bot::Cobalt::IRC::Event::Topic> is a subclass of 
L<Bot::Cobalt::IRC::Event> and 
L<Bot::Cobalt::IRC::Event::Channel> -- see the documentation for those base 
classes for complete details on available methods.

Note that the topic setter may be a server, just a nickname, 
the name of a service, or some other arbitrary string.

=head3 Bot_mode_changed

Broadcast when a channel mode has changed.

  my ($self, $core) = splice @_, 0, 2;
  my $modechg = ${$_[0]};
  
  my $context  = $modechg->context;
  my $modestr  = $modechg->mode;
  my $modeargs = $modechg->args;
  my $modehash = $modechg->hash;

The hashref returned by B<<->hash>> is produced by 
L<IRC::Utils/parse_mode_line>.

It has two keys: I<modes> and I<args>. They are both ARRAY references:

  my @modes = @{ $modechg->hash->{modes} };
  my @args  = @{ $modechg->hash->{args}  };

If parsing failed, the hash is empty.

The trick to parsing modes is determining whether or not they have args 
that need to be pulled out.
You can walk each individual mode and handle known types:

  MODE: for my $mode (@modes) {
    for ($mode) {
      next MODE if $mode =~ /[cimnpstCMRS]/; # oftc-hybrid/bc6 param-less modes
      if ($mode eq 'l') {  ## limit mode has an arg
        my $limit = shift @args;
        ...
      }
      if ($mode eq 'b') {
        ## shift off a ban ...
      }
      ## etc
    }
  }

Theoretically, you can find out which types should have args via ISUPPORT:

  my $irc = $self->Servers->{$context}->irc;
  my $is_chanmodes = $irc->isupport('CHANMODES')
                     || 'b,k,l,imnpst';  ## oldschool set
  ## $m_list modes add/delete modes from a list (bans for example)
  ## $m_always modes always have a param specified.
  ## $m_only modes only have a param specified on a '+' operation.
  ## $m_never will never have a parameter.
  my ($m_list, $m_always, $m_only, $m_never) = split ',', $is_chanmodes;
  ## get status modes (ops, voice ...)
  ## allegedly not all servers report all PREFIX modes
  my $m_status = $irc->isupport('PREFIX') || '(ov)@+';
  $m_status =~ s/^\((\w+)\).*$/$1/;

See L<http://www.irc.org/tech_docs/005.html> for more information on ISUPPORT.

As of this writing the Cobalt core provides no convenience method for this.


=head3 Bot_user_joined

Broadcast when a user joins a channel we are on.

  my ($self, $core) = splice @_, 0, 2;
  my $join     = ${$_[0]};
  
  my $nickname = $join->src_nick;
  my $context  = $join->context;

Carries a L<Bot::Cobalt::IRC::Event::Channel> object.

=head3 Bot_self_joined

Broadcast when the bot joins a channel.

A L</Bot_user_joined> is still issued as well.

Carries the same syntax and caveats as L</Bot_self_left> (below)

=head3 Bot_user_left

Broadcast when a user parts a channel we are on.

  my ($self, $core) = splice @_, 0, 2;
  my $part    = ${$_[0]};

Carries a L<Bot::Cobalt::IRC::Event::Channel> object; also see 
L</Bot_user_joined>.

=head3 Bot_self_left

Broadcast when the bot parts a channel, possibly via coercion.

A plugin can catch I<Bot_part> events to find out that the bot was 
told to depart from a channel. However, the bot may've been forced 
to PART by the IRCD. Many daemons provide a 'REMOVE' and/or 'SAPART' 
that will do this. I<Bot_self_left> indicates the bot left the channel, 
as determined by matching the bot's nickname against the user who left.

${$_[1]} is the channel name.

  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};
  my $channel = ${$_[1]};

B<IMPORTANT>:

Uses eq_irc with the server's CASEMAPPING to determine whether this 
is actually the bot leaving, in order to cope with servers issuing 
forced parts with incorrect case.

This method may be unreliable on servers with an incorrect CASEMAPPING 
in ISUPPORT, as it will fall back to normal rfc1459 rules.

Also see L</Bot_user_left>

=head3 Bot_self_kicked

Broadcast when the bot was seemingly kicked from a channel.

  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};
  my ($src, $chan, $reason) = (${$_[1]}, ${$_[2]}, ${$_[3]});

Relies on the same logic as L</Bot_self_left> -- be sure to read the 
note in that section (above).

The bot will probably attempt to auto-rejoin unless configured 
otherwise.

=head3 Bot_user_kicked

Broadcast when a user (maybe us) is kicked.

  my ($self, $core) = splice @_, 0, 2;
  my $kick    = ${$_[0]};
  
  my $kicked    = $kick->kicked;
  my $kicked_by = $kick->src_nick;
  my $reason    = $kick->reason;

Carries a L<Bot::Cobalt::IRC::Event::Kick> object.

=head3 Bot_invited

Broadcast when the bot has been invited to a channel.

  my ($self, $core) = splice @_, 0, 2;
  my $invite  = ${$_[0]};
  
  my $invited_to = $invite->channel;
  my $invited_by = $invite->src_nick;

Carries a L<Bot::Cobalt::IRC::Event::Channel> object.

=head2 User state events

=head3 Bot_umode_changed

Broadcast when mode changes on the bot's nickname (umode).

  my ($self, $core) = splice @_, 0, 2;
  my $modechg = ${$_[0]};

  my $modestr = $modechg->mode;

Carries a L<Bot::Cobalt::IRC::Event::Mode> object.

=head3 Bot_nick_changed

Broadcast when a visible user's nickname changes.

  my ($self, $core) = splice @_, 0, 2;
  my $nchange = ${$_[0]};
  
  my $old = $nchange->old_nick;
  my $new = $nchange->new_nick;

  if ( $nchange->equal ) {
    ## Case change only
  }

Carries a L<Bot::Cobalt::IRC::Event::Nick> object.

I<equal> is determined by attempting to get server CASEMAPPING= 
(falling back to 'rfc1459' rules) and using L<IRC::Utils> to check 
whether this appears to be just a case change. This method may be 
unreliable on servers with an incorrect CASEMAPPING value in ISUPPORT.


=head3 Bot_self_nick_changed

Broadcast when our own nickname changed, possibly via coercion.

  my ($self, $core) = splice @_, 0, 2;
  my $context  = ${$_[0]};
  my $new_nick = ${$_[1]};


=head3 Bot_user_quit

Broadcast when a visible user has quit.

We can only receive quit notifications if we share channels with the 
user, of course.

  my ($self, $core) = splice @_, 0, 2;
  my $quit = ${ $_[0] };
  
  my $nickname = $quit->src_nick;
  my $reason   = $quit->reason;

Carries a L<Bot::Cobalt::IRC::Event::Quit> object.


=head2 Outgoing message triggers

It's possible to write plugins that register for B<USER> events to catch 
messages before they are dispatched to IRC.

These events are prefixed with B<Outgoing_>.

Using this mechanism, you can write output filters by registering for a 
USER event:

  ## in your Cobalt_register, perhaps:
  $core->plugin_register( $self, 'USER',
    [ 'message' ],
  );
  
  ## handler:
  sub Outgoing_message {
    my ($self, $core) = splice @_, 0, 2;
    my $context = ${ $_[0] };
    my $target  = ${ $_[1] };
    
    ## You can modify these references directly.
    ## This is the same as Plugin::OutputFilters::StripFormat:
    ${ $_[2] } = strip_formatting( ${ $_[2] } );
    
    ## If you EAT_ALL, the message won't be sent:
    return PLUGIN_EAT_NONE
  }


The following B<USER> events are emitted:

=head3 Outgoing_message

Syndicated when a L</message> event has been received.

Event arguments are references to the context, target, and message 
string, respectively.

=head3 Outgoing_notice

Syndicated when a L</notice> event has been received; arguments are 
the same as L</Outgoing_message>.

=head3 Outgoing_ctcp

Syndicated when a CTCP is about to be sent via L</action> or a 
similar CTCP handler.

  my $context   = ${ $_[0] };
  my $ctcp_type = ${ $_[1] };
  my $target    = ${ $_[2] };
  my $content   = ${ $_[3] };



=head1 ACCEPTED EVENTS

=head2 Outgoing IRC commands

=head3 message

A C<message> event for our context triggers a PRIVMSG send.

  broadcast( 'message', $context, $target, $string );

An L</Outgoing_message> USER event will be issued prior to sending.

Upon completion a L</Bot_message_sent> event will be broadcast.

=head3 notice

A C<notice> event for our context triggers a NOTICE.

  broadcast( 'notice', $context, $target, $string );

An L</Outgoing_notice> USER event will be issued prior to sending.

Upon completion a L</Bot_notice_sent> event will be broadcast.

=head3 action

A C<action> event sends a CTCP ACTION (also known as '/me') to a 
channel or nickname.

  broadcast( 'action', $context, $target, $string );

An L</Outgoing_ctcp> USER event will be issued prior to sending.

Upon completion a L</Bot_ctcp_sent> event will be broadcast.

=head3 send_raw

Quote a raw string to the IRC server.

Does no parsing or sanity checking.

  broadcast( 'send_raw', $raw );

A L</Bot_raw_sent> will be broadcast.

=head3 mode

A C<mode> event for our context attempts a mode change.

Typically the target will be either a channel or the bot's own nickname.

  broadcast( 'mode', $context, $target, $modestr );
  ## example for Main context:
  broadcast( 'mode', 'Main', '#mychan', '+ik some_key' );

This being IRC, there is no guarantee that the bot has privileges to 
effect the changes, or that the changes took place.

=head3 topic

A C<topic> event for our context attempts to change channel topic.

  broadcast( 'topic', $context, $channel, $new_topic );

=head3 kick

A C<kick> event for our context attempts to kick a user.

A reason can be supplied:

  broadcast( 'kick', $context, $channel, $target, $reason );

=head3 join

A C<join> event for our context attempts to join a channel.

  broadcast( 'join', $context, $channel );

Catch L</Bot_chan_sync> to check for channel sync status.

=head3 part

A C<part> event for our context attempts to leave a channel.

A reason can be supplied:

  broadcast( 'part', $context, $channel, $reason );

There is no guarantee that we were present on the channel in the 
first place.

=head2 Server control

=head3 ircplug_connect

Takes the name of a configured context.

Attempts to initialize a connection for the named context (if the 
configuration can be found).

This interface is evolving and subject to change.

=head3 ircplug_disconnect

Same arguments and caveats as ircplug_connect.

=head1 SEE ALSO

=over

=item *

L<Bot::Cobalt::IRC::Server>

=item *

L<Bot::Cobalt::IRC::Event>

=item *

L<Bot::Cobalt::IRC::Message>

=item *

L<Bot::Cobalt::Manual::Plugins>

=back


=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

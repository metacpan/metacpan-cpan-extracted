package Bot::Cobalt::Plugin::Info3;
$Bot::Cobalt::Plugin::Info3::VERSION = '0.021003';
use strictures 2;
use v5.10;

## Handles glob-style "info" response topics
## Modelled on darkbot/cobalt1 behavior
## Commands:
##  <bot> add
##  <bot> del(ete)
##  <bot> replace
##  <bot> (d)search
##
## Also handles darkbot-style variable replacement

use Bot::Cobalt;
use Bot::Cobalt::Common;
use Bot::Cobalt::DB;

use Bot::Cobalt::Plugin::RDB::SearchCache;

use File::Spec;

use POSIX ();


sub new { bless {}, shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  $self->{Cache} = Bot::Cobalt::Plugin::RDB::SearchCache->new(
    MaxKeys => 20,
  );

  $self->{NegCache} = Bot::Cobalt::Plugin::RDB::SearchCache->new(
    MaxKeys => 8,
  );

  my $pcfg = plugin_cfg( $self );
  my $var = core->var;

  my $relative_to_var = $pcfg->{Opts}->{InfoDB} //
    File::Spec->catfile( 'db', 'info3.db' );

  my $dbpath = File::Spec->catfile(
    $var,
    File::Spec->splitpath( $relative_to_var )
  );

  $self->{DB_PATH} = $dbpath;
  $self->{DB} = Bot::Cobalt::DB->new(
    File => $dbpath,
  );

  $self->{MAX_TRIGGERED} = $pcfg->{Opts}->{MaxTriggered} || 3;

  ## hash mapping contexts/channels to previously-triggered topics
  ## used for MaxTriggered
  $self->{LastTriggered} = { };

  ## glob-to-re mapping:
  $self->{Globs} = { };
  ## reverse of above:
  $self->{Regexes} = { };

  ## build our initial hashes (this is slow, ~1s on spork's huge db)
  $self->{DB}->dbopen(ro => 1) || croak 'DB open failure';
  while (my ($glob, $ref) = each %{ $self->{DB}->Tied }) {
    ++$core->Provided->{info_topics};
    my $regex = $ref->{Regex};
    $self->{Globs}->{$glob} = my $compiled_re = qr/$regex/i;
    $self->{Regexes}->{$compiled_re} = $glob;
  }
  $self->{DB}->dbclose;

  register($self, 'SERVER',
    [
      'public_msg',
      'ctcp_action',
      'info3_relay_string',
      'info3_expire_maxtriggered',
    ],
  );

  logger->info("Loaded, topics: ".($core->Provided->{info_topics}||=0));

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  logger->info("Unregistering Info plugin");

  delete $core->Provided->{info_topics};

  PLUGIN_EAT_NONE
}

sub Bot_ctcp_action {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${$_[0]};
  my $context = $msg->context;
  ## similar to _public_msg handler
  ## pre-pend ~action+ and run a match

  my @message = @{ $msg->message_array };
  return PLUGIN_EAT_NONE unless @message;

  my $str = join ' ', '~action', @message;

  my $nick = $msg->src_nick;
  my $channel = $msg->target;

  ## is this a channel? ctcp_action doesn't differentiate on its own
  my $first = substr($channel, 0, 1);
  return PLUGIN_EAT_NONE
    unless grep { $_ eq $first } ( '#', '&', '+' );

  ## should we be sending info3 responses anyway?
  my $chcfg = $core->get_channels_cfg($context);
  return PLUGIN_EAT_NONE
    if defined $chcfg->{$channel}->{info3_response}
    and $chcfg->{$channel}->{info3_response} == 0;

  return PLUGIN_EAT_NONE
    if $self->_over_max_triggered($context, $channel, $str);

  my $match = $self->_info_match($str, 'ACTION') || return PLUGIN_EAT_NONE;

  if ( index($match, '~') == 0) {

    my $rdb = substr( (split ' ', $match)[0], 1);

    if ($rdb) {
      broadcast( 'rdb_triggered',
        $context,
        $channel,
        $nick,
        lc($rdb),
        $match,
        ## orig question str for Q~ etc replacement:
        join(' ', @message)
      );
      return PLUGIN_EAT_NONE
    }
  }

  logger->debug("issuing info3_relay_string in response to action");
  broadcast( 'info3_relay_string',
    $context, $channel, $nick, $match, join(' ', @message)
  );

  PLUGIN_EAT_NONE
}

sub Bot_public_msg {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${$_[0]};
  my $context = $msg->context;

  my @message = @{ $msg->message_array };
  return PLUGIN_EAT_NONE unless @message;

  my $with_highlight;
  if ($msg->highlight) {
    ## we were highlighted -- might be an info3 cmd
    my %handlers = (
      'add' => '_info_add',
      'del' => '_info_del',
      'delete'  => '_info_del',
      'replace' => '_info_replace',
      'search'  => '_info_search',
      'dsearch' => '_info_dsearch',
      'display' => '_info_display',
      'about'   => '_info_about',
      'tell'    => '_info_tell',
      'infovars' => '_info_varhelp',
    );

    $message[1] = lc($message[1]) if $message[1];
    if ($message[1] && grep { $_ eq $message[1] } keys %handlers) {
      ## this is apparently a valid command
      my @args = @message[2 .. $#message];
      my $method = $handlers{ $message[1] };
      if ( $self->can($method) ) {
          ## pass handlers $msg ref as first arg
          ## the rest is the remainder of the string
          ## (without highlight or command)
          ## ...which may be nothing, up to the handler to send syntax RPL
          my $resp = $self->$method($msg, @args);
          broadcast( 'message',
            $context, $msg->channel, $resp ) if $resp;
          return PLUGIN_EAT_NONE
      } else {
          logger->warn($message[1]." is a valid cmd but method missing");
          return PLUGIN_EAT_NONE
      }

    } else {
      ## not an info3 cmd
      ## shift the highlight off and see if it's a match, below
      ## save the highlighted version, it might still be a valid match
      $with_highlight = join ' ', @message;
      shift @message;
    }

  }

  ## rejoin message
  my $str = join ' ', @message;

  my $nick    = $msg->src_nick;
  my $channel = $msg->channel;

  my $chcfg = $core->get_channels_cfg($context) || {};
  return PLUGIN_EAT_NONE
    if defined $chcfg->{$channel}->{info3_response}
    and $chcfg->{$channel}->{info3_response} == 0;

  return PLUGIN_EAT_NONE
    if $self->_over_max_triggered($context, $channel, $str);

  ## check for matches
  my $match = $self->_info_match($str);
  if ($with_highlight && ! defined $match) {
    $match = $self->_info_match($with_highlight);
  }
  return PLUGIN_EAT_NONE unless $match;

  ## ~rdb, maybe? hand off to RDB.pm
  if ( index($match, '~') == 0) {
    my $rdb = (split ' ', $match)[0];
    $rdb = substr($rdb, 1);
    if ($rdb) {
      logger->debug("issuing rdb_triggered");
      broadcast( 'rdb_triggered',
        $context,
        $channel,
        $nick,
        lc($rdb),
        $match,
        $str
      );
      return PLUGIN_EAT_NONE
    }
  }

  logger->debug("issuing info3_relay_string");

  broadcast( 'info3_relay_string',
    $context, $channel, $nick, $match, $str
  );

  PLUGIN_EAT_NONE
}

sub Bot_info3_relay_string {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};
  my $channel = ${$_[1]};
  my $nick    = ${$_[2]};
  my $string  = ${$_[3]};
  my $orig    = ${$_[4]};

  ## format and send info3 response
  ## also received from RDB when handing off ~rdb responses

  logger->debug("info3_relay_string received; calling _info_format");

  my $resp = $self->_info_format($context, $nick, $channel, $string, $orig);

  ## if $resp is a +action, send ctcp action
  if ( index($resp, '+') == 0 ) {
    $resp = substr($resp, 1);
    logger->debug("Dispatching action -> $channel");
    broadcast('action', $context, $channel, $resp);
  } else {
    logger->debug("Dispatching msg -> $channel");
    broadcast('message', $context, $channel, $resp);
  }

  return PLUGIN_EAT_NONE
}

sub Bot_info3_expire_maxtriggered {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${ $_[0] };
  my $channel = ${ $_[1] };

  unless ($context && $channel) {
    logger->debug(
      "missing context and channel pair in expire_maxtriggered"
    );
  }
  delete $self->{LastTriggered}->{$context}->{$channel};

  logger->debug("cleared maxtriggered for $channel on $context");

  return PLUGIN_EAT_ALL
}

### Internal methods

sub _over_max_triggered {
  my ($self, $context, $channel, $str) = @_;

  if ($self->{LastTriggered}->{$context}->{$channel}) {
    my $lasttrig = $self->{LastTriggered}->{$context}->{$channel};
    my ($last_match, $tries) = @$lasttrig;
    if ($str eq $last_match) {
      ++$tries;
      if ($tries > $self->{MAX_TRIGGERED}) {
        ## we've hit this topic too many times in a row
        ## plugin should EAT_NONE
        logger->debug("Over trigger limit for $str");

        ## set a timer to expire this LastTriggered
        core->timer_set( 90,
          {
            Alias => plugin_alias($self),
            Event => 'info3_expire_maxtriggered',
            Args => [ $context, $channel ],
          },
        );

        return 1
      } else {
        ## haven't hit MAX_TRIGGERED yet.
        $self->{LastTriggered}->{$context}->{$channel} = [$str, $tries];
      }
    } else {
      ## not the previously-returned topic
      ## reset
      delete $self->{LastTriggered}->{$context}->{$channel};
    }
  } else {
    $self->{LastTriggered}->{$context}->{$channel} = [ $str, 1 ];
  }

  return 0
}


sub _info_add {
  my ($self, $msg, $glob, @args) = @_;
  my $string = join ' ', @args;

  my $context = $msg->context;
  my $nick    = $msg->src_nick;

  my $auth_user  = core->auth->username($context, $nick);
  my $auth_level = core->auth->level($context, $nick);

  my $pcfg = plugin_cfg( $self );
  my $required = $pcfg->{RequiredLevels}->{AddTopic} // 2;
  unless ($auth_level >= $required) {
    return core->rpl( q{RPL_NO_ACCESS},
      nick => $nick,
    );
  }

  unless ($glob && $string) {
    return core->rpl( q{INFO_BADSYNTAX_ADD} );
  }

  ## lowercase
  $glob = decode_irc(lc $glob);

  if (exists $self->{Globs}->{$glob}) {
    ## topic already exists, use replace instead!
    return core->rpl( q{INFO_ERR_EXISTS},
      topic => $glob,
      nick => $nick,
    );
  }

  ## set up a re
  my $re = glob_to_re_str($glob);
  ## anchored:
  $re = '^'.$re.'$' ;

  ## add to db, keyed on glob:
  unless ($self->{DB}->dbopen) {
    logger->warn("DB open failure");
    return 'DB open failure'
  }
  $self->{DB}->put( $glob,
    {
      AddedAt => time(),
      AddedBy => $auth_user,
      Regex => $re,
      Response => decode_irc($string),
    }
  );
  $self->{DB}->dbclose;

  ## invalidate info3 cache:
  $self->{Cache}->invalidate('info3');
  $self->{NegCache}->invalidate('info3_neg');

  ## add to internal hashes:
  my $compiled_re = qr/$re/i;
  $self->{Regexes}->{$compiled_re} = $glob;
  $self->{Globs}->{$glob} = $compiled_re;

  core->Provided->{info_topics} += 1;

  logger->debug("topic add: $glob ($re)");

  ## return RPL
  return core->rpl( q{INFO_ADD},
    topic => $glob,
    nick  => $nick,
  )
}

sub _info_del {
  my ($self, $msg, @args) = @_;
  my ($glob) = @args;

  my $context = $msg->context;
  my $nick    = $msg->src_nick;

  my $auth_user  = core->auth->username($context, $nick);
  my $auth_level = core->auth->level($context, $nick);

  my $pcfg = plugin_cfg( $self );
  my $required = $pcfg->{RequiredLevels}->{DelTopic} // 2;
  unless ($auth_level >= $required) {
    return core->rpl( q{RPL_NO_ACCESS},
      nick => $nick,
    )
  }

  unless ($glob) {
    return core->rpl( q{INFO_BADSYNTAX_DEL} )
  }


  unless (exists $self->{Globs}->{$glob}) {
    return core->rpl( q{INFO_ERR_NOSUCH},
      topic => $glob,
      nick  => $nick,
    );
  }

  ## delete from db
  unless ($self->{DB}->dbopen) {
    logger->warn("DB open failure");
    return 'DB open failure'
  }
  $self->{DB}->del($glob);
  $self->{DB}->dbclose;

  $self->{Cache}->invalidate('info3');
  $self->{NegCache}->invalidate('info3_neg');

  ## delete from internal hashes
  my $regex = delete $self->{Globs}->{$glob};
  delete $self->{Regexes}->{$regex};

  core->Provided->{info_topics} -= 1;

  logger->debug("topic del: $glob ($regex)");

  return core->rpl( q{INFO_DEL},
    topic => $glob,
    nick  => $nick,
  )
}

sub _info_replace {
  my ($self, $msg, @args) = @_;
  my ($glob, @splstring) = @args;
  my $string = join ' ', @splstring;
  $glob = lc $glob;

  my $context = $msg->context;
  my $nick    = $msg->src_nick;

  my $auth_user  = core->auth->username($context, $nick);
  my $auth_level = core->auth->level($context, $nick);

  my $pcfg = plugin_cfg( $self );
  my $req_del = $pcfg->{RequiredLevels}->{DelTopic} // 2;
  my $req_add = $pcfg->{RequiredLevels}->{AddTopic} // 2;
  ## auth check for BOTH add and del reqlevels:
  unless ($auth_level >= $req_add && $auth_level >= $req_del) {
    return core->rpl( q{RPL_NO_ACCESS},
      nick => $nick,
    );
  }

  unless ($glob && $string) {
    return core->rpl( q{INFO_BADSYNTAX_REPL} );
  }

  unless (exists $self->{Globs}->{$glob}) {
    return core->rpl( q{INFO_ERR_NOSUCH},
      topic => $glob,
      nick  => $nick,
    )
  }

  logger->debug("replace called for $glob by $nick ($auth_user)");

  $self->{Cache}->invalidate('info3');
  $self->{NegCache}->invalidate('info3_neg');

  unless ($self->{DB}->dbopen) {
    logger->warn("DB open failure");
    return 'DB open failure'
  }
  $self->{DB}->del($glob);
  $self->{DB}->dbclose;
  core->Provided->{info_topics} -= 1;

  logger->debug("topic del (replace): $glob");

  my $regex = delete $self->{Globs}->{$glob};
  delete $self->{Regexes}->{$regex};

  my $re = glob_to_re_str($glob);
  $re = '^'.$re.'$' ;

  unless ($self->{DB}->dbopen) {
    logger->warn("DB open failure");
    return 'DB open failure'
  }
  $self->{DB}->put( $glob,
    {
      AddedAt => time(),
      AddedBy => $auth_user,
      Regex => $re,
      Response => $string,
    }
  );
  $self->{DB}->dbclose;
  core->Provided->{info_topics} += 1;

  my $compiled_re = qr/$re/i;
  $self->{Regexes}->{$compiled_re} = $glob;
  $self->{Globs}->{$glob} = $compiled_re;

  logger->debug("topic add (replace): $glob ($re)");

  return core->rpl( q{INFO_REPLACE},
    topic => $glob,
    nick  => $nick,
  )
}

sub _info_tell {
  ## 'tell X about Y' syntax
  my ($self, $msg, @args) = @_;
  my $target = shift @args;

  unless ($target) {
    return core->rpl( q{INFO_TELL_WHO},
      nick => $msg->src_nick,
    )
  }

  unless (@args) {
    return core->rpl( q{INFO_TELL_WHAT},
      nick   => $msg->src_nick,
      target => $target
    )
  }

  my $str_to_match;
  ## might be 'tell X Y':
  if (lc $args[0] eq 'about') {
    ## 'tell X about Y' syntax
    $str_to_match = join ' ', @args[1 .. $#args];
  } else {
    ## 'tell X Y' syntax
    $str_to_match = join ' ', @args;
  }

  ## find info match
  my $match = $self->_info_match($str_to_match);
  unless ($match) {
    return core->rpl( q{INFO_DONTKNOW},
      nick  => $msg->src_nick,
      topic => $str_to_match
    );
  }

  ## if $match is a RDB, send rdb_triggered and bail
  if ( index($match, '~') == 0) {
    my $rdb = (split ' ', $match)[0];
    $rdb = substr($rdb, 1);
    if ($rdb) {
      ## rdb_triggered will take it from here
      broadcast( 'rdb_triggered',
        $msg->context,
        $msg->channel,
        $target,
        lc($rdb),
        $match,
        $str_to_match
      );
      return
    }
  }

  my $channel = $msg->channel;

  logger->debug("issuing info3_relay_string for tell");

  broadcast( 'info3_relay_string',
    $msg->context, $channel, $target, $match, $str_to_match
  );

  return
}

sub _info_about {
  my ($self, $msg, @args) = @_;
  my ($glob) = @args;

  unless ($glob) {
    my $count = core->Provided->{info_topics};
    return "$count info topics in database."
  }

  unless (exists $self->{Globs}->{$glob}) {
    return core->rpl( q{INFO_ERR_NOSUCH},
      topic => $glob,
      nick  => $msg->src_nick,
    )
  }

  ## parse and display addedat/addedby info
  $self->{DB}->dbopen(ro => 1) || return 'DB open failure';
  my $ref = $self->{DB}->get($glob);
  $self->{DB}->dbclose;

  my $addedby = $ref->{AddedBy} || '(undef)';

  my $addedat = POSIX::strftime(
    "%H:%M:%S (%Z) %Y-%m-%d", localtime( $ref->{AddedAt} )
  );

  my $str_len = length( $ref->{Response} );

  return core->rpl( q{INFO_ABOUT},
    nick   => $msg->src_nick,
    topic  => $glob,
    author => $addedby,
    date   => $addedat,
    length => $str_len,
  )
}

sub _info_display {
  ## return raw topic
  my ($self, $msg, @args) = @_;
  my ($glob) = @args;
  return "No topic specified" unless $glob; # FIXME rpl?

  ## check if glob exists
  unless (exists $self->{Globs}->{$glob}) {
    return core->rpl( q{INFO_ERR_NOSUCH},
      topic => $glob,
      nick  => $msg->src_nick,
    )
  }

  ##  if so, show unparsed Response
  $self->{DB}->dbopen(ro => 1) || return 'DB open failure';
  my $ref = $self->{DB}->get($glob);
  $self->{DB}->dbclose;
  my $response = $ref->{Response};

  return $response
}

sub _info_search {
  my ($self, $msg, @args) = @_;
  my ($str) = @args;

  my @matches = $self->_info_exec_search($str);
  return 'No matches' unless @matches;

  my $resp = "Matches: ";
  while ( length($resp) < 350 && @matches) {
    $resp .= ' '.shift(@matches);
  }

  return $resp
}

sub _info_exec_search {
  my ($self, $str) = @_;
  return 'Nothing to search' unless $str;

  my @matches;

  for my $glob (keys %{ $self->{Globs} }) {
    push(@matches, $glob) unless index($glob, $str) == -1;
  }

  return @matches
}

sub _info_dsearch {
  my ($self, $msg, @args) = @_;
  my $str = join ' ', @args;

  my $pcfg = plugin_cfg( $self );
  my $req_lev = $pcfg->{RequiredLevels}->{DeepSearch} // 0;
  my $usr_lev = core->auth->level($msg->context, $msg->src_nick);
  unless ($usr_lev >= $req_lev) {
    return core->rpl( q{RPL_NO_ACCESS},
      nick => $msg->src_nick
    )
  }

  my @matches = $self->_info_exec_dsearch($str);
  return 'No matches' unless @matches;

  my $resp = "Matches: ";
  while ( length($resp) < 350 && @matches) {
    $resp .= ' '.shift(@matches);
  }

  return $resp
}

sub _info_exec_dsearch {
  my ($self, $str) = @_;

  my $cache = $self->{Cache};
  my @matches = $cache->fetch('info3', $str) || ();
  ## matches found in searchcache
  return @matches if @matches;

  $self->{DB}->dbopen(ro => 1) || return 'DB open failure';

  for my $glob (keys %{ $self->{Globs} }) {
    my $ref = $self->{DB}->get($glob);
    unless (ref $ref eq 'HASH') {
      logger->error(
        "Inconsistent Info3? $glob appears to have no value.",
        "This could indicate database corruption."
      );
      next
    }

    my $resp_str = $ref->{Response};
    push(@matches, $glob) unless index($resp_str, $str) == -1;
  }

  $self->{DB}->dbclose;

  $cache->cache('info3', $str, [ @matches ]);

  return @matches;
}

sub _info_match {
  my ($self, $txt, $isaction) = @_;
  ## see if text matches a glob in hash
  ## if so retrieve string from db and return it

  my $str;

  return if $self->{NegCache}->fetch('info3_neg', $txt);

  for my $re (keys %{ $self->{Regexes} }) {
    if ($txt =~ $re) {
      my $glob = $self->{Regexes}->{$re};
      ## is this glob an action response?
      if ( index($glob, '~action') == 0 ) {
        ## action topic, are we matching a ctcp_action?
        next unless $isaction;
      } else {
        ## not an action topic
        next if $isaction;
      }

      $self->{DB}->dbopen(ro => 1) || return 'DB open failure';
      my $ref = $self->{DB}->get($glob) || { };
      $self->{DB}->dbclose;

      $str = $ref->{Response} // 'Error retrieving Response string';

      last
    }
  }

  return $str if $str;

  ## negative searchcache if there's no match
  ## really only helps in case of flood ...
  $self->{NegCache}->cache('info3_neg', $txt, [1]);
  return
}


sub _info_varhelp {
  my ($self, $msg) = @_;

  my $help =
     ' !~ = CmdChar, B~ = BotNick, C~ = Channel, H~ = UserHost, N~ = Nick,'
    .' P~ = Port, Q~ = Question, R~ = RandomNick, S~ = Server'
    .' t~ = unixtime, T~ = localtime, V~ = Version, W~ = Website'
  ;

  broadcast( 'notice',
    $msg->context,
    $msg->src_nick,
    $help
  );

  return ''
}

# Variable replacement / format
sub _info_format {
  my ($self, $context, $nick, $channel, $str, $orig) = @_;
  ## variable replacement for responses
  ## some of these need to pull info from context
  ## maintains oldschool darkbot6 variable format

  logger->debug("formatting text response ($context)");

  my $irc_obj = irc_object($context);
  return $str unless ref $irc_obj;

  my $ccfg = core->get_core_cfg;
  my $cmdchar = $ccfg->opts->{CmdChar};
  my @users   = $irc_obj->channel_list($channel) if $channel;
  my $random  = $users[ rand @users ] if @users;
  my $website = core->url;

  my $vars = {
    '!' => $cmdchar,          ## CmdChar
    B => $irc_obj->nick_name, ## bot's nick for this context
    C => $channel,            ## channel
    H => $irc_obj->nick_long_form($irc_obj->nick_name) || '',
    N => $nick,               ## nickname
    P => $irc_obj->port,      ## remote port
    Q => $orig,               ## question string
    R => $random,             ## random nickname
    S => $irc_obj->server,    ## current server
    t => time,                ## unixtime
    T => scalar localtime,    ## parsed time
    V => 'cobalt-'.core->version,  ## version
    W => core->url,          ## website
  };

  ##  1~ 2~ .. etc
  my $x = 0;
  for my $item (split ' ', $orig) {
    ++$x;
    $vars->{$x} = $item;
  }

  ## var replace kinda like rplprintf
  ## call _info3repl()
  my $re = qr/((\S)~)/;
  $str =~ s/$re/__info3repl($1, $2, $vars)/ge;
  return $str
}
sub __info3repl {
  my ($orig, $match, $vars) = @_;
  return $orig unless defined $vars->{$match};
  return $vars->{$match}
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Info3 - Text-triggered responses for Bot::Cobalt

=head1 SYNOPSIS

  <JoeUser> cobaltbot: add hi Howdy N~!
  <Bob> hi
  <cobaltbot> Howdy Bob!

=head1 DESCRIPTION

B<darkbot6> came with built-in I<info2> functionality; text responses
(possibly with variables) could be triggered by simple glob matches.

This plugin follows largely the same pattern; users can add a topic:

  <JoeUser> cobaltbot: add hello*everyone Howdy N~! Welcome to C~!

When a user says something matching the glob, the response is 
triggered:

  <Somebody> hello there, everyone
  <cobaltbot> Howdy Somebody! Welcome to #thischannel!

(Note that if multiple added globs match a given IRC string, the result 
is somewhat unpredictable and will largely depend on what your database 
gives up first. Managing your topics sanely is up to you.)

Topics can also be hooked into randomized responses.
See L</"RDB integration"> -- this functionality also requires 
L<Bot::Cobalt::Plugin::RDB>.

Back-end storage takes place via L<Bot::Cobalt::DB>.
The core distribution comes with a tool called B<cobalt2-import-info2> 
capable of converting B<darkbot> and B<cobalt1> 'info' databases.

By default, the same topic can be requested 4 times in a row before 
being blocked to prevent loops. This can be adjusted via B<Opts> 
in your B<info3.conf>:

  Opts:
    MaxTriggered: 2

=head1 USAGE

=head2 Add and delete

=head3 add

Add a new B<info3> topic:

  bot: add my+new+topic This is my new topic.
  
  bot: add help You're beyond help, N~!

The most common wildcards are * (match any number of any character) and 
+ (match a single space).
See L<Bot::Cobalt::Utils/glob_to_re_str> for details regarding glob syntax.

Note that ^$ start/end anchors are not valid when adding B<info3> globs; 
every glob is automatically anchored.

Variables are available for use in topic responses -- see 
L</"Response variables">.

=head4 Responding with an action

A topic response can also be an action ('/me').

In order to send a response as an action, prefix the response with B<+> :

  bot: add greetings +waves to N~

Variable replacement works as-normal.

=head4 Responding to an action

A topic prefixed with C<~action> is a response to an action:

  bot: add ~action+waves +waves back to N~

=head3 del

Deletes the specified topic.

  bot: del my+new+topic

=head3 replace

Same as 'del' then 'add' for an existing topic:

  bot: replace this+topic Some new string


=head2 Searching

=head3 search

Searches for the literal string specified within our stored topics.

  bot: search some+topic

Only matches B<topics> -- see L</dsearch> to search within responses.

=head3 dsearch

Does a 'deep search,' checking the B<contents> of every topic for a possible 
match to the specified string.

  bot: dsearch N~

=head3 display

Displays the raw (unparsed) topic response.

Useful for checking for variables or RDBs.

=head3 about

Returns metadata regarding when the topic was added and by whom.

=head2 Directing responses at other users

=head3 tell

You can instruct the bot to "talk" to someone else using B<tell>:

  bot: add how+good+is+perl Awesome!
  bot: tell Somebody about how good is perl

=head2 Response variables

Responses to topics can include variables that are processed before 
the response string is sent.

These mostly follow legacy B<darkbot6> syntax.

The following variables are valid:

  !~  == Bot's command character
  B~  == Bot's nick for this server
  C~  == The current channel
  H~  == Bot's current nick!user@host
  N~  == Nickname of the user bot is talking to
  P~  == Port we're connected to
  Q~  == Original string bot is responding to
  R~  == A random nickname from the channel
  S~  == Server we're connected to
  t~  == Unix epoch seconds (unixtime)
  T~  == Human-readable date and time
  V~  == Current bot version
  W~  == Cobalt website

Additionally, words in the original string that triggered the response can 
be pulled out individually by their relative position. The first word is 
B<1~>, the second word is B<2~>, and so forth.

=head3 infovars

The 'infovars' command will send you a notice briefly describing the 
available variables; useful for a quick refresher when adding topics.


=head2 RDB integration

Topics can also trigger randomized responses if the
L<Bot::Cobalt::Plugin::RDB> plugin is loaded.

To pull a randomized response from a B<RDB>, a topic should trigger a response
starting with '~<rdbname>' -- for example:

  bot: add hello ~hi
  bot: rdb dbadd hi
  bot: rdb add hi Hello N~! Welcome to C~!
  bot: rdb add hi How goes it, N~?

See L<Bot::Cobalt::Plugin::RDB> for more details.


=head1 EVENTS

=head2 Received Events

=head3 Bot_info3_relay_string

Feeds a given string to the response formatter and relays the result 
back to IRC.

Arguments are:

  $context, $channel, $nick, $string_to_format, $question_string

=head3 Bot_info3_expire_maxtriggered

Expires MaxTriggered for a particular topic match after 90 seconds.

=head2 Emitted Events

=head3 Bot_rdb_triggered

Broadcast when a topic's response triggers a RDB; see 
L<Bot::Cobalt::Plugin::RDB> for details.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

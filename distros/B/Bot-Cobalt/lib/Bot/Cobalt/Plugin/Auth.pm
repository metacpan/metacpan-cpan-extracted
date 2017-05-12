package Bot::Cobalt::Plugin::Auth;
$Bot::Cobalt::Plugin::Auth::VERSION = '0.021003';
use strictures 2;

## "Standard" Auth module
##
## Commands:
## PRIVMSG:
##    login <username> <passwd>
##    chpass <oldpass> <newpass>
##    user add
##    user del
##    user list
##    user search
##    user chpass
##
##
## Fairly basic access level system:
##
## - Users can have any numeric level.
##   Generally unauthenticated users will be level 0
##   Higher levels trump lower levels.
##   SuperUsers (auth.conf) get access level 9999.
##
## - Plugins determine required levels for their respective commands
##
## Passwords are hashed via bcrypt and stored in YAML
## Location of the authdb is determined by auth.conf
##
## Loaded authdb exists in memory in $self->AccessList:
## ->AccessList = {
##   $context => {
##     $username => {
##       Masks => ARRAY,
##       Password => STRING (passwd hash),
##       Level => INT (9999 if superuser),
##       Flags => HASH,
##     },
##   },
## }
##
## Also see Bot::Cobalt::Core::ContextMeta::Auth


use Bot::Cobalt;
use Bot::Cobalt::Common;
use Bot::Cobalt::Error;
use Bot::Cobalt::Serializer;

use Scalar::Util 'reftype';
use Storable 'dclone';

use Try::Tiny;

use File::Spec;


### Constants, mostly for internal retvals:
sub ACCESS_LIST() { 0 }
sub DB_PATH()     { 1 }


sub new {
  bless [
    +{}, ## ACCESS_LIST
    '', ## DB_PATH
  ], shift
}

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  my $p_cfg = plugin_cfg( $self );

  my $relative_path = $p_cfg->{Opts}->{AuthDB} ||
    File::Spec->catfile( 'db', 'authdb.yml');

  my $authdb = File::Spec->catfile(
    $core->var,
    File::Spec->splitpath($relative_path)
  );

  logger->debug("Using authdb path $authdb");

  $self->_db_path($authdb);

  ## Read in main authdb:
  my $alist = $self->_read_access_list;

  unless ($alist) {
    die "initial _read_access_list failed, check log\n";
  }

  $self->AccessList( $alist );

  $self->_init_superusers;

  register($self, 'SERVER',
      'connected',
      'disconnected',

      'user_quit',
      'user_left',
      'self_left',

      'self_kicked',
      'user_kicked',

      'nick_changed',

      'private_msg',
  );

  ## clear any remaining auth states.
  ## (assuming the plugin unloaded cleanly, there should be none)
  $self->_clear_all;

  logger->info("Loaded");

  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  logger->info("Unregistering core IRC plugin");

  $self->_clear_all;

  return PLUGIN_EAT_NONE
}

sub _init_superusers {
  my ($self) = @_;
  my $p_cfg = plugin_cfg($self);

  ## Read in configured superusers to AccessList
  ## These will override existing usernames
  my $superusers = $p_cfg->{SuperUsers};
  unless (ref $superusers && reftype $superusers eq 'HASH') {
    logger->error("Configuration may be broken . . .");
    logger->error("SuperUsers directive is not a hash, skipping");
    return
  }

  my %su = %$superusers;

  SERVER: for my $context (keys %su) {
    unless (ref $su{$context} && reftype $su{$context} eq 'HASH') {
      logger->error("Skipping $context; configuration is not a hash");
      next SERVER
    }

    USER: for my $user (keys %{$su{$context}}) {
      unless (ref $su{$context}->{$user} 
              && reftype $su{$context}->{$user} eq 'HASH') {
        logger->error("Skipping $user; configuration is not a hash");
        next USER
      }

      ## Usernames on accesslist automatically get lowercased
      ## per rfc1459 rules, aka CASEMAPPING=rfc1459
      ## (we probably don't even know the server's CASEMAPPING= yet)
      my $lc_user = lc_irc($user);

      my $flags = ref $su{$context}->{$user}->{Flags}
                  && reftype $su{$context}->{$user}->{Flags} eq 'HASH' ?
        $su{$context}->{$user}->{Flags}
        : +{} ;

      $flags->{SUPERUSER} = 1;

      $self->AccessList->{$context}->{$lc_user} = {
        Password => $su{$context}->{$user}->{Password}
                     // $self->_mkpasswd(rand 10),
        Level => 9999,
        Flags => $flags,
      };

      ## Mask and Masks are both valid directives, Mask trumps Masks
      if (exists $su{$context}->{$user}->{Masks}
          && !exists $su{$context}->{$user}->{Mask} )
      {
        $su{$context}->{$user}->{Mask} =
          delete $su{$context}->{$user}->{Masks};
      }

      ## the Mask specification in cfg may be an array or a string:
      if (ref $su{$context}->{$user}->{Mask}) {
        unless (reftype $su{$context}->{$user}->{Mask} eq 'ARRAY') {
          logger->error(
            "Expected a string or list of masks in 'Mask:' for $user"
          );
          # FIXME currently leaves user with no Masks ...
          next USER
        }
        $self->AccessList->{$context}->{$lc_user}->{Masks} = [
          ## normalize masks into full, matchable masks:
          map {; normalize_mask($_) } @{ $su{$context}->{$user}->{Mask} }
        ];
      } else {
          $self->AccessList->{$context}->{$lc_user}->{Masks} = [
            normalize_mask( $su{$context}->{$user}->{Mask} )
          ];
      }

      logger->debug("added superuser: $user (context: $context)");
    } ## USER

  } ## SERVER

  1
}


### Bot_* events:
sub Bot_connected {
  my ($self, $core) = splice @_, 0, 2;
  ## Bot's freshly connected to a context
  ## Clear any auth entries for this pkg + context
  my $context = ${$_[0]};

  $self->_clear_context($context);

  return PLUGIN_EAT_NONE
}

sub Bot_disconnected {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};

  $self->_clear_context($context);

  return PLUGIN_EAT_NONE
}

sub Bot_user_left {
  my ($self, $core) = splice @_, 0, 2;
  ## User left a channel
  ## If we don't share other channels, this user can't be tracked
  ## (therefore clear any auth entries for user belonging to us)
  my $left    = ${$_[0]};
  my $context = $left->context;

  my $channel = $left->channel;
  my $nick    = $left->src_nick;

  ## Call _remove_if_lost to see if we can still track this user:
  $self->_remove_if_lost($context, $nick);

  return PLUGIN_EAT_NONE
}

sub Bot_self_left {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};
  my $channel = ${$_[1]};
  ## The bot left a channel. Check auth status of all users.
  ## This method may be unreliable on nets w/ busted CASEMAPPING=

  $self->_remove_if_lost($context);

  return PLUGIN_EAT_NONE
}

sub Bot_self_kicked {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};

  $self->_remove_if_lost($context);

  return PLUGIN_EAT_NONE
}

sub Bot_user_kicked {
  my ($self, $core) = splice @_, 0, 2;
  my $kick    = ${ $_[0] };
  my $context = $kick->context;
  my $nick    = $kick->src_nick;

  $self->_remove_if_lost($context, $nick);

  return PLUGIN_EAT_NONE
}

sub Bot_user_quit {
  my ($self, $core) = splice @_, 0, 2;
  my $quit    = ${$_[0]};
  my $context = $quit->context;
  my $nick    = $quit->src_nick;
  ## User quit, clear relevant auth entries
  ## We can call _do_logout directly here:

  $self->_do_logout($context, $nick);

  return PLUGIN_EAT_NONE
}

sub Bot_nick_changed {
  my ($self, $core) = splice @_, 0, 2;
  my $nchg = ${$_[0]};

  my $old = $nchg->old_nick;
  my $new = $nchg->new_nick;
  my $context = $nchg->context;

  ## a nickname changed, adjust Auth accordingly:
  core->auth->move($context, $old, $new);

  return PLUGIN_EAT_NONE
}


sub Bot_private_msg {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${$_[0]};
  my $context = $msg->context;

  my $command = $msg->message_array->[0] // return PLUGIN_EAT_NONE;
  $command = lc $command;

  ## simple method check/dispatch:
  my $resp;
  my $method = "_cmd_".$command;
  if ( $self->can($method) ) {
    logger->debug("dispatching '$command' for ".$msg->src_nick);
    $resp = $self->$method($context, $msg);
  }

  if (defined $resp) {
    my $target = $msg->src_nick;
    broadcast( 'message', $context, $target, $resp );
  }

  return PLUGIN_EAT_NONE
}


### Frontends:

sub _cmd_login {
  ## interact with _do_login and set up response RPLs
  ## _do_login does the heavy lifting, we just talk to the user
  ## this is stupid, but I'm too lazy to fix
  my ($self, $context, $msg) = @_;

  my (undef, $l_user, $l_pass) = @{ $msg->message_array };

  my $origin = $msg->src;
  my $nick   = $msg->src_nick;

  unless (defined $l_user && defined $l_pass) {
    ## bad syntax resp, currently takes no args ...
    return core->rpl( q{AUTH_BADSYN_LOGIN} );
  }

  ## NOTE: usernames in accesslist are stored lowercase per rfc1459 rules:
  $l_user = lc_irc($l_user);

  ## IMPORTANT:
  ## nicknames (for auth hash) remain unmolested
  ## case changes are managed by tracking actual nickname changes
  ## (that way we don't have to worry about it when checking access levels)

  my $rplvars = {
    context => $context,
    src  => $origin,
    nick => $nick,
    user => $l_user,
  };

  my $resp;

  try {
    $self->_do_login($context, $nick, $l_user, $l_pass, $origin);

    $rplvars->{lev} = core->auth->level($context, $nick);

    $resp = core->rpl( q{AUTH_SUCCESS}, $rplvars );
  } catch {
    my %rplmap = (
      E_NOSUCH   => 'AUTH_FAIL_NO_SUCH',
      E_BADPASS  => 'AUTH_FAIL_BADPASS',
      E_BADHOST  => 'AUTH_FAIL_BADHOST',
      E_NOCHANS  => 'AUTH_FAIL_NO_CHANS',
    );

    my $rpl = $rplmap{$_};

    logger->error("BUG; unknown retval from _do_login")
      unless defined $rpl;

    $resp = core->rpl( $rpl, $rplvars );
  };

  broadcast( 'notice', $context, $nick, $resp ) if defined $resp;

  return
}

sub _cmd_chpass {
  my ($self, $context, $msg) = @_;
  ## 'self' chpass for logged-in users
  ##    chpass OLD NEW

  my $nick = $msg->src_nick;

  my $auth_for_nick = core->auth->username($context, $nick);

  unless (defined $auth_for_nick) {
    return core->rpl( q{RPL_NO_ACCESS},
      nick => $nick,
    )
  }

  my $passwd_old = $msg->message_array->[1];
  my $passwd_new = $msg->message_array->[2];
  unless (defined $passwd_old && defined $passwd_new) {
    return core->rpl( q{AUTH_BADSYN_CHPASS} );
  }

  my $user_rec = $self->_get_user_rec($context, $auth_for_nick);

  if ($user_rec->{Flags}->{SUPERUSER}) {
    return "Superusers are hard-coded and cannot chpass"
  }

  my $stored_pass = $user_rec->{Password};
  unless ( passwdcmp($passwd_old, $stored_pass) ) {
    return core->rpl( q{AUTH_CHPASS_BADPASS},
      context => $context,
      nick => $nick,
      user => $auth_for_nick,
      src => $msg->src,
    )
  }

  $user_rec->{Password} = $self->_mkpasswd($passwd_new);

  unless ( $self->_write_access_list ) {
    logger->warn(
      "Couldn't _write_access_list in _cmd_chpass",
    );

    broadcast( 'message', $context, $nick,
      "Failed access list write! Admin should check logs."
    );
  }

  return core->rpl( q{AUTH_CHPASS_SUCCESS},
    context => $context,
    nick => $nick,
    user => $auth_for_nick,
    src  => $msg->src,
  )
}

sub _cmd_whoami {
  my ($self, $context, $msg) = @_;
  ## return current auth status
  my $nick = $msg->src_nick;

  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick)
                 // 'Not Authorized';

  return core->rpl( q{AUTH_STATUS},
    user => $auth_usr,
    nick => $nick,
    lev  => $auth_lev,
  )
}

sub _cmd_user {
  my ($self, $context, $msg) = @_;

  ## user add
  ## user del
  ## user list
  ## user search
  my $cmd = lc( $msg->message_array->[1] // '');

  my $resp;

  unless ($cmd) {
    return 'No command specified'
  }

  ## All of these need *some* access level
  ## Bail early if we don't know this user
  my $auth_lev = core->auth->level($context, $msg->src_nick);
  unless ($auth_lev) {
    return core->rpl( q{RPL_NO_ACCESS},
      nick => $msg->src_nick,
    )
  }

  my $method = "_user_".$cmd;
  if ( $self->can($method) ) {
    logger->debug("dispatching $method for ".$msg->src_nick);

    return $self->$method($context, $msg)
  }

  return
}



### Auth routines:

sub _do_login {
  ## backend handler for _cmd_login
  ## $username should've already been normalized via lc_irc:
  my ($self, $context, $nick, $username, $passwd, $host) = @_;

  my $user_rec;
  unless ($user_rec = $self->_get_user_rec($context, $username) ) {
    logger->info(
      "[$context] authfail; no such user: $username ($host)"
    );

    ## auth_failed_login ($context, $nick, $username, $host, $error_str)
    broadcast( 'auth_failed_login',
      $context,
      $nick, $username, $host,
      'NO_SUCH_USER',
    );

    die Bot::Cobalt::Error->new("E_NOSUCH")
  }

  ## fail if we don't share channels with this user
  my $irc = core->get_irc_obj($context);
  unless ($irc->nick_channels($nick)) {
    logger->info(
      "[$context] authfail; no shared chans: $username ($host)"
    );

    broadcast( 'auth_failed_login',
      $context,
      $nick, $username, $host,
      'NO_SHARED_CHANS',
    );

    die Bot::Cobalt::Error->new("E_NOCHANS")
  }

  ## masks should be normalized already:
  my @matched_masks;
  for my $mask (@{ $user_rec->{Masks} }) {
    push(@matched_masks, $mask) if matches_mask($mask, $host);
  }

  unless (@matched_masks) {
    logger->info("[$context] authfail; no host match: $username ($host)");

    broadcast( 'auth_failed_login',
      $context,
      $nick, $username, $host,
      'BAD_HOST',
    );

    die Bot::Cobalt::Error->new("E_BADHOST")
  }

  unless ( passwdcmp($passwd, $user_rec->{Password}) ) {
    logger->info("[$context] authfail; bad passwd: $username ($host)");

    broadcast( 'auth_failed_login',
      $context,
      $nick, $username, $host,
      'BAD_PASS',
    );

    die Bot::Cobalt::Error->new("E_BADPASS")
  }

  my $level = $user_rec->{Level};
  my %flags = %{ $user_rec->{Flags} // {} };

  core->auth->add(
    Context  => $context,
    Username => $username,
    Nickname => $nick,
    Host     => $host,
    Level    => $level,
    Flags    => \%flags,
    Alias    => core->get_plugin_alias($self),
  );

  logger->info(
    "[$context] successful auth: $username (lev $level) ($host)"
  );

  ## send Bot_auth_user_login ($context, $nick, $host, $username, $lev):
  broadcast( 'auth_user_login',
    $context,
    $nick, $username, $host,
    $level,
  );

  1
}


sub _user_add {
  my ($self, $context, $msg) = @_;
  my $nick = $msg->src_nick;
  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick);

  unless ($auth_usr) {
    ## not logged in, return rpl
    logger->info("Failed user add attempt by $nick on $context");
    return core->rpl( q{RPL_NO_ACCESS},
      nick => $nick,
    )
  }

  my $pcfg = plugin_cfg($self);

  my $required_base_lev = $pcfg->{RequiredPrivs}->{AddingUsers} // 2;

  unless ($auth_lev >= $required_base_lev) {
    ## doesn't match configured required base level
    ## otherwise this user can add users with lower access levs than theirs
    logger->info(
      "Failed user add; $nick ($auth_usr) has insufficient perms"
    );

    return core->rpl( q{AUTH_NOT_ENOUGH_ACCESS},
      nick => $nick,
      lev  => $auth_lev,
    )
  }

  ## user add <username> <lev> <mask> <passwd> ?
  my @message = @{ $msg->message_array };
  my @args = @message[2 .. $#message];
  my ($target_usr, $target_lev, $mask, $passwd) = @args;
  unless ($target_usr && $target_lev && $mask && $passwd) {
    return "Usage: user add <username> <level> <mask> <initial_passwd>"
  }

  $target_usr = lc_irc($target_usr);

  unless ($target_lev =~ /^\d+$/) {
    return "Usage: user add <username> <level> <mask> <initial_passwd>"
  }

  if ( exists $self->AccessList->{'-ALL'}->{$target_usr} ) {
    logger->warn(
      "Failed user add ($nick); $target_usr already exists in -ALL"
    );

    return core->rpl( q{AUTH_USER_EXISTS},
      nick => $nick,
      user => $target_usr,
    )
  }

  if ( exists $self->AccessList->{$context}->{$target_usr} ) {
    logger->warn(
      "Failed user add ($nick); $target_usr already exists on $context"
    );

    return core->rpl( q{AUTH_USER_EXISTS},
      nick => $nick,
      user => $target_usr,
    )
  }

  unless ($target_lev < $auth_lev) {
    ## user doesn't have enough access to add this level
    ## (superusers have to be hardcoded in auth.conf)
    logger->info(
      "Failed user add; lev ($target_lev) too high for $auth_usr ($nick)"
    );

    return core->rpl( q{AUTH_NOT_ENOUGH_ACCESS},
      nick => $nick,
      lev  => $auth_lev,
    )
  }

  $mask = normalize_mask($mask);

  ## add to AccessList
  $self->AccessList->{$context}->{$target_usr} = {
    Masks    => [ $mask ],
    Password => $self->_mkpasswd($passwd),
    Level    => $target_lev,
    Flags    => {},
  };

  logger->info("New user added by $nick ($auth_usr)");
  logger->info("New user $target_usr ($mask) level $target_lev");

  unless ( $self->_write_access_list ) {
    ## added to AccessList but couldn't be written out
    logger->warn("Couldn't _write_access_list in _user_add");

    broadcast( 'message', $context, $nick,
      "Failed access list write! Admin should check logs."
    );
  }

  return core->rpl( q{AUTH_USER_ADDED},
    nick => $nick,
    user => $target_usr,
    mask => $mask,
    lev  => $target_lev,
  )
}

sub _user_delete { _user_del(@_) }
sub _user_del {
  my ($self, $context, $msg) = @_;
  my $nick = $msg->src_nick;
  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick);

  unless ($auth_usr) {
    logger->info("Failed user del attempt by $nick on $context");
    return core->rpl( q{RPL_NO_ACCESS},
      nick => $nick,
    )
  }

  my $pcfg = plugin_cfg($self);

  my $required_base_lev = $pcfg->{RequiredPrivs}->{DeletingUsers} // 2;

  unless ($auth_lev >= $required_base_lev) {
    logger->info(
      "Failed user del; $nick ($auth_usr) has insufficient perms"
    );

    return core->rpl( q{AUTH_NOT_ENOUGH_ACCESS},
      nick => $nick,
      lev  => $auth_lev,
    )
  }

  ## user del <username>
  my $target_usr = $msg->message_array->[2];
  unless ($target_usr) {
    return "Usage: user del <username>"
  }

  $target_usr = lc_irc($target_usr);

  ## check if exists
  my $this_alist = $self->AccessList->{$context};
  unless (exists $this_alist->{$target_usr}) {
    return core->rpl( q{AUTH_USER_NOSUCH},
      nick => $nick,
      user => $target_usr
    )
  }

  ## get target user's auth_level
  ## check if authed user has a higher identified level
  my $target_lev = $this_alist->{$target_usr}->{Level};
  unless ($target_lev < $auth_lev) {
    logger->info(
      "Failed user del; $nick ($auth_usr) has insufficient perms"
    );

    return core->rpl( q{AUTH_NOT_ENOUGH_ACCESS},
      nick => $nick,
      lev  => $auth_lev
    )
  }

  ## delete users from AccessList
  delete $this_alist->{$target_usr};

  logger->info("User deleted: $target_usr ($target_lev) on $context");
  logger->info("Deletion issued by $nick ($auth_usr)");

  ## see if user is logged in, log them out if so
  my $auth_context = core->auth->list($context);
  for my $authnick (keys %$auth_context) {
    my $this_username = $auth_context->{$authnick}->{Username};

    next unless $this_username eq $target_usr;

    $self->_do_logout($context, $authnick);
  }

  unless ( $self->_write_access_list ) {
    logger->warn("Couldn't _write_access_list in _user_add");

    broadcast( 'message', $context, $nick,
      "Failed access list write! Admin should check logs."
    );
  }

  return core->rpl( q{AUTH_USER_DELETED},
    nick => $nick,
    user => $target_usr
  )
}

sub _user_list {
  my ($self, $context, $msg) = @_;

  my $nick = $msg->src_nick;
  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick);

  return core->rpl( q{RPL_NO_ACCESS}, nick => $nick )
    unless $auth_lev;

  ## FIXME extra opt for users w/ add perms to list -ALL ?
  my $alist = $self->AccessList->{$context} // {};

  my $respstr = "Users ($context): ";

  USER: for my $username (keys %$alist) {
    my $lev = $alist->{$username}->{Level};
    $respstr .= "$username ($lev)   ";

    if ( length($respstr) > 250 ) {
      broadcast( 'message', $context, $nick,
        $respstr
      );

      $respstr = '';
    }

  } ## USER

  return $respstr if $respstr
}

sub _user_whois {
  my ($self, $context, $msg) = @_;
  my $nick = $msg->src_nick;

  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick);

  return core->rpl( q{RPL_NO_ACCESS}, nick => $nick )
    unless $auth_lev;

  my $target_nick = $msg->message_array->[2];

  if ( my $target_lev = core->auth->level($context, $target_nick) ) {
    my $target_usr = core->auth->username($context, $target_nick);

    return "$target_nick is user $target_usr with level $target_lev"
  } else {
    return "$target_nick is not currently logged in"
  }
}

sub _user_info {
  my ($self, $context, $msg) = @_;
  my $nick = $msg->src_nick;

  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick);

  unless ($auth_lev) {
    return core->rpl( q{RPL_NO_ACCESS}, nick => $nick );
  }

  my $target_usr = $msg->message_array->[2];
  unless (defined $target_usr) {
    return 'Usage: user info <username>'
  }

  $target_usr = lc_irc($target_usr);

  my $user_rec;
  unless ( $user_rec = $self->_get_user_rec($context, $target_usr) ) {
    return core->rpl( q{AUTH_USER_NOSUCH},
      nick => $nick,
      user => $target_usr
    );
  }

  my $usr_lev     = $user_rec->{Level};
  my $usr_maskref = $user_rec->{Masks};

  my $maskcount = @$usr_maskref;

  broadcast( 'message', $context, $nick,
    "User $target_usr is level $usr_lev, $maskcount masks listed"
  );

  my @flags = keys %{ $user_rec->{Flags} };

  my $flag_repl = "Flags: ";

  while (my $this_flag = shift @flags) {
    $flag_repl .= "  ".$this_flag;

    if (length $flag_repl > 300 || !@flags) {
      broadcast('message', $context, $nick, $flag_repl);
      $flag_repl = '';
    }
  }

  my $mask_repl = "Masks: ";
  my @masks = @$usr_maskref;

  while (my $this_mask = shift @masks) {
    $mask_repl .= "  ".$this_mask;
    if (length $mask_repl > 300 || !@masks) {
      broadcast('message', $context, $nick, $mask_repl);
      $mask_repl = '';
    }
  }

  return
}

sub _user_search {
  my ($self, $context, $msg) = @_;
  my $nick = $msg->src_nick;

  ## Auth should've already been checked in user_* dispatcher

  ## FIXME

  ## search by: username, host, ... ?
  ## limit results ?

}

sub _user_chflags {
  my ($self, $context, $msg) = @_;
  my $nick = $msg->src_nick;

  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick);

  my $pcfg = plugin_cfg($self);
  my $req_lev = $pcfg->{RequiredPrivs}->{DeletingUsers};

  my @message = @{ $msg->message_array };
  my $target_usr = $message[2];
  my @flags = @message[3 .. $#message];

  unless ($target_usr && @flags) {
    return "Syntax: user chflags <username> <+/-flag> ..."
  }

  my $alist_ref;
  unless ($alist_ref = $self->_get_user_rec($context, $target_usr) ) {
    return core->rpl( q{AUTH_USER_NOSUCH},
      nick => $nick,
      user => $target_usr,
    )
  }

  my $target_usr_lev = $alist_ref->{Level};

  my $auth_flags = core->auth->flags($context, $nick);

  unless ($auth_lev >= $req_lev
    && ($auth_lev > $target_usr_lev || $auth_usr eq $target_usr
        || $auth_flags->{SUPERUSER}) )  {

    my $src = $msg->src;
    logger->warn(
      "Access denied in chflags: $src tried to chflags $target_usr"
    );

    return core->rpl( q{AUTH_NOT_ENOUGH_ACCESS},
      nick => $nick,
      lev  => $auth_lev,
    )
  }

  my $resp;
  FLAG: for my $this_flag (@flags) {
    my $first = substr($this_flag, 0, 1, '');
    $this_flag = uc($this_flag||'');

    unless ($first && $this_flag) {
      return "Bad syntax; flags should be in the form of -/+FLAG"
    }

    if ($this_flag eq 'SUPERUSER') {
      return "Cannot set SUPERUSER flag manually"
    }

    if ($first eq '+') {
      logger->debug("$nick ($auth_usr) flag add $target_usr $this_flag");
      $alist_ref->{Flags}->{$this_flag} = 1;
      next FLAG
    } elsif ($first eq '-') {
      logger->debug("$nick ($auth_usr) flag drop $target_usr $this_flag");
      delete $alist_ref->{Flags}->{$this_flag};
      next FLAG
    }

    return "Bad syntax; flags should be prefixed by + or -"
  }  ## FLAG

  if ( $self->_write_access_list ) {
    broadcast( 'message', $context, $nick,
      "Adjusted flags for $target_usr"
    );
  } else {
    broadcast( 'message', $context, $nick,
      "List write failed in _user_chflags, admin should check logs"
    );
  }

  return
}

sub _user_chmask {
  my ($self, $context, $msg) = @_;
  my $nick = $msg->src_nick;
  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick);

  my $pcfg = plugin_cfg($self);
  ## If you can't delete users, you probably shouldn't be permitted
  ## to delete their masks, either
  my $req_lev = $pcfg->{RequiredPrivs}->{DeletingUsers};

  ## You also should have higher access than your target
  ## (unless you're a superuser)
  my $target_usr    = $msg->message_array->[2];
  my $mask_specified = $msg->message_array->[3];

  unless ($target_usr && $mask_specified) {
    return "Usage: user chmask <user> [+/-]<mask>"
  }

  my $alist_ref;
  unless ( $alist_ref = $self->_get_user_rec($context, $target_usr) ) {
    return core->rpl( q{AUTH_USER_NOSUCH},
      nick => $nick,
      user => $target_usr,
    )
  }

  my $target_usr_lev = $alist_ref->{Level};
  my $flags = core->auth->flags($context, $nick);

  ## Must be:
  ##  higher than target user's lev
  ##   or adjusting your own mask
  ##   or superuser
  unless ($auth_lev >= $req_lev
    && ($auth_lev > $target_usr_lev || $auth_usr eq $target_usr
        || $flags->{SUPERUSER}) )  {

    my $src = $msg->src;

    logger->warn(
      "Access denied in chmask: $src tried to chmask $target_usr"
    );

    return core->rpl( q{AUTH_NOT_ENOUGH_ACCESS},
      nick => $nick,
      lev  => $auth_lev
    );
  }

  my ($oper, $host) = $mask_specified =~ /^(\+|\-)(\S+)/;
  unless ($oper && $host) {
    return "Bad mask specification, should be operator (+ or -) followed by mask"
  }

  $host = normalize_mask($host);

  my $resp;
  if ($oper eq '+') {
    push(@{ $alist_ref->{Masks} }, $host)
      unless grep { $_ eq $host } @{ $alist_ref->{Masks} };
    $resp = core->rpl( q{AUTH_MASK_ADDED},
      nick => $nick,
      user => $target_usr,
      mask => $host,
    );
  } else {
    ## Remove a mask (the inefficient way, at the moment - lazy)

    my @masks = grep { $_ ne $host } @{ $alist_ref->{Masks} };
    if (@masks == @{$alist_ref->{Masks}}) {
      return "Mask not found."
    }

    $alist_ref->{Masks} = \@masks;
    $resp = core->rpl( q{AUTH_MASK_DELETED},
      nick => $nick,
      user => $target_usr,
      mask => $host
    );
  }

  ## call a list sync
  if ( $self->_write_access_list ) {
    broadcast( 'message', $context, $nick, $resp );
  } else {
    broadcast( 'message', $context, $nick,
      "List write failed in _user_chmask, admin should check logs"
    );
  }

  return
}

sub _user_chpass {
  my ($self, $context, $msg) = @_;
  my $nick = $msg->src_nick;
  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick);

  unless (core->auth->has_flag($context, $nick, 'SUPERUSER')) {
    return "Must be flagged SUPERUSER to use user chpass"
  }

  my $target_usr = $msg->message_array->[2];
  my $new_passwd  = $msg->message_array->[3];

  unless ($target_usr && $new_passwd) {
    return "Usage: user chpass <username> <new_passwd>"
  }

  my $user_rec;
  unless ($user_rec = $self->_get_user_rec($context, $target_usr) ) {
    return core->rpl( q{AUTH_USER_NOSUCH},
      nick => $nick,
      user => $target_usr,
    )
  }

  my $hashed = $self->_mkpasswd($new_passwd);

  logger->info(
    "$nick ($auth_usr) CHPASS for $target_usr"
  );

  $user_rec->{Password} = $hashed;

  if ( $self->_write_access_list ) {
    return core->rpl( q{AUTH_CHPASS_SUCCESS},
      nick => $nick,
      user => $target_usr,
    );
  } else {
    logger->warn(
      "Couldn't _write_access_list in _cmd_chpass",
    );

    return "Failed access list write! Admin should check logs."
  }
}


### Utility methods:

sub _get_user_rec {
  my ($self, $context, $user) = @_;

  ## Return user AccessList record, preferring hardcoded -ALL:

  confess "_get_user_rec called without required arguments"
    unless defined $context and defined $user;

  return unless exists $self->AccessList->{'-ALL'}->{$user}
    or  exists $self->AccessList->{$context}
    and exists $self->AccessList->{$context}->{$user};

  exists $self->AccessList->{'-ALL'}->{$user} ?
    $self->AccessList->{'-ALL'}->{$user}
    : $self->AccessList->{$context}->{$user}
}

sub _remove_if_lost {
  my ($self, $context, $nick) = @_;
  ## $self->_remove_if_lost( $context );
  ## $self->_remove_if_lost( $context, $nickname );
  ##
  ## called by event handlers that track users (or the bot) leaving
  ##
  ## if a nickname is specified, ask _check_for_shared if we still see
  ## this user, otherwise remove relevant Auth
  ##
  ## if no nickname is specified, do the above for all Auth'd users
  ## in the specified context
  ##
  ## return list of removed users

  ## no auth for specified context? then we don't care:
  my $authref;
  return unless $authref = core->auth->list($context);

  my @removed;

  if ($nick) {
    ## ...does auth for this nickname in this context?
    return unless exists $authref->{$nick};

    unless ( $self->_check_for_shared($context, $nick) ) {
      ## we no longer share channels with this user
      ## if they're auth'd and their authorization is "ours", kill it
      ## call _do_logout to log them out and notify the pipeline
      ##
      ## _do_logout handles the messy details, incl. checking to make sure
      ## that we are the "owner" of this auth:
      push(@removed, $nick) if $self->_do_logout($context, $nick);
    }

  } else {
    ## no nickname specified
    ## check trackable status for all known
    for $nick (keys %$authref) {
      unless ( $self->_check_for_shared($context, $nick) ) {
        push(@removed, $nick) if $self->_do_logout($context, $nick);
      }
    }

  }

  return @removed
}

sub _check_for_shared {
  ## $self->_check_for_shared( $context, $nickname );
  ##
  ## Query the IRC component to see if we share channels with a user.
  ## Actually just a simple frontend to get_irc_obj & PoCo::IRC::State
  ##
  ## Returns boolean true or false.
  ## Typically called after either the bot or a user leave a channel
  ## ( normally by _remove_if_lost() )
  ##
  ## Tells Auth whether or not we can sanely track this user.
  ## If we don't share channels it's difficult to get nick change
  ## notifications and generally validate authenticated users.
  my ($self, $context, $nick) = @_;
  my $irc = core->get_irc_obj( $context );
  my @shared = $irc->nick_channels( $nick );
  return @shared ? 1 : 0 ;
}

sub _clear_context {
  my ($self, $context) = @_;

  ## $self->_clear_context( $context )
  for my $nick ( core->auth->list($context) ) {
    $self->_do_logout($context, $nick);
  }
}

sub _clear_all {
  my ($self) = @_;
  ## $self->_clear_all()
  ## clear any states belonging to us
  for my $context ( core->auth->list() ) {

    NICK: for my $nick ( core->auth->list($context) ) {

      next NICK unless core->auth->alias($context, $nick)
                    eq core->get_plugin_alias($self);

      logger->debug("clearing: $nick [$context]");
      $self->_do_logout($context, $nick)
    }

  }
}

sub _do_logout {
  my ($self, $context, $nick) = @_;
  ## $self->_do_logout( $context, $nick )
  ## handles logout routines for 'lost' users
  ## normally called by method _remove_if_lost
  ##
  ## sends auth_user_logout event in addition to clearing auth hash
  ##
  ## returns the deleted user auth hash (or nothing)
  my $auth_context = core->auth->list($context);

  if (exists $auth_context->{$nick}) {
    my $auth_pkg    = core->auth->alias($context, $nick);
    my $current_pkg = core->get_plugin_alias($self);

    if ($auth_pkg eq $current_pkg) {
      my $host     = core->auth->host($context, $nick);
      my $username = core->auth->username($context, $nick);
      my $level    = core->auth->level($context, $nick);

      ## Bot_auth_user_logout ($context, $nick, $host, $username, $lev, $pkg):
      broadcast( 'auth_user_logout',
        $context,
        $nick, $host, $username,
        $level,
        $auth_pkg,
      );

      logger->debug(
        "cleared auth state: $username ($nick on $context)"
      );

      return core->auth->del($context, $nick)
    } else {
      logger->debug(
        "skipped auth state, not ours: $nick [$context]"
      );
    }
  }
  return
}

sub _mkpasswd {
  my ($self, $passwd) = @_;
  return unless $passwd;
  ## $self->_mkpasswd( $passwd );
  ## simple frontend to Bot::Cobalt::Utils::mkpasswd()
  ## handles grabbing cfg opts for us:

  my $cfg = plugin_cfg( $self );

  my $crypt_method = $cfg->{Method} // 'bcrypt';
  my $bcrypt_cost  = $cfg->{Bcrypt_Cost} || '08';

  mkpasswd($passwd, $crypt_method, $bcrypt_cost)
}

sub _db_path {
  my ($self, $dbpath) = @_;

  return $self->[DB_PATH] = $dbpath if defined $dbpath;

  $self->[DB_PATH]
}

sub AccessList {
  my ($self, $alist) = @_;

  if (defined $alist) {
    confess "AccessList is not a hashref"
      unless ref $alist 
      and reftype $alist eq 'HASH';

    return $self->[ACCESS_LIST] = $alist
  }

  $self->[ACCESS_LIST]
}


### Access list rw methods (serialize to YAML)
### These can also be used to read/write arbitrary authdbs

sub _read_access_list {
  my ($self, $authdb) = @_;
  ## Default to $self->_db_path
  $authdb = $self->_db_path unless $authdb;
  ## read authdb, spit out hash

  unless (-f $authdb) {
    logger->debug("did not find authdb at $authdb");
    logger->info("No existing authdb, creating empty access list.");

    return { }
  }

  my $serializer = Bot::Cobalt::Serializer->new();

  my $accesslist;
  try {
    $accesslist = $serializer->readfile($authdb);
  } catch {
    logger->error("readfile() failure; $authdb $_");
  };

  return $accesslist
}

sub _write_access_list {
  my ($self, $authdb, $alist) = @_;
  $authdb = $self->_db_path unless $authdb;
  $alist  = $self->AccessList unless $alist;

  ## we don't want to write superusers back out
  ## copy from ref to a fresh hash:
  my $cloned = dclone($alist);
  delete $cloned->{'-ALL'};

  for my $context (keys %$cloned) {
    for my $user (keys %{ $cloned->{$context} }) {
      if ( $cloned->{$context}->{$user}->{Flags}->{SUPERUSER} ) {
        ## FIXME
        ##  sync superusers too so we can preserve flags?
        ##  need to check/delete them at load time if there's a change
        delete $cloned->{$context}->{$user};
      }
    }
    ## don't need to write empty contexts either:
    delete $cloned->{$context} unless keys %{ $cloned->{$context} };
  }

  ## don't need to write empty access lists to disk ...
  return $authdb unless keys %$cloned;

  my $serializer = Bot::Cobalt::Serializer->new();

  return $authdb if try {
    $serializer->writefile($authdb, $cloned);

    my $p_cfg = plugin_cfg( $self );
    my $perms = oct( $p_cfg->{Opts}->{AuthDB_Perms} // '0600' );
    chmod($perms, $authdb);
    1
  };

  logger->error("writefile() failure; $authdb $_");
  return
}

1;
__END__


=pod

=head1 NAME

Bot::Cobalt::Plugin::Auth -- User management and auth plugin

=head1 DESCRIPTION

This plugin provides the standard authorization and access control
functionality for L<Bot::Cobalt>.

=head1 CONFIGURATION

=head2 plugins.conf

A basic plugins.conf entry for this plugin:

  Auth:
    Module: Bot::Cobalt::Plugin::Auth
    Config: auth.conf

=head2 auth.conf

C<auth.conf> is the central configuration file for this plugin, 
including statically-configured superuser auth entries.

=head3 SuperUsers

The B<SuperUsers> directive specifies statically configured superusers, 
who receive access level 9999 by default and typically have access to 
the totality of the bot's functionality.

Users are specified per-context. Multiple masks can be specified as a 
list:

  SuperUsers:
    Main:
      'avenj':
        Mask:
          - '*avenj@*.oppresses.us'
          - '*avenj@*.cobaltirc.org'
        Password: '$2a$08$W19087w4d(. . . .)'

B<Password> should be a hashed password. You can create them from the 
command line via C<bmkpasswd> from L<App::bmkpasswd>, which this 
distribution depends on.

=head3 Opts

B<Opts> defines a small set of password and database related options:

  Opts:
    Method: 'bcrypt'
    Bcrypt_Cost: '08'
    AuthDB: 'db/authdb.yml'

=head4 Method

B<Method> is a string describing the preferred password hashing method 
for new passwords. Hashes are created via L<App::bmkpasswd> -- C<bcrypt> 
is the recommended method and guaranteed to be available.

C<sha256> and C<sha512> methods may be available, although you might 
need L<Crypt::Passwd::XS> on certain platforms. Consult the 
L<App::bmkpasswd> documentation for details.

=head4 Bcrypt_Cost

If using bcrypt (see L</Method>), the 'work cost factor' is 
configurable. Must be a two digit power of 2. Lower is faster (less 
secure), higher is slower (more secure). 

The default work cost factor is '08' -- you can probably leave this 
alone.

=head4 AuthDB

Path (relative to the bot's C<var/> directory) used to store user 
information (except for superusers).

Defaults to 'db/authdb.yml'

=head3 RequiredPrivs

Required base access levels for specific operations.

  RequiredPrivs:
    AddingUsers: 2
    DeletingUsers: 2

=head1 IRC USAGE

=head2 Logging in

  /msg cobalt login <username> <password>

You must share at least one channel with the bot in order to log in.

=head2 Changing your password

You can change your own password at any time:

  /msg cobalt chpass <oldpasswd> <newpasswd>

=head2 User administration

=head3 user add

  /msg cobalt user add <username> <level> <mask> <passwd>

New users can be added by anyone with at least C<AddingUsers> level (see 
L</RequiredPrivs>). Users can only be added at levels below your own.

=head3 user del

  /msg cobalt user del <username>

Users can only be removed below your own access level (and you must have 
at least C<DeletingUsers> permissions -- see L</RequiredPrivs>)

=head3 user chflags

  /msg cobalt user chflags <username> +FLAG -FLAG [...]

Alter a user's marked flags; flags must be prefixed with + or - to 
indicate an addition or removal.

(As of this writing, flags are under-utilized in the Cobalt core 
distribution)

=head3 user chpass

  /msg cobalt user chpass <username> <passwd>

Alter a user's password manually. Only usable by superusers.

=head3 user chmask

  /msg cobalt user chmask <username> +*!*some@*.mask.example.org
  /msg cobalt user chmask <username> -*!*some@*.mask.example.org

Add or remove authorized masks for a particular user.

You can add or remove masks for yourself at any time, so long as you 
have at least B<DeletingUsers> level (see L</RequiredPrivs>). Altering 
masks for other users requires a higher access level than theirs.

Only one mask can be added or deleted at a time.

=head3 user whois

  /msg cobalt user whois <nickname>

Find out if a nickname is currently logged in to the bot (and under what 
username / access level)

=head3 user info

  /msg cobalt user info <username>

Display user record information for a username.

=head3 user list

  /msg cobalt user list

Display the current user list.

=head3 user search

FIXME

=head1 EMITTED EVENTS

=head2 Bot_auth_user_login

Broadcast when a login is successful.

Arguments are:

  $context, $nickname, $username, $hostname, $authorized_level

=head2 Bot_auth_failed_login

Broadcast when a login fails.

Arguments are:

  $context, $nickname, $username, $hostname, "ERR_STR"

Where 'ERR_STR' is one of the following strings:

  "NO_SUCH_USER"
  "NO_SHARED_CHANS"
  "BAD_HOST"
  "BAD_PASS"

=head2 Bot_auth_user_logout

Broadcast when a user is logged out, either manually or because the user 
was "lost" (no longer visible by the bot).

Arguments are:

  $context, $nickname, $hostname, $username, $authorized_level

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

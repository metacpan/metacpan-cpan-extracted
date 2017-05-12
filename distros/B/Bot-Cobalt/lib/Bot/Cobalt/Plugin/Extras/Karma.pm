package Bot::Cobalt::Plugin::Extras::Karma;
$Bot::Cobalt::Plugin::Extras::Karma::VERSION = '0.021003';
## simple karma++/-- tracking

use Carp;
use strictures 2;

use Object::Pluggable::Constants qw/ :ALL /;

use Bot::Cobalt;
use Bot::Cobalt::DB;

use List::Objects::WithUtils;

use File::Spec;

use IRC::Utils qw/decode_irc/;

sub new { bless +{ Cache => hash }, shift }

sub _cache { shift->{Cache} }
sub _set_cache { $_[0]->{Cache} = ($_[1] || confess "Expected a param") }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;
  
  my $dbpath = File::Spec->catfile( $core->var, 'karma.db' );
  
  $self->{karmadb} = Bot::Cobalt::DB->new(
    file => $dbpath,
  );

  $self->{karma_regex} = qr/^(\S+)(\+{2}|\-{2})$/;

  register( $self, 'SERVER',
    qw/
      public_msg
      public_cmd_karma
      public_cmd_topkarma
      public_cmd_resetkarma
      
      karmaplug_sync_db
    /
  );

  $core->timer_set( 5,
    { Event => 'karmaplug_sync_db' },
    'KARMAPLUG_SYNC_DB',
  );

  logger->info("Registered");

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  logger->debug("Calling _sync");
  $self->_sync();
  logger->info("Unregistered");
  PLUGIN_EAT_NONE
}


sub _sync {
  my ($self) = @_;
  return unless keys %{ $self->_cache };
  
  my $db = $self->{karmadb};
  unless ($db->dbopen) {
    logger->error("dbopen failure for karmadb in _sync");
    return
  }
  
  for my $karma_for (keys %{ $self->_cache }) {
    my $current = $self->_cache->{$karma_for};
    $current ?
        $db->put($karma_for, $current)
      : $db->del($karma_for);
    delete $self->_cache->{$karma_for};
  }

  $db->dbclose;
  1
}

sub _get {
  my ($self, $karma_for) = @_;
  
  return $self->_cache->{$karma_for}
    if exists $self->_cache->{$karma_for};
  
  my $db = $self->{karmadb};
  unless ($db->dbopen) {
    logger->error("dbopen failure for karmadb in _get");
    return
  }
  my $current = $db->get($karma_for) || 0;
  $db->dbclose;

  $current 
}

sub Bot_karmaplug_sync_db {
  my ($self, $core) = splice @_, 0, 2;
  
  $self->_sync();
  $core->timer_set( 5,
    { Event => 'karmaplug_sync_db' },
    'KARMAPLUG_SYNC_DB',
  );

  PLUGIN_EAT_NONE  
}

sub Bot_public_msg {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${$_[0]};
  return PLUGIN_EAT_NONE if $msg->highlight
                         or $msg->cmd;
  my $context = $msg->context;

  my $first_word = $msg->message_array->[0] // return PLUGIN_EAT_NONE;
  $first_word = decode_irc($first_word);

  if ($first_word =~ $self->{karma_regex}) {
    my ($karma_for, $karma) = (lc($1), $2);
    my $current = $self->_get($karma_for);
    if      ($karma eq '--') {
      --$current;
    } elsif ($karma eq '++') {
      ++$current;
    }

    $self->_cache->{$karma_for} = $current;
  }

  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_resetkarma {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${$_[0]};
  my $context = $msg->context;
  my $nick    = $msg->src_nick;
  my $usr_lev = $core->auth->level($context, $nick)
                || return PLUGIN_EAT_ALL;

  my $pcfg = $core->get_plugin_cfg($self);
  my $req_lev = $pcfg->{LevelRequired} || 9999;
  return PLUGIN_EAT_ALL unless $usr_lev >= $req_lev;

  my $channel = $msg->target;

  my $karma_for = lc($msg->message_array->[0] || return PLUGIN_EAT_ALL);
  $karma_for = decode_irc($karma_for);

  unless ( $self->_get($karma_for) ) {
    broadcast( 'message', $context, $channel,
      "${nick}: that item has no karma to clear",
    );
    return PLUGIN_EAT_ALL
  }
  
  $self->_cache->{$karma_for} = 0;
  logger->debug("Calling explicit _sync for cmd_resetkarma");
  $self->_sync;

  logger->info("Cleared karma for '$karma_for' per '$nick' on $context");
  broadcast( 'message', $context, $channel, "Cleared karma for $karma_for" );
  
  PLUGIN_EAT_ALL
}

sub Bot_public_cmd_karma {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${$_[0]};
  my $context = $msg->context;
  my $channel = $msg->target;

  my $karma_for = $msg->message_array->[0];
  $karma_for = lc($karma_for || $msg->src_nick);
  $karma_for = decode_irc($karma_for);

  my $resp;
  if ( my $karma = $self->_get($karma_for) ) {
    $resp = "Karma for $karma_for: $karma";
  } else {
    $resp = "$karma_for currently has no karma, good or bad.";
  }

  broadcast( 'message', $context, $channel, $resp );

  PLUGIN_EAT_ALL
}

sub Bot_public_cmd_topkarma {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${ $_[0] };
  my $context = $msg->context;
  my $channel = $msg->target;

  if ($self->{cached_top} && time - $self->{cached_top}->[0] < 300) {
    broadcast( 'message', $context, $channel, $self->{cached_top}->[1] );
    return PLUGIN_EAT_NONE
  }

  my $db = $self->{karmadb};
  unless ($db->dbopen) {
    logger->error("dbopen failure for karmadb in cmd_topkarma");
    broadcast( 'message', $context, $channel, 'karmadb open failure' );
    return PLUGIN_EAT_ALL
  }
  my $karma = hash(%{ $db->dbdump('HASH') });
  $db->dbclose;
  $karma->set(%{ $self->_cache }) if keys %{ $self->_cache };
  # some common junk data:
  $karma->delete('<', '-', '<-', '<--');
  my $sorted = $karma->kv_sort(sub { $karma->get($a) <=> $karma->get($b) });
  my $bottom = $sorted->sliced(0..4)->grep(sub { defined });
  my $top    = $sorted
                ->sliced( ($sorted->end - 4) .. $sorted->end )
                ->grep(sub { defined });

  my $str = '[ top -> ';
  for my $pair ($top->reverse->all) {
    my ($item, $karma) = @$pair;
    $str .= "'${item}':${karma} ";
  }
  $str .= ']; [ bottom -> ';
  for my $pair ($bottom->all) {
    my ($item, $karma) = @$pair;
    $str .= "'${item}':${karma} ";
  }
  $str .= ']';

  $self->{cached_top} = [ time, $str ];

  broadcast( 'message', $context, $channel, $str );
  PLUGIN_EAT_ALL
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Extras::Karma - Simple karma bot plugin

=head1 SYNOPSIS

  ## Retrieve karma:
  !karma
  !karma <word>

  ## Add or subtract karma:
  <JoeUser> someone++
  <JoeUser> someone--

  ## See highest and lowest scores (updates every 5 minutes):
  !topkarma
  
  ## Superusers can clear karma:
  !resetkarma foo

=head1 DESCRIPTION

A simple 'karma bot' plugin for Cobalt.

Uses L<Bot::Cobalt::DB> for storage, saving to B<karma.db> in the instance's 
C<var/> directory.

If an B<< Opts->LevelRequired >> directive is specified via plugins.conf, 
the specified level will be permitted to clear karmadb entries. Defaults to 
superusers (level 9999).

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

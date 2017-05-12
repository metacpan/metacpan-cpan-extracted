package Bot::Cobalt::Plugin::Extras::Debug;
$Bot::Cobalt::Plugin::Extras::Debug::VERSION = '0.021003';
use strictures 2;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use Data::Dumper;

sub new { bless [], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  my @events = map { 'public_cmd_'.$_ } 
    qw/
      dumpcfg 
      dumpstate 
      dumptimers 
      dumpservers
      dumplangset
      dumpheap
    / ;

  register $self, SERVER => [ @events ];

  $core->log->info("Loaded Debug");

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  $core->log->info("Unloaded DEBUG");
  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_dumpcfg {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };
  my $context  = $msg->context;
  my $src_nick = $msg->src_nick;

  return PLUGIN_EAT_ALL unless
    $core->auth->has_flag($context, $src_nick, 'SUPERUSER');

  broadcast message => $msg->context, $msg->channel,
    "Dumping configuration hash to log . . .";
  $core->log->warn("dumpcfg called (debugger)");
  $core->log->warn(Dumper $core->cfg);

  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_dumpstate {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };
  my $context  = $msg->context;
  my $src_nick = $msg->src_nick;

  return PLUGIN_EAT_ALL unless
    $core->auth->has_flag($context, $src_nick, 'SUPERUSER');

  broadcast message => $msg->context, $msg->channel,
    "Dumping state hash to log . . .";
  $core->log->warn("dumpstate called (debugger)");
  $core->log->warn(Dumper $core->State);
  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_dumptimers {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };
  my $context  = $msg->context;
  my $src_nick = $msg->src_nick;

  return PLUGIN_EAT_ALL unless
    $core->auth->has_flag($context, $src_nick, 'SUPERUSER');

  broadcast message => $msg->context, $msg->channel,
    "Dumping timer pool to log . . .";
  $core->log->warn("dumptimers called (debugger)");
  $core->log->warn(Dumper $core->TimerPool);
  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_dumpservers {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };
  my $context  = $msg->context;
  my $src_nick = $msg->src_nick;

  return PLUGIN_EAT_ALL unless
    $core->auth->has_flag($context, $src_nick, 'SUPERUSER');

  broadcast message => $msg->context, $msg->channel,
    "Dumping Servers hash to log . . .";
  $core->log->warn("dumpservers called (debugger)");
  $core->log->warn(Dumper $core->Servers);
  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_dumplangset {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };
  my $context  = $msg->context;
  my $src_nick = $msg->src_nick;

  return PLUGIN_EAT_ALL unless
    $core->auth->has_flag($context, $src_nick, 'SUPERUSER');

  broadcast message => $msg->context, $msg->channel,
    "Dumping core language set to log . . .";
  $core->log->warn("dumplangset called (debugger)");
  $core->log->warn(Dumper $core->lang);
  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_dumpheap {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };
  my $context  = $msg->context;
  my $src_nick = $msg->src_nick;

  return PLUGIN_EAT_ALL unless
    $core->auth->has_flag($context, $src_nick, 'SUPERUSER');

  try {
    require Devel::MAT::Dumper; 1
  } catch {
    my $err = "Attempted to dump heap but Devel::MAT could not be loaded: $_";
    logger->error($err);
    broadcast message => $msg->context, $msg->channel, $err;
    undef
  } or return PLUGIN_EAT_ALL;

  my $fname = $core->var . '/dump.' . time . '.pmat' ;
  logger->info("Dumping heap to '$fname'");
  broadcast message => $msg->context, $msg->channel,
    "Dumping heap file to 'var' dir . . .";
  Devel::MAT::Dumper::dump( $fname );

  PLUGIN_EAT_ALL
}

1;
__END__
=pod

=head1 NAME

Bot::Cobalt::Plugin::Extras::Debug - Dump internal state information

=head1 SYNOPSIS

  !plugin load Bot::Cobalt::Plugin::Extras::Debug

  # Dump full config hash to log:
  !dumpcfg

  # Dump langset to log:
  !dumplangset

  # Dump server state to log:
  !dumpservers

  # Dump miscellaneous state (core->State) to log:
  !dumpstate

  # Dump current timer pool to log:
  !dumptimers

  # Dump memory state for inspection (requires Devel::MAT):
  !dumpheap

=head1 DESCRIPTION

This is a simple development tool allowing developers to dump the 
current contents of various core attributes to STDOUT for inspection.

All commands are restricted to superusers.

References are displayed using L<Data::Dumper>.

Dumping memory state requires L<Devel::MAT>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut

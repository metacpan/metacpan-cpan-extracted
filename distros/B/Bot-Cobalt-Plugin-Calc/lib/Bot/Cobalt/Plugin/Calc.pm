package Bot::Cobalt::Plugin::Calc;
$Bot::Cobalt::Plugin::Calc::VERSION = '0.004005';
use strictures 2;

use List::Objects::WithUtils;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use Bot::Cobalt::Plugin::Calc::Session;

use POE;

sub SESSID () { 0 }
sub CALC   () { 1 }

sub new { 
  bless [
    undef,                                    # SESSID
    Bot::Cobalt::Plugin::Calc::Session->new,  # CALC
  ], shift 
}

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  my $sess = POE::Session->create(
    object_states => [
      $self => +{
        _start      => 'px_start',
        issue_calc  => 'px_issue_calc',
        calc_result => 'px_calc_result',
        calc_error  => 'px_calc_error',
      },
    ],
  );
  $self->[SESSID] = $sess->ID;

  register( $self, SERVER => 'public_cmd_calc' );
  logger->info("Loaded: calc");
  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  $poe_kernel->post( $self->[CALC]->session_id, 'shutdown' );
  $poe_kernel->refcount_decrement( $self->[SESSID], 'Plugin loaded' );
  logger->info("Unloaded");  
  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_calc {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${ $_[0] };

  my $msgarr  = $msg->message_array;
  my $calcstr = join ' ', @$msgarr;
  my $hints = hash(
    context => $msg->context,
    channel => $msg->channel,
    nick    => $msg->src_nick,
  )->inflate;

  logger->debug("issue_calc '$calcstr'");
  $poe_kernel->call( $self->[SESSID], issue_calc => $calcstr, $hints );
  
  PLUGIN_EAT_NONE
}


sub px_start {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->refcount_increment( $_[SESSION]->ID, 'Plugin loaded' );
  $self->[CALC]->start;
}

sub px_issue_calc {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  logger->debug("got issue_calc, relaying to CALC");
  $kernel->post( $self->[CALC]->session_id, calc => @_[ARG0, ARG1] )
}

sub px_calc_result {
  my ($kernel, $self)  = @_[KERNEL, OBJECT];
  my ($result, $hints) = @_[ARG0, ARG1];
  logger->debug("got calc_result");
  broadcast( message => $hints->context, $hints->channel,
    $hints->nick . ": $result"
  );
}

sub px_calc_error {
  my ($kernel, $self)  = @_[KERNEL, OBJECT];
  my ($error, $hints) = @_[ARG0, ARG1];
  # if this is a bad-args warn there's no hints hash - but then it's also a
  # bug and should warn() from ::Calc::Session
  return unless keys %$hints;

  broadcast( message => $hints->context, $hints->channel,
    $hints->nick . ": backend error: $error"
  );
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Calc - Calculator plugin for Bot::Cobalt

=head1 SYNOPSIS

  # See Math::Calc::Parser ->
  !calc 2 + 2
  !calc 0xff << 2
  !calc int rand 5

=head1 DESCRIPTION

A L<Bot::Cobalt> calculator plugin using L<Math::Calc::Parser>.

See the L<Math::Calc::Parser> documentation for details on acceptable
expressions.

=head1 CAVEATS

This plugin uses a "safe-ish" forked worker to do the actual calculations,
with resource limits in place to avoid denial-of-service attacks via large
factorials and similar. Not all platforms support all relevant
L<BSD::Resource> rlimits, however, in which case it may be possible to force
the bot to perform very large calculations.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

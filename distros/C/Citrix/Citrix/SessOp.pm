package Citrix::SessOp;
#use strict;
#use warnings;

our $VERSION = "0.25";

=head1 NAME

Citrix::SessOp - Disconnect or Logoff from an existing Citrix Session.

=head1 DESCRIPTION

Control Citrix session state by launching associated command line utilities.
The module user should take care of gaining authority to (by host/user,
whatever) execute these commands successfully on Citrix Farm as the
current process runtime user (It seems Citrix commands and associated protocol map the user
1-to-1 to the server end). Lacking this permission the commands will fail.

Module aims to provide proper return values and error messages
when things fail, but this is not a substitute for first taking care of
of proper permissions (for lauching Citrix commands) with your local Citrix Admin.

=head1 SYNOPSIS

  use Citrix::SessOp;
  my $fms = Citrix::getfarms('idx' => 1);
  my $farmctx = $fms->{'cairo'};
  my $csop = Citrix::SessOp->new($farmctx);
  
  # Disconnect (leaves session idle, to "returnable" state)
  $err = $csop->disconnect("the-cx-host-12:8879");
  
  # Log Off Completely (Terminating UNIX X-Windows session)
  $err = $csop->logoff("the-cx-host-12:8879");

=head1 METHODS

=head2 $csop = Citrix::SessOp->new($farmctx);

Create a new Citrix session operation by L<Citrix::Farm> context ($farmctx).
The ops available later are disconnect() / logoff() (See method docs on each for details).
Return session operation instance.

=cut
sub new {
   my ($class, $fc) = @_;
   #my ($h, $sid) = split(/:/, $hostsess);
   if (!$fc) {return(undef);}
   return(bless({ 'fc' => $fc}, $class)); # 'hs' => $hostsess,
}


=head2 $err = $cop->disconnect("the-cx-host-12:8879");

Disconnect a Citrix session By Host Session ID ($hostsess in format "$hostname:$sessid").
Disconnect persists the session state (leaves applications in the state they were before disconnect).
Return 0 for success, 1 (and up) for errors.

=cut

sub disconnect {
   my ($op, $hostsess) = @_;
   opexec($op, $hostsess, 'ctxdisconnect');
   
}

=head2 $err = $cop->logoff("the-cx-host-12:8879");

Logoff from a Citrix session By Host Session ID ($hostsess in format "$hostname:$sessid").
Logging off completely destroys the session state (closes apps and terminates X-Windows session).
Return 0 for success, 1 (and up) for errors.

=cut
sub logoff {
   my ($op, $hostsess) = @_;
   opexec($op, $hostsess, 'ctxlogoff');
}

# Internal accessor to Get/Set Farm context of a Citrix Operation.
sub fc {
   my ($op, $fc) = @_;
   if ($fc) {$op->{'fc'} = $fc;}
   $op->{'fc'};
}

# Internal method for executing Citrix Operation by launching associated command $cmd.
# Not part of public API, do not use this directly. Please use the wrapper methods disconnect() and
# logoff() as operations.
# Return 0 for success, 1 for failure.
sub opexec {
   my ($op, $hostsess, $cmd) = @_;
   #my ($h, $sid) = split(/:/, $hostsess);
   #my ($h, $sid) = split(/:/, $op->{'hs'});
   my $tout = $Citrix::touts->{'op'}; # 5;
   my $fc = $op->fc();
   #if (!$fc) {die("No Farm Context for operation");}
   my $mh = $fc->masterhost(); # OLD: {'mh'}
   #if (!$mh) {die("No Master host for Farm");}
   if (!$Citrix::binpath) {die("Citrix binary path is NOT set !!!");}
   my $clcmd = "$Citrix::binpath/$cmd";
   # Allow configuring Command to be local
   my $wcmd = "rsh $mh $clcmd $hostsess";
   #OLD:system($wcmd);
   eval {
      local $SIG{'ALRM'} = sub {die("Error Controlling session '$hostsess' within timelimit ($tout s.)\n");};
      alarm($tout);
      $op->{'msg'} = `$wcmd`;
   };
   alarm(0);
   if ($? || $@) {$op->{'msg'} = "Error $? / $! ($op->{'msg'}) Executing Session command '$wcmd'\n";return(1);}
   #else {$op->{'msg'} = "$op->{'msg'}";}
   # Consider the Error Indicators (Any others ?)
   if ($op->{'msg'} =~ /^Access/) {return(1);}
   # If no message is gotten expect it to be successful (is this correct assumption ?).
   # One of commands does not return any message
   if (!$op->{'msg'}) {$op->{'msg'} = "Operation Successful";}
   return(0);
}

1;

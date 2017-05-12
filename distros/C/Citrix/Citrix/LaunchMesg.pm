package Citrix::LaunchMesg;
#use strict;
#use warnings;

use Storable ('dclone');
our $VERSION = '0.25';

# TODO:
# - Create a more precise description of what (keys) is in the session config sections
# DONE:
# - Now use accessors on Farm
# - Generate message into a string, no direct output.

=head1 NAME

Citrix::LaunchMesg - Generate Citrix session launch messages in format understood by Citrix Desktop Clients.

=head1 DESCRIPTION
 
Citrix::LaunchMesg Has methods for both initiating a totally new session and reconnecting
to an existing session. Depends on Net::DNS to resolve server hostname to IP Address
(convention used in Citrix launch messages).

For now please look into the file session_template.pl within module distro to learn about
launch message sections used for constructing the launch message (by Citrix::LaunchMesg::new()).

=head1 SYNOPSIS

   use Citrix::LaunchMesg;
   # Get "all farms" configuration (as indexed hash)
   my $fms = Citrix::getfarms('idx' => 1);
   
   # Pick Farm to launch session on
   my $fc = $fms->{'istanbul'};
   # (Perl hash) default-valued Templates for launch message sections
   my %sections = ('client' => $client, 'app' => $app, );
   my $clm = Citrix::LaunchMesg->new($fc, %sections);
   # Launch a new session (by Domain, Username, CitrixApp)
   my $err = $clm->setbalanced('hypertechno', 'joecitrix', 'DESKTOP-UNIX');
   # Send "launch.ica" to web browser to be processed by wfcmgr Citrix desktop client app.
   # When set via HTTP in a web application Need to add respective http headers
   # within application. Use 'application/x-ica' to launch Citrix client helper app. 
   print $clm->output();
   
   
   # ... Connect to existing session (after Citrix::LaunchMesg->new(...))
   # You should do app level checks that this session actually belongs to user launching it.
   # However the Citrix authentication phase still prevents abuse.
   $clm->sethostappsess("good-old-host-22:3567");
   print $clm->output();

=head1 METHODS

=cut




our ($foo, $bar);
# Keyword param Attributes of constructor for templates
our @tattr = ('client','app',);
# Translations for section names from runtime names to INI-section labels used in message
our %sectheads = ('client' => 'WFClient', 'app' => '',  'enc' => 'Encoding',  '' => '', );

=head2 my $clm = Citrix::LaunchMesg->new($farmctx, %opt);

Constructor for launch Message by Farm Context $farmctx, templates for various sections of
Citrix Launch message. This may later serve for launching a truly new session or connecting to
existing one. Options (%opt) are:

=over 4

=item client - Client Config section

=item app - Application Config section

=item inputenc - Input Encoding (optional, default: 'InputEncoding' => 'ISO8859_1')

=back

For an example / quick reference on above section see file 'session_template.pl' in source distribution.

=cut

sub new {
   my ($class, $fc, %c) = @_;
   my $lm = {
   	  'fc' => $fc,
      'enc'  => {'InputEncoding' => 'ISO8859_1',},
      'appx' => {},
      'appserv' => {$c{'appserv'} => '',},
   };
   $fc || die("Farm Missing");
   # Validate  templates passid in %c to be hashes. Also test contents ?
   for (@tattr) {(ref($c{$_}) eq 'HASH') || die("No Template for $_ passed");}
   bless($lm, $class);
   # Grab copies of templates for instance specific tweaks
   @$lm{@tattr} = map({dclone($c{$_});} @tattr);
   if ($c{'inputenc'}) {$lm->{'enc'}->{'InputEncoding'} = $c{'inputenc'};}
   return($lm);
}
#sub ctxlaunch {my ($ctxt, $t_c, $t_as, $t_a, $capp) = @_;}

=head2 $clm->setbalanced($dom, $uid, $capp);

Initialize message state for launching a new load-balanced session for user $uid in Citrix
domain ($dom) by application name ($capp).
Domain string usually looks like Windows domain name (e.g. company name without spaces).
The launch message already contain Citrix Farm context (so does not need to be passed in here).
Use output() later to generate the actual message.
Returns 0 for success

=cut

sub setbalanced {
   my ($lm, $dom, $uid, $capp) = @_;
   my $fc = $lm->{'fc'};
   my $errstr;
   if (!$dom) {$errstr = "No Domain for new session"; goto ERROR;}
   if (!$uid) {$errstr = "No Username for new session"; goto ERROR;}
   if (!$capp) {$errstr = "No Application for new session"; goto ERROR;}
   my $t_c = $lm->{'client'};
   my $t_a = $lm->{'app'};
   $t_c->{'ClientName'} = "$dom-$uid";
   $t_a->{'Address'} = $capp;
   # Nest Browser info Into WFClient sect of launch message (looked up masterhost from Farminfo)
   my $mh = $fc->masterhost(); #OLD:{'mh'}
   my $ds = $fc->domainsuffix(); # #OLD: {'ds'}
   # Need to have masterhost address fully qualified for bulletproof function under all DNS / nameres. conditions
   # For now fix anything that contains dost to be combo of first (hostname) part and complete domain
   # This can be left in without hurting functionality
   if ($mh =~ /^([\w\-]+)\./) {$mh = "$1.$ds";}
   $t_c->{'TcpBrowserAddress'} = $mh;
   $t_c->{'HttpBrowserAddress'} = "$mh:8080";
   # Fill in proper app (repeated)
   $t_a->{'InitialProgram'} = "#$capp";
   $lm->{'appid'} = $capp;
   return(0);
   ERROR:
   $lm->{'errstr'} = $errstr;
   return(1);
}
# # 'cdom'... 'appid' ... 'userid' 

=head2 $clm->sethostappsess($hostsess);

Initialize message state for connecting to an existing session by passing host / session ID info
in $hostsess. $hostsess should be given in Citrix native notation "$host:$sessid".
Queries Citrix Application ID live from current farm, since this is required in message.
Use output() to generate the actual message
Returns 0 for success

=cut
sub sethostappsess {
   my ($lm, $hostsess) = @_; # NONEED: , $app
   my $errstr;
   my $t_c = $lm->{'client'};
   my $t_a = $lm->{'app'};
   my $fc = $lm->{'fc'};
   my ($host, $sid) = split(/:/, $hostsess);
   if (!$host || !$sid) {$errstr = "No Host or session passed"; goto ERROR;} # .Dumper($cgi)
   # We need Farm Context here to resolve host with full domain
   my $abshost = "$host.".$fc->domainsuffix(); # OLD:{'ds'}
   my @addr = dnsresolve($abshost); # SUPEROLD: $fc->{'ds'}
   if (!@addr)    {$errstr = "No Result for host ($abshost) search";goto ERROR;}
   if (@addr > 1) {$errstr = "Host '$abshost' Resolved to multiple addresses";goto ERROR;}
   if (!$addr[0]) {$errstr = "Not even single IP found for '$abshost'";goto ERROR;}
   $t_a->{'Address'} = $addr[0];
   # Need to fill in InitialProgram ?
   my $ss = Citrix::SessionSet->new($fc);
   $ss->gethostsess($host);
   my $sess = $ss->getsessbyid($hostsess);
   if (!$sess) {$errstr = "No Session by '$hostsess'";goto ERROR;}
   # NOW Resolve $capp by session
   my $capp = $sess->{'APPID'};
   if (!$capp) {$errstr = "No Application Found for $hostsess";goto ERROR;}
   #OLD:$t_as = {$capp, ''};
   $lm->{'appserv'} = {$capp, ''};
   $t_a->{'InitialProgram'} = "#$capp";
   $lm->{'appid'} = $capp;
   return(0);
   ERROR:
   $lm->{'errstr'} = $errstr;
   return(1);
}
=head2 $clm->output();

Generate, format and output the 4 sections of a Citrix launch message.
The sections internally accessed are 'client' (Citrix Client), 'app' (Citrix Application),
'appserv' (Citrix Application Server host).
Return none

=cut
sub output {
   my ($lm)  =@_;
   # Possibly encapsulate this to citrix launcher
   #inisect($ctxt::enc, "Encoding");
   #inisect($t_c, "WFClient");
   #inisect($t_as, "ApplicationServers");
   #inisect($t_a, $capp);
   my $t_c = $lm->{'client'};
   my $t_a = $lm->{'app'};
   my $t_as = $lm->{'appserv'};
   ###############################
   my $OUT = '';
   $OUT .= inisect($lm->{'enc'}, "Encoding");
   $OUT .= inisect($t_c, "WFClient");
   $OUT .= inisect($t_as, "ApplicationServers");
   #????:inisect($t_a, $capp);
   $OUT .= inisect($t_a, $lm->{'appid'});
   #OLD:print($OUT);
   return($OUT);
}

# ????
#sub initas {   
#}

# Internal method for Generic INI-section creation.
# Create section with name $n (in [...]) followed by key-value pairs from %{$rn->{$n}} or directly from %$rn
sub inisect {
   my ($rn, $n) = @_;
   # Try looking up sub-node, fallback on node itself
   my $h = $rn->{$n} ? $rn->{$n} : $rn;
   my $OUT = "[$n]\r\n";
   $OUT .= join('', map({"$_=$h->{$_}\r\n"} sort(keys(%$h))), "\r\n");
   #OLD:print($OUT);
   return($OUT);
}

# Internal method to find out IP address for a host by name.
# Could use Citrix-based resolution to make more independent from (non-core) Perl Modules
sub dnsresolve {
   my ($host, $dom) = @_;
   my @addr = ();
   require Net::DNS;
   my $resv  = Net::DNS::Resolver->new();
   my $usehost = $dom ? "$host.$dom" : $host;
   my $query = $resv->search($usehost);
   if (!$query) {return(undef);}
   for my $rr ($query->answer()) {
      if ($rr->type eq "A") {push(@addr, $rr->address());}
   }
   return(@addr);
}
1;

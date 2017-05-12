package Citrix::SessionSet;
use Data::Dumper;
#use strict;
#use warnings;

our $VERSION = "0.25";

# TODO: Allow loading sessions from perl cache file or DB for mock testing
# # http://support.citrix.com/proddocs/index.jsp?topic=/ps-unix/ps-unix-cmd-ref-commands-ctxquery.html

=head1 NAME

Citrix::SessionSet - Query UNIX Citrix Sessions from a Citrix Farm.

=head1 DESCRIPTION

Citrix::SessionSet Allows querying:

=over 4

=item 1) All sessions on farm (multiple, typically 2-8 hosts, by "farm context")

=item 2) Sessions on a single host (by DNS hostname)

=item 3) Sessions for an individual user (by username).

=back

Parses output from Citrix command line tools to Perl objects.
The module tries to do its best to deal with traditional problems
of sub-shell execution (command piping) and remote shelling (rsh).

A UNIX Citrix "application" is usually a complete Desktop environment, but may
also be single app like X-Terminal, Mail Client or Word processor.

=cut




# Use -f for short format opts -o For long fmt options
# See p. 234 in Citrix Guide
# d = 'DEVICE' (client)
# i = 'HOST:ID' (Combo of host+sessid)
# I = 'IDLE TIME'
# S = STATE
# u = USER
# x = X display number
# s = 'SERVER NAME'
# l = LOGON TIME
# p = APPLICATION NAME published app (APPID)

=head1 CLASS VARIABLES

=head2 $Citrix::SessionSet::ctxcols

Column format string 

=head2 @Citrix::SessionSet::ctxattr

Citrix Session set attributes (matching the letters in $ctxcols format string).
These turn into hash keys in the sessionset collection.

=head2 $Citrix::SessionSet::debug

Class level "global" debugging level (Notice that also instance has a debug flag). Set to true to
troubleshoot Citrix::SessionSet retrieval.

=cut


# The path of Citrix Command line utilities.
# This is used as a path prefix for commands to eliminate runtime guesswork.
#OLD: our $Citrix::binpath = "/opt/CTXSmf/bin";
# 
our $debug = 0;
# Default Col layout of ctxquery
our $ctxcols = "iSupd"; #  t
# Arributes to use in the session collection (mapping to tab output format
# specifiers above). Notice col format specifiers in $ctxcols and this should match.
my @ctxattr = ('HOST_SID','STATE','USERNAME','APPID','DEVICE',); #'TYPE'
# OLD Unused: Legacy Default Citrix Query Timeout
#our $tout = 5;

# Provide a better alias (to use in API)
*Citrix::SessionSet::usersessions = \&Citrix::SessionSet::mysess;


=head1 METHODS

=head2 my $ss = Citrix::SessionSet->new($farmctx);

Construct a new Citrix session collection.
Indicate Farm context of query by $fc (See L<Citrix::Farm>).
Return empty session set (to be queried later)

=cut

sub new {
   my ($class, $fc) = @_;
   #OLD:my $ss = [];
   if (!%$fc) {print("Session::new() : NO FC");return(undef);}
   my $ss = {'sarr' => [], 'fc' => $fc};
   bless($ss, $class);
   return($ss);
}

=head2 $err = $ss->gethostsess('the-cx-host-67');

Get all sessions for a single host (passed as $host) and load the sessions (adding them) into
session set instance.
Return 1 for errors, 0 on success.

=cut
sub gethostsess {
   my ($ss, $host) = @_;
   my $sarr = $ss->getsessions();
   my $fh;
   my $ap = '';
   my $fc = $ss->farmctx();
   my $mh = $ss->getmh(); # $fc->masterhost();
   my $ds = $fc->domainsuffix(); # OLD: {'ds'}
   my $cnt = scalar(@$sarr);
   my $usehost; # Final Host to use for query
   my $tout = $Citrix::touts->{'host'}; # 10;
   my @times = ();
   my $trace = debug($ss);
   if ($trace && $ENV{'HTTP_HOST'}) {print("<pre>");}
   #if ($host =~ /\./) {die("Expecting bare hostname (got: $host)");}
   if (!$host) {$usehost = $mh;$ap = ' -S';}
   elsif ($ds) {$usehost = "$host.$ds";} 
   my $cmd = "rsh $usehost $Citrix::binpath/ctxquery -f $ctxcols $ap"; # -S
   # Added loading of Net::Ping to circumvent
   eval {require(Net::Ping);};
   if ($@) {} # print("Dont have Net::Ping (risk hanging)");
   else {
      my $p = Net::Ping->new();
      if ($p->ping($usehost)) {if ($trace) {print("$usehost is alive (reachable by PING).\n");}}
      # Reuse $tout as state variable
      else {$tout = 0;}
      $p->close();
      if (!$tout) {$ss->{'msg'} = "$usehost NOT Alive.\n";return(1);}
   }
   if ($trace) {print("Launch Query: $cmd\n");$times[0] = time();}
   eval {
      local $SIG{'ALRM'} = sub {
      	 die("RSH Timeout ($usehost)\n");
      	 die("Host '$usehost' was unable to return session within $tout\n");
      };
      #local $SIG{'CHLD'} = sub {die("Child ($usehost)\n");};
      alarm($tout);
      if ($trace) {print("Opening Pipe ...\n");}
      my $ok = open($fh, "$cmd |");
      if (!$ok) {die("Failed to open the pipe");}
      if ($trace) {print("Opened: '$cmd' (as $< / $>)\n");}
      
   };
   # Enforce reset in a place which is always visited
   alarm(0);
   if ($trace) {$times[1] = time();print("Done Trying (Success, ",($times[1]-$times[0])," s.)\n");}
   
   if ($trace) {print("Reset Timeout ($tout => 0)\n");}
   if ($@) {$ss->{'msg'} = $@;return(2);}
   if ($trace) {print("Parse Query (From: $fh)\n");}
   parse($fh, $sarr, \@ctxattr);
   my $cnt2 = scalar(@$sarr);
   if ($host) {
      my $cd = ($cnt2 - $cnt);
      $ss->{'stat'}->{$host}->{'cnt'} = $cd;
      #if (!$cd) {$ss->{'stat'}->{$host}->{'out'} = "$!";}
   }
   if ($trace && $ENV{'HTTP_HOST'}) {print("</pre>\n");}
   return(0);
}

=head2 $err = $ss->getsession('the-cx-host-67:5234');

Get a session identified by $hostsess string (HOST:SESSID) from session set
(Involves sequential search within session set as sessions are not
indexed in current version).
The composite key of form "HOST:SESSID" is required, because session set may contain
sessions from multiple hosts (With single farm context though).
Return the single identified session (as hash) or undef if no session by SESSID
is found.

=cut

sub getsession {
   my ($ss, $hostsess) = @_;
   my $sarr = $ss->getsessions();
   my (@s) = grep({$_->{'HOST_SID'} eq $hostsess} @$sarr);
   if (@s < 1) {$ss->errstr("No Sessions for $hostsess'' ");return(undef);}
   if (@s > 1) {$ss->errstr("Multiple session for Identified session '$hostsess'");return(undef);}
   #ORG:return((@s == 1) ? $s[0] : undef);
   return($s[0]);
}

=head2 $err = $ss->mysess('joecitrix');

Load sessions for single user (by username) into session set.
Usually loading takes place on an empty set to have truly the sessions for individual only.
This can be used to create "My Sessions" views, but this is just "Sessions for User by ID".
Return 1 (and up) for errors 0, for success.

=cut
sub mysess {
   my ($ss, $userid) = @_;
   my $sarr = $ss->getsessions();
   my $mh = $ss->getmh();
   if (!$mh) {print("No Host to query from (master host for Farm)\n");return(1);}
   if (!$userid) {print("Err: No User passed for getting sessions\n");return(1);}
   my $cmd = "rsh $mh $Citrix::binpath/ctxquery -f $ctxcols -S user $userid"; # -S
   if ($ss->debug()) {print("<pre>$< / $>:  $cmd</pre>\n");}
   my $fh;
   my $tout = $Citrix::touts->{'user'}; # 5;
   local $SIG{'ALRM'} = sub {
   	  #  'cx86-bh-1.bh' was not able respond within given timilimit
   	  #die("Query Timeout after $tout s. (sig: '$_[0]', masterhost '$mh')");
   	  die("Citrix server '$mh' (master) was not able respond within given timilimit ($tout s.)");
   };
   alarm($tout);
   eval {
      my $ok = open($fh, "$cmd |");
      if (!$ok) {die("Failed to open the pipe");}
   };
   alarm(0);
   if ($@) {print("Failed: $@");return(3);}
   my $err = parse($fh, $sarr, \@ctxattr, 2);
   return(0);
}

# Access (Set/Get) all session from session set.
# Return session.
sub getsessions {
   my ($ss, $set) = @_;
   if (defined($set)) {$ss->{'sarr'} = $set;}
   return($ss->{'sarr'});
}

# Get the master host of farm context related to session set.
# Return master host name.
sub getmh {
   my ($ss) = @_;
   $ss->{'fc'}->masterhost(); # OLD: {'mh'}
}

# Deprecated. See farmctx
#sub getfc {
#   $_[0]->{'fc'};
#}

# Get the complete Farm context node for current session set.
# Return Farm Context node.
sub farmctx {
   if (@_ >= 2) {$_[0]->{'fc'} = $_[1];}
   $_[0]->{'fc'};
}

=head2 my $cnt = $ss->count();

Accessor method to get the number of sessions stored in current session set.
Return the (integer) count.

=cut
sub count {
   my ($ss) = @_;
   my $sarr = $ss->getsessions();
   return(scalar(@$sarr));
}

# See getsession()
sub getsessbyid {
   my ($ss, $hostsess) = @_;
   my $sarr = $ss->getsessions();
   my (@s) = grep({$_->{'HOST_SID'} eq $hostsess} @$sarr);
   if (scalar(@s) == 1) {return($s[0]);}
   return(undef);
}

# Toggle debug mode on in session set collection.
# This may be used in various contexts to produce more verbose output.
# Also class level (non-instance) debug flag is probed to find out
# the desired debug level.
# As a setter this can only affect the instance level debug setting.
sub debug {
   my ($ss, $lv) = @_;
   if (defined($lv)) {$ss->{'debug'} = $lv;}
   return($ss->{'debug'} || $debug);
}
sub errstr {
   my ($ss, $es) = @_;
   if (defined($es)) {$ss->{'errstr'} = $es;}
   $ss->{'errstr'};
}
# Parse output from Citrix Command pipe fiehandle $fh to $arr (which will be filled with hashes).
# Space delimited fields will be parsed into attributes @$attr in hashes.
# This parser is (sofar) applicable to all the possible outputs from
# Citrix commands returning tabular sets.
# For internal use only. Not part of exposed API.
# Return 0 (indicating success)
sub parse {
   my ($fh, $arr, $attr, $scnt) = @_;
   if (!$scnt) {$scnt = 0;} # To keep warnings silent
   # Discard heading line
   <$fh>;
   if ($scnt > 1) {for (2..$scnt) {<$fh>}}
   my $i = 0;
   my $spcnt = scalar(@$attr);
   # Consider error message from Citrix server
   my $ere = qr/Session\s+info/; # not available
   while (<$fh>) {
      # Check early
      if (/$ere/) {last;}
      chomp();
      s/^\s+//;
      if (!$_) {next;}
      my @a = split(/\s+/, $_, $spcnt);
      my %h;
      @h{@$attr} = @a;
      # Separate this to a parser hook ?
      @h{'HOST', 'SID'} = split(/:/, $h{'HOST_SID'});
      $h{'APPID'} =~ s/^#//;
      # Never care about STATE=listen,conn - Not here
      push(@$arr, \%h);
      $i++;
   }
   close($fh);
   return(0);
}


# Internal: Extract Host Statistics Information from a session set (total number,
# distributions of various session states).
# Return Host Statistics (Hash of hashes).
sub hin {
   my ($ss) = @_;
   my $sarr = $ss->getsessions();
   my %hosts;
   map({
      $hosts{$_->{'HOST'}}->{'tot'}++;
      $hosts{$_->{'HOST'}}->{$_->{'STATE'}}++;
   } @$sarr);
   # Update Names into stats
   for (keys(%hosts)) {$hosts{$_}->{'host'} = $_;}
   return(\%hosts);
}

1;

#__END__
# =head2 NOTES
# 

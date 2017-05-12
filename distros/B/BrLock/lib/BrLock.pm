#!/usr/bin/perl -w
#!/usr/local/bin/perl -w

package BrLock; 

=head1 NAME 

BrLock - Distributed Lock with minimal messages exchanges 
over a reliable network. 

=head1 SYNOPSIS

 BrLock->new('cfg_file', # configuration file, (see DESCRIPTION).
            '127.0.0.1', # this node's ip.
  	    3001);       # port to be bound to this node.

 BrLock->br_lock(); 
 # enter critical region
 BrLock->br_unlock(); 

=head1 DESCRIPTION

BrLock features a distributed lock, using the algorithm
Carvalho and Roucariol, On mutual exclusion in computer networks,
ACM Communications, Feb83.

The algorithm features minimal messages for acquiring the next lock,
but with the trade-off of network being reliable enough to ensure that
all nodes are alive. In fact, one node won't be able to acquire the
next lock if it can't communicate to all other nodes (unless the node
which was the last one to acquire the lock).

If this is a hard constraint for you, you may want to use IPC::Lock.

The list containing all nodes that may apply for this lock must be
described in the configuration file passed as parameters to the 
environment builder (see SYNOPSIS). The file must be as this:

 0 0
 0.0.0.0 0
 x.x.x.x  port
 y.y.y.y  port
 ...

The first line must have two zeros, and the second  must have the 
0.0.0.0 ip and the 0 port (deprecated parameters, see TODO). The 
next lines must have a node ip and a node port. All nodes must use
the same configuration file, so a node will read its own 
parameters. 

A valid cfg_file for BrLock->new('cfg_file', '127.0.0.1', 3001), 
for an environment with 3 nodes, is: 
 0 0
 0.0.0.0 0
 127.0.0.1 3002
 127.0.0.1 3001
 127.0.0.1 3003

Note the networking setup will be made by this module. So, after
calling Br->new, the node will be listening at 127.0.0.1:3001 in
the above example. 


=head1 TODO

=over

=item * Accept entire configuration as parameters thus not requiring 
a configuration file. 

=item * Switch to PerlOO, so multiple locks can be used at once. 

=back

=head1 AUTHORS

Ribamar Santarosa <ribamar@gmail.com>

Tarcisio Genaro <cuervojonas@gmail.com>

=head1 SEE ALSO

<IPC::Lock>

=cut 




use IO::Socket; 
use Switch; 
use threads; 
use threads::shared; 
use XML::Parser;
use BrLock::BrXML;               # shipped toghether with this. 
use BrLock::SomePerlFunc;        # shipped toghether with this. 
use warnings;
use diagnostics;

use strict;
use base 'Exporter';

our $VERSION =  0.1_00; 
our @ISA     =  qw(Exporter);
our @EXPORT  =  qw(br_lock br_unlock br_free);


###
# General use constants. 
###
use constant DEBUG => 0; 
use constant TRUE => 1; 
use constant FALSE => 0; 
# max acceptance size for udp messages. It's not specified anywhere: 
use constant UDP_MSG_SIZE => 1024; 
# max random number for unknown tests (see file mutex.txt):
use constant TEST_RANDOM_NUMBER => 100000; 
# if we are not informed what are our ip number: 
use constant OUR_IP => "127.0.0.1"; 
#use constant OUR_IP => "143.106.73.160"; 
# if we are not informed what are our ip port: 
use constant OUR_PORT => 3002; 


####
# Global variables
### 

our $debug;          # to print debug info. 
our $our_port; 
our $our_ip; 
# file where to read config options. 
our $config_file; 

# variables to be filled with configuration data. 
our ( $s,             # max waiting time for a requisition. 
      $t,             # max resource use time.  
      $our_id,        # our site ID.
      %resource_info, # resource is any site. see the definition of
	              # this hash in the info below. 
):shared; 

# The list of sites is defined as a list of Hashes 
# ( Site => $u , Port => $v , SiteId => $cur_siteid,
# AuthBy => TRUE or FALSE, RepDeferred => TRUE or FALSE )
# -- FALSE default for both; $cur_siteid -> current line number
# in the config_file (see below) the first line in the file has line
# number = -1. 
  
our @sites:shared = ();  # list of sites in the kidding(see info below).  
our $osn:shared = 0;     # timestamp for our messages.

###
# Global protocol variables (we'll go to hell for using globals). Note
# this doesn't mean the procotol won't use the other globals. In an 
# implemented class, these are private values. 
###

our @baffer:shared = ();     # buffer of received messages. 
our $n_auth:shared = 0; # how many sites gave us auth (to optmized wait).
our $hsn:shared = 0;    # max known timestamp. 
our $inside:shared = FALSE;  # are we using the resource?
our $waiting:shared = FALSE; # are we waiting for the resource? 
our $br_end;                 # when set threads finish. 

###
# Protocol constants. 
###

use constant BR_REP => 0; # reply message.
use constant BR_REQ => 1; # request message. 


# parse_cfgfile(f):
#  parse the configuration file f and set the globals: 
#  $s, $t, @sites. 
# The function assumes being ran only once. Undocumented 
# behaviour if ran more than once. 
#
#  Parameters: the config file name.
#
#  Returns:
#  0 -> success
#  a string cotaining a message error (TODO not that good).
#
# TODO: not really a general function. this function is 
# really a br_function as it set up br_ data structures. 
#
sub parse_cfgfile {
	my $file =  $_[0]; 
	#TODO: untested change
	my $line; 
	my $F; 
	return "File $file not found.\n" unless open $F, $file; 
	return "Nothing in file $file.\n" 
	                    unless (defined $F and $line = <$F>); 
	# first line: $s $t
	return "Can't parse first line of the config file $file.\n" 
	             unless ($line =~ m/([^ ]+)[ ]+([^ ]+)[ ]*$/gi); 
	$s = $1;
	chomp ($t = $2); 
	# the rest of the file: folks in the kidding. 
	my $cur_siteid = 0;
	while($line = <$F>){
		 if($line =~ m/([^ ]+)[ ]+([^ ]+)[ ]*$/gi){
			 my ($u, $v); 
			 $u = $1; 
			 chomp ($v = $2);
			 if ( ($v eq $our_port) and ($u eq $our_ip) ){
				 # we've found our identification. 
				 $our_id = $cur_siteid; 
			 }
			 else{
				 my $ha = &share({});
				 $ha->{Site} = $u;
				 $ha->{Port} = $v; 
				 $ha->{SiteId} =  $cur_siteid;
				 $ha->{AuthBy} =  FALSE;
				 $ha->{RepDeferred} = FALSE; 
				 push @sites, $ha ; 
			 }
			 $cur_siteid++;
		 }
		 else {
			 return "Can't parse config file $file.\n";
		 }
	}
	close $F; 
	# transferring resource information from @sites into its hash:  
	my $ri = shift @sites; 
	share(%resource_info); 
	%resource_info = ( Site => $ri->{Site}, 
		Port => $ri->{Port}, 
		SiteId => $ri->{SiteId}
	); 
	return 0; 
}



###
# Protocol functions. The names of these functions start 
# with "br_", which recalls "Brazilian", which in turn recalls
# other things.  
### 

#sub br_send(msg_type, receiver, osn):
#  Send the message $msg_type (which must be BR_REP or BR_REQ), 
#  to $receiver, saying that our timestamp is $osn. 
#
#  $receiver must be an element of the list @sites (a hash as defined
#  in the definition of the @sites array). 
#  
#  If everything was OK (well, we can't know if the package was
#  received, we assume as OK if we can send it), returns 0. Else, we
#  return 1. 
#

sub br_send {
	my ($msg_type, $receiver, $osn) = @_; 
	# Prepare the XML message (Just remeber: No XML parsing here!). 
	$msg_type = "REP" if ($msg_type eq BR_REP); 
	$msg_type = "REQ" if ($msg_type eq BR_REQ); 
	if ($msg_type ne "REQ" and $msg_type ne "REP"){
		# ops:  bad argument passed... 
		print "br_send(): \$msg_type must be either BR_REP ".
		"or BR_REQ.\n" if $debug;
		return 1;
	}
	my $xml_str = xmlmessage_brpack ($msg_type, $our_id, $osn, 
		         choose_integer(TEST_RANDOM_NUMBER) );
	# Send a TCP pkg w/ the XML message to $receiver's host:port.
	return 0 if send_tcp_string ($xml_str, 
		         $receiver->{Site}, $receiver->{Port});
	return 1; # problems in send_tcp_string... 
}

# br_xml_to_brdata(xml_str): 
#    converts the xml_str string returning a list ($msg, $j, $k) ---
#    $msg being one of (BR_REP, BR_REQ). This list is ready to be used
#    as parameter list to br_functions such br_receiving or br_send. 
#
# Uses Globals:
#    @sites (read only).
#
# TODO: verify return values. (undef, again?) / sanity tests. 
#

sub br_xml_to_brdata {
	my $xml_str = $_[0]; 
	my ($type, $site_id, $site_sequence, $random) = 
	     xmlparse_brmsg ($xml_str);
	my ($msg, $j, $k) = 0; 
	# setting $msg...
	$msg = BR_REP if ($type eq "REP"); 
	$msg = BR_REQ if ($type eq "REQ"); 
	if ($type ne "REQ" and $type ne "REP"){ 
		# ops:  xmlparse_brmsg went wrong... 
		print "br_xml_to_brdata(): Message must be either \"REQ\"".
			 " or \"REP\".\n" if $debug;
		return undef; 
	}
	# searching for a site $j with $site_id in @sites...
	foreach my $dummy_var ( @sites ){
		if ( $dummy_var->{SiteId} eq $site_id){
			$j = $dummy_var; 
			last; 
		}
	}
	if ( $j->{SiteId} ne $site_id){
		# ops:  fail, can't find this site_id in @sites; 
		print "Can't find site_id = [$site_id] in \@sites.\n" if $debug;
		return undef; 
	}
	# setting $msg...
	$k = $site_sequence; 
	# returning...
	return ($msg, $j, $k); 
}

# sub inside():
#  returns TRUE if this host is in the moment in the critical region
#  or FALSE if not. 
sub inside {
	return $inside; 
}

# sub waiting():
#  returns TRUE if this host is in the moment waiting to enter
#  the critical region; FALSE if not. 
sub waiting {
	return $waiting; 
}


# br_n_auth():
#  returns the number of sites we already got authorization. 
sub br_n_auth {
	my $vr = 0; 
	lock @sites; 
	foreach my $j (@sites) {
		if ($j->{AuthBy}){ 
			$vr++;
		}
	}
	return $vr; 
}

# sub br_wanna_resource():
#  when we find ourselves wondering how the life would be if we had
#  the resource, we start this function (probably as a new thread). 
#  Note only one instance of this function must be running at any
#  time, or strange things may happen. I don't know if the
#  responsability of checking that falls under the implementation of
#  this function; never count on it. 
#
#  No parameters. No return codes. 
# 
#  TODO: NOTE: this function was split into br_lock() and br_unlock().


sub br_lock{
	$waiting = TRUE; 
	$osn = $hsn + 1; 
	foreach my $j (@sites) {
		if (not $j->{AuthBy}){ 
			br_send (BR_REQ, $j , $osn); 
			print "br_wanna:send(REQ,  $j->{Site}:$j->{Port}, $osn)\n"
			if $debug; 
		}
	}
	my $na = br_n_auth();  
	# waiting for all sites to give us auth. 
	while ($na < @sites ){
		$na = br_n_auth();  
	}
	$inside = TRUE; 
	$waiting = FALSE; 
}

sub br_unlock{
	$inside = FALSE; 
	foreach my $j (@sites) {
		if ($j->{RepDeferred}){  
			$n_auth--  if $j->{AuthBy}; 
			$j->{RepDeferred} = ($j->{AuthBy} = FALSE); 
			br_send (BR_REP, $j , $osn); 
			print "br_wanna:send(REP,  $j->{Site}:$j->{Port}, $osn)\n"
			     if $debug; 
		}
		else{
			print "br_wanna:undeferred $j->{Site}:$j->{Port}.\n"
			     if $debug; 
		}
	}
}


#sub br_receiving(msg, j, k):
# When $j has sent us a message $msg (which must be BR_REP or BR_REQ),
# with timestamp $k, this function must be called to process it. Do
# not multithread it; instead, use a buffer to handle the messages
# received (the algorithm presumes it process the messages in a fifo). 

sub br_receiving {
	my ($msg, $j,  $k) = @_; 
	#TODO: untested change
	my $priority; 
	#debug if we are receiving correctly the parameters. After
	#tested, we must remove up to the return and let things to happen!
	print "br_rec:****($msg,  $j->{Site}:$j->{Port}, $k)\n" if $debug; 
	$hsn = ( $k > $hsn ?  $k : $hsn ) + 1; 
	print "br_rec:k=$k, osn=$osn, hsn=$hsn, n=$n_auth\n" if $debug; 
	switch ($msg){
		case BR_REQ {
			$priority = 
			(($k > $osn) or 
			            ( ($k==$osn) and ($our_id < $j->{SiteId}) ) );
			# if we feel we are better than the guy sending message, we
			# kick out him.
			if ( $inside or ($waiting and $priority) ){
				print "br_rec:inside (k=$k)\n" if $debug and $inside; 
				print "br_rec:priority and waiting(k=$k)\n" 
				           if $debug and $priority and $waiting; 
				print "br_rec: deferred $j->{Site}:$j->{Port})\n" 
				                                             if $debug; 
				$j->{RepDeferred} = TRUE; 
				#TODO: realy return? 
				return;
			}
			# We lose the authorization from the guy and gently give
			# him the BR_REP beucase we don't have enough priority. 
			#TODO: if (     (not ($inside or $waiting)) or: 
			# this  $inside seems to be a tautology. 
			if (     (not ($inside or $waiting)) or 
				     ( ($waiting) and 
					   (not $priority) and 
					   (not $j->{AuthBy})
				     )
			   ) {
				   print "br_rec:(not inside||wait) (k=$k)\n" if $debug 
					                   and (not ($inside or $waiting)); 
				   print "br_rec: not \$j->{AuthBy} (k=$k)\n" if $debug 
				                       and ($inside or $waiting); 
			           print "br_rec:send(REP,  $j->{Site}:$j->{Port})\n" 
				                                             if $debug; 
				   $n_auth-- if $j->{AuthBy}; 
				   $j->{AuthBy} = FALSE; 
				   br_send (BR_REP, $j , $osn); 
				   # Shouldn't we ask again REQ once we're waiting?
				   # Nope: if we're waiting and we haven't get auth
				   # yet, we're in his RepDeferred list and the guy 
				   # will somehow send us the auth in the future. 
				   return;
			}
			# We lose the authorization from the guy and gently give
			# him the BR_REP because he has greatest priority, but we
			# ask him to give us BR_REP as soon as possible, in order
			# of us to enter his RepDeferred list. 
			if ( ($waiting) and 
				 (not $priority) and 
				 ($j->{AuthBy})
			   ) {
				   print "br_rec: \$j->{AuthBy} (k=$k)\n" if $debug ; 
			       print "br_rec:send(REP, $j->{Site}:$j->{Port},$osn)\n" 
				                                             if $debug; 
			       print "br_rec:send(REQ, $j->{Site}:$j->{Port},$osn)\n" 
				                                             if $debug; 
				   $n_auth--  if $j->{AuthBy}; 
				   $j->{AuthBy} = FALSE; 
				   br_send (BR_REP, $j , $osn); 
				   br_send (BR_REQ, $j , $osn); 
				   return;
			}
		}
		case BR_REP {
			# huuuuhhuuu... one more auth... 
			$n_auth++  if not $j->{AuthBy}; 
			print "br_rec: REP ($j->{Site}:$j->{Port}, $k)\n"
			                                           if $debug ; 
			$j->{AuthBy} =  TRUE; 
			return;
		}
	}
}

# sub br_handle_received(baffer):
#  this function calls br_receiving() for all elements in the global
#  buffer @baffer, respecting the order (@baffer is a buffer of raw
#  XML messages). However, this function doesn't stop if the buffer 
#  is empty: this function will run forever, waiting new messages 
#  in the buffer and calling br_receiving() for these new messages. 
#  

# TODO: threads should never run forever, but test if an attribute 
# saying that the application is over is set. 

sub br_handle_received {
# do:
# shift the first element from buffer (loop/next if empty).
# parse it. 
# pass it to br_receiving. 
# loop.
	$| = 1; 
	while (not $br_end) {
		my $xml_str = shift @baffer; 
		#print "($xml_str)\n" if $xml_str; 
		br_receiving (br_xml_to_brdata($xml_str)) if $xml_str;
	}
}

# br_listen(): 
#  thread that accepts incomming connections, and bufferizes them 
#  into @baffer. 

# we're a "server", running 'till the end of the times, waiting for
# xml messages. 

# TODO: threads should never run forever, but test if an attribute
# saying that the application is over is set. 

sub br_listen{
 while (not $br_end) {
	 my ($sock) = @_; 
	 # printf "welcome br_listen.\n"; 
	 my $new_connect = $sock->accept(); 
	 # printf "newly connected.\n"; 
	 my $rec_msg = ""; 
	 while(<$new_connect>){
		 $rec_msg .= $_; 
	 }
	 push @baffer, $rec_msg if $rec_msg; 
	 $rec_msg = FALSE; 
 }
	 # printf "connect finished.\n"; 
}


###
# New.
###



####
# Global variables
### 

sub new{
	# OO stuff. 
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class; 

	# config. vars. 
	$config_file =  $_[0]; 
	$our_port =     $_[1]; 
	$our_ip =       $_[2]; 

	# config. vars. 
	$s = 0; 
	$t = 0; 
	$our_id = 0; 
	%resource_info = (); 
	@sites = (); 

	# protocol vars. 
	$osn = 0;  
	@baffer = ();     
	$n_auth = 0; 
	$hsn = 0;    
	$inside = FALSE;  
	$waiting = FALSE; 

	$br_end = 0; 

	$BrXML::brxml_debug = $debug = DEBUG; 

	parse_cfgfile($config_file); 

	my $sock = new IO::Socket::INET ( 
			LocalPort 	=> $our_port, 
			Proto       => 'tcp',
			Listen		=> 1,
			Reuse		=> 1, 

			); 


	# start the thread for handling rec messages. 
	# " pop @baffer, $xml_msg "
	threads->new(\&br_handle_received); 

	# start the thread to accept connections, to receive
	# messages  "push @baffer, $rec_msg "
	threads->new(\&br_listen, $sock);
} 

sub br_free{
	# TODO: find some way to stop threads. 
	# print "br_free(): about to set \$br_end.\n" if $debug;
	# $br_end = 1; 
	# print "br_free(): \$br_end set.\n" if $debug;
}

1; 


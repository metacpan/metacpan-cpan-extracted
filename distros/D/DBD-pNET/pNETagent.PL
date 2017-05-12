# Hej, Emacs, please give us -*- perl -*- mode

# We do not distribute pNETagent directly, instead we extract it
# from here by inserting the local Perl path into the first line,
# so that "#!/path/perl" works.

use Config;
use File::Basename qw(&basename &dirname);
# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
if ($Config{osname} eq 'VMS' or $Config{osname} eq 'os2') { # "case-forgiving"
    $file =~ s/\.pl$//;
}

open OUT,">$file" or die "Can\'t create $file: $!";

print "Extracting $file (with variable substitutions)\n";

#
# Start of pNETagent
#

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w
!GROK!THIS!

print OUT <<'!NO!SUBS!';
#
#   DBD::pNET - DBI network driver
#
#   pNETagent - this is the server
# 
# 
#   Copyright (c) 1997  Jochen Wiedmann
#
#   Based on DBD::Oracle, which is
#
#   Copyright (c) 1994,1995,1996,1997 Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.
#
#
#   Author: Jochen Wiedmann
#           Am Eisteich 9
#           72555 Metzingen
#           Germany
# 
#           Email: wiedmann@neckar-alb.de
#           Phone: +49 7123 14881
# 
# 
#   $Id: pNETagent.PL,v 1.1.1.1 1997/09/19 20:34:23 joe Exp $
#

require 5.004;
use strict;
require Sys::Syslog;
require IO::File;
require IO::Socket;
require RPC::pServer;
require DBI;
require DBD::pNET;


############################################################################
#
#   Constants
#
############################################################################

my $VERSION          = $DBD::pNET::VERSION;
   $VERSION          = $DBD::pNET::VERSION;  # Hate -w ...
my $DEFAULT_PID_FILE = '/tmp/pNETagent.pid';
$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin';
delete $ENV{'ENV'};


############################################################################
#
#   Global variables
#
############################################################################

my $debugging = 0;       # Debugging mode on or off (default off)
my $forking = 1;         # Debugging: Suppress forking
my $stderr = 0;          # Log to syslog or stderr (default syslog)
my $pidFile = '';        # Name of PID file; could be a local variable, but
                         # perhaps we use SIGHUP some day
my $commandLine = '';    # Command line, we are currently executing


############################################################################
#
#   Name:    Msg, Debug, Error, Fatal
#
#   Purpose: Error handling functions
#
#   Inputs:  $msg - message being print, will be formatted with
#                sprintf using the following arguments
#
#   Result:  Fatal() dies, Error() returns without result
#
############################################################################

sub Msg ($$@) {
    my $level = shift;
    my $msg = shift;
    if ($stderr) {
	printf STDERR ($msg, @_);
    } else {
        Sys::Syslog::syslog($level, $msg, @_);
    }
}

sub Debug ($@) {
    if ($debugging) {
	my $msg = shift;
	Msg('debug', $msg, @_);
    }
}

sub Error ($@) {
    my $msg = shift;
    Msg('err', $msg, @_);
}

sub Fatal ($@) {
    my $msg = shift;
    Msg('crit', $msg, @_);
    exit 10;
}


############################################################################
#
#   Name:    ClientConnect
#
#   Purpose: Create a dbh for a client
#
#   Inputs:  $con - server object
#            $ref - reference to the entry in the function table
#                being currently executed
#            $dsn - data source name
#            $uid - user
#            $pwd - password
#
#   Result:  database handle or undef
#
############################################################################

sub ClientConnect ($$$$$) {
    my ($con, $ref, $dsn, $uid, $pwd) = @_;
    my ($dbh);

    $con->Log('debug', "Connecting as $uid to $dsn");

    if ($uid ne $con->{'user'}) {
	$con->{'error'} = "Nice try, to connect as " . $con->{'user'}
	   . " and login as $uid. ;-)";
	$con->Log('notice', $con->error);
	return (0, $con->{'error'});
    }

    if (!defined($dbh = DBI->connect($dsn, $uid, $pwd))) {
	my $errMsg = $DBI::errstr;
	$con->{'error'} = "Cannot connect to database: $DBI::errstr";
	return (0, $con->{'error'});
    }

    my ($handle) = RPC::pServer::StoreHandle($con, $ref, $dbh);
    if (!defined($handle)) {
	return (0, $con->error); # StoreHandle did set error message
    }

    Debug("Created dbh as $handle.\n");
    return (1, $handle);
}


############################################################################
#
#   Name:    ClientMethod
#
#   Purpose: Coerce a method for a client
#
#   Inputs:  $con - server object
#            $ref - reference to the entry in the function table
#                being currently executed
#            $handle - object handle
#            $method - method name
#
#   Result:  database handle or undef
#
############################################################################

sub ClientMethod ($$$$) {
    my ($con, $ref, $handle, $method, @margs) = @_;
    my ($obj) = RPC::pServer::UseHandle($con, $ref, $handle);

    if (!defined($obj)) {
	return (0, $con->error); # UseHandle () stored an error message
    }

    # We could immediately map this to RPC::pServer::CallMethod(),
    # but certain methods need special treatment.
    if ($method eq 'STORE') {
	my ($key, $val) = @margs;
	$obj->{$key} = $val;
	Debug("Client stores value %s as attribute %s for %s",
	      defined($val) ? $val : "undef",
	      defined($key) ? $key : "undef", $handle);
	return (1);
    }
    if ($method eq 'FETCH') {
	my ($key) = @margs;
	my ($val) = $obj->{$key};
	Debug("Client fetches value %s as attribute %s from %s",
	      defined($val) ? $val : "undef",
	      defined($key) ? $key : "undef", $handle);
	return (1, $obj->{$key});
    }
    if ($method eq 'DESTROY') {
	RPC::pServer::DestroyHandle($con, $ref, $handle);
	Debug("Client destroys %s", $handle);
	return (1);
    }

    if (!$obj->can($method)) {
	$con->{'error'} = "Object $handle cannot execute method $method";
	Debug("Client attempt to execute unknown method $method");
	return (0, $con->error);
    }

    if ($method eq 'prepare') {
	my $statement = shift @margs;

	# Check for restricted access
	if ($con->{client}->{sqlRestricted}) {
	    if ($statement =~ /^\s*(\S+)/) {
		my $st = $1;
		if (!($statement = $con->{client}->{$st})) {
		    $con->{'error'} = "Unknown SQL query: $st";
		    return (0, $con->error);
		}
	    } else {
		$con->{'error'} = "Cannot parse restricted SQL statement";
		return (0, $con->error);
	    }
	}

	# We need to execute 'prepare' and 'execute' at once
	my $sth;
	if (!defined($sth = $obj->prepare($statement))) {
	    $con->{'error'} = "Cannot prepare: " . $obj->errstr;
	    return (0, $con->error);
	}

	# Handle binding parameters
	my $i = 0;
	while (@margs) {
	    my ($value) = shift @margs;
	    my ($type) = shift @margs;
	    Debug("Binding parameter: Type $type, Value $value");
	    if (!($sth->bind_param(++$i, $value, $type))) {
		$con->{'error'} = "Cannot bind param: " . $sth->errstr;
		return (0, $con->error);
	    }
	}

	if (!$sth->execute) {
	    $con->{'error'} = "Cannot execute: " . $sth->errstr;
	    return (0, $con->error);
	}

	my ($handle) = RPC::pServer::StoreHandle($con, $ref, $sth);
	if (!defined($handle)) {
	    return (0, $con->error); # StoreHandle did set error message
	}

	Debug("Prepare: handle $handle, fields %d, rows %d\n",
	      $sth->{'NUM_OF_FIELDS'}, $sth->rows);
	return (1, $handle, int($sth->{'NUM_OF_FIELDS'}), int($sth->rows));
    }
    if ($method eq 'execute') {
	# Handle binding parameters
	my $i = 0;
	while (@margs) {
	    my ($value) = shift @margs;
	    my ($type) = shift @margs;
	    if (!$obj->bind_param(++$i, $value, $type)) {
		$con->{'error'} = "Cannot bind param: " . $obj->errstr;
		return (0, $con->error);
	    }
	}

	if (!$obj->execute) {
	    $con->{'error'} = "Cannot execute: " . $obj->errstr;
	    return (0, $con->error);
	}
	Debug("Execute: handle $handle, rows %d\n", $obj->rows);
	return (1, $handle, $obj->rows);
    }
    if ($method eq 'fetch') {
	my $chopblanks = shift @margs;
	if (defined($chopblanks)  &&  $chopblanks) {
	    $chopblanks = 1;
	} else {
	    $chopblanks = 0;
	}
	$obj->{'ChopBlanks'} = $chopblanks;
	my $ref = $obj->fetchrow_arrayref;
	Debug("Fetch: handle $handle, %d fields, ChopBlanks = $chopblanks.\n",
	      defined($ref) ? scalar(@$ref) : 0, $chopblanks);
	return (1, (defined($ref) ? @$ref : ()));
    }

    #   Default method
    Debug("Client executes method $method");
    my ($result) = eval '$obj->' . $method . '(@margs)';
    if ($@) {
	$con->{'error'} = "Error while executing $method: $@";
	return (0, $con->error);
    }
    if (!$result) {
	$con->{'error'} = "Error while executing $method: " . $obj->errstr;
    }
    (1);
}


############################################################################
#
#   Name:    Server
#
#   Purpose: Server child's main loop
#
#   Inputs:  $server - server object
#
#   Result:  Nothing, never returns
#
############################################################################

sub Server ($) {
    my ($server) = shift;
    my (%handles);

    # Initialize the function table
    my ($funcTable) = {
	'connect' => { 'code' => \&ClientConnect, 'handles' => \%handles },
	'method'  => { 'code' => \&ClientMethod, 'handles' => \%handles }
    };
    $server->{'funcTable'} = $funcTable;

    while (!$server->{'sock'}->eof()) {
	if ($server->{'sock'}->error()) {
	    exit(1);
	}
	if (!$server->Loop()) {
	    Error("Error while communicating with child: " . $server->error);
	}
    }
    exit(0);
}


############################################################################
#
#   Name:    Usage
#
#   Purpose: Print usage message
#
#   Inputs:  None
#
#   Returns: Nothing, aborts with error status
#
############################################################################

sub Usage () {
    print STDERR "Usage: $0 [options]\n\n",
    "Possible options are:\n",
    "    -p <port> |             Set port number where the agent should\n",
    "    -port <port> |          bind to. This option is required, no\n",
    "    --port <port>           defaults set.\n",
    "    -i <ip-number>          Set ip number where the agent should\n",
    "    -ip <ip-number>         bind to. Defaults to INADDR_ANY, any\n",
    "    --ip <ip-number>        local ip number.\n",
    "    -cf <file> |            Set the name of the configuration file\n",
    "    -configFile <file> |    that the agent should read upon startup.\n",
    "    --configFile <file>     This file contains host based authori-\n",
    "                            zation and encryption rules and the\n",
    "                            like.\n",
    "    -nf | -noFork |         Supress forking, useful for debugging\n",
    "    --noFork                only.\n",
    "    -pf <file> |            Set the name of the file, where the\n",
    "    -pidFile <file> |       pNET agent will store its PID number,\n",
    "    --pidFile <file>        ip and port number and other information.\n",
    "                            This is required mainly for administrative\n",
    "                            purposes. Default is '/tmp/pNETagent.pid'.\n",
    "    -h | -help | --help     Print this help message.\n",
    "    -d | -debug | --debug   Turn on debugging messages.\n",
    "    -s | -stderr | --stderr Print debugging messages on stderr.\n",
    "                            defaults to syslog.\n",
    "    -v | -version |         Print version number and exit.\n",
    "    --version\n\n",
    "pNETagent $VERSION - the DBD::pNET agent, Copyright (C) 1997 Jochen",
        " Wiedmann\n",
    "see 'perldoc pNETagent' for additional information.\n";

    exit 0;
}


############################################################################
#
#   Name:    CreatePidFile
#
#   Purpose: Creates PID file
#
#   Inputs:  $sock - socket object being currently used by the server
#
#   Returns: Nothing
#
############################################################################

sub CreatePidFile ($) {
    my ($sock) = shift;
    my $fh = IO::File->new($pidFile, "w");
    if (!defined($fh)) {
	Error("Cannot create PID file $pidFile: $!");
    } else {
	$fh->printf("$$\nIP number: %s, Port number %s\n$commandLine\n",
		    $sock->sockhost, $sock->sockport);
	$fh->close();
    }
}


############################################################################
#
#   Name:    catchChilds
#
#   Purpose: Signal handler for SIGCHLD.
#
#   Inputs:  None
#
#   Returns: Nothing
#
############################################################################

sub catchChilds () {
    my $pid = wait;
    $SIG{'CHLD'} = \&catchChilds;  # Rumours say, we need to reinitialize
                                   # the handler on System V
}


############################################################################
#
#   This is main().
#
############################################################################

{
    # Read command line arguments
    my ($arg, $ip, $port, $configFile, $nofork);

    $commandLine = "$0 " . join(" ", @ARGV);
    $pidFile = $DEFAULT_PID_FILE;

    while ($arg = shift @ARGV) {
	if ($arg eq "-p"  ||  $arg eq "-port"  ||  $arg eq "--port") {
	    if (!defined($port = shift @ARGV)) { Usage(); }
	} elsif ($arg eq "-i"  ||  $arg eq "-ip"  ||  $arg eq "--ip") {
	    if (!defined($ip = shift @ARGV)) { Usage(); }
	} elsif ($arg eq "-cf"  ||  $arg eq "-configFile"  ||
		 $arg eq "--configFile") {
	    if (!defined($configFile = shift @ARGV)) { Usage(); }
	} elsif ($arg eq "-nf"  ||  $arg eq "-noFork"  ||
		 $arg eq "--noFork") {
	    $forking = 0;
	} elsif ($arg eq "-pf"  ||  $arg eq "-pidFile"  ||
		 $arg eq "--pidFile") {
	    if (!defined($pidFile = shift @ARGV)) { Usage(); }
	} elsif ($arg eq "-d"  ||  $arg eq "-debug"  ||  $arg eq "--debug") {
	    $debugging = 1;
	} elsif ($arg eq "-s"  ||  $arg eq "-stderr"  ||  $arg eq "--stderr") {
	    $stderr = 1;
	} elsif ($arg eq "-v"  ||  $arg eq "-version"  ||
		 $arg eq "--version") {
	    print("pNETagent $VERSION - the DBD::pNET agent, Copyright (C)",
		  " 1997 Jochen Wiedmann\n",
		  "see 'perldoc pNETagent' or 'pNetagent --help' for",
		  " additional information.\n");
	    exit 0;
	} elsif ($arg eq "-h"  ||  $arg eq "-help"  ||  $arg eq "--help") {
	    Usage();
	} else {
	    Usage();
	}
    }

    if (!defined($port)) {
	Usage();
    }


    #   Initialize debugging and logging
    if (defined(&Sys::Syslog::setlogsock)) {
        Sys::Syslog::setlogsock('unix');
    }
    Sys::Syslog::openlog('pNETagent', 'pid', 'daemon');
    Sys::Syslog::syslog('info', 'agent starting at %s, port %s',
			defined($ip) ? $ip : 'any ip number', $port);

    #   Create an IO::Socket object
    my $sock = IO::Socket::INET->new('Proto' => 'tcp',
				     'LocalPort' => $port,
				     'LocalAddr' => defined($ip) ? $ip : '',
				     'Reuse' => 1,
				     'Listen' => 5);
    if (!defined($sock)) {
	Fatal("Cannot create socket: $!");
    }


    #   Create the PID file
    CreatePidFile($sock);


    $SIG{'CHLD'} = \&catchChilds;

    #   In a loop, wait for connections.
    while (1) {
	#   Create a RPC::pServer object
	my $server = RPC::pServer->new('sock' => $sock,
					    'debug' => $debugging,
					    'stderr' => $stderr,
					    'configFile' => $configFile);
	if (!ref($server)) {
	    Error("Cannot create server object: $server");
	    next;
	}
	Debug("Client logged in: application = %s, version = %s, user = %s",
	      $server->{'application'}, $server->{'version'},
	      $server->{'user'});

	my ($client) = $server->{'client'};
	if (ref($client) ne 'HASH') {
	    Error("Server is missing a 'client' object.");
	    $server->Deny("Not authorized.");
	    next;
	}
	my $users = '';
	if ($client->{'users'}) {
	    # Ensure, that first and last user can match \s$user\s
	    $users = " " . $client->{'users'} . " ";
	}
	my $user = $server->{'user'};

	if ($server->{'application'} !~ /^DBI\:[^\:]+\:/) {
	    #   Whatever this client is looking for, it cannot be us :-)
	    Debug("Wrong application.");
	    $server->Deny("This is a DBD::pNET agent. Go away!");
	    undef $server;
	} elsif ($server->{'version'} > $VERSION) {
	    Debug("Wrong version.");
	    $server->Deny("Sorry, but I am running version"
			  . " $VERSION");
	} elsif ($users !~ /\s$user\s/) {
	    Debug("User not permitted.");
	    $server->Deny("You are not permitted to connect.");
	} else {
	    #   Fork, and enter the main loop.
	    my $pid;
	    if ($forking) {
		if (!defined($pid = fork())) {
		    Error("Cannot fork: $!.");
		    $server->Deny("Cannot fork: $!");
		}
	    }
	    if (!$forking ||  $pid == 0) {
		#   I am the child.
		Debug("Accepting client.");
		$server->Accept("Welcome, this is the DBD::pNET agent"
				. " $VERSION.");

		#
		#   Switch to user specific encryption
		#
		my $uval;
		if ($uval = $server->{'client'}->{$user}) {
		    if ($uval =~ /encrypt=\"(.*),(.*),(.*)\"/) {
			my $module = $1;
			my $class = $2;
			my $key = $3;
			my $cipher;
			eval "use $module;"
			    . " \$cipher = $class->new(pack('H*', \$key))";
			if ($cipher) {
			    $server->Encrypt($cipher);
			    $server->Log('debug', "Changed encryption to %s",
					 $server->Encrypt());
			} else {
			    $server->Log('err', "Cannot not switch to user"
					 . " specific encryption: $@");
			    exit(1);
			}
		    }
		}
		Server($server);
	    }
	}
    }
}

__END__

=head1 NAME

pNETagent - a Perl agent for the DBI network driver DBD::pNET

=head1 SYNOPSIS

  pNETagent -p <port> [<other options>]

=head1 DESCRIPTION

pNETagent is an agent for the DBI network driver, DBD::pNET. It allows
access to databases over the network if the DBMS does not offer 
networked operations. But pNETagent might be useful for you,
even if you have a DBMS with integrated network functionality: It
can be used as a DBI proxy in a firewalled environment.

pNETagent runs as a daemon on the machine with the DBMS or on the
firewall. The client connects to the agent using the DBI driver DBD::pNET,
thus in the exactly same way than using DBD::mysql, DBD::mSQL or any other
DBI driver.

The agent is implemented as a RPC::pServer application. Thus you
have access to all the possibilities of this module, in particular
encryption and a similar configuration file. pNETagent adds the possibility
of query restrictions: You can define a set of queries that a client may
execute and restrict access to these. See L</CONFIGURATION FILE>.

=head1 OPTIONS

The following options can be used when starting pNETagent:

=over 4

=item C<-cf filename>

=item C<-configFile filename>

=item C<--configFile filename>

The pNETagent can use a configuration file for authorizing clients.
The file is almost identical to that of DBD::pNET::Server, with the
exception of an additional attribute I<users>. See L</CONFIGURATION
FILE>.

=item C<-d>

=item C<-debug>

=item C<--debug>

Turns on debugging mode. Debugging messages will usually be logged
to syslog with facility I<daemon> unless you use the option C<-stderr>.
See below.

=item C<-h>

=item C<-help>

=item C<--help>

Tells the pNETagent to print a help message and exit immediately.

=item C<-i ip-number>

=item C<-ip ip-number>

=item C<--ip ip-number>

Tells the pNETagent, on which ip number he should bind. The default is,
to bind to C<INADDR_ANY> or any ip number of the local host. You might
use this option, for example, on a firewall with two network interfaces.
If your LAN has non public IP numbers and you bind the pNET agent to
the inner network interface, then you will easily disable the access
from the outer network or the Internet.

=item C<-p port>

=item C<-port port>

=item C<--port port>

This option tells the pNETagent, on which port number he should bind.
Unlike other applications, pNETagent has no builtin default, so you
using this option is required.

=item C<-pf filename>

=item C<-pidFile filename>

=item C<--pidFile filename>

Tells the daemon, where to store its PID file. The default is
I</tmp/pNETagent.pid>. pNETagent's PID file looks like this:

    567
    IP number 127.0.0.1, port 3334
    pNETagent -ip 127.0.0.1 -p 3334

The first line is the process number. The second line are IP number
and port number, so that they can be used by local clients and the
third line is the command line. These can be used in administrative
scripts, for example to first kill the pNETagent and then restart
it with the same options you do a

    kill `head -1 /tmp/pNETagent.pid`
    `tail -1 /tmp/pNETagent.pid`

=item C<-s>

=item C<-stderr>

=item C<--stderr>

Forces printing of messages to stderr. The default is sending messages
to syslog with facility I<daemon>.

=item C<-v>

=item C<-version>

=item C<--version>

Forces the pNETagent to print its version number and copyright message
and exit immediately.

=back

=head1 CONFIGURATION FILE

pNETagent's configuration file is just that of I<RPC::pServer> with
some additional attributes. Currently its own use is authorization
and encryption.

=head2 Syntax

Empty lines and comment lines (starting with hashes, C<#> charactes)
are ignored. All other lines have the syntax

    var value

White space at the beginning and the end of the line will be removed,
so will white space between C<var> and C<val> be ignored. On the other
hand C<value> may contain white space, for example

    description Free form text

would be valid with C<value> = C<Free form text>.

=head2 Accepting and refusing hosts

Semantically the configuration file is a collection of host definitions,
each of them starting with

    accept|deny mask

where C<mask> is a Perl regular expression matching host names or IP
numbers (in particular this means that you have to escape dots),
C<accept> tells the server to accept connections from C<mask> and
C<deny> forces to refuse connections from C<mask>. The first match
is used, thus the following will accept connections from 192.168.1.*
only

    accept 192\.168\.1\.
    deny .*

and the following will accept all connections except those from
evil.guys.com:

    deny evil\.guys\.com
    accept .*

Default is to refuse connections, thus the C<deny .*> in the first
example is redundant, but of course good style.

=head2 Host based encryption

You can force a client to use encryption. The following example will
accept connections from 192.168.1.* only, if they are encrypted with
the DES algorithm and the key C<0123456789abcdef>:

    accept 192\.168\.1\.
        encryption DES
        key 0123456789abcdef
        encryptModule Crypt::DES

    deny .*

You are by no means bound to use DES. pNETagent just expects a certain
API, namely the methods I<new>, I<keysize>, I<blocksize>, I<encrypt>
and I<decrypt>. For example IDEA is another choice. The above example
will be mapped to this Perl source:

    $encryptModule = "Crypt::DES";
    $encryption = "DES";
    $key = "0123456789abcdef";

    eval "use $encryptModule;"
       . "$crypt = \$encryption->new(pack('H*', \$key));";

I<encryptModule> defaults to <encryption>, this is only needed because
of the brain damaged design of I<Crypt::IDEA> and I<Crypt::DES>, where
module name and class name differ.

=head2 User based authorization

The I<users> attribute allows to restrict access to certain users.
For example the following allows only the users C<joe> and C<jack>
from host C<alpha> and C<joe> and C<mike> from C<beta>:

    accept alpha
        users joe jack

    accept beta
        users joe mike

=head2 User based encryption

Although host based encryption is fine, you might still wish to force
different users to use different encryption secrets. Here's how it
goes:

    accept alpha
        users joe jack
        jack encrypt="Crypt::DES,DES,fedcba9876543210"
        joe encrypt="Crypt::IDEA,IDEA,0123456789abcdef0123456789abcdef"

This would force jack to encrypt with I<DES> and key C<fedcba9876543210>
and joe with I<IDEA> and C<0123456789abcdef0123456789abcdef>. The three
fields of the I<encrypt> entries correspond to the I<encryptionModule>,
I<encryption> and I<key> attributes of the host based encryption.

You note the problem: Of course user based encryption can only be
used when the user has already logged in. Thus we recommend to use
both host based and user based encryption: The former will be used
in the authorization phase and the latter once the client has logged
in. Without user based secrets the host based secret (if any) will
be used for the complete session.

=head2 Query restrictions

You have the possibility to restrict the queries a client may execute
to a predefined set.

Suggest the following lines in the configuration file:

    accept alpha
        sqlRestrict 1
        insert1 INSERT INTO foo VALUES (?, ?)
        insert2 INSERT INTO bla VALUES (?, ?, ?)

    accept beta
        sqlRestrict 0

This allows users connecting from C<beta> to execute any SQL query, but
users from C<alpha> can only insert values into the tables I<foo> and
I<bar>. Clients select the query by just passing the query name
(I<insert1> and I<insert2> in the example above) as an SQL statement
and binding parameters to the statement. Of course the client side must
know how much parameters should be passed. Thus you should use the
following for inserting values into foo from the client:

    my $dbh;
    my $sth = $dbh->prepare("insert1 (?, ?)");
    $sth->execute(1, "foo");
    $sth->execute(2, "bar");


=head1 AUTHOR

    Copyright (c) 1997    Jochen Wiedmann
                          Am Eisteich 9
                          72555 Metzingen
                          Germany

                          Email: wiedmann@neckar-alb.de
                          Phone: +49 7123 14881

You may distribute DBD::pNET and pNETagent under the terms of either the
GNU General Public License or the Artistic License, as specified in the
Perl README file, with the exception that it cannot be placed on a CD-ROM
or similar media for commercial distribution without the prior approval
of the author.

=head1 SEE ALSO

L<DBI(3)>, L<DBD::pNET(3)>, L<RPC::pServer(3)>,
L<RPC::pClient(3)>, L<Sys::Syslog(3)>, L<syslog(2)>

!NO!SUBS!

#
# End of pNETagent
#

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";

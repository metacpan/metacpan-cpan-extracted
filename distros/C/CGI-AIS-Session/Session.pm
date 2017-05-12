package CGI::AIS::Session;

 use strict;

use vars qw{ *SOCK @ISA @EXPORT $VERSION };

require Exporter;

 @ISA = qw(Exporter);
 @EXPORT = qw(Authenticate);

 $VERSION = '0.02';

use Carp;


use Socket qw(:DEFAULT :crlf);
use IO::Handle;
sub miniget($$$$){
	my($HostName, $PortNumber, $Desired, $agent)  = @_;
	$PortNumber ||= 80;
	my $iaddr	= inet_aton($HostName)	|| die "Cannot find host named $HostName";
	my $paddr	= sockaddr_in($PortNumber,$iaddr);
	my $proto	= getprotobyname('tcp');
							
	socket(SOCK, PF_INET, SOCK_STREAM, $proto)  || die "socket: $!";
	connect(SOCK, $paddr)    || die "connect: $!";
	SOCK->autoflush(1);

	print SOCK
		"GET $Desired HTTP/1.1$CRLF",
		# Do we need a Host: header with an "AbsoluteURI?"
		# not needed: http://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html#sec5.2
		# but this is trumped by an Apache error message invoking RFC2068 sections 9 and 14.23
		"Host: $HostName$CRLF",
		"User-Agent: $agent$CRLF",
		"Connection: close$CRLF",
		$CRLF;

	join('',<SOCK>);

};



sub Authenticate{

	my %Param = (agent => 'AISclient', @_);
	my %Result;
	my $AISXML;


	print STDERR "$$ Session coox: $ENV{HTTP_COOKIE}\n";
	my (@Cookies) = ($ENV{HTTP_COOKIE} =~  /AIS_Session=(\w+)/g);
	tie my %Session, $Param{tieargs}->[0],
	$Param{tieargs}->[1],$Param{tieargs}->[2],$Param{tieargs}->[3],
	$Param{tieargs}->[4],$Param{tieargs}->[5],$Param{tieargs}->[6],
	$Param{tieargs}->[7],$Param{tieargs}->[8],$Param{tieargs}->[9]
		or croak "failed to tie @{$Param{tieargs}}";

	print STDERR "Session database has ",scalar(keys %Session)," keys\n";

	my $Cookie;

	# make Cookie imply its validity
	push @Cookies, undef;
	while ($Cookie = shift @Cookies){
		#$Session{$Cookie} and last;
		if($Session{$Cookie}){
			print STDERR "Session $Cookie exists\n";
			last;
		}else{
			print STDERR "Session <$Cookie> false\n";

		};
	};	

	my $OTUkey;
	my $SessionKey;
	my ($PostKey) = ($ENV{QUERY_STRING} =~ /AIS_POST_key=(\w+)/);

	# if (!$Cookie and $ENV{REQUEST_METHOD} eq 'POST' ){
	# in general, whenever we've got the wrong name for the
	# server, it won't work.  So we need to redirect ourselves
	# back to here with the right name for the server, and
	# then we'll get our cookie, if we have one.
	if (!$Cookie and !defined($PostKey) ){
		# print STDERR "$$ Cookieless POST caught early\n";
		print STDERR "$$ possible wrong SERVER_NAME\n";
		if ($ENV{REQUEST_METHOD} eq 'POST' ){
			$PostKey = join('',time,(map {("A".."Z")[rand 26]}(0..9)));
			$Session{$PostKey} = join('',(<>));
		}else{
			$PostKey = '';
		};

		print "Location: http://$ENV{SERVER_NAME}$ENV{REQUEST_URI}?AIS_POST_key=$PostKey&$ENV{QUERY_STRING}$CRLF$CRLF";
		exit;
	};

	if ($PostKey){	# will be defined but false '' when servicing a GET
		pipe(POSTREAD,POSTWRITE) or die "Cannot create pipe: $!";
		if (fork){
			# we are in parent
			close POSTWRITE;
			open STDIN, "<&POSTREAD";
			$ENV{REQUEST_METHOD} = 'POST';

		}else{
			# in child -- write POSTdata to pipe and exit
			close STDOUT;
			close STDIN;
			close POSTREAD;
			print POSTWRITE '&',$Session{$PostKey};
			close POSTWRITE or die "$$: Error closing POSTWRITE\n";
			$Cookie and delete $Session{$PostKey};
			# exit;
			#POSIX:_exit(0); # perldoc -f exit
			exec '/usr/bin/true';
		};
	};

	if ($ENV{QUERY_STRING} =~ /AIS_OTUkey=(\w+)/){
	   $OTUkey = $1;
	   my ($method, $host, $port, $path) =
	     ($Param{aissri} =~ m#^(\w+)://([^:/]+):?(\d*)(.+)$#)
	      or die "Could not get meth,hos,por,pat from <$Param{aissri}>";
	   unless ($method eq 'http'){
		croak "aissri parameter must begin 'http://' at this time";
	   };

	   # my $Response = `lynx -source $Param{aissri}query?$OTUkey$CRLF$CRLF`
	   my $Response = miniget $host, $port,
	   "$Param{aissri}query?$OTUkey", $Param{agent};

	   $SessionKey = join('',time,(map {("A".."Z")[rand 26]}(0..19)));
	   # print "Set-Cookie: AIS_Session=$SessionKey; path=$ENV{SCRIPT_NAME};$CRLF";
	   print "Set-Cookie: AIS_Session=$SessionKey; path=/; expires=$CRLF";
	   ($AISXML) =
		$Response =~ m#<aisresponse>(.+)</aisresponse>#si
	   	   or die "no <aisresponse> element from $Param{aissri}query?$OTUkey\n";
	   $Session{$SessionKey} = $AISXML;

	}elsif (!$Cookie){
		my $PostString = '';
		# if ($ENV{REQUEST_METHOD} eq 'POST' and !eof){
		if ($ENV{REQUEST_METHOD} eq 'POST' ){
			print STDERR "$$ Cookieless POST\n";
			my $PostKey = join('',time,(map {("A".."Z")[rand 26]}(0..9)));
			$Session{$PostKey} = join('',(<>));
			$PostString = "AIS_POST_key=$PostKey&";

		};
		print "Location: $Param{aissri}present?http://$ENV{SERVER_NAME}$ENV{REQUEST_URI}?${PostString}AIS_OTUkey=\n\n";
		exit;
	}else{ # We have a cookie
		$AISXML = $Session{$Cookie};
		delete  $Session{$Cookie} if $ENV{QUERY_STRING} eq 'AIS_LOGOUT';
	};

	foreach (qw{
			identity
			error
			aissri
			user_remote_addr
		       },
		    @{$Param{XML}}
	){
	   	$AISXML =~ m#<$_>(.+)</$_>#si or next;
		$Result{$_} = $1;
	};

	if ( defined($Param{timeout})){
		my $TO = $Param{timeout};
		delete @Session{ grep { time - $_ > $TO } keys %Session };

	};

	#Suppress caching NULL and ERROR
	if( $Result{identity} eq 'NULL' or $Result{identity} eq 'ERROR'){
		print "Set-Cookie: AIS_Session=$CRLF";
	        $SessionKey and delete $Session{$SessionKey} ;

		$Param{nodie} or die "AIS: $Result{identity} identity $Result{error} error";

	};
	return \%Result;
};


# Preloaded methods go here.

1;
__END__

=head1 NAME

CGI::AIS::Session - Perl extension to manage CGI user sessions with external identity authentication via AIS

=head1 SYNOPSIS

  use DirDB;	# or any other concurrent-access-safe
		# persistent hash abstraction

  use CGI::AIS::Session;

  eval {
     my $Session = Authenticate(
             aissri <= 'http://www.pay2send.com/cgi/ais/',
             tieargs <= ['DirDB', './data/Sessions'],
	     XML <= ['name','age','region','gender'],
	     agent <= 'Bollow',	# this is the password for the AIS service, if needed
             # nodie <= 1,  # suppress exception-throwing (support version 0.01 behavior)
	     ( $$ % 100 ? () : (timeout <= 4 * 3600)) # four hours
     );
  };

  if ($@){
	my ($iden, $err) = $@ =~ /AIS: (.*) identity (.*) error/;

       	if($iden eq 'NULL'){
	   print "Location: http://www.pay2send.com/cgi/ais/login\n\n"
	   exit;
  	}elsif($iden eq 'ERROR'){
	   print "Content-type: text/plain\n\n";
	   print "There was an error with the authentication layer",
	         " of this web service: $err\n\n",
	         "please contact $ENV{SERVER_ADMIN} to report this.";
	   exit;
	
  	}else {
	   die "Unexpected exception thrown by Authenticate: $@";
	};
  };

  tie my %UserData, 'DirDB', "./data/$$Session{identity}";
 

=head1 DESCRIPTION

This module creates and maintains a read-only session abstraction based on data in
a central AIS server.

The session data provided by AIS is read-only.  A second
database keyed on the identity provided by AIS should be
used to store persistent local information such as shopping cart
contents. This may be repaired in future releases, so the 
session object will be more similar to the session objects
used with the Apache::Session modules, but for now, all the
data in the object returned by C<Authenticate> comes from the
central AIS server.

On the first use, the user is redirected to the AIS server
according to the AIS protocol. Then the identity, if any,
is cached
under a session key in the session database as tied to by
the 'tieargs' parameter.

This module will create a http cookie named AIS_Session.

Authenticate will croak on aissri methods other than
http in this version.

Additional expected XML fields can be listed in an XML parameter.

If a 'timeout' paramter is provided,  Sessions older than
the timeout get deleted from the tied sessions hash.

'ERROR' and 'NULL' identities are not cached.  In fact, they're
not even returned.  ERROR or NULL responses from the AIS server
will cause the Authenticate module to die, which is usually what
you want:  A good AIS server will keep the user until they
authenticate themselves instead of immediately serving a NULL
response.

You can suppress the dieing by specifying a true value for the
"nodie" parameter.  This makes the module compatible with any
software written around version 1.

Internally, the possible states of this system are:

no cookie because we're not accessing the server using the SERVER_NAME
no cookie, no OTU
OTU
cookie

The second two return a session object. The
first two cause redirection.

if a query string of AIS_LOGOUT is postpended to any url in the
domain protected by this module, the session will be deleted before
it times out.

=head1 ABOUT AIS

Authenticated Identity Service is a scheme for sharing single sign-on
identity (and possibly other information) with participating services 
on distributed equipment.  A compliant AIS server has three defined
methods, "present" which maps a user identity to a one-time-use ticket,
"query" which exchanges a block of AISXML for the corresponding ticket,
and "about" which provides a human-readable description of the policies
of the particular AIS server, such as how to log on, how to get an
account, what additional data is provided by it, what the privacy policy is,
how to become an affiliated  to it and use its authentication realm, and
if it is "hard" or "soft" and whether there is a corresponding AIS server
of the other flavor.

"hard" AIS will offer the user a log-in screen when they access the "present"
method without being logged in already.  "soft" ais merrily sets up an OTU ticket
for the NULL user and serves it.

=head1 EXPORTS

the Authenticate routine is exported.

=head1 AUTHOR

David Nicol, davidnico@cpan.org

=head1 SEE ALSO

http://www.pay2send.com/ais/ais.html

The Apache::Session family of modules on CPAN


=cut

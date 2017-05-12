package AIS::client;

use 5.006;
$VERSION = 0.07;
use Carp;

use DirDB 0.09; # or any other concurrent-access-safe
                # persistence abstraction
	        # that can store and retreive hash references
	        # and has a working DELETE method
	        #
	        # but if you change it, you'll also need to change
	        # the lines that refer to DirDB subsequently,
	        # including the tieing of %{"caller().'::AIS_STASH'}

sub miniget($$$$){
	my($HostName, $PortNumber, $Desired, $agent)  = @_;
	eval <<'ENDMINIGET';
	use Socket qw(:DEFAULT :crlf);
	$PortNumber ||= 80;
	$agent ||= "$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}";
	my $iaddr	= inet_aton($HostName)	|| die "Cannot find host named $HostName";
	my $paddr	= sockaddr_in($PortNumber,$iaddr);
	my $proto	= getprotobyname('tcp');

	socket(SOCK, PF_INET, SOCK_STREAM, $proto)  || die "socket: $!";
	connect(SOCK, $paddr)    || die "connect: $!";

	# SOCK->autoflush(1);
	my $ofh = select SOCK;
	$| = 1;
	select $ofh;
	my $Query = join("\r\n", # "CRLF"
		"GET $Desired HTTP/1.1",
		# Do we need a Host: header with an "AbsoluteURI?"
		# not needed: http://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html#sec5.2
		# but this is trumped by an Apache error message invoking RFC2068 sections 9 and 14.23
		"Host: $HostName",
		"User-Agent: $agent",
		"Connection: close",
		'','') ;
	print SOCK $Query  or croak "could not print to miniget socket";

	 join('',<SOCK>);

ENDMINIGET

}

sub housekeeping(){

	my @deletia;
	my $t = time;

	while(($k,$v) = each %Sessions){

		if ($v->{last_access} < ($t - $maxage)){
			push @deletia, $k
		};
	};

	@Sessions{@deletia} = ();
};

sub redirect($){
	print <<EOF;
Location: $_[0]
Content-Type: text/html

<HTML><HEAD><TITLE>Relocate </TITLE>
<META HTTP-EQUIV="REFRESH" CONTENT="1;URL=$_[0]">
</HEAD>
<BODY>
<A HREF="$_[0]">
<H1>Trying to relocate to $_[0]</H1>please click
here</A>.
</BODY></HTML>

EOF

};

sub import{
	shift;
	my %params = @_;

my $Coo;

 $ssl_ext = exists($ENV{SSL_CIPHER}) ? 's' : '';
 $freq = (defined($params{freq}) ? $params{freq} : 2000);
 $maxage = $params{maxage} || 72*60*60;
 $aissri = $params{aissri} || 'http://www.pay2send.com/cgi/ais/';
 $agent = $params{agent} || 
	"http$ssl_ext://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}";
 $SessionPrefix = $params{prefix} || 'AIS'; # 'AIS_session';

eval{
tie  %Sessions => DirDB => "${SessionPrefix}_sessions";
};
if($@){
	print <<EOF;
Content-Type: text/plain

AIS::client module was not able to open DirDB [${SessionPrefix}_sessions]

eval result:

$@

AIS::client version $VERSION

EOF

	exit;

};
	if($freq){
		 housekeeping unless ($$ % $freq)
	};

	if ($ENV{QUERY_STRING} eq 'LOGOUT'){
#	eval <<'LOGOUT';
		($Coo) = ($ENV{HTTP_COOKIE} =~ /${SessionPrefix}_session=(\w+)/)
			and 	delete $Sessions{$Coo};

		print <<EOF;
Set-Cookie:/${SessionPrefix}_session=
Content-Type: text/html

<html><head><title> LOGGED OUT </title></head>
<body bgcolor=ffffff>

Cookie cleared, you are logged out of "${SessionPrefix}"
<p>
<a href="${aissri}logout">
click here to log out of AIS service $aissri</a>

</body></html>
EOF

		exit;
# LOGOUT

	};


	# check for cookies
	($Coo) = ($ENV{HTTP_COOKIE} =~ /${SessionPrefix}_session=(\w+)/);
	if($Coo){
		# print "Content-Type: text/plain\n\n";
		# print "We have a cookie: $Coo\n";
		# print( %{$Sessions{$Coo}});
		# exit;
		# Do we have an identity?
		if (exists($Sessions{$Coo}->{identity}) and $Sessions{$Coo}->{identity} ne 'ERROR'){
			# most of the time, this is what we are expecting
			goto HAVE_ID ; # unless $Sessions{$Coo}->{identity} eq 'ERROR';
		}else{
			# eval <<'NOIDENTITYEVAL';
			# get an identity from the AIS server
			# (process might be underway already)
			if ($ENV{QUERY_STRING} =~ /^OTU_KEY=(\w+)/){
				# eval <<'HAVEOTUKEYEVAL';
				my $OTUkey = $1;
				# carp "have aissri [$aissri]";
				my ($method, $host, $port, $path) =
				   ($aissri =~ m#^(\w+)://([^:/]+):?(\d*)(.+)$#)
				      or die "Could not get meth,hos,por,pat from aissri <$aissri>";
				# carp "have \$method, \$host, \$port, \$path $method, $host, $port, $path";
				unless ($method eq 'http'){
					croak "aissri parameter must begin 'http://' at this time";
				};

				# issue the AIS QUERY request
				# carp "doing miniget $host, $port,${aissri}query?$OTUkey, $agent";

				my $Response = miniget $host, $port,
				  "${aissri}query?$OTUkey", $agent;

				# carp "got $Response";
				(my $AISXML) = 
				$Response =~ m#<aisresponse>(.+)</aisresponse>#si
				   or die "no <aisresponse> element from ${aissri}query?$OTUkey\n in BEGINRESPONSE\n$Response\nENDRESPONSE";
				$Sessions{$Coo}->{AISXML} = $AISXML;
				# parse AISXML...
				my %aisvar;
				foreach (qw{
					identity
					error
					aissri
					user_remote_addr
			       		}
					# ,@{$Param{XML}}
				){
					$AISXML =~ m#<$_>(.+)</$_>#si or next;
					$aisvar{$_} = $1;
					# print STDERR "ais var $_ is $1\n";
				};

				if ($aisvar{identity} eq 'NULL'){
redirect(
"$aisvar{aissri}add?RU=http$ssl_ext://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}$ENV{PATH_INFO}");
					exit;
				};

				# hooray! we have an identity.
				foreach (keys %aisvar){
					$Sessions{$Coo}->{$_} = $aisvar{$_};
				};

				#reconstruct initial form data if any
				$ENV{QUERY_STRING} = delete $Sessions{$Coo}->{QueryString};
				if(exists $Sessions{$Coo}->{PostData}){
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
						print POSTWRITE delete $Sessions{$Coo}->{PostData};
						close POSTWRITE or die "$$: Error closing POSTWRITE\n";
						# exit;
						#POSIX:_exit(0); # perldoc -f exit
						exec '/usr/bin/true';
					};
# HAVEOTUKEYEVAL
				};
				goto HAVE_ID;
			}else{
				# redirect us to AIS server PRESENT function

				redirect "${aissri}present?http$ssl_ext://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}$ENV{PATH_INFO}?OTU_KEY=";
				exit;


			};

# NOIDENTITYEVAL
		};
	}else{
		# no cookie.
		my $suffix = '';
		if($ENV{QUERY_STRING}eq'AIS_INITIAL'){
			# for when the first time we were called with the wrong host name.
			$suffix = 2;
		};
		$ENV{QUERY_STRING}eq'AIS_INITIAL2'and goto NOCOO;
		($Coo = localtime) =~ s/\W//g;
		my @chars = 'A'..'Z' ;
		substr($Coo, rand(length $Coo), 1) = $chars[rand @chars]
		foreach 1..8;
		print "X-Ais-Received-Request-Method: $ENV{REQUEST_METHOD}\n";
		print "X-Ais-Received-Query-String: $ENV{QUERY_STRING}\n";
		$Sessions{$Coo}->{QueryString} = $ENV{QUERY_STRING};
		$ENV{REQUEST_METHOD} =~ /POST/i and
		$Sessions{$Coo}->{PostData} = <>;

		print "Set-Cookie:/${SessionPrefix}_session=$Coo\n";
		redirect "http$ssl_ext://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}$ENV{PATH_INFO}?AIS_INITIAL$suffix";
		exit;
	};

	print <<EOF;
Content-Type: text/plain

internal AIS module logic error

EOF

	exit;






	NOCOO:
		print <<EOF;
Content-Type: text/plain

Cookies appear to be disabled in your web browser.

Cookie string: $ENV{HTTP_COOKIE}

This program uses a session and authentication system
(AIS, the Authenticated Identity Service)
that relies on cookies.

Please enable cookies and try again. (you may have to log in)

*******************************************************************

You appear to be using a $ENV{HTTP_USER_AGENT}
from $ENV{REMOTE_ADDR}
to access http$ssl_ext://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}
(this web server is adminned by $ENV{SERVER_ADMIN})

EOF
	exit;

	HAVE_ID:
	$Sessions{$Coo}->{last_access} = time;
	$Identity = $Sessions{$Coo}->{identity};
	if($Identity eq 'ERROR'){
		print <<EOF;
Content-type: text/plain

There was an error with the authentication layer
of this web service: $Sessions{$Coo}->{error}

please contact $ENV{SERVER_ADMIN} to report this.
EOF

     		exit;
	};


# print STDERR "setting ",caller().'::AIS_IDENTITY', " to $Sessions{$Coo}->{identity}\n";
# $ENV{AIS_IDENTITY} = $Sessions{$Coo}->{identity};
$ENV{AIS_IDENTITY} =
${caller().'::AIS_IDENTITY'} = $Sessions{$Coo}->{identity};
tie %{caller().'::AIS_STASH'}, DirDB => ${tied(%{$Sessions{$Coo}})};

}; # import

1;

__END__


1;
__END__

=head1 NAME

AIS::client - get an authenticated e-mail address for users of your web service

=head1 SYNOPSIS

  BEGIN{umask(0077 & umask())}; # if your web server gives you a 0177 umask
  use AIS::client;
  print "Content-type: text/plain\n\nWelcome $AIS_IDENTITY\n";
  print "this is page view number ", ++$AIS_STASH{accesses};
  __END__

=head1 DESCRIPTION

The goal of AIS::client is to provide a very easy way to require an
authenticated identity for a perl web application.  The user's e-mail
address appears in a global variable C<$AIS_IDENTITY> and a persistent
session stash is available in C<%AIS_STASH>.

=head1 USE-LINE CONFIGURATION OPTIONS

=item aissri

By default, AIS::client will refer to the AIS service defined
at http://www.pay2send.com/cgi/ais/ but an alternate AIS service
can be specified with the C<aissri> parameter:

   use AIS::client aissri => 'http://www.cpan.org/service/ais/';

=item agent

By default, AIS::client will give the URL of the webpage being
requested as the agent string, but an alternate agent string
can be specified with the C<agent> parameter:

   use AIS::client aissri => "Bob's web services: account MZNXBCV";

It is expected that a subscription-based or otherwise access-controlled
AIS service might issue expiring capability keys which would have to be
listed as part of the agent string.

=item prefix

By default, C<AIS>, which means that AIS::client will store session
data (incliding identity, which is also available as
C<$AIS_STASH{identity}>) in subdirectories under a directory
called C<AIS_sessions> under the current directory
your script runs in.  This can be changed with the C<prefix> parameter:

  use AIS::client prefix => '.AIS'; # hide session directory

The prefix is also used as the prefix for the session cookie name,
which defaults to C<AIS_session>.

=item freq

By default, AIS::client will examine the session directory for stale
sessions approximately once every 2000 invocations.  Adjust this
with the C<freq> parameter. C<0> will suppress housekeeping entirely.

=item maxage

Minimum time in seconds since C<$AIS_STASH{last_access}> that will
trigger session deletion at housekeeping time.  Defaults to C<72*60*60>.


=head1 ENDING SESSIONS

AIS::client recognizes a reserved QUERY_STRING of C<LOGOUT> which will
end a session, delete all session data, and offer the user a link to
the logout function of the specified AIS server so they can log out
of that too if they want.

=head1 HISTORY

=over 8

=item 0.05

	This is the first public AIS client module release with this
	interface, which is entirely different from the CGI::AIS::Session
	interface.

=item 0.06

	fixed the Makefile.pl to call in DirDB

=item 0.07

	installation problems due to permissions now go to the
	web browser instead of silently dying. 

	redirections now done with more portable REFRESH meta tags
	instead of (along with) less portable Location: headers

=back

=head1 SUPPORT

please use rt.cpan.org to report problems (and successes!) (And wishes!)

=head1 AUTHOR

David Nicol <davidnico@cpan.org>

=head1 SEE ALSO

L<CGI::Session::Auth> does something very similar.

L<CGI::AIS::Session> is now deprecated and replaced.

=cut

=head1 NAME

Authen::Libwrap - access to Wietse Venema's TCP Wrappers library

=head1 SYNOPSIS

  use Authen::Libwrap qw( hosts_ctl STRING_UNKNOWN );

  # we know the remote username (using identd)
  $rc = hosts_ctl(
    "programname",
	"hostname.domain.com",
	"10.1.1.1",
	"username"
  );
  print "Access is ", $rc ? "granted" : "refused", "\n";

  # we don't know the remote username
  $rc = hosts_ctl(
    "programname",
	"hostname.domain.com",
	"10.1.1.1"),
  );
  print "Access is ", $rc ? "granted" : "refused", "\n";

  # use a socket instead
  my $client = $listener->accept();
  $rc = hosts_ctl( "programname" $socket );
  print "Access is ", $rc ? "granted" : "refused", "\n";

=head1 DESCRIPTION

The Authen::Libwrap module allows you to access the hosts_ctl() function from
the popular TCP Wrappers security package.  This allows validation of
network access from perl programs against the system-wide F<hosts.allow>
file.

If any of the parameters to hosts_ctl() are not known (i.e. username due to
lack of an identd server), the constant STRING_UNKNOWN may be passed to
the function.

=begin testing

use Test::Exception;

use_ok('Authen::Libwrap');
Authen::Libwrap->import( ':all' );
ok( defined(&hosts_ctl), "'hosts_ctl' function is exported");
ok( defined(&STRING_UNKNOWN), "'STRING_UNKNOWN' constant is exported");

my $daemon = "tcp_wrappers_test";
my $hostname = "localhost";
my $hostaddr = "127.0.0.1";
my $username = 'me';

# these tests aren't very comprehensive because the path to hosts.allow
# is set when libwrap is built and I can't tell what the user's rules
# are.  I can make sure they don't croak, but I can't really tell
# if any call to hosts_ctl should give back a true or false value

# call with all four arguments explicitly
lives_ok { hosts_ctl($daemon, $hostname, $hostaddr, $username) }
    'call hosts_ctl with four explicit args';

# use a default user
lives_ok { hosts_ctl($daemon, $hostname, $hostaddr) }
    'call hosts_ctl without a username';

# give something that is blessed but not a IO::Socket
my $thingy = bless {}, 'Foo';
throws_ok { hosts_ctl($daemon, $thingy) }
    qr/can't use/, 'cannot use a non-socket as a socket';

# pass an IO::Socket that is not initialized
use IO::Socket::INET;
my $sock = IO::Socket::INET->new;
throws_ok { hosts_ctl($daemon, $sock) }
    qr/can't get peer/, 'call hosts_ctl an uninitialized IO::Socket';

# set up a listening socket and connect to it
my $listener;
lives_and {
    $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        Proto => 'tcp',
        Listen => 10,
    );
    isa_ok($listener, 'IO::Socket::INET');
} 'create listener socket';
lives_and {
    $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $listener->sockport,
        Proto => 'tcp'
    );
    isa_ok($sock, 'IO::Socket::INET');
} 'connect to listener';

# use an IO::Socket with a username
lives_ok { hosts_ctl($daemon, $sock, $username) }
    'call hosts_ctl with a glob and username';

# use an IO::Socket without a username
lives_ok { hosts_ctl($daemon, $sock) }
    'call hosts_ctl with a glob and username';

# close the IO::Socket
$sock->close;
throws_ok { hosts_ctl($daemon, $sock) }
    qr/can't get peer/, 'call hosts_ctl an uninitialized IO::Socket';

# try with an uninitialized glob 
throws_ok { hosts_ctl($daemon, *SOCK) }
    qr/can't get peer/, 'call hosts_ctl an uninitialized GLOB';

# connect to the listening socket
lives_and {
    my $proto = getprotobyname('tcp');
    socket(SOCK, PF_INET, SOCK_STREAM, $proto);
    my $iaddr = inet_aton('127.0.0.1');
    my $paddr = sockaddr_in($listener->sockport, $iaddr);
    connect(SOCK,$paddr);
} 'connect to listener';

# use a glob with a username
lives_ok { hosts_ctl($daemon, *SOCK, $username) }
    'call hosts_ctl with a glob and username';

# use a glob without a username
lives_ok { hosts_ctl($daemon, *SOCK) }
    'call hosts_ctl with a glob and username';

# close the glob
close SOCK;
throws_ok { hosts_ctl($daemon, *SOCK) }
    qr/can't get peer/, 'call hosts_ctl an uninitialized GLOB';

# try with an uninitialized globref 
throws_ok { hosts_ctl($daemon, \*SOCK) }
    qr/can't get peer/, 'call hosts_ctl an uninitialized GLOBREF';

# connect to the listening socket
lives_and {
    my $proto = getprotobyname('tcp');
    socket(SOCK, PF_INET, SOCK_STREAM, $proto);
    my $iaddr = inet_aton('127.0.0.1');
    my $paddr = sockaddr_in($listener->sockport, $iaddr);
    connect(SOCK,$paddr);
} 'connect to listener';

# use a globref with a username
lives_ok { hosts_ctl($daemon, \*SOCK, $username) }
    'call hosts_ctl with a glob and username';

# use a globref without a username
lives_ok { hosts_ctl($daemon, \*SOCK) }
    'call hosts_ctl with a glob and username';

# close the glob
close SOCK;

=end testing

=cut

package Authen::Libwrap;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS $DEBUG);

use constant STRING_UNKNOWN => "unknown";

require Exporter;

use XSLoader ();
use Carp ();
use Scalar::Util ();
use Socket ();

@ISA = 'Exporter';

# set up our exports
@EXPORT_OK = qw(
	hosts_ctl
	STRING_UNKNOWN
);
%EXPORT_TAGS = (
    functions => [ qw|hosts_ctl| ],
    constants => [ qw|STRING_UNKNOWN| ],
);
{
    my %seen;
    push @{$EXPORT_TAGS{all}},
    grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}
Exporter::export_ok_tags('all');

$VERSION = '0.23';

# pull in the XS parts
XSLoader::load 'Authen::Libwrap', $VERSION;

# set this to a true value to enable XS argument debug output
$DEBUG = 0;

=head1 FUNCTIONS

Authen::Libwrap has only one function, though it can be invoked
in several ways.  In each case, an true return code indicates that
the connection is allowed per the rules in F<hosts.allow> and an
undef value indicates the opposite.

=head2 hosts_ctl($daemon, $hostname, $ip_addr, [ $user ] )

Takes three mandatory and one optional argument. C<$daemon> is the service
for which access is being requested (like 'ftpd' or 'sendmail').
C<$hostname> is the name of the host requesting access. C<$ip_addr> is the
IP address of the host in dotted-quad notation. C<$user> is the name of the
user requesting access. If unknown, $user can be omitted; STRING_UNKNOWN
will be passed in it's place.

=head2 hosts_ctl($daemon, $socket, [ $user ] )

If you have a socket (be it a glob, glob reference or an IO::Socket::INET,
you can pass that as the second argument. The hostname and IP address will
be determined using this socket. If the hostname or IP address cannot be
determined from the socket, STRING_UNKNOWN will be passed in their place.

=cut

sub hosts_ctl
{
    
    my $daemon = shift;
    my $hostname;
    my $ip_addr;
    my $user;
    
    # next arg could be a literal hostname or a socket or a glob
    if( Scalar::Util::reftype  $_[0]  eq 'IO'     ||
        Scalar::Util::reftype  $_[0]  eq 'GLOB'   ||
        Scalar::Util::reftype \$_[0]  eq 'GLOB' )
    {
        
        # get the peer address from the socket
        my $socket = shift;
        my(undef, $peer) = eval {
            Socket::sockaddr_in(getpeername($socket))
        };
        Carp::croak "can't get peer address from socket" if $@;
        
        # get the IP addr
        $ip_addr = Socket::inet_ntoa($peer) || STRING_UNKNOWN;

        if( $peer ) {
            
            # get IP address or set to unknown
            $ip_addr = Socket::inet_ntoa($peer) || STRING_UNKNOWN;
            
            # get hostname or set to unknown
            $hostname = gethostbyaddr($peer, &Socket::AF_INET)
                || STRING_UNKNOWN;
           
        } else {

            # set hostname and IP addr to unknown
            $hostname = STRING_UNKNOWN;
            $ip_addr  = STRING_UNKNOWN;
        
        }
        
    }
    elsif( ref $_[0] ) {
        
        # ref but not one we can use
        Carp::croak("can't use a ", ref $_[0], " as a socket");
        
    }
    else {
        
        # must be a hostname then ip addr
        $hostname = shift || STRING_UNKNOWN;
        $ip_addr = shift || STRING_UNKNOWN;
        
    }

    # if there isn't another argument then we sub one in
    $user = shift || STRING_UNKNOWN;
    
    # dispatch to the XS function
    if( $DEBUG ) {
        warn("hosts_ctl: $daemon, $hostname, $ip_addr, $user\n");
    }
    return _hosts_ctl($daemon, $hostname, $ip_addr, $user);
    
}

# keep require happy
1;


__END__

=head1 DEBUGGING

If you want to see the arguments that will be passed to the C function
hosts_ctl(), set $Authen::Libwrap::DEBUG to a true value.

=head1 EXPORTS

Nothing unless you ask for it.

hosts_ctl optionally

STRING_UNKNOWN optionally

=head1 EXPORT_TAGS

=over 4

=item * B<functions>

 hosts_ctl

=item * B<constants>

 STRING_UNKNOWN

=item * B<all>

everything the module has to offer.

=back

=head1 CONSTANTS

 STRING_UNKNOWN

=head1 BUGS AND FEATURES

Please report any bugs or feature requests (and a pull request for bonus points)
 through the issue tracker at L<https://github.com/drmuey/p5-Authen-Libwrap/issues>.

=over 4

=item * B<twist> in F<hosts.allow>

Calls to hosts_ctl() which match a line in F<hosts.allow> that uses the
"twist" option will terminate the running perl program.  This is not a bug
in Authen::Libwrap per se -- libwrap uses exec(3) to replace the running
process with the specified program, so there's nothing to return to.

Some operating systems ship with a default catch-all rule in F<hosts.allow>
that uses the twist option.  You may have to modify this configuration to
use Authen::Libwrap effectively.

=item * Test suite is not comprehensive

The test suite isn't very comprehensive because the path to hosts.allow is
set when libwrap is built and I can't tell what the user's rules are. I can
make sure the function calls don't die, but I can't really tell if any call
to hosts_ctl should give back a true or false value.

=back

=head1 TODO

In early 2003 I was contacted by another Perl developer who had developed an
XS interface to libwrap that covered more of the API than mine did.
Originally he offered it as a patch to my module, but at the time I wasn't
in a position to actively maintain anything on CPAN, so I suggested that he
upload it himself. I unfortunately lost the email thread to a disk crash.

As of December 2003 I don't see any other modules professing to support
libwrap om CPAN. If that person is still out there, please get in contact
with me, otherwise I'll plan on implementing some of these TODOs in the new
year:

=over 4

=item * provide support for hosts_access and request_* functions

=item * develop an OO interface

=back

=head1 SEE ALSO

L<Authen::Tcpdmatch>, a Pure Perl module that can parse hosts.allow and
hosts.deny if you don't need all the underlying features of libwrap.

hosts_access(3), hosts_access(5), hosts_options(5)

Wietse's tools and papers page:
L<ftp://ftp.porcupine.org/pub/security/index.html>.

=head1 AUTHOR

James FitzGibbon, E<lt>jfitz@CPAN.orgE<gt>

=cut

#
# EOF

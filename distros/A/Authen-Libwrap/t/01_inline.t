#!/usr/local/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}

my $Original_File = 'lib/Authen/Libwrap.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 43 lib/Authen/Libwrap.pm

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


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}


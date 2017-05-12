package Authen::SASL::Authd;

use strict;
use warnings;
use IO::Socket::UNIX;
use IO::Select;
use MIME::Base64 qw(encode_base64);

our($VERSION, @EXPORT, @EXPORT_OK, @ISA);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(auth_cyrus auth_dovecot user_dovecot);

$VERSION = "0.04";


sub auth_cyrus {

    my ($login, $passwd, %prop) = @_;

    my $service = $prop{service_name} || '';
    my $timeout = $prop{timeout} || 5;
    my $socket = $prop{socket} || '/var/run/saslauthd/mux';
    
    my $sock = new IO::Socket::UNIX(Type => SOCK_STREAM, Peer => $socket) or
        die "Can't open socket. Check saslauthd is running and $socket is readable.";

    $sock->send(pack 'n/a*n/a*n/a*xx', $login, $passwd, $service) or
        die "Can't write to $socket";

    my $sel = new IO::Select($sock);
    $sel->can_read($timeout) or die 'Timed out while waiting for response';

    defined recv($sock, my $res, 1, 0) or die 'Error while reading response';
    defined recv($sock, $res, 1, 0) or die 'Error while reading response';
    defined recv($sock, $res, 1, 0) or die 'Error while reading response';
    $sock->close;

    $res eq 'O';
}


sub auth_dovecot {

    my ($login, $passwd, %prop) = @_;
    utf8::encode($login);
    utf8::encode($passwd);

    my $service = $prop{service_name} || '';
    my $timeout = $prop{timeout} || 5;
    my $socket = $prop{socket} || '/var/run/dovecot/login/default';

    my $sock = new IO::Socket::UNIX(Type => SOCK_STREAM, Peer => $socket) or
        die "Can't open socket. Check dovecot is running and $socket is readable.";

    my $handshake = read_until($sock, '^DONE$', $timeout);
    die "Unsupported protocol version"
        unless $handshake =~ /^VERSION\t1\t\d+$/m;

    die "PLAIN mechanism is not supported by the authentication daemon"
        unless $handshake =~ /^MECH\tPLAIN/m;

    my $base64 = encode_base64("\0$login\0$passwd");
    $sock->send("VERSION\t1\t0\nCPID\t$$\nAUTH\t1\tPLAIN\tservice=$service\tresp=$base64\n") or
        die "Can't write to $socket";

    my $result = read_until($sock, '\n', $timeout);

    $sock->close;

    $result =~ /^OK/;
}


sub user_dovecot {

    my ($login, %prop) = @_;
    utf8::encode($login);

    my $service = $prop{service_name} || '';
    my $timeout = $prop{timeout} || 5;
    my $socket = $prop{socket} || '/var/run/dovecot/auth-master';

    my $sock = new IO::Socket::UNIX(Type => SOCK_STREAM, Peer => $socket) or
        die "Can't open socket. Check dovecot is running and $socket is readable.";

    my $handshake = read_until($sock, '^VERSION\t\d+\t', $timeout);
    die "Unsupported protocol version"
        unless $handshake =~ /^VERSION\t1\t\d+$/m;

    $sock->send("VERSION\t1\t0\nUSER\t1\t$login\tservice=$service\n") or
        die "Can't write to $socket";

    my $result = read_until($sock, '\n', $timeout);

    $sock->close;

    return wantarray ? () : undef if $result !~ /^USER/;

    my %result = map { split /\=/, $_, 2 } (grep /\=/, (split /[\t\n]/, $result));
    return wantarray ? %result : \%result;
}


sub read_until {
    my ($sock, $re, $timeout) = @_;
    my $sel = new IO::Select($sock);
    my $result = '';
    while ($result !~ /$re/m) {
        $sel->can_read($timeout) or die "Timed out while waiting for response";
        defined recv($sock, my $buf, 256, 0) or die 'Error while reading response';
        $result .= $buf;
    }
    return $result;
}

1;
__END__

=head1 NAME

Authen::SASL::Authd - Client authentication via Cyrus saslauthd or
Dovecot authentication daemon.

=head1 SYNOPSIS

    use Authen::SASL::Authd qw(auth_cyrus auth_dovecot);

    # authenticate user against Cyrus saslauthd
    auth_cyrus('login', 'passwd') or die "saslauthd: FAIL";

    # authenticate user against Dovecot authentication daemon
    auth_dovecot('login', 'passwd') or die "dovecot-auth: FAIL";

    # check user existence
    my %user_attr = user_dovecot('login', timeout => 3) or die "dovecot-auth: NO SUCH USER";
    print "user home: $user_attr{home}\n";

=head1 DESCRIPTION

The C<Authen::SASL::Authd> package implements LOGIN authentication protocol used by Cyrus saslauthd and
PLAIN authentication protocol supported by Dovecot authentication daemon.
It can be used to process authentication requests against configured SASL mechanism
implemented by Cyrus or Dovecot SASL libraries. It can also be used to check if a particular user exists
according to the Dovecot authentication daemon.

=head1 METHODS

=item auth_cyrus( 'LOGIN', 'PASSWD', [ service_name => 'SERVICE_NAME', ]
    [ timeout => 'TIMEOUT (sec)', ] [ socket => '/SOCK/FILE/NAME', ] )

Check supplied user name and password against Cyrus saslauthd.
Return true if authentication succeeded. Die in case of a likely configuration problem.

=item auth_dovecot( 'LOGIN', 'PASSWD', [ service_name => 'SERVICE_NAME', ]
    [ timeout => 'TIMEOUT (sec)', ] [ socket => '/SOCK/FILE/NAME', ] )

Check supplied user name and password against Dovecot authentication daemon.
Return true if authentication succeeded. Die in case of a likely configuration problem.

=item user_dovecot( 'LOGIN', [ service_name => 'SERVICE_NAME', ] [ timeout => 'TIMEOUT (sec)', ]
    [ socket => '/SOCK/FILE/NAME', ] )

Check if supplied user name exists according to the Dovecot authentication daemon.
Return a reference to the hashtable (or the hashtable in list context) with optional user attributes
if the user exists, undef (or empty list in list context) otherwise.
The hashtable can contain such attributes as 'home', 'gid', 'uid', etc defined by the Dovecot SASL
implementation.
Die in case of a likely configuration problem.

=head1 AUTHOR

Alex Protasenko http://www.bkmks.com/

=head1 COPYRIGHT and LICENSE

Copyright 2007 by Alex Protasenko.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


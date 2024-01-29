package Cache::MemcachedBinary;

use strict;
use warnings;

no strict 'refs';
use IO::Socket;
use Encode;
$| = 1;

use vars qw($VERSION);
$VERSION = "1.02";

use constant HOST       => '127.0.0.1';
use constant PORT       => 11211;
use constant LOGIN      => 'login';
use constant PASSWORD   => 'password';
use constant TIMEOUT    => 2;
use constant DEBUG      => 0;
use constant ERROR_FLAG => 1;

use constant PROTOCOL_BINARY_REQ  => 0x80;
use constant PROTOCOL_BINARY_RES  => 0x81;
use constant PROTOCOL_BINARY_RESPONSE_SUCCESS    => 0x00;
use constant PROTOCOL_BINARY_RESPONSE_AUTH_ERROR => 0x20;
use constant PROTOCOL_BINARY_CMD_GET             => 0x00;
use constant PROTOCOL_BINARY_CMD_SET             => 0x01;
use constant PROTOCOL_BINARY_CMD_ADD             => 0x02;
use constant PROTOCOL_BINARY_CMD_DELETE          => 0x04;
use constant PROTOCOL_BINARY_CMD_INCREMENT       => 0x05;
use constant PROTOCOL_BINARY_CMD_QUIT            => 0x07;
use constant PROTOCOL_BINARY_CMD_FLUSH           => 0x08;
use constant PROTOCOL_BINARY_CMD_SASL_LIST_MECHS => 0x20;
use constant PROTOCOL_BINARY_CMD_SASL_AUTH       => 0x21;

sub new {
    my $class = shift;
    my %param = @_;

    if (! exists $param{host})     {$param{host}     = HOST;}
    if (! exists $param{port})     {$param{port}     = PORT;}
    if (! exists $param{timeout})  {$param{timeout}  = TIMEOUT;}
    if (! exists $param{login})    {$param{login}    = LOGIN;}
    if (! exists $param{password}) {$param{password} = PASSWORD;}
    if (! exists $param{debug})    {$param{debug}    = DEBUG;}

    bless {%param}, $class;
}

sub add {
    my $self = shift;
    $self->_set(PROTOCOL_BINARY_CMD_ADD, @_);
}

sub set {
    my $self = shift;
    $self->_set(PROTOCOL_BINARY_CMD_SET, @_);
}

sub _set {
    my $self = shift;
    my ($opcode, $key, $val, $sec) = @_;
    $sec //= 0;

    if ($opcode == PROTOCOL_BINARY_CMD_ADD) {$self->_log("ADD key:$key, seconds:$sec");}
    elsif ($opcode == PROTOCOL_BINARY_CMD_SET) {$self->_log("SET key:$key, seconds:$sec");}

    my $socket = $self->_get_socket() || return;

    if (Encode::is_utf8($key)) {Encode::_utf8_off($key);}
    if (Encode::is_utf8($val)) {Encode::_utf8_off($val);}

    my $sec_binary = sprintf '%08x', $sec;

    $self->set_err(undef);

    $self->_request_packet({
        Opcode => $opcode,
        Extras => 'deadbeef' . $sec_binary,
        Key    => join("", map sprintf('%x', $_), unpack("C*", $key)),
        Value  => join("", map sprintf('%x', $_), unpack("C*", $val)),
    });

    my $data = $self->_read_responce();
    if ( $$data{MagicUnpack} == PROTOCOL_BINARY_RES && $$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_SUCCESS ) {
        $self->_log("Result: success");
        return 1;
    }

    $self->_log("Result: fail, server answer: $$data{ValueUnpack}");
    $self->set_err($$data{ValueUnpack});

    if ($$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_AUTH_ERROR) { # auth error, try auth
        $self->_socket_destroy();
        return $self->_set(@_) if $self->auth();
    }

    return;
}

sub get {
    my $self = shift;
    my $key = shift || return;

    $self->_log("GET key:$key");

    my $socket = $self->_get_socket() || return;

    if (Encode::is_utf8($key)) {Encode::_utf8_off($key);}

    $self->set_err(undef);

    $self->_request_packet({
        Opcode => PROTOCOL_BINARY_CMD_GET,
        Key    => join("", map sprintf('%x', $_), unpack("C*", $key)),
    });

    my $data = $self->_read_responce();
    if ( $$data{MagicUnpack} == PROTOCOL_BINARY_RES && $$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_SUCCESS ) {
        $self->_log("Result: success");
        return $$data{ValueUnpack};
    }

    $self->_log("Result: fail, server answer: $$data{ValueUnpack}");
    $self->set_err($$data{ValueUnpack});

    if ($$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_AUTH_ERROR) { # auth error, try auth
        $self->_socket_destroy();
        return $self->get($key) if $self->auth();
    }

    return;
}

sub delete {
    my $self = shift;
    my $key = shift || return;

    $self->_log("DELETE key:$key");

    my $socket = $self->_get_socket() || return;

    if (Encode::is_utf8($key)) {Encode::_utf8_off($key);}

    $self->set_err(undef);

    $self->_request_packet({
        Opcode => PROTOCOL_BINARY_CMD_DELETE,
        Key    => join("", map sprintf('%x', $_), unpack("C*", $key)),
    });

    my $data = $self->_read_responce();
    if ( $$data{MagicUnpack} == PROTOCOL_BINARY_RES && $$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_SUCCESS ) {
        $self->_log("Result: success");
        return 1;
    }

    $self->_log("Result: fail, server answer: $$data{ValueUnpack}");
    $self->set_err($$data{ValueUnpack});

    if ($$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_AUTH_ERROR) { # auth error, try auth
        $self->_socket_destroy();
        return $self->delete($key) if $self->auth();
    }

    return;
}

sub incr {
    my $self = shift;
    my $key = shift || return;

    $self->_log("INCREMENT key:$key");

    my $socket = $self->_get_socket() || return;

    if (Encode::is_utf8($key)) {Encode::_utf8_off($key);}

    $self->set_err(undef);

    $self->_request_packet({
        Opcode => PROTOCOL_BINARY_CMD_INCREMENT,
        Key    => join("", map sprintf('%x', $_), unpack("C*", $key)),
        Extras => '0000000000000001' . '0000000000000000' . '00000000',
    });

    my $data = $self->_read_responce();
    if ( $$data{MagicUnpack} == PROTOCOL_BINARY_RES && $$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_SUCCESS ) {
        $self->_log("Result: success");
        my @mess = unpack('N2', $$data{Value});
        return $mess[1];
        return 1;
    }

    $self->_log("Result: fail, server answer: $$data{ValueUnpack}");
    $self->set_err($$data{ValueUnpack});

    if ($$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_AUTH_ERROR) { # auth error, try auth
        $self->_socket_destroy();
        return $self->incr($key) if $self->auth();
    }

    return;
}

sub flush {
    my $self = shift;
    my $sec  = shift // 0;

    $self->_log("FLUSH seconds:$sec");

    my $socket = $self->_get_socket() || return;

    my $sec_binary = sprintf '%08x', $sec;

    $self->set_err(undef);

    $self->_request_packet({
        Opcode => PROTOCOL_BINARY_CMD_FLUSH,
        Extras => $sec_binary,
    });

    my $data = $self->_read_responce();
    if ( $$data{MagicUnpack} == PROTOCOL_BINARY_RES && $$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_SUCCESS ) {
        $self->_log("Result: success");
        return 1;
    }

    $self->_log("Result: fail, server answer: $$data{ValueUnpack}");
    $self->set_err($$data{ValueUnpack});

    if ($$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_AUTH_ERROR) { # auth error, try auth
        $self->_socket_destroy();
        return $self->flush($sec) if $self->auth();
    }

    return;
}

sub quit {
    my $self = shift;

    $self->_log("QUIT");

    my $socket = $self->_get_socket() || return;

    $self->set_err(undef);

    $self->_request_packet({
        Opcode => PROTOCOL_BINARY_CMD_QUIT,
    });

    my $data = $self->_read_responce();
    if ( $$data{MagicUnpack} == PROTOCOL_BINARY_RES && $$data{StatusUnpack} == PROTOCOL_BINARY_RESPONSE_SUCCESS ) {
        $self->_log("Result: success");
        $self->_socket_destroy();
        return 1;
    }

    $self->_log("Result: fail, server answer: $$data{ValueUnpack}");
    $self->set_err($$data{ValueUnpack});

    return;
}

sub auth {
    my $self = shift;

    $self->_log("AUTH");

    my $socket = $self->_get_socket() || return;

    $self->_request_packet({
        Opcode => PROTOCOL_BINARY_CMD_SASL_LIST_MECHS,
    });

    my $data = $self->_read_responce();

    my $methods = unpack('A*', $$data{Value});
    $self->_log("Server support auth SASL methods: $methods");
    if ( $methods !~ m/PLAIN/ ) {
        $self->set_err("Server not support SASL PLAIN");
        $self->_log("Server not support SASL PLAIN", ERROR_FLAG);
        return;
    }

    my $login    = join "", map sprintf('%x', $_), unpack("C*", $self->login);
    my $password = join "", map sprintf('%x', $_), unpack("C*", $self->password);
    $self->_request_packet({
        Opcode => PROTOCOL_BINARY_CMD_SASL_AUTH,
        Key    => join("", map sprintf('%x', $_), unpack("C*", 'PLAIN')),
        Value  => $login . '00'  . $login . '00'  . $password,
    });

    $data = $self->_read_responce();
    my $mess = unpack('A*', $$data{Value});
    $self->_log("Server answer: $mess");
    if ( $mess ne 'Authenticated' ) {
        $self->set_err("Auth failure");
        $self->_log("Auth failure with login: " . $self->login, ERROR_FLAG);
        return;
    }

    return 1;
}

sub _request_packet {
    my $self = shift;
    my $data = shift || return;

    my $socket = $self->_get_socket() || return;

    $$data{Magic}  = sprintf '%x', PROTOCOL_BINARY_REQ;
    $$data{Opcode} = sprintf '%x', $$data{Opcode};
    $$data{DataType} = '00'; # Raw bytes

    $$data{Extras} //= '';
    $$data{Key}    //= '';
    $$data{Value}  //= '';

    $$data{ExtrasLength}    = length($$data{Extras}) / 2;
    $$data{KeyLength}       = length($$data{Key}) / 2;
    $$data{TotalBodyLength} = length($$data{Value}) / 2 + $$data{ExtrasLength} + $$data{KeyLength};

    $$data{Opcode}          = sprintf '%02d',  ( $$data{Opcode}          // '00' );
    $$data{KeyLength}       = sprintf '%04x',  ( $$data{KeyLength}       // '0000' );
    $$data{ExtrasLength}    = sprintf '%02x',  ( $$data{ExtrasLength}    // '00' );
    $$data{VbucketId}       = sprintf '%04d',  ( $$data{VbucketId}       // '0000' );
    $$data{TotalBodyLength} = sprintf '%08x',  ( $$data{TotalBodyLength} // '00000000' );
    $$data{Opaque}          = sprintf '%08d',  ( $$data{Opaque}          // '00000000' );
    $$data{CAS}             = sprintf '%016d', ( $$data{CAS}             // '0000000000000000' );

    my $packet = join "", map( $$data{$_}, (qw(Magic Opcode KeyLength ExtrasLength DataType VbucketId TotalBodyLength Opaque CAS Extras Key Value)));

    $self->_log(">> $packet");
    send($socket, pack('H*', $packet), 0);

    return 1;
}

sub _read_responce {
    my $self = shift;

    my $socket = $self->_get_socket() || return;

    my %data;

    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm $self->timeout;

        sysread($socket, $data{Magic}, 1);
        sysread($socket, $data{Opcode}, 1);
        sysread($socket, $data{KeyLength}, 2);
        sysread($socket, $data{ExtrasLength}, 1);
        sysread($socket, $data{DataType}, 1);
        sysread($socket, $data{Status}, 2);
        sysread($socket, $data{TotalBodyLength}, 4);
        sysread($socket, $data{Opaque}, 4);
        sysread($socket, $data{CAS}, 8);

        $data{Key}    = '';
        $data{Extras} = '';
        $data{Value}  = '';

        my $len_key    = sprintf('%d', unpack( 'H*', $data{KeyLength} ));
        my $len_extras = hex(unpack( 'H*', $data{ExtrasLength} ));
        my $len_total  = unpack('N*', $data{TotalBodyLength}) || 0;
        my $len_value  = $len_total - $len_extras - $len_key;

        if ($len_extras) {
            sysread($socket, $data{Extras}, $len_extras);
        }

        if ($len_key) {
            sysread($socket, $data{Key}, $len_key);
        }

        if ($len_value) {
            sysread($socket, $data{Value}, $len_value);
        }

        $data{MagicUnpack}  = hex(unpack('H*', $data{Magic}));
        $data{OpcodeUnpack} = hex(unpack('H*', $data{Opcode}));
        $data{StatusUnpack} = unpack('n1', $data{Status});
        $data{ValueUnpack}  = unpack('A*', $data{Value});

        alarm 0;
    };

    $self->_log("<< " . ( join "", map { unpack('H*', $data{$_}) } (qw(Magic Opcode KeyLength ExtrasLength DataType Status TotalBodyLength Opaque CAS Extras Key Value)) ));

    if ( $data{OpcodeUnpack} == PROTOCOL_BINARY_CMD_GET ) { # clean binary data from Value section, maybe big data
        $data{Value} = '';
    }

    return \%data;
}

sub _get_socket {
    my $self = shift;

    return $self->socket if $self->socket && $self->socket->connected();
    return $self->_connect();
}

sub _connect {
    my $self = shift;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $self->host,
        PeerPort => $self->port,
        Proto    => 'tcp',
        Timeout  => $self->timeout,
        Type     => SOCK_STREAM
    );

    my $error = $!;
    if ($error) {Encode::_utf8_on($error);}

    $self->_log( sprintf "Connect to host: %s, port: %s, timeout: %s", $self->host, $self->port, $self->timeout );
    $self->_log("result: " . ($socket ? 'success' : 'error: ' . $error));

    if ($socket) {
        binmode $socket;
        $self->set_socket($socket);
        return $socket;
    }

    $self->set_err($!);
    $self->_log( sprintf("Don't connect to %s:%s, error: %s", $self->host, $self->port, $error), ERROR_FLAG );
    return;
}

sub _socket_destroy {
    my $self = shift;
    $self->_log("socket destroy " . $self->socket);
    close($self->socket) if $self->socket;
    $self->set_socket(undef);
    return;
}

sub _log {
    my ($self, $str, $flag) = @_;
    return unless $str;

    $flag //= 0;

    if (! $self->logger) {
        $self->set_logger( sub { print STDERR shift() . "\n" } );
    }

    if (ref $self->logger ne 'CODE') {
        print STDERR "param 'logger' has type of reference not function\n";
        return;
    }

    if ($self->debug || $flag == ERROR_FLAG) {
        $self->logger->($str);
    }

    return;
}

sub host     {return $_[0]->{host}}
sub port     {return $_[0]->{port}}
sub timeout  {return $_[0]->{timeout}}
sub login    {return $_[0]->{login}}
sub password {return $_[0]->{password}}
sub socket   {return $_[0]->{socket}}
sub debug    {return $_[0]->{debug}}
sub logger   {return $_[0]->{logger}}
sub err      {return $_[0]->{err}}

sub set_host     { $_[0]->{err} = $_[1]; }
sub set_port     { $_[0]->{port} = $_[1]; }
sub set_timeout  { $_[0]->{timeout} = $_[1]; }
sub set_login    { $_[0]->{login} = $_[1]; }
sub set_password { $_[0]->{password} = $_[1]; }
sub set_socket   { $_[0]->{socket} = $_[1]; }
sub set_debug    { $_[0]->{debug} = $_[1]; }
sub set_logger   { $_[0]->{logger} = $_[1]; }
sub set_err      { $_[0]->{err} = $_[1]; }

1;
__END__
=head1 NAME

Cache::MemcachedBinary - Perl extension for Memcached server with binary protocol.

=head1 SYNOPSIS

    use Modern::Perl;
    use Cache::MemcachedBinary;

    my $logger = sub {say @_};
    my $obj_mem = Cache::MemcachedBinary->new(
        host     => '127.0.0.1',
        port     => 11211,
        timeout  => 2,
        login    => 'login',
        password => 'password',
        debug    => 1,
        logger   => $logger, # default print to STDERR
    );

    my $key = 'memcached_key';

    # get value
    my $value = $obj_mem->get($key);

    # add/set
    $obj_mem->add($key, 'my value' [, $exptime]);
    $obj_mem->set($key, 'my value' [, $exptime]);

    # delete
    $obj_mem->delete($key);

    # increment
    my $incr = $obj_mem->incr($key);

    # flush all memcached data
    $obj_mem->flush();

=head1 DESCRIPTION

This module is simple interface for Memcached server with binary protocol.

=head2 EXPORT

None.

=head1 AUTHOR

Konstantin Titov, E<lt>xmolex@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Konstantin Titov

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
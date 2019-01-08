package Broadworks::OCIP;

# ABSTRACT: API for communication with Broadworks OCI-P Interface

use strict;
use warnings;
use utf8;
use feature 'unicode_strings';
use namespace::autoclean;

our $VERSION = '0.08'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Broadworks::OCIP::Response;
use Broadworks::OCIP::Throwable;
use Config::Any;
use Data::UUID;
use Digest::MD5 qw( md5_hex );
use Digest::SHA1 qw( sha1_hex );
use Encode;
use IO::Select;
use IO::Socket::INET;
use Moose;
use Method::Signatures;
use MooseX::StrictConstructor;
use XML::Writer;

extends 'Broadworks::OCIP::Methods';


# ------------------------------------------------------------------------
sub _list {
    return () unless ( defined( $_[0] ) );
    return @{ $_[0] } if ( ref( $_[0] ) eq 'ARRAY' );
    return $_[0];
}

# ------------------------------------------------------------------------


has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# ------------------------------------------------------------------------


has username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# ------------------------------------------------------------------------


has authhash => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# ------------------------------------------------------------------------


has version => (
    is      => 'ro',
    isa     => 'Str',
    default => '17sp4',
);

# ------------------------------------------------------------------------


has character_set => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ISO-8859-1',
);

# ------------------------------------------------------------------------


has encoder => (
    is      => 'ro',
    isa     => 'Object',
    builder => '_build_encoder',
);

method _build_encoder () {
    my $character_set = $self->character_set;
    return find_encoding($character_set)
        || Broadworks::OCIP::Throwable->throw(
        message         => "Cannot find encoder for $character_set",
        execution_phase => 'setup',
        error_code      => 'no_encode'
        );
}

# ------------------------------------------------------------------------


has protocol => (
    is      => 'ro',
    isa     => 'Str',
    default => 'OCI',
);

# ------------------------------------------------------------------------


has port => (
    is      => 'ro',
    isa     => 'Int',
    default => 2208,
);

# ------------------------------------------------------------------------


has target => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_target',
    lazy    => 1
);

method _build_target () {
    return join( ':', $self->host, $self->port );
}

# ------------------------------------------------------------------------


has timeout => (
    is      => 'rw',
    isa     => 'Int',
    default => 8,
);

# ------------------------------------------------------------------------


has socket => (
    is      => 'ro',
    isa     => 'Object',
    builder => '_build_socket',
    lazy    => 1,
);

method _build_socket () {
    return IO::Socket::INET->new( $self->target )
        || Broadworks::OCIP::Throwable->throw(
        message         => sprintf( "Unable to connect to %s - %s\n", $self->target, $! ),
        execution_phase => 'setup',
        error_code      => 'cant_connect'
        );
}

# ------------------------------------------------------------------------


has select => (
    is      => 'ro',
    isa     => 'Object',
    builder => '_build_select',
    lazy    => 1,
);

method _build_select () {
    return IO::Select->new( $self->socket )
        || Broadworks::OCIP::Throwable->throw(
        message         => sprintf( "Unable to build select  on socket to %s - %s\n", $self->target, $! ),
        execution_phase => 'setup',
        error_code      => 'no_select'
        );
}

# ------------------------------------------------------------------------


has session => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_session',
    lazy    => 1,
);

method _build_session () { return Data::UUID->new->create_str; }

# ------------------------------------------------------------------------


has is_authenticated => (
    is        => 'ro',
    isa       => 'Bool',
    builder   => '_build_is_authenticated',
    predicate => 'is_set_is_authenticated',
    lazy      => 1,
);

method _build_is_authenticated () {

    # send authentication request to get nonce
    $self->send_command_xml( 'AuthenticationRequest', [ userId => $self->username ] );
    my $res = $self->receive( 'AuthenticationResponse', 1 );

    # send login request
    $self->send_command_xml(
        'LoginRequest14sp4',
        [   userId         => $self->username,
            signedPassword => lc( md5_hex( join( ':', $res->payload->{nonce}, $self->authhash ) ) )
        ]
    );
    my $res2 = $self->receive( 'LoginResponse14sp4', 1 );

    return 1;
}

# ------------------------------------------------------------------------


has last_sent => (
    is  => 'rw',
    isa => 'Str',
);

# ------------------------------------------------------------------------


has trace => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

# ----------------------------------------------------------------------


around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    my $args;
    if ( scalar(@_) == 1 ) {
        if ( not( ref( $_[0] ) ) ) {

            # single non reference argument - we treat this as a config filename
            my $fn = shift;
            my $confset = Config::Any->load_files( { files => [$fn], use_ext => 1 } );
            unless ($confset) {
                Broadworks::OCIP::Throwable->throw(
                    message         => sprintf( "Unable to handle config file %s - %s", $fn, $! ),
                    execution_phase => 'buildargs',
                    error_code      => 'no_config'
                );
            }
            my $config = ( values( %{ $confset->[0] } ) )[0]
                or Broadworks::OCIP::Throwable->throw(
                message         => sprintf( "No valid config file %s - %s", $fn, $! ),
                execution_phase => 'buildargs',
                error_code      => 'invalid_config'
                );

            $args = $config->{'Broadworks::OCIP'}
                or Broadworks::OCIP::Throwable->throw(
                message         => sprintf( "No Broadworks::OCIP section in config file %s", $fn ),
                execution_phase => 'buildargs',
                error_code      => 'duff_config'
                );
        }
        else {
            # single reference argument - treat as a hash ref
            $args = $_[0];
        }
    }
    else {    # just make some args up
        $args = {@_};
    }

    # convert password to authhash
    if ( my $password = delete $args->{password} ) {
        $args->{authhash} = lc( sha1_hex($password) );
    }

    $class->$orig($args);
};

# ----------------------------------------------------------------------


method send ($string) {

    $self->last_sent($string);
    $self->socket->print( $self->encoder->encode($string) );
    warn( '>>> ', $string, "\n" ) if ( $self->trace );
}

# ----------------------------------------------------------------------
method receive ($expected,$die_on_error) {

    my $bytes = '';
    {    # delimit section where we override character handling
        use bytes;
        my $select = $self->select;
        while ( my ($fh) = $select->can_read( $self->{timeout} ) ) {
            Broadworks::OCIP::Throwable->throw(
                message         => "Timeout on receive for [$expected] - $!\n",
                execution_phase => 'receive',
                error_code      => 'timeout'
            ) unless ( defined($fh) );

            # read - bail out if EOF
            my $eofs = 0;
            unless ( sysread $fh, $bytes, 65536, length($bytes) ) {
                last if ( $eofs++ );
                next;
            }
            last if ( $bytes =~ /<\/BroadsoftDocument>/ );
        }

        Broadworks::OCIP::Throwable->throw(
            message         => "No Data on receive - $!\n($bytes)\n",
            execution_phase => 'receive',
            error_code      => 'no_data'
        ) unless ( length($bytes) );
    }

    # convert string from cruddy encoding to utf8
    my $str = $self->encoder->decode($bytes);
    warn( '<<< ', $str, "\n" ) if ( $self->trace );

    # we rely on the XML decoder handling any character set issues correctly!
    return ( Broadworks::OCIP::Response->new( xml => $str, expected => $expected, die_on_error => $die_on_error ) );
}

# ----------------------------------------------------------------------
sub _command_xml_parameters {
    my ( $xw, $parampairs ) = @_;

    while ( scalar( @{$parampairs} ) ) {
        my ( $key, $val ) = splice( @{$parampairs}, 0, 2 );
        if ( ref($val) eq 'ARRAY' ) {
            $xw->startTag($key);
            _command_xml_parameters( $xw, $val );
            $xw->endTag($key);
        }
        else {

            # attribs is there to allow correct tagging of empty elements
            my @attribs = ( defined($val) && ( $val eq qq[] ) ) ? ( 'xsi:nil' => 'true' ) : ();
            $xw->dataElement( $key => $val, @attribs );
        }
    }
}

# ----------------------------------------------------------------------


method send_command_xml ($cmd, $parampairs) {

    # start XML build
    my $xw = XML::Writer->new( OUTPUT => 'self' )
        or Broadworks::OCIP::Throwable->throw(
        message         => "Cannot build XML object - $!",
        execution_phase => 'send',
        error_code      => 'xml_fail'
        );
    $xw->xmlDecl( $self->character_set );

    # build document
    $xw->startTag(
        'BroadsoftDocument',
        'protocol'  => $self->protocol,
        'xmlns'     => 'C',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
    );
    $xw->dataElement( sessionId => $self->session, xmlns => '' );

    # build command section
    $xw->startTag( 'command', xmlns => '', 'xsi:type' => $cmd );

    # inject command parameters
    _command_xml_parameters( $xw, $parampairs );

    # close up tags
    $xw->endTag('command');
    $xw->endTag('BroadsoftDocument');

    # get XML string
    my $xml_string = $xw->end;

    # send XML string
    $self->send($xml_string);
}

# ----------------------------------------------------------------------


method send_query ($cmd, @parampairs) {

    Broadworks::OCIP::Throwable->throw(
        message         => "Not authenticated",
        execution_phase => 'send_query',
        error_code      => 'no_auth'
    ) unless ( $self->is_authenticated );
    my $response = $cmd;
    $response =~ s/Request/Response/;
    $self->send_command_xml( $cmd, \@parampairs );
    return $self->receive( $response, 1 );
}

# ----------------------------------------------------------------------


method send_command ($cmd, @parampairs) {

    Broadworks::OCIP::Throwable->throw(
        message         => "Not authenticated",
        execution_phase => 'send_command',
        error_code      => 'no_auth'
    ) unless ( $self->is_authenticated );
    $self->send_command_xml( $cmd, \@parampairs );
    return $self->receive( 'c:SuccessResponse', 0 );
}

# ----------------------------------------------------------------------


method DEMOLISH ($flag) {
    if ( $self->is_set_is_authenticated ) {

        # Logout request still does not return despite documentation saying it does,
        # so we fiddle things in a way to prevent us waiting for no response...
        $self->send_command_xml( 'LogoutRequest', [ userId => $self->username, reason => 'Object destruction' ] );
        $self->socket->close;
    }
}

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Broadworks::OCIP - API for communication with Broadworks OCI-P Interface

=head1 VERSION

version 0.08

=for test_synopsis 1;
__END__

=for stopwords NIGELM

=for Pod::Coverage mvp_multivalue_args

=head1 SYNOPSIS

  use Broadworks::OCIP;

  my $ocip = Broadworks::OCIP->new(params);
  my $res = $ocip->SystemSoftwareVersionGetRequest();

=head1 DESCRIPTION

Broadworks::OCIP is a perl interface to the Broadworks OCI-P Provisioning
interface.  The functions provided reflect the AS OCI-P. The methods supported
are documented in the L<Broadworks::OCIP::Methods> module, which is
autogenerated from the Broadworks schemas.

=head2 Required Parameters

=head3 host

The host that is being connected to - either a host name or an IP address.

=head3 username

The username to authenticate with on the remote system.

=head3 authhash

An authentication hash to use for authenticating the username.  Alternatively
the password attribute can be set and this is transformed into an appropriate
authhash (and the password deleted).

=head2 Other attributes

=head3 version

Broadworks version - currently defaults to C<17sp4>.

=head3 character_set

The character set to use - currently defaults to C<ISO-8859-1>.

=head3 encoder

A character set encoder - uses an instance of L<Encode> returned by
L<Encode/find_encoding>.

=head3 protocol

The protocol to implement - always C<OCI>.

=head3 port

The port number to connect to - default C<2208>.

=head3 target

The target to connect to - consists of the host and port linked by a colon.

=head3 timeout

The timeout within the connection in seconds - defaults to C<8> can be changed
during the session.

=head3 socket

The connection socket - automatically set.

=head3 select

A select object on the connection socket.

=head3 session

The session identifier for the session - defaults to a L<Data::UUID> string.

=head3 is_authenticated

Are we authenticated.  Checking this forces authentication.  If authentication
fails then we throw an exception.

=head3 last_sent

The last sent XML document.

=head3 trace

Are we tracing.  If this is true then we output sent and received data to
STDERR.

=head1 METHODS

=head3 BUILDARGS

Standard L<Moose> C<BUILDARGS> function.  If a single argument is passed this
is treated as a config filename (opened with L<Config::Any>) if it is a scalar,
or assumed to be a hash reference, which is expanded up.

If a config filename is passed this is opened, and any C<Broadworks::OCIP> is
taken as the overall config.

Any C<password> attribute is removed from the config and an L<authhash> is put
in its place.  This means dumping the object will not reveal the password.

=head3 send

Sends an XML document to the Broadworks remote over the socket. Convert the
passed string to the correct character set.

=head3 send_command_xml

Builds an XML command document from the command passed and the parameters
(which are passed as an array ref of pairs).

When the document has been created it is send using the L<send> method.

=head3 send_query

Sends an XML command to the Broadworks remote over the socket, and receives and
passes back the expected response document.  Throws an exception if the reply
type is returned.

=head3 send_command

Sends an XML command to the Broadworks remote over the socket, and receives and
passes back the expected C<SuccessResponse> document.   An exception is not
thrown if the wrong reply type is returned, however the C<status_ok> attribute
should be checked for this.

=head3 DEMOLISH

On object destruction, if the system has authenticated, sends a
C<LogoutRequest> command and then tears down the socket connection.

=head1 AUTHOR

Nigel Metheringham <Nigel.Metheringham@redcentricplc.com>

=head1 COPYRIGHT

Copyright 2014 Recentric Solutions Limited. All rights reserved.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

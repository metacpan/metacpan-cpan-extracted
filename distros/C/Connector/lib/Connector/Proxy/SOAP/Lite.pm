# Connector::Proxy::SOAP::Lite
#
# Proxy class for accessing SOAP servers
#
# Written by Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::SOAP::Lite;

use strict;
use warnings;
use English;
use SOAP::Lite;
use Try::Tiny;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

has uri => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    );

has method => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    );

has do_not_use_charset => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    );

has use_microsoft_dot_net_compatible_separator => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    );

# By default the SOAP call uses positional parameters. If this flag is set,
# the argument list to the call is interpreted as a Hash
has named_parameters => (
    is => 'rw',
    isa => 'ArrayRef|Str|Undef',
    trigger => \&_convert_parameters,
    );

has attrmap => (
    is  => 'rw',
    isa => 'HashRef',
    required => 0,
    predicate => 'has_attrmap'
);

has use_net_ssl => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    );

has ssl_ignore_hostname => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    );

has certificate_file => (
    is => 'rw',
    isa => 'Str',
    );

has certificate_key_file => (
    is => 'rw',
    isa => 'Str',
    );

has certificate_p12_file => (
    is => 'rw',
    isa => 'Str',
    );

has certificate_key_password => (
    is => 'rw',
    isa => 'Str',
    );

has ca_certificate_path => (
    is => 'rw',
    isa => 'Str',
    );

has ca_certificate_file => (
    is => 'rw',
    isa => 'Str',
    );

sub BUILD {
    my $self = shift;
    if ($self->do_not_use_charset) {
    $SOAP::Constants::DO_NOT_USE_CHARSET = 1;
    }
}

# If named_parameters is set using a string (necessary atm for Config::Std)
# its converted to an arrayref. Might be removed if Config::* improves
# This might create indefinite loops if something goes wrong on the conversion!
sub _convert_parameters {
    my ( $self, $new, $old ) = @_;

    # Test if the given value is a non empty scalar
    if ($new && !ref $new && (!$old || $new ne $old)) {
        my @attrs = split(" ", $new);
        $self->named_parameters( \@attrs )
    }

}

sub _build_config {
    my $self = shift;
}

# override this to add authentication headers
# must return an array (not array ref!) with SOAP::Head objects
sub _make_head {
    return;
}

# can be overriden in case you need a more complex data structure
sub _make_params {
    my $self = shift;
    my $args = shift;

    my @params;
    if (ref $self->named_parameters eq 'ARRAY' && scalar @{$self->named_parameters}) {
        my @args = @{$args};
        foreach my $key (@{$self->named_parameters}) {
            my $value = shift @args;
            push @params, SOAP::Data->new(name => $key, value => $value );
            $self->log()->debug('Named parameter: ' . $key . ' => ' . $value );
        }
    } else {
        @params = @{$args};
        $self->log()->debug('Parameters: ' . join(', ', @params));
    }
    return @params;
}

sub _soap_call {
    my $self = shift;

    my @args = $self->_build_path( shift );

    my $proxy = $self->LOCATION();

    my %ENV_BACKUP = %ENV;

    my $client = SOAP::Lite
        ->uri($self->uri);

    $self->log()->debug('Performing SOAP call to method ' . $self->method . ' on service ' . $self->uri . ' via ' . $proxy);

    # Force usage of net::ssl
    if ($self->use_net_ssl()) {
        require Net::SSL;
        $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";

        if ($self->certificate_p12_file) {
            $ENV{HTTPS_PKCS12_FILE}  = $self->certificate_p12_file;

            if ($self->certificate_key_file || $self->certificate_file) {
                die "Options certificate_file/certificate_key_file and certificate_p12_file are mutually exclusive";
            }

            if ($self->certificate_key_password) {
                $ENV{HTTPS_PKCS12_PASSWORD}  = $self->certificate_key_password;
            }
        }

        if ($self->certificate_key_file) {
            if ($self->certificate_key_password) {
                die "Net::SSL does not support password protected keys - use certificate_p12_file instead";
            }

            if (!$self->certificate_file) {
                die "You need to pass certificate AND key file, use certificate_p12_file to pass a PKCS12";
            }

            $ENV{HTTPS_KEY_FILE}  = $self->certificate_key_file;
            $ENV{HTTPS_CERT_FILE} = $self->certificate_file;

        } elsif ($self->certificate_file) {
            die "You need to pass certificate AND key file, use certificate_p12_file to pass a PKCS12";
        }

        if ($self->ca_certificate_path) {
            $ENV{HTTPS_CA_DIR} = $self->ca_certificate_path;
        }

        if ($self->ca_certificate_file) {
            $ENV{HTTPS_CA_FILE} = $self->ca_certificate_file;
        }

        $client->proxy($proxy);

        $self->log()->trace('Using Net::SSL, EVN is' . Dumper $ENV);

    } # end of Net:SSL, IO::Socket::SSL
    elsif( $proxy =~ /^https:/i ) {

        use IO::Socket::SSL;
        $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "IO::Socket::SSL";

        my $ssl_opts = {
            verify_hostname => ($self->ssl_ignore_hostname ? 0 : 1)
        };

        if ($self->certificate_p12_file) {
            die "Using pkcs12 containers is not supported by IO::Socket::SSL"
        }

        if ($self->certificate_key_file) {
            if (!$self->certificate_file) {
                die "You need to pass certificate AND key file";
            }
            $ssl_opts->{SSL_key_file}  = $self->certificate_key_file;
            $ssl_opts->{SSL_cert_file}  = $self->certificate_file;

            if ( $self->certificate_key_password ) {
                $ssl_opts->{SSL_passwd_cb} = sub { return $self->certificate_key_password; };
            }

        } elsif ($self->certificate_file) {
            die "You need to pass certificate AND key file";
        }

        if ($self->ca_certificate_path) {
            $ssl_opts->{SSL_ca_path}  = $self->ca_certificate_path;
        }

        if ($self->ca_certificate_file) {
            $ssl_opts->{SSL_ca_file}  = $self->ca_certificate_file;
        }
        # For whatever reason LWP wants the ssl_opts as ARRAYref!
        $client-> proxy($proxy, ssl_opts => [%{$ssl_opts}] );

        $self->log()->trace('Using IO::Socket::SSL with options ' . Dumper $ssl_opts);
    } else {
        # No ssl
        $client->proxy($proxy);
    }

    if ($self->use_microsoft_dot_net_compatible_separator) {
        # This modifies the seperator used in the SOAPAction Header to add
        # the method to the uri. Default is # but .Net expects a slash.
        $client->on_action( sub { join('/', @_) } );
    }

    my @params = $self->_make_head();
    push @params, $self->_make_params( \@args );

    my $som;
    eval {
        $som = $client->call($self->method, @params);
    };
    if ($@) {
       $self->log()->error('SOAP call died: ' . $@);
       die 'Fatal SOAP Error: ' . $@ . " [method=" . $self->method . ", params=(" . join(', ', @params) . ")]";
    }


    # restore environment
    %ENV = %ENV_BACKUP;

    if ($som->fault) {
       $self->log()->error('SOAP call returned error: ' . $som->fault->{faultstring});
       die $som->fault->{faultstring};
    }

    return $som->result;
}


sub get {
    my $self = shift;

    my $result = $self->_soap_call(@_);
    return if (! defined $result);

    if ((ref $result eq 'HASH') && $self->has_attrmap()) {
        my @keys = keys %{$self->attrmap()};
        if (scalar @keys != 1) {
            $self->log()->error('SOAP result is hash but attrmap has more than one item');
            die 'SOAP result is hash but attrmap has more than one item';
        }
        if (!defined $result->{$keys[0]}) {
            return $self->_node_not_exists();
        }
        return $result->{$keys[0]};
    }

    if (ref $result ne '') {
       die "SOAP call result is not a scalar";
    }

    return $result;
}

sub get_size {
    my $self = shift;

    my $result = $self->get_list(@_);
    return scalar @{$result};
}

sub get_list {
    my $self = shift;

    my $result = $self->_soap_call(@_);

    return $self->_node_not_exists() if (! defined $result);

    if (ref $result ne 'ARRAY' ) {
        die "SOAP call result is not a list";
    }

    return @{$result};
}

sub get_keys {
    my $self = shift;

    my $result = $self->get_hash(@_);
    return keys %{$result};
}

sub get_hash {
    my $self = shift;

    my $result = $self->_soap_call(@_);

    return $self->_node_not_exists() if (! defined $result);

    if (ref $result ne 'HASH' ) {
        die "SOAP call result is not a hash";
    }


    my $res;
    if ($self->has_attrmap()) {
        my %map = %{$self->attrmap()};
        foreach my $key (keys %map) {
            $res->{ $map{$key} } = $result->{$key};
        }
        return $res;
    }

    return $result;
}

sub get_meta {
    my $self = shift;
    # FIXME
    die "Sorry that is not supported, yet";
}

sub exists {

    my $self = shift;

    # FIXME
    die "Sorry that is not supported, yet";

}
no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 NAME

Connector::Proxy::SOAP::Lite

=head 1 DESCRIPTION

Make a SOAP call using the SOAP::Lite package. Use get if your SOAP call
expects a scalar result or get_hash for a hashref. get_meta, get_list and
set methods are not supported yet.

=head1 USAGE

=head2 minimal setup

  Connector::Proxy::SOAP::Lite->new({
    LOCATION => 'https://127.0.0.1/soap',
    uri => 'http://schema.company.org/SOAP/Endpoint',
    method => 'GetInfo'
  });

=head2 additional options

=over

=item do_not_use_charset

Boolean, sets $SOAP::Constants::DO_NOT_USE_CHARSET = 1;

=item use_microsoft_dot_net_compatible_separator

Boolean, set the parameter seperator to "/" (forward slash)

=item named_parameters

By default, the passed arguments are used as postional arguments in the
soap call. If you want to use a named parameter, set this to a list of names
used as keys with the passed parameters. If you pass a string, it is split
into a list a the whitespace character (usefull with Config::Std, etc).

=item attrmap

Optional, if set keys of the returned hash are mapped from the given hash.
Keys must be the names of the SOAP response fields, values are the names of
the keys in the connector response. Can be used with I<get> to extract a
single field from the response, must contain one element, value is ignored.


=back

=head2 SSL support

This connector supports client authentication using certificates.

=over

=item use_net_ssl

Set this to a true value to use Net::SSL as backend library (otherwise
IO::Socket::SSL is used). Be aware the Net::SSL does not check the hostname
of the server certificate so Man-in-the-Middle-Attacks might be possible.
You should use this only with a really good reason or if you need support
for PKCS12 containers.

=item ssl_ignore_hostname

Do not validate the hostname of the server certificate (only useful with
IO::Socket::SSL as Net::SSL does not check the hostname at all).

=item certificate_file

Path to a PEM encoded certificate file.

=item certificate_key_file

Path to a PEM encoded key file.

=item certificate_p12_file

Path to a PKCS12 container file. This is only supported by Net:SSL and can
not be used together with certificate_file/certificate_key_file.

=item certificate_key_password

The plain password of your encrypted key or PKCS12 container. Note that
Net::SSL does not support password protected keys. You need to use a PKCS12
container instead! Leave this empty if your key is not protected by a password.

=item ca_certificate_path

Path to a directory with trusted certificates (with openssl hashed names).
Also used to validate the server certificate even if no client authentication
is used.

=item ca_certificate_file

Same as ca_certificate_path pointing to a single file.


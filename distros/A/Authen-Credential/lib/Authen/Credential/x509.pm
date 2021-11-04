#+##############################################################################
#                                                                              #
# File: Authen/Credential/x509.pm                                              #
#                                                                              #
# Description: abstraction of an X.509 credential                              #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Authen::Credential::x509;
use strict;
use warnings;
our $VERSION  = "1.2";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);

#
# inheritance
#

our @ISA = qw(Authen::Credential);

#
# used modules
#

use Authen::Credential qw();
use Params::Validate qw(validate_pos :types);

#
# Params::Validate specification
#

$Authen::Credential::ValidationSpec{x509} = {
    cert    => { type => SCALAR, optional => 1 },
    key     => { type => SCALAR, optional => 1 },
    ca      => { type => SCALAR, optional => 1 },
    ca_file => { type => SCALAR, optional => 1 },
    pass    => { type => SCALAR, optional => 1 },
};

#
# accessors
#

foreach my $name (qw(cert key ca ca_file pass)) {
    no strict "refs";
    *{ $name } = sub {
        my($self);
        $self = shift(@_);
        validate_pos(@_) if @_;
        return($self->{$name});
    };
}

#
# preparators
#

$Authen::Credential::Preparator{x509}{"IO::Socket::SSL"} = sub {
    my($self, %data);
    $self = shift(@_);
    validate_pos(@_) if @_;
    foreach my $tmp ($self->cert(), $ENV{X509_USER_CERT}) {
        next unless defined($tmp);
        $data{SSL_cert_file} = $tmp;
        last;
    }
    foreach my $tmp ($self->key(), $ENV{X509_USER_KEY}) {
        next unless defined($tmp);
        $data{SSL_key_file} = $tmp;
        last;
    }
    foreach my $tmp ($self->ca(), $ENV{X509_CERT_DIR}) {
        next unless defined($tmp);
        $data{SSL_ca_path} = $tmp;
        last;
    }
    foreach my $tmp ($self->ca_file(), $ENV{X509_CERT_FILE}) {
        next unless defined($tmp);
        $data{SSL_ca_file} = $tmp;
        last;
    }
    $data{SSL_passwd_cb} = sub { return($self->pass()) }
        if defined($self->pass());
    $data{SSL_use_cert} = 1 if $data{SSL_cert_file} and $data{SSL_key_file};
    return(\%data);
};

1;

__DATA__

=head1 NAME

Authen::Credential::x509 - abstraction of an X.509 credential

=head1 DESCRIPTION

This helper module for Authen::Credential implements an X.509
credential, see L<http://en.wikipedia.org/wiki/X.509>.

It supports the following attributes:

=over

=item cert

the path of the file holding the certificate

=item key

the path of the file holding the private key

=item pass

the pass-phrase protecting the private key (optional)

=item ca

the path of the directory containing trusted certificates (optional)

=item ca_file

the path of the file that contains the trusted certificate (optional)

=back

It supports the following targets for the prepare() method:

=over

=item IO::Socket::SSL

it returns a reference to a hash containing the suitable options for
IO::Socket::SSL

=back

=head1 EXAMPLE

  use Authen::Credential;
  use IO::Socket::SSL;

  # get the credential from somewhere
  $cred = Authen::Credential->parse(...);

  # use the prepare() method to get ready-to-use data
  $sslopts = $cred->prepare("IO::Socket::SSL");
  $socket = IO::Socket::SSL->new(
      PeerHost => "web.acme.com",
      PeerPort => "https",
      %{ $sslopts },
  );

=head1 SEE ALSO

L<Authen::Credential>,
L<IO::Socket::SSL>,
L<http://en.wikipedia.org/wiki/X.509>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2015

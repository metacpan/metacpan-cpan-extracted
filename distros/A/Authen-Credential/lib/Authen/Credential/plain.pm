#+##############################################################################
#                                                                              #
# File: Authen/Credential/plain.pm                                             #
#                                                                              #
# Description: abstraction of a "plain" credential                             #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Authen::Credential::plain;
use strict;
use warnings;
our $VERSION  = "1.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

#
# inheritance
#

our @ISA = qw(Authen::Credential);

#
# used modules
#

use Authen::Credential qw();
use MIME::Base64 qw(encode_base64);
use Params::Validate qw(validate_pos :types);

#
# Params::Validate specification
#

$Authen::Credential::ValidationSpec{plain} = {
    name => { type => SCALAR },
    pass => { type => SCALAR },
};

#
# accessors
#

foreach my $name (qw(name pass)) {
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

$Authen::Credential::Preparator{plain}{"HTTP.Basic"} = sub {
    my($self);
    $self = shift(@_);
    validate_pos(@_) if @_;
    return("Basic " . encode_base64($self->name() . ":" . $self->pass(), ""));
};

1;

__DATA__

=head1 NAME

Authen::Credential::plain - abstraction of a "plain" credential

=head1 DESCRIPTION

This helper module for Authen::Credential implements a "plain"
credential, that is a pair of name and clear text password.

It supports the following attributes:

=over

=item name

the (usually user) name

=item pass

the associated (clear text) password

=back

It supports the following targets for the prepare() method:

=over

=item HTTP.Basic

HTTP Basic authentication, it returns a string that can be used for
the C<WWW-Authenticate> header

=back

=head1 EXAMPLE

  use Authen::Credential;
  use HTTP::Request;

  # get the credential from somewhere
  $cred = Authen::Credential->parse(...);

  # use the prepare() method to get ready-to-use data
  $req = HTTP::Request->new(GET => $url);
  $req->header(Authorization => $cred->prepare("HTTP.Basic"));

=head1 SEE ALSO

L<Authen::Credential>,
L<http://en.wikipedia.org/wiki/Basic_access_authentication>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2015

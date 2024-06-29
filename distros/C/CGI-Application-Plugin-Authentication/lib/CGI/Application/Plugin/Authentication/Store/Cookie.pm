package CGI::Application::Plugin::Authentication::Store::Cookie;
$CGI::Application::Plugin::Authentication::Store::Cookie::VERSION = '0.25';
use strict;
use warnings;

use base qw(CGI::Application::Plugin::Authentication::Store);
use MIME::Base64 ();
use Digest::SHA ();
use CGI::Cookie  ();

# CONFIGURABLE OPTIONS
#
# - SECRET
#
# If this value is defined, it will be used to protect
# the Cookie values from tampering.  To generate a good
# secret, run the following perl script and cut and paste
# the value it generates into this variable.
#
# perl -MDigest::MD5=md5_base64 -l -e 'print md5_base64($$,time(),rand(9999))'
#
our $SECRET = '';


=head1 NAME

CGI::Application::Plugin::Authentication::Store::Cookie - Cookie based Store

=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Session;
 use CGI::Application::Plugin::Authentication;

  __PACKAGE__->authen->config(
        STORE => ['Cookie', SECRET => "Shhh, don't tell anyone", NAME => 'CAPAUTH_DATA', EXPIRY => '+1y'],
  );

=head1 DESCRIPTION

This module uses a cookie to store authentication information across multiple requests.
It works by creating a cookie that contains the information we would like to store (like
the name of the user that is currently authenticated), and then base64 encoding
the data.  In order to ensure that the information is not manipulated by the end-user, we include
a CRC checksum that is generated along with our secret.  Since the user does not know the value
of the secret, they will not be able to recreate the checksum if they change some of the values, so we
will be able to tell if the information in the cookie has been manipulated.

=head1 THE SECRET

=head2 Choosing a good secret

An easy way to generate a relatively good secret is to run the following perl snippet:

  perl -MDigest::MD5=md5_base64 -l -e 'print md5_base64($$,time(),rand(9999))'

Just use the resulting string as your secret.

=head2 Configuring the secret

There are three ways that you can provide a secret to the module:

=over 4

=item Hardcode the secret

You can hardcode a secret right in the CGI::Application::Plugin::Authentication::Store::Cookie module,
so that you don't have to remember to provide one every time you use the module.  Just open the
source in a text editor and look at the top of the file where it defines 'our $SECRET' and follow
the instruction listed there.

=item Provide the SECRET option when using the module

You can also just provide the secret as an option when using the module using the SECRET
parameter.

  __PACKAGE__->authen->config(
        STORE => ['Cookie', SECRET => "Shhh, don't tell anyone"],
  );

=item Let the module choose a secret for you

And lastly, if you forget to do either of these, the module will use the name of your application
as the secret, but that is not a very good value to use, so a warning will be spit out everytime
it uses this.  This is the least desirable choice, and is only included as a last resort.

=back

=head1 DEPENDENCIES

This module requires the following modules to be available.

=over 4

=item MIME::Base64

=item Digest::SHA

=item CGI::Cookie

=back

=head1 METHODS

=head2 fetch

This method accepts a list of parameters and fetches them from the cookie data.

=cut

sub fetch {
    my $self = shift;
    my @items = map { $self->{cookie}->{data}->{$_} } @_;
    return @items[0..$#items];
}

=head2 save

This method accepts a hash of parameters and values and stores them in the cookie data.

=cut

sub save {
    my $self = shift;
    my %items = @_;
    while (my ($param, $value) = each %items) {
        $self->{cookie}->{data}->{$param} = $value;
    }
    $self->_register_postrun_callback;
    return 1;
}

=head2 delete

This method accepts a list of parameters and deletes them from the cookie data.

=cut

sub delete {
    my $self = shift;
    foreach my $param (@_) {
        delete $self->{cookie}->{data}->{$param};
    }
    $self->_register_postrun_callback;
    return 1;
}

=head2 initialize

This method will check for an existing cookie, and decode the contents for later retrieval.

=cut

sub initialize {
    my $self = shift;

    my @options = $self->options;
    die "Invalid Store Configuration for the Cookie store - options section must contain a hash of values" if @options % 2;
    my %options = @options;
    $self->{cookie}->{options} = \%options;

    my %cookies = CGI::Cookie->fetch;
    if ($cookies{$self->cookie_name}) {
        my $rawdata = $cookies{$self->cookie_name}->value;
        $self->{cookie}->{data} = $self->_decode($rawdata);
    }
#    $self->_register_postrun_callback;

    return;
}

=head2 cookie_name

This method will return the name of the cookie

=cut

sub cookie_name {
    my $self = shift;
    return $self->{cookie}->{options}->{NAME} || 'CAPAUTH_DATA';
}

###
### Helper methods
###

# _register_postrun_callback
#
# We only register the postrun callback once a change has been made to the data
# so that we don't unecesarily send out a cookie.
sub _register_postrun_callback {
    my $self = shift;
    return if $self->{cookie}->{postrun_registered}++;

    $self->authen->_cgiapp->add_callback('postrun', \&_postrun_callback);
    return;
}

# _postrun_callback
#
# This callback will add a cookie to the outgoing headers at the postrun stage
sub _postrun_callback {
    my $self = shift;

    my $store = $self->authen->store;
    my $rawdata = $store->_encode($store->{cookie}->{data});

    my %cookie_params = (
        -name => $store->cookie_name,
        -value => $rawdata,
    );
    $cookie_params{'-expires'} = $store->{cookie}->{options}->{EXPIRY} if $store->{cookie}->{options}->{EXPIRY};
    my $cookie = new CGI::Cookie(%cookie_params);
    $self->header_add(-cookie => [$cookie]);
    return;
}

# _decode
#
# Take a raw cookie value, and decode and verify the data
sub _decode {
    my $self = shift;
    my $rawdata = MIME::Base64::decode(shift);
    return if not $rawdata;

    my %hash = map { split /\=/, $_, 2 } split /\0/, $rawdata;

    my $checksum = delete $hash{c};
    # verify checksum
    if ($checksum eq Digest::SHA::sha1_base64(join("\0", $self->_secret, sort values %hash))) {
        # Checksum verifies so the data is clean
        return \%hash;
    } else {
        # The data could not be verified, so we trash it all
        return;
    }
}

# _encode
#
# Take the data we want to store and encode the data into a cookie
sub _encode {
    my $self = shift;
    my $hash = shift;
    my %hash = %$hash;

    my $checksum = Digest::SHA::sha1_base64(join("\0", $self->_secret, sort values %hash));
    $hash{c} = $checksum;
    my $rawdata = join("\0", map { join('=', $_, $hash{$_}) } keys %hash);
    return MIME::Base64::encode($rawdata, "");
}

# _secret
#
# A unique value for this application that is used to secure the Cookies
sub _secret {
    my $self = shift;
    my $secret = $self->{cookie}->{options}->{SECRET} || $SECRET;
    unless ($secret) {
        $secret = Digest::SHA::sha1_base64( ref $self->authen->_cgiapp );
        warn "using default SECRET!  Please provide a proper SECRET when using the Cookie store (See CGI::Application::Plugin::Authentication::Store::Cookie for details)";
    }
    return $secret;
}

=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Store>, L<CGI::Application::Plugin::Authentication>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;

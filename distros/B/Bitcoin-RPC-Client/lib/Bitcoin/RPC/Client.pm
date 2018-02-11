package Bitcoin::RPC::Client;

use 5.008;

use strict;
use warnings;

use Moo;
use JSON::RPC::Legacy::Client;

our $VERSION  = '0.08';

has jsonrpc  => (is => "lazy", default => sub { "JSON::RPC::Legacy::Client"->new });
has user     => (is => 'ro');
has password => (is => 'ro');
has cookie   => (is => 'ro', isa => \&isa_cookie);
has host     => (is => 'ro');
has wallet   => (is => 'ro');
has port     => (is => "lazy", default => 8332);
has timeout  => (is => "lazy", default => 20);
has debug    => (is => "lazy", default => 0);

# SSL constructor options
#  OpenSSL support has been removed from Bitcoin Core as of v0.12.0
#  but should work with older versions
has ssl      => (is => 'ro', default => 0);
has verify_hostname => (is => 'ro', default => 1);

my $DEBUG_DUMPED = 0;

sub AUTOLOAD {
   my $self   = shift;
   my $method = $Bitcoin::RPC::Client::AUTOLOAD;

   $method =~ s/.*:://;

   return if ($method eq 'DESTROY');

   # Build request URL
   my $url = "";

   # Are we using SSL?
   my $uri = "http://";
   if ($self->ssl eq 1) {
      $uri = "https://";
   }

   # Cookie will take precedence over user/password
   if ($self->cookie) {
      # If cookie is defined its contents become user:password
      $url = $uri . $self->cookie . "\@" . $self->host . ":" . $self->port;
   } elsif ($self->user) {
      $url = $uri . $self->user . ":" . $self->password . "\@" . $self->host . ":" . $self->port;
   } else {
      die "An RPC user or RPC cookie file must be defined";
   }

   # Tack on a specific wallet name if given
   if ($self->wallet) {
      $url .= "/wallet/" . $self->wallet;
   }

   my $client = $self->jsonrpc;

   # Set timeout because bitcoin is slow
   $client->ua->timeout($self->timeout);

   # Set Agent, let them know who we be
   $client->ua->agent("Bitcoin::RPC::Client/" . $VERSION);

   # Turn on debugging for LWP::UserAgent
   if ($self->debug) {
      if (!$DEBUG_DUMPED) { # We only want to set this up once
         $client->ua->add_handler("request_send",  sub { shift->dump; return });
         $client->ua->add_handler("response_done", sub { shift->dump; return });
         $DEBUG_DUMPED = 1;
      }
   } else {# Don't print error message when debug is on.
      # We want to handle broken responses ourself
      $client->ua->add_handler("response_data",
         sub {
            my ($response, $ua, $h, $data) = @_;

            if ($response->is_error) {
               my $content = JSON->new->utf8->decode($data);
               print STDERR "error code: ";
               print STDERR $content->{error}->{code};
               print STDERR ", error message: ";
               print STDERR $content->{error}->{message} . " ($method)\n";
               exit(1);
            } else {
               # If no error then ditch the handler
               # otherwise things that did not error will get handled too
               $ua->remove_handler();
            }

            return;
         }
      );
   }

   # For self signed certs
   if ($self->verify_hostname eq 0) {
      $client->ua->ssl_opts( verify_hostname => 0,
                             SSL_verify_mode => 'SSL_VERIFY_NONE' );
   }

   my $obj = {
      method => $method,
      params => (ref $_[0] ? $_[0] : [@_]),
   };

   my $res = $client->call( $url, $obj );
   if($res) {
      if ($res->is_error) {
         return $res->error_message;
      }

      return $res->result;
   }

   return;
}

# function to setup cookie attrib
sub isa_cookie {

   my $failed = 0;

   # We only want to read this once (limit io).
   open COOKIE, $_[0] or $failed = 1;

   if ($failed) {
      print STDERR "Could not open RPC cookie file: " . $_[0];
      print STDERR "\n";
      exit(1);
   }

   my $cookie = <COOKIE>;
   close COOKIE;
   if (!defined($cookie) or $cookie !~ /:/) {
      print STDERR "Invalid RPC cookie file format\n";
      exit(1);
   }
   $cookie =~ s/\s+//g;
   $_[0] = $cookie;

}

1;

=pod

=head1 NAME

Bitcoin::RPC::Client - Bitcoin Core JSON RPC Client

=head1 SYNOPSIS

   use Bitcoin::RPC::Client;

   # Create Bitcoin::RPC::Client object
   $btc = Bitcoin::RPC::Client->new(
      user     => "username",
      password => "p4ssword",
      host     => "127.0.0.1",
   );

   # Check the block height of our bitcoin node
   #     https://bitcoin.org/en/developer-reference#getblockchaininfo
   $chaininfo = $btc->getblockchaininfo;
   $blocks = $chaininfo->{blocks};

   # Estimate a reasonable transaction fee
   #     https://bitcoin.org/en/developer-reference#estimatefee
   $fee = $btc->estimatesmartfee(6);
   $feerate = $fee->{feerate};

   # Set the transaction fee
   #     https://bitcoin.org/en/developer-reference#settxfee
   $settx = $btc->settxfee($feerate);

   # Check your balance
   # (JSON::Boolean objects must be passed as boolean parameters)
   #     https://bitcoin.org/en/developer-reference#getbalance
   $balance = $btc->getbalance("yourAccountName", 1, JSON::true);

   # Send to an address
   #     https://bitcoin.org/en/developer-reference#sendtoaddress
   $transid = $btc->sendtoaddress("1Ky49cu7FLcfVmuQEHLa1WjhRiqJU2jHxe","0.01");

   # See ex/example.pl for more in depth JSON handling:
   #     https://github.com/whindsx/Bitcoin-RPC-Client/tree/master/ex

=head1 DESCRIPTION

This module implements in Perl the functions that are currently part of the
Bitcoin Core RPC client calls (bitcoin-cli).The function names and parameters
are identical between the Bitcoin Core API and this module. This is done for
consistency so that a developer only has to reference one manual:
https://bitcoin.org/en/developer-reference#remote-procedure-calls-rpcs

=head1 CONSTRUCTOR

$btc = Bitcoin::RPC::Client->new( %options )

This method creates a new C<Bitcoin::RPC::Client> and returns it.

   Key                 Default
   -----------         -----------
   host                undef (Required)
   user                undef (Required)
   password            undef (Required)
   cookie              undef
   port                8332
   wallet              undef
   timeout             20
   ssl                 0
   verify_hostname     1
   debug               0
   syntax              0

cookie - Absolute path to your RPC cookie file (.cookie). When cookie is
defined user and password will be ignored and the contents of cookie will
be used instead.

wallet - Work against specific wallet.dat file when Multi-wallet support is
enabled (Bitcoin Core v0.15+ only)

timeout - Set the timeout in seconds for individual RPC requests. Increase
this for slow bitcoind instances.

ssl - OpenSSL support has been removed from the Bitcoin Core project as of
v0.12.0. However Bitcoin::RPC::Client will work over SSL with earlier versions
or with a reverse web proxy such as nginx.

verify_hostname - Disable SSL certificate verification. Needed when
bitcoind is fronted by a proxy or when using a self-signed certificate.

debug - Turns on raw HTTP request/response output from LWP::UserAgent.

syntax - Removed as of Bitcoin::RPC::Client v0.7, however having the value
set will not break anything.

=head1 AUTHOR

Wesley Hinds wesley.hinds@gmail.com

=head1 AVAILABILITY

The latest branch is avaiable from Github.

https://github.com/whindsx/Bitcoin-RPC-Client.git

=head1 DONATE

1Ky49cu7FLcfVmuQEHLa1WjhRiqJU2jHxe

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Wesley Hinds.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

package Bitcoin::RPC::Client;

use 5.008;

use strict;
use warnings;

use Moo;
use JSON::RPC::Client;

use Bitcoin::RPC::Client::API;

our $VERSION  = '0.06';

has jsonrpc  => (is => "lazy", default => sub { "JSON::RPC::Client"->new });
has user     => (is => 'ro');
has password => (is => 'ro');
has host     => (is => 'ro');
has port     => (is => "lazy", default => 8332);
has timeout  => (is => "lazy", default => 20);
has syntax   => (is => "lazy", default => 0);
has debug    => (is => "lazy", default => 0);

# SSL constructor options
#  OpenSSL support has been removed from Bitcoin Core as of v0.12.0
#  but should work with older versions
has ssl      => (is => 'ro', default => 0);
has verify_hostname => (is => 'ro', default => 1);

sub AUTOLOAD {
   my $self   = shift;
   my $method = $Bitcoin::RPC::Client::AUTOLOAD;

   $method =~ s/.*:://;

   return if ($method eq 'DESTROY');
   # Thanks JSON::RPC::Client

   # Are we using SSL?
   my $uri = "http://";
   if ($self->ssl eq 1) {
      $uri = "https://";
   }
   my $url = $uri . $self->user . ":" . $self->password . "\@" . $self->host . ":" . $self->port;

   my $client = $self->jsonrpc;

   # Set timeout because bitcoin is slow
   $client->ua->timeout($self->timeout); 

   # Set Agent, let them know who we be 
   $client->ua->agent("Bitcoin::RPC::Client/" . $VERSION); 

   # Turn on debugging for LWP::UserAgent
   if ($self->debug) {
      $client->ua->add_handler("request_send",  sub { shift->dump; return });
      $client->ua->add_handler("response_done", sub { shift->dump; return });
   } else {
      # We want to handle broken responses ourself
      $client->ua->add_handler("response_data", 
         sub { 
            my ($response, $ua, $h, $data) = @_;

            if ($response->is_error) {
               my $content = JSON->new->utf8->decode($data);

               print STDERR "error code: ";
               print STDERR $content->{error}->{code} . "\n";
               print STDERR "error message:\n";
               print STDERR $content->{error}->{message}; 
            }

            return;
         }
      );
   }

   # For self signed certs
   if ($self->verify_hostname eq 0) {
      $client->ua->ssl_opts( verify_hostname => 0 );
   }

   #my @params = @_;
   # ^ Should this be here?

   # Need to fix booleans.
   # JSON::true
   # But cant modify @_

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

   # Usage errors are on by default
   if ($self->syntax) {
      # Check that method is even availabe in the API
      hasMethod($method);

      # Print SYNTAX for API call
      failMethod($method);
   }

   return;
}

sub hasMethod {
   my ($method) = @_;

   # Check that method is even availabe in the API
   my $hasMethod = 0;
   foreach my $meth (@Bitcoin::RPC::Client::API::methods) {
      if (lc($meth) eq lc($method)) {
         $hasMethod = 1;
         last;
      }
   }

   if (!$hasMethod) {
      print STDERR "error : Method $method does not exist\n";
   }

   return 1;
}

sub failMethod {
   my ($method) = @_;

   foreach my $entry (@Bitcoin::RPC::Client::API::help) {
      if ($entry =~ /$method / || $entry =~ /$method$/) {
         print STDERR "error : usage: $entry\n";
         last;
      }
   }

   return 1;
}

1;

=pod

=head1 NAME

Bitcoin::RPC::Client - Bitcoin Core API RPCs

=head1 SYNOPSIS

   use Bitcoin::RPC::Client;

   # Create Bitcoin::RPC::Client object
   $btc = Bitcoin::RPC::Client->new(
      user     => "username",
      password => "p4ssword",
      host     => "127.0.0.1",
   );

   # Functions that do not return a JSON object will have a scalar result
   $balance  = $btc->getbalance("yourAccountName");
   print $balance;

   # JSON::Boolean objects must be passed as boolean parameters
   $balance  = $btc->getbalance("yourAccountName", 1, JSON::true);
   print $balance;

   # Getting Data when JSON/hash is returned
   # A person would need to know the JSON elements of
   # the output https://bitcoin.org/en/developer-reference#getinfo
   #
   #{
   #  "version": 130000,
   #  "protocolversion": 70014,
   #  "walletversion": 130000,
   #  "balance": 0.00000000,
   #  "blocks": 584240,
   #  "proxy": "",
   #  "difficulty": 1,
   #  "paytxfee": 0.00500000,
   #  "relayfee": 0.00001000,
   #  "errors": ""
   #}
   $info    = $btc->getinfo;
   $balance = $info->{balance};
   print $balance;
   # 0.0

   # JSON Objects
   # Let's say we want the timeframe value
   #
   #{
   #  "totalbytesrecv": 7137052851,
   #  "totalbytessent": 211648636140,
   #  "uploadtarget": {
   #    "timeframe": 86400,
   #    "target": 0,
   #    "target_reached": false,
   #    "serve_historical_blocks": true,
   #    "bytes_left_in_cycle": 0,
   #    "time_left_in_cycle": 0
   #  }
   #}
   $nettot = $btc->getnettotals;
   $timeframe = $nettot->{uploadtarget}{timeframe};
   print $timeframe;
   # 86400

   # JSON arrays
   # Let's say we want the softfork IDs from the following:
   #
   #{
   #  "chain": "main",
   #  "blocks": 464562,
   #  "headers": 464562,
   #  "pruned": false,
   #  "softforks": [
   #    {
   #      "id": "bip34",
   #      "version": 2,
   #      "reject": {
   #        "status": true
   #      }
   #    },
   #    {
   #      "id": "bip66",
   #      "version": 3,
   #      "reject": {
   #        "status": true
   #      }
   #    }
   $bchain = $btc->getblockchaininfo;
   @forks = @{ $bchain->{softforks} };
   foreach $f (@forks) {
      print $f->{id};
      print "\n";
   }
   # bip34
   # bip66

=head1 DESCRIPTION

This module implements in PERL the functions that are currently part of the
Bitcoin Core RPC client calls (bitcoin-cli).The function names and parameters
are identical between the Bitcoin Core API and this module. This is done for
consistency so that a developer only has to reference one manual:
https://bitcoin.org/en/developer-reference#remote-procedure-calls-rpcs

=head1 CONSTRUCTOR

$btc = Bitcoin::RPC::Client->new( %options )

This method creates a new C<Bitcoin::RPC::Client> and returns it.

   Key                 Default
   -----------         -----------
   user                undef (Required)
   password            undef (Required)
   host                undef (Required)
   port                8332
   timeout             20
   ssl                 0
   verify_hostname     1
   syntax              0
   debug               0

verify_hostname - OpenSSL support has been removed from the Bitcoin Core 
project as of v0.12.0.

syntax - setting to 1 will turn on correct method name checking as well as 
usage errors. This works with all versions of Bitcoin Core, but the API class 
currently only contains what is valid for v0.12.0. You may want to keep this off
if you are using a version other than v0.12.0 and you are getting errors you 
think you should not be getting.

debug - Turns on raw HTTP request/response output from LWP::UserAgent.

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

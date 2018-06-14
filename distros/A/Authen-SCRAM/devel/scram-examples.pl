#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use utf8;
use open qw/:std :utf8/;
use charnames ':full';

use Authen::SCRAM::Client;
use Authen::SCRAM::Server;
use Authen::SASL::SASLprep 1.100 qw/saslprep/;
use JSON::MaybeXS;
use MIME::Base64 qw/encode_base64/;
use Tie::IxHash;
use Path::Tiny;

my $JSON = JSON::MaybeXS->new( ascii => 1, canonical => 1, pretty => 1 );

my @common = (
    iters       => 4096,
    salt        => "saltSALTsalt",
    clientNonce => "clientNONCE",
    serverNonce => "serverNONCE",
);

my @CRED_INPUTS = (
    {
        label => "ASCII",
        user  => "user",
        pass  => "pencil",
        @common,
    },
    {
        label => "ASCII user",
        user  => "user",
        pass  => "p\N{U+00E8}ncil",
        @common,
    },
    {
        label => "ASCII pass",
        user  => "ram\N{U+00F5}n",
        pass  => "pencil",
        @common,
    },
    {
        label => "SASLprep normal",
        user  => "ram\N{U+00F5}n",
        pass  => "p\N{U+00C5}assword",
        @common,
    },
    {
        label => "SASLprep non-normal",
        user  => "ramo\N{U+0301}n",
        pass  => "p\N{U+212B}ssword",
        @common,
    },
    {
        label        => "no-SASLprep",
        user         => "ramo\N{U+0301}n",
        pass         => "p\N{U+212B}ssword",
        skipSASLprep => 1,
        @common,
    },
);

sub nice_string {
    join(
        "",
        map {
            $_ > 127 # if above ASCII
              ? sprintf( "\\u%04x", $_ ) # JSON-style escapes
              : chr($_)                  # else as themselves
        } unpack( "W*", $_[0] )
    );                                   # unpack Unicode characters
}

for my $digest_name (qw/SHA-1 SHA-256/) {
    for my $c (@CRED_INPUTS) {
        my $cred     = {%$c};
        my $label    = $cred->{label} = "$digest_name $cred->{label}";
        my $niceuser = nice_string( $cred->{user} );
        my $nicepass = nice_string( $cred->{pass} );
        say "Test Case: $label";
        say "User: '$niceuser'";
        say "Pass: '$nicepass'";

        my $client = Authen::SCRAM::Client->new(
            digest           => $digest_name,
            username         => $cred->{user},
            password         => $cred->{pass},
            skip_saslprep    => $cred->{skipSASLprep},
            _nonce_generator => sub { $cred->{clientNonce} },
        );

        my ( $stored_key, $client_key, $server_key ) =
          $client->computed_keys( $cred->{salt}, $cred->{iters} );

        my $prepped_user = saslprep( $cred->{user}, 1 );
        my $prepped_pass = saslprep( $cred->{pass}, 1 );
        if ( !$cred->{skipSASLprep} ) {
            say "Prepped User: '" . nice_string($prepped_user) . "'";
            say "Prepped Pass '" . nice_string($prepped_pass) . "'";
        }

        my $server = Authen::SCRAM::Server->new(
            digest        => $digest_name,
            credential_cb => sub {
                my $user = shift;
                if ( $user eq $prepped_user ) {
                    return ( $cred->{salt}, $stored_key, $server_key, $cred->{iters} );
                }
                else {
                    warn "BAD USERNAME MATCH FOR '$user'\n";
                    return;
                }
            },
            _nonce_generator => sub { $cred->{serverNonce} },
        );

        my ( $c1, $c2, $s1, $s2 );

        say "C1: " . nice_string( $c1 = $client->first_msg() );
        say "S1: " . nice_string( $s1 = $server->first_msg($c1) );
        say "C2: " . nice_string( $c2 = $client->final_msg($s1) );
        say "S2: " . nice_string( $s2 = $server->final_msg($c2) );

        $cred->{steps} = [ $c1, $s1, $c2, $s2, "" ];

        say eval { $cred->{valid} = $client->validate($s2) ? \1 : \0; 1 }
          ? "Server: valid"
          : "Server: invalid";
        say "";

        $cred->{salt64}       = encode_base64( delete $cred->{salt} );
        $cred->{authID}       = "";
        $cred->{skipSASLprep} = $cred->{skipSASLprep} ? \1 : \0;
        $cred->{digest}       = $digest_name;

        tie my %thash, "Tie::IxHash";
        for my $k (
            qw/label digest user pass authID skipSASLprep salt64 iters clientNonce serverNonce valid steps/
          )
        {
            $thash{$k} = $cred->{$k};
        }
        my $fname = lc "$label.json";
        $fname =~ tr[ ][-];
        path($fname)->spew( $JSON->encode( \%thash ) );
    }

}

#!/usr/bin/perl -w 
# vim: set ts=4 sw=4 expandtab showmatch
# PODNAME: coinbase.pl 
# above is for POD::Weaver

use strict;
use Getopt::Long; 
use Acme::Coinbase::DefaultAuth;
use Acme::Coinbase::Config;
use File::Basename;
use Digest::SHA qw(hmac_sha256_hex); 
use LWP::UserAgent;
use Data::Dumper;
use Carp;
use Time::HiRes;
use bignum;

my $prog = basename($0);
my $verbose;
my $auth = Acme::Coinbase::DefaultAuth->new();
#my $nonce = time();
my $nonce = Time::HiRes::time() * 1E6;
my $config_file;# = $ENV{HOME} . "/.acmecoinbase.ini";
my $use_curl = 0;

# Usage() : returns usage information
sub Usage {
    "$prog [--verbose] [--use-curl] [--nonce=NONCE] [--config=CONF.ini]\n";
}

# call main()
main();

# main()
sub main {
    GetOptions(
        "verbose!" => \$verbose,
        "config-file=s" => \$config_file,
        "use-curl" => \$use_curl,
        "nonce=n" => \$nonce,
    ) or die Usage();
    $SIG{__WARN__} = sub { Carp::confess $_[0] };
    $SIG{__DIE__} = sub { Carp::confess $_[0] };

    print "$prog: NONCE: $nonce\n";
    my $base = "https://api.coinbase.com/api"; 
    #my $base = "https://api.coinbase.com";
    my $url  = "$base/v1/account/balance";

    my $default_config_file = $ENV{HOME} . "/.acmecoinbase.ini";
    if (!$config_file && -e $default_config_file) {
        $config_file = $default_config_file;
    }
    my $config = Acme::Coinbase::Config->new( );
    if ($config_file && -e $config_file) {
        $config->config_file($config_file);
        $config->read_config();
    }
    my $api_key    = $config->get_param("default", "api_key")    || $auth->api_key(); 
    my $api_secret = $config->get_param("default", "api_secret") || $auth->api_secret();
    #print "$prog: using API key $api_key\n";

    perform_request( $url, $api_key, $api_secret, $verbose );
}


sub perform_request {
    my ( $url, $api_key, $api_secret, $verbose ) = @_;
    if ($use_curl) {
        # use curl to do basic request
        my $sig  = hmac_sha256_hex($nonce . $url . "", $api_secret); 
            # somehow this is different than what we get from non-curl
        print "$prog: in callback, str=$nonce$url, ACCESS_SIGNATURE => $sig\n";
        my $curl = "curl";
        if ($verbose) { $curl .= " --verbose"; }
        my $cmd = "$curl " . 
                    " -H 'Accept: */*' " . 
                    " -H 'Host: coinbase.com' " . 
                    " -H 'ACCESS_KEY: $api_key' " . 
                    " -H 'ACCESS_NONCE: $nonce' " .
                    " -H 'ACCESS_SIGNATURE: $sig' " .
                    " -H 'Connection: close' " . 
                    " -H 'Content-Type: application/json' " . 
                    " $url";
        print "$cmd\n";
        system( $cmd );
        print "\n";
    } else {
        # use LWP::UserAgent
        my $ua = LWP::UserAgent->new();
        $ua->default_headers->push_header( Accept       => "*/*" );
        $ua->default_headers->push_header( ACCESS_KEY   => $api_key );
        $ua->default_headers->push_header( ACCESS_NONCE => $nonce );
        $ua->default_headers->push_header( Host         => "coinbase.com" );
        $ua->default_headers->push_header( Connection   => "close" );
        $ua->default_headers->push_header( "Content-Type" => "application/json" );

        # add ACCESS_SIGNATURE in a request_prepare handler so we can set it knowing the request content
        # ... it doesn't matter for GETs though because the content should be blank (like we see in our code)
        $ua->add_handler( 
            request_prepare => sub { 
                my($request, $ua, $h) = @_; 
                my $content = $request->decoded_content();  # empty string.
                $content = "" unless defined($content);

                my $to_hmac = $nonce . $url . $content;
                my $sig = hmac_sha256_hex( $to_hmac, $api_secret ); 
                print "$prog: in callback, str=$to_hmac, ACCESS_SIGNATURE => $sig\n";
                $request->headers->push_header( ACCESS_SIGNATURE => $sig );
            }
        );

        if ($verbose) {
            # a handler to dump out the request for debugging
            $ua->add_handler( request_send => sub { 
                    print "$prog: verbose mode: BEGIN dump of request object: ***********\n";
                    shift->dump; 
                    print "$prog: verbose mode: END dump of request object: *************\n";
                    return 
                });
        }

        my $response = $ua->get( $url );

        my $noun = $response->is_success() ? "Success" : "Error";
        #print ("$prog: $noun " . $response->status_line . ", content: " . $response->decoded_content . "\n");
        print ("$prog: $noun " . $response->status_line . ", content: " . $response->content . "\n");
    }
}

# this is an example of a header used on the coinbase API, from their docs;
# GET /api/v1/account/balance HTTP/1.1
# Accept: */*
# User-Agent: Ruby
# ACCESS_KEY: <YOUR-API-KEY>
# ACCESS_SIGNATURE: <YOUR-COMPUTED-SIGNATURE>
# ACCESS_NONCE: <YOUR-UPDATED-NONCE>
# Connection: close
# Host: coinbase.com

__END__

=pod

=encoding UTF-8

=head1 NAME

coinbase.pl 

=head1 VERSION

version 0.007

=head1 SYNOPSIS

The synopsis, showing one or more typical command-line usages.

      perl -Ilib bin/coinbase.pl

or

      perl -Ilib bin/coinbase.pl --use-curl

both with and without curl the script outputs some debug info

=head1 DESCRIPTION

Tests checking a balance using the coinbase api

=head1 NAME

coinbase.pl -- Tests checking a balance using the coinbase api

=head1 OPTIONS

Overall view of the options

    coinbase.pl [-verbose] [--use-curl] [--nonce=NONCE] [--config=CONF.ini]

=over 4

=item --config=/dif/coinbase.ini

Set path to an acmecoinbase.ini file. 
The will default to ~/.acmecoinbase.ini

This file is expected to have contents like:

    [default]
    api_key    = 123456apikeyfgYZ
    api_secret = ZZZ111apisecret333DDD444EEE555ZZ

For now, the [default] part is mandatory.

=item --verbose/--noverbose

Turns on/off verbose mode. (off by default)

=item --use-curl

Use curl instead of perl LWP libraries, for test purposes.

=item --nonce=NUMBER

Hard code the nonce to a particular number. For testing. 
(Techically this is supposed to 'always increase')

=back

=head1 COPYRIGHT

Copyright (c) 2014 Josh Rabinowitz, All Rights Reserved.

=head1 AUTHORS

Josh Rabinowitz

=head1 AUTHOR

joshr <joshr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by joshr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#!/usr/bin/env perl

# see http://swxformat.org/php/explorer/

use AMF::Connection;
use HTTP::Cookies;

use JSON;

BEGIN
  {
    no strict 'refs';

    # blessed hash object to JSON object
    map
      {
        my $amf_class = $_;
        my $foo = $amf_class."::TO_JSON";

        # unbless object
        *$foo = sub {
            my $f = $_[0];

            #process_amf_object ($f, $amf_class);

            +{ %{$f} };
          }
      } (
          # add your own remote service classes here - or use an SWFDecompiler

          'flex.messaging.messages.AcknowledgeMessage'
        );

    # blessed hash object to JSON array
    map
      {
        my $foo = $_."::TO_JSON";
        # unbless
        *$foo = sub {
            $_[0]->{'externalizedData'};
          }
      } (
          'flex.messaging.io.ArrayCollection'
        );
  }

my $endpoint = 'http://swxformat.org/php/amf.php';
my $service = 'Twitter';
my $method = 'search';

my $client = new AMF::Connection( $endpoint );

$client->setEncoding(3);
#$client->setHTTPProxy('http://127.0.0.1:8888');
#$client->addHeader( 'serviceBrowser', 'true' );
$client->setHTTPCookieJar( HTTP::Cookies->new(file => "/tmp/lwpcookies.txt", autosave => 1, ignore_discard => 1 ) );

my $params = [  "italy" ];
my ($response) = $client->call( $service.'.'.$method, $params );

my $json = JSON->new;
$json->ascii(1);
$json->utf8(1);
$json->pretty(1);
$json->allow_blessed(1);
$json->convert_blessed(1);
my $json_data = $json->encode( $response->getData );

if ( $response->is_success ) {
        print $json_data;
} else {
        die "Can not send remote request for $service.$method method with params on $endpoint using AMF".$client->getEncoding()." encoding:\n".$json_data."\n";
        };

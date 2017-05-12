#!/usr/bin/env perl

# see http://code.google.com/p/get-flash-videos/

use AMF::Connection;
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

          'com.brightcove.templating.SecondaryContentDTO',
	  'com.brightcove.templating.FeaturedItemDTO',
	  'com.brightcove.catalog.trimmed.VideoDTO',
	  'com.brightcove.utils.BrightcoveDateDTO',
	  'com.brightcove.catalog.TagDTO',
	  'com.brightcove.catalog.VideoCuePointDTO'
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

my $endpoint = 'http://c.brightcove.com/services/amfgateway';
my $service = 'com.brightcove.templating.TemplatingFacade';
my $method = 'getContentForTemplateInstance';

my $client = new AMF::Connection( $endpoint );

# $client->config( ... ); # LWP::UserAgent extra params (proxy, auth etc... )

#$client->setEncoding(3);
#$client->setHTTPProxy('http://127.0.0.1:8888');
#$client->setHTTPCookieJar( HTTP::Cookies->new(file => "/tmp/lwpcookies.txt", autosave => 1, ignore_discard => 1 ) );

# eg taken from http://link.brightcove.com/services/player/bcpid34762914001?bctid=672454611001
# works only with AMF0 encoding - at least it seems so - because using openamf ?
#
my $player_id = '34762914001';
my $videoId = '672454611001';

my $params = [
                                                       $player_id, # param 1 - playerId
                                                       {
                                                         'fetchInfos' => [
                                                                           {
                                                                             'fetchLevelEnum' => '1',
                                                                             'contentType' => 'VideoLineup',
                                                                             'childLimit' => '100'
                                                                           },
                                                                           {
                                                                             'fetchLevelEnum' => '3',
                                                                             'contentType' => 'VideoLineupList',
                                                                             'grandchildLimit' => '100',
                                                                             'childLimit' => '100'
                                                                           }
                                                                         ],
                                                         'optimizeFeaturedContent' => 1,
                                                         'lineupRefId' => undef,
                                                         'lineupId' => undef,
                                                         'videoRefId' => undef,
                                                         'videoId' => $videoId, # param 2 - videoId
                                                         'featuredLineupFetchInfo' => {
                                                                                        'fetchLevelEnum' => '4',
                                                                                        'contentType' => 'VideoLineup',
                                                                                        'childLimit' => '100'
                                                                                      }
                                                       }
                                                     ];

my $response = $client->call( $service.'.'.$method, $params );

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

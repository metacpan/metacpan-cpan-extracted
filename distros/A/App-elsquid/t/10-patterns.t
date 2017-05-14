use strict;
use warnings;

use Test::More;

use App::elsquid;


is_deeply(parse_line('[Adblock Plus 2.0]'),
          {},
          'Discard [Adblock] header');



is_deeply(parse_line('! Title: EasyList'),
          {},
          'Discard comment');



is_deeply(parse_line('||heisebanner.geizhals.at^'),
          { d => "heisebanner.geizhals.at" },
          'Pure domain');

is_deeply(parse_line('||ad-hits.de^$third-party'),
          { d => "ad-hits.de" },
          'Pure domain with EL flag');


is_deeply(parse_line('@@||u-hacks.net/ads.js'),
          {},
          'Discard exception rule');

              
is_deeply(parse_line('der-postillon.com#@#.middleads'),
          {},
          'Discard exception rule (2)');


is_deeply(parse_line('##.werbungamazon'),
          {},
          'Discard element hiding');


is_deeply(parse_line('||amazon.de/s/*&tag=$popup,domain=bluray-disc.de'),
          {},
          'Discard $popup');

is_deeply(parse_line('||pizza.de^*/banner_$third-party'),
          {},
          'Discard $third-party');


is_deeply(parse_line('||hosteurope.de/goloci/$domain=goloci.de'),
          {},
          'Discard $domain');


is_deeply(parse_line('|http://*.com^*|*$script,third-party,domain=sporcle.com'),
          {},
          'Discard |http');


is_deeply(parse_line('||zeckenwetter.de/img/banner/'),
          { u => 'zeckenwetter.de/img/banner/'},
          'Clean url');


# TODO: Some tests for expressions...


done_testing();

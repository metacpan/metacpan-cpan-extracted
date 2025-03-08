package Local::ipinfo;
use parent qw(App::ipinfo);
use experimental qw(signatures);

use Geo::Details;

sub get_info ($app, $ip) {
	bless( {
	  "anycast" => 1,
	  "city" => "Brisbane",
	  "continent" => {
		"code" => "OC",
		"name" => "Oceania"
	  },
	  "country" => "AU",
	  "country_currency" => {
		"code" => "AUD",
		"symbol" => "\$"
	  },
	  "country_flag" => {
		"emoji" => "\x{1f1e6}\x{1f1fa}",
		"unicode" => "U+1F1E6 U+1F1FA"
	  },
	  "country_flag_url" => "https://cdn.ipinfo.io/static/images/countries-flags/AU.svg",
	  "country_name" => "Australia",
	  "hostname" => "one.one.one.one",
	  "ip" => "1.1.1.1",
	  "is_eu" => undef,
	  "latitude" => "-27.4820",
	  "loc" => "-27.4820,153.0136",
	  "longitude" => "153.0136",
	  "meta" => {
		"from_cache" => 0,
		"time" => "1741392418"
	  },
	  "org" => "AS13335 Cloudflare, Inc.",
	  "postal" => 4101,
	  "readme" => "https://ipinfo.io/missingauth",
	  "region" => "Queensland",
	  "timezone" => "Australia/Brisbane"
	}, 'Geo::Details' )
	}

__PACKAGE__;

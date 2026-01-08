package MY::CookieMaker;

###################################################################
### The cookies cases are from:
###    HTTP-CookieJar-0.014/t/add.t
### and
###    HTTP-Cookies-6.11/t/cookies.t
###################################################################

use strict;
use warnings;

our $VERSION = '0.01';

#use FindBin;
#use lib ($FindBin::Bin.'/../blib/lib');

use Test::Deep '!blessed';

use HTTP::Request;
use HTTP::Response;
use HTTP::Cookies;
use HTTP::CookieJar;
use HTTP::Date qw/time2isoz/;
use Firefox::Marionette::Cookie;
use DateTime;

use Cookies::Roundtrip qw/:new/;

my $VERBOSITY = 2;

my $year_plus_one = (localtime)[5] + 1900 + 1;

sub random_path { return '/'.join('', map { chr(ord('a')+int(rand(24+1))) } 1..5).'/'.join('', map { chr(ord('a')+int(rand(24+1))) } 1..5) }
sub random_key { return join('', map { chr(ord('A')+int(rand(24+1))) } 1..5).join('', map { chr(ord('0')+int(rand(9+1))) } 1..2) }
sub random_value { return join('', map { chr(ord('A')+int(rand(24+1))) } 1..5).join('', map { chr(ord('0')+int(rand(9+1))) } 1..2).join('', map { chr(ord('a')+int(rand(24+1))) } 1..5) }
sub random_hostname {  return 'www.'.join('', map { chr(ord('a')+int(rand(24+1))) } 1..9).':80' }
sub random_host { return random_scheme().join('.', map { 5+int(rand(250+1)) } 1..4) }
sub random_scheme { return 'http'.(rand>0.5?'s':'').'://' }
sub random_expiry_date {
	return DateTime->now->add(
		seconds=>int(rand(100)),
		minutes=>int(rand(100)),
		hours=>int(rand(100)),
		days=>int(rand(3))
	)->strftime('%A, %d-%b-%Y %T GMT')
}

sub HTTPCookieJar_make_random {
	my $N = $_[0] // (1+int(rand(3+1)));
	my $c = HTTP::CookieJar->new;

	for(1..$N){
		my $acookstr = random_key().'='.random_value()
			.'; path='.random_path()
			.'; expires='.random_expiry_date()
		;
		$c->add(random_scheme().random_hostname(), $acookstr);
	}
	return $c;
}

sub HTTPCookies_make_random {
	my $N = $_[0] // (1+int(rand(3+1)));
	my $c = HTTP::Cookies->new;

	my @cookies;
	for(1..$N){
		my $req = HTTP::Request->new(GET => random_host());
		$req->header("Host", random_hostname());
		my $res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => random_key()
					.'='
					.random_value()
					.'; path='.random_path()
					.'; expires='.random_expiry_date()
		);
		$c->extract_cookies($res);
	}
	return $c
}

my $li = 1;
our @HTTPCookieJar_cases = (
     {
	label   => "".($li++).") simple key=value secure",
	request => "https://example.com/",
	cookies => ["SID=31d4d96e407aad42"],
	store   => {
	    'example.com' => {
		'/' => {
		    SID => {
			name	     => "SID",
			value	    => "31d4d96e407aad42",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			# originally it does not have expires,
			# if you want to add:
			#expires	   => '2025-09-11 00:58:53Z',
			hostonly	 => 1,
			path	     => "/",
		    }
		}
	    },
	},
    },
    {
	label   => "".($li++).") simple key=value not secure",
	request => "http://example.com/",
	cookies => ["SID=31d4d96e407aad42"],
	store   => {
	    'example.com' => {
		'/' => {
		    SID => {
			name	     => "SID",
			value	    => "31d4d96e407aad42",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			# originally it does not have expires,
			# if you want to add:
			#expires	   => '2025-09-11 00:58:53Z',
			hostonly	 => 1,
			path	     => "/",
		    }
		}
	    },
	},
    },
     {
	label   => "".($li++).") simple key=value quoted value",
	request => "https://example.com/",
	cookies => ["SID=quoted=\"31d4d96e407\", non-quoted=aad42"],
	store   => {
	    'example.com' => {
		'/' => {
		    SID => {
			name	     => "SID",
			value	    => "quoted=\"31d4d96e407\", non-quoted=aad42",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			# originally it does not have expires,
			# if you want to add:
			#expires	   => '2025-09-11 00:58:53Z',
			hostonly	 => 1,
			path	     => "/",
		    }
		}
	    },
	},
    },
    {
	label   => "".($li++).") invalid cookie not stored",
	request => "http://example.com/",
	cookies => [";"],
	store   => {},
    },
    {
	label   => "".($li++).") localhost treated as host only",
	request => "http://localhost/",
	cookies => ["SID=31d4d96e407aad42; Domain=localhost"],
	store   => {
	    'localhost' => {
		'/' => {
		    SID => {
			name	     => "SID",
			value	    => "31d4d96e407aad42",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "localhost",
			hostonly	 => 1,
			path	     => "/",
		    }
		}
	    },
	},
    },
    {
	label   => "".($li++).") single domain level treated as host only",
	request => "http://foobar/",
	cookies => ["SID=31d4d96e407aad42; Domain=foobar"],
	store   => {
	    'foobar' => {
		'/' => {
		    SID => {
			name	     => "SID",
			value	    => "31d4d96e407aad42",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "foobar",
			hostonly	 => 1,
			path	     => "/",
		    }
		}
	    },
	},
    },
    {
	label   => "".($li++).") different domain not stored",
	request => "http://example.com/",
	cookies => ["SID=31d4d96e407aad42; Domain=example.org"],
	store   => {},
    },
    {
	label   => "".($li++).") subdomain not stored",
	request => "http://example.com/",
	cookies => ["SID=31d4d96e407aad42; Domain=www.example.com"],
	store   => {},
    },
    {
	label   => "".($li++).") superdomain stored",
	request => "http://www.example.com/",
	cookies => ["SID=31d4d96e407aad42; Domain=example.com"],
	store   => {
	    'example.com' => {
		'/' => {
		    SID => {
			name	     => "SID",
			value	    => "31d4d96e407aad42",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			path	     => "/",
		    }
		}
	    },
	},
    },
    {
	label   => "".($li++).") path prefix /foo/ stored",
	request => "http://www.example.com/foo/bar",
	cookies => ["SID=31d4d96e407aad42; Path=/foo/"],
	store   => {
	    'www.example.com' => {
		'/foo/' => {
		    SID => {
			name	     => "SID",
			value	    => "31d4d96e407aad42",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "www.example.com",
			hostonly	 => 1,
			path	     => "/foo/",
		    }
		}
	    },
	},
    },
    {
	label   => "".($li++).") path prefix /foo stored",
	request => "http://www.example.com/foo/bar",
	cookies => ["SID=31d4d96e407aad42; Path=/foo"],
	store   => {
	    'www.example.com' => {
		'/foo' => {
		    SID => {
			name	     => "SID",
			value	    => "31d4d96e407aad42",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "www.example.com",
			hostonly	 => 1,
			path	     => "/foo",
		    }
		}
	    },
	},
    },
    {
	label   => "".($li++).") last cookie wins",
	request => "http://example.com/",
	cookies => [ "SID=31d4d96e407aad42", "SID=0000000000000000", ],
	store   => {
	    'example.com' => {
		'/' => {
		    SID => {
			name	     => "SID",
			value	    => "0000000000000000",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			hostonly	 => 1,
			path	     => "/",
		    }
		}
	    },
	},
    },
    {
	label   => "".($li++).") expired supercedes prior",
	request => "http://example.com/",
	cookies => [ "SID=31d4d96e407aad42", "SID=0000000000000000; Max-Age=-60", ],
	store   => { 'example.com' => { '/' => {}, }, },
    },
    {
	label   => "".($li++).") our own, 2 cookies same domain",
	request => "http://example.com/foo/bar",
	cookies => [ "SID1=31d4d96e407aad42-SID1; Path=/", "SID2=31d4d96e407aad42-SID2; Path=/" ],
	store   => {
	    'example.com' => {
		'/' => {
		    SID1 => {
			name	     => "SID1",
			value	    => "31d4d96e407aad42-SID1",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			hostonly	 => 1,
			path	     => "/",
		    },
		    SID2 => {
			name	     => "SID2",
			value	    => "31d4d96e407aad42-SID2",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			hostonly	 => 1,
			path	     => "/",
		    }
		}
	    },
	},
    },
    {
	label   => "".($li++).") separated by path",
	request => "http://example.com/foo/bar",
	cookies => [ "SID=31d4d96e407aad42; Path=/", "SID=0000000000000000", ],
	store   => {
	    'example.com' => {
		'/' => {
		    SID => {
			name	     => "SID",
			value	    => "31d4d96e407aad42",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			hostonly	 => 1,
			path	     => "/",
		    }
		},
		'/foo' => {
		    SID => {
			name	     => "SID",
			value	    => "0000000000000000",
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			hostonly	 => 1,
			path	     => "/foo",
		    }
		}
	    },
	},
    },
    # check that Max-Age supercedes Expires and that Max-Age <= 0 forces
    # expiration
    {
	label   => "".($li++).") max-age supercedes expires",
	request => "http://example.com/",
	cookies => [
	    "lang=en-us; Max-Age=100; Expires=Thu, 1 Jan 1970 00:00:00 GMT",
	    "SID=0000000000000000; Expires=Thu, 3 Jan 4841 00:00:00 GMT",
	    "SID=31d4d96e407aad42; Max-Age=0; Expires=Thu, 3 Jan 4841 00:00:00 GMT",
	    "FOO=0000000000000000; Max-Age=-100; Expires=Thu, 3 Jan 4841 00:00:00 GMT",
	],
	store   => {
	    'example.com' => {
		'/' => {
		    lang => {
			name	     => "lang",
			value	    => "en-us",
			expires	  => ignore(),
			creation_time    => ignore(),
			last_access_time => ignore(),
			domain	   => "example.com",
			hostonly	 => 1,
			path	     => "/",
		    },
		},
	    },
	},
    },
); # end our @HTTPCookieJar_cases

$li = 1;
our @HTTPCookies_cases = (
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);
		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new(GET => "http://1.1.1.1/");
		$req->header("Host", "www.example.com:80");

		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE; path=/ ; expires=Wednesday, 09-Nov-$year_plus_one 23:12:40 GMT");
		print $res->as_string;
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d testing value with quotes', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);
		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new(GET => "http://1.1.1.1/");
		$req->header("Host", "www.example.com:80");

		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => "CUSTOMER=quoted=\"WILE\", non-quoted=_E_COYOTE; path=/ ; expires=Wednesday, 09-Nov-$year_plus_one 23:12:40 GMT");
		print $res->as_string;
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new(GET => "http://www.example.com/");
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie", "PART_NUMBER=ROCKET_LAUNCHER_0001; path=/");
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	# this is an empty cookie!
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$c->extract_cookies(HTTP::Response->new("200", "OK"));
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		interact($c, "http://www.example.com/acme/ammo/specific",
		     'Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"',
		     'Part_Number="Riding_Rocket_0023"; Version="1"; Path="/acme/ammo"');
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new('GET', 'http://www.example.com');
		# this is slow and it changes the site to uk.trip.com thus not accepting cookie
		#$req = HTTP::Request->new('GET', 'http://www.trip.com/trs/trip/flighttracker/flight_tracker_home.xsl');
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->push_header("Set-Cookie"  => qq(trip.appServer=1111-0000-x-024;Domain=.example.com;Path=/));
		$res->push_header("Set-Cookie"  => qq(JSESSIONID=fkumjm7nt1.JS24;Path=/trs));
		$res->push_header("Set-Cookie2" => qq(JSESSIONID=fkumjm7nt1.JS24;Version=1;Discard;Path="/trs"));
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		#$req = HTTP::Request->new('GET', 'http://www.trip.com/trs/trip/flighttracker/flight_tracker_home.xsl');
		$req = HTTP::Request->new('GET', 'http://www.example.com');
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->push_header("Set-Cookie"  => qq(trip.appServer=1111-0000-x-024;Domain=.example.com;Path=/));
		$res->push_header("Set-Cookie"  => qq(JSESSIONID=fkumjm7nt1.JS24;Path=/trs));
		$res->push_header("Set-Cookie2" => qq(JSESSIONID=fkumjm7nt1.JS24;Version=1;Discard;Path="/trs"));
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new('GET', 'http://www.perlmeister.com/scripts');
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		   # Set session/perm cookies and mark their values as "session" vs. "perm"
		   # to recognize them later
		$res->push_header("Set-Cookie"  => qq(s1=session;Path=/scripts));
		$res->push_header("Set-Cookie"  => qq(p1=perm; Domain=.perlmeister.com;Path=/;expires=Fri, 02-Feb-$year_plus_one 23:24:20 GMT));
		$res->push_header("Set-Cookie"  => qq(p2=perm;Path=/;expires=Fri, 02-Feb-$year_plus_one 23:24:20 GMT));
		$res->push_header("Set-Cookie"  => qq(s2=session;Path=/scripts;Domain=.perlmeister.com));
		$res->push_header("Set-Cookie2" => qq(s3=session;Version=1;Discard;Path="/"));
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new(GET => "https://1.1.1.1/");
		$req->header("Host", "www.example.com:80");

		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE ; secure ; path=/");
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new("GET" => "http://example.com");
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => "Expires=10101");
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new("GET" => "http://example.com");
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => "Expires=10101");
		$res->header("Set-Cookie" => ["CUSTOMER=WILE_E_COYOTE; path=/;", ""]);
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new("GET" => "http://example.com");
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => "Expires=10101");
		$res->header("Set-Cookie" => ["CUSTOMER=WILE_E_COYOTE; path=/;", ""]);
		$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE;;path=/;");
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new("GET" => "http://example.com");
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => "Expires=10101");
		$res->header("Set-Cookie" => ["CUSTOMER=WILE_E_COYOTE; path=/;", ""]);
		$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE;;path=/;");
		$res->header("Set-Cookie" => "foo=\"bar\";version=1");
		$c->extract_cookies($res);
		$req = HTTP::Request->new(GET => "http://www.example.com/foo");
		$c->add_cookie_header($req);
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new("GET" => "http://example.com");
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => "Expires=10101");
		$res->header("Set-Cookie" => ["CUSTOMER=WILE_E_COYOTE; path=/;", ""]);
		$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE;;path=/;");
		$res->header("Set-Cookie" => "foo=\"bar\";version=1");
		$c->extract_cookies($res);
		$req = HTTP::Request->new(GET => "http://www.example.com/foo");
		$c->add_cookie_header($req);
		$res->header("Set-Cookie", "PREF=ID=cee18f7c4e977184:TM=1254583090:LM=1254583090:S=Pdb0-hy9PxrNj4LL; expires=Mon, 03-Oct-2211 15:18:10 GMT; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired1=1; expires=Mon, 03-Oct-2001 15:18:10 GMT; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired2=1; expires=Fri Jan  1 00:00:00 GMT 1970; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired3=1; expires=Fri Jan  1 00:00:01 GMT 1970; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired4=1; expires=Thu Dec 31 23:59:59 GMT 1969; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired5=1; expires=Fri Feb  2 00:00:00 GMT 1950; path=/; domain=.example.com");
		$c->extract_cookies($res);
		return $c
	},
  },
  {
	'label' => sprintf('test-%02d', $li++),
	'getcookie' => sub {
		my ($rec, $req, $res, $c);

		$c = HTTP::Cookies->new;
		$req = HTTP::Request->new("GET" => "http://example.com");
		$res = HTTP::Response->new(200, "OK");
		$res->request($req);
		$res->header("Set-Cookie" => "Expires=10101");
		$res->header("Set-Cookie" => ["CUSTOMER=WILE_E_COYOTE; path=/;", ""]);
		$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE;;path=/;");
		$res->header("Set-Cookie" => "foo=\"bar\";version=1");
		$c->extract_cookies($res);
		$req = HTTP::Request->new(GET => "http://www.example.com/foo");
		$c->add_cookie_header($req);
		$res->header("Set-Cookie", "PREF=ID=cee18f7c4e977184:TM=1254583090:LM=1254583090:S=Pdb0-hy9PxrNj4LL; expires=Mon, 03-Oct-2211 15:18:10 GMT; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired1=1; expires=Mon, 03-Oct-2001 15:18:10 GMT; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired2=1; expires=Fri Jan  1 00:00:00 GMT 1970; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired3=1; expires=Fri Jan  1 00:00:01 GMT 1970; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired4=1; expires=Thu Dec 31 23:59:59 GMT 1969; path=/; domain=.example.com");
		$res->push_header("Set-Cookie", "expired5=1; expires=Fri Feb  2 00:00:00 GMT 1950; path=/; domain=.example.com");
		$c->extract_cookies($res);
		$res->header("Set-Cookie", "foo=1; path=/");
		$c->extract_cookies($res);

		$req = HTTP::Request->new(GET => "http://www.example.com/foo");
		$req->header("Cookie", "x=bcd");
		$c->add_cookie_header($req);
		return $c
	},
  },
); # end our @HTTPCookies_cases

$li = 1;
our @FirefoxMarionetteCookies_cases = (
  {
	# these cookies are basically an ARRAY of Firefox::Marionette::Cookie objects
	# so there will be an array of constructor params, one for each Cookie
	'label' => sprintf('test-%02d', $li++),
	'constructor-params' => [
	  {
		"secure" => 0,
		"same_site" => "None",
		"domain" => "www.example.com",
		"http_only" => 0,
		"name" => "_rat",
		"value" => 1383819,
		# expires in the future for sure like this
		"expiry" => time()+16521,
		"path" => "/"
	  },
	],
	'getcookie' => sub {
		my $ffpars = shift;
		my $ret = new_firefoxmarionettecookies($ffpars, undef, $VERBOSITY);
		if( ! defined $ret ){ print STDERR perl2dump($ffpars).__PACKAGE__.", line ".__LINE__." : error call to ".'new_firefoxmarionettecookies()'." has failed for above params.\n"; return undef }
		# return an array of cookies
		return $ret;
	},
  },
  {
	# these cookies are basically an ARRAY of Firefox::Marionette::Cookie objects
	# so there will be an array of constructor params, one for each Cookie
	'label' => sprintf('test-%02d testing with quotes in value', $li++),
	'constructor-params' => [
	  {
		"secure" => 0,
		"same_site" => "None",
		"domain" => "www.example.com",
		"http_only" => 0,
		"name" => "_rat",
		"value" => "quoted=\"138\" and non-quoted=3819",
		# expires in the future for sure like this
		"expiry" => time()+16521,
		"path" => "/"
	  },
	],
	'getcookie' => sub {
		my $ffpars = shift;
		my $ret = new_firefoxmarionettecookies($ffpars, undef, $VERBOSITY);
		if( ! defined $ret ){ print STDERR perl2dump($ffpars).__PACKAGE__.", line ".__LINE__." : error call to ".'new_firefoxmarionettecookies()'." has failed for above params.\n"; return undef }
		# return an array of cookies
		return $ret;
	},
  },
); # end our @FirefoxMarionetteCookies_cases

sub interact
{
    my $c = shift;
    my $url = shift;  
    my $req = HTTP::Request->new(POST => $url);
    $c->add_cookie_header($req);
    my $cookie = $req->header("Cookie");
    my $res = HTTP::Response->new(200, "OK");
    $res->request($req);
    for (@_) { $res->push_header("Set-Cookie2" => $_) }
    $c->extract_cookies($res);
    return $cookie;
}

1;

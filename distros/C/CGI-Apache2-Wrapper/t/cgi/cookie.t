use strict;
use warnings FATAL => 'all';

use Apache::Test;

use Apache::TestUtil;
use Apache::TestRequest qw(GET_BODY GET_HEAD);

plan tests => 12, need_min_module_version('Apache::Test' => 1.29) || need_lwp;

my $module = "TestCGI::cookie";
my $location = Apache::TestRequest::module2url($module);

{
    my $test  = 'new';
    my $value = 'new';
    ok t_cmp(GET_BODY("$location?test=new"),
             $value,
             $test);
}
{
    my $test  = '';
    my $value = 'foo=; path=/quux; domain=example.com';
    my ($header) = (GET_HEAD("$location?test=$test")
                   =~ /^#Set-Cookie:\s+(.+)/m) ;
    ok t_cmp($header,
             $value,
             $test);
}
{
    my $test  = 'bake';
    my $value = 'foo=bake; path=/quux; domain=example.com';
    my ($header) = (GET_HEAD("$location?test=bake")
                   =~ /^#Set-Cookie:\s+(.+)/m) ;
    ok t_cmp($header,
             $value,
             $test);
}
{
    my $test  = 'new';
    my $value = 'new';
    ok t_cmp(GET_BODY("$location?test=new;expires=%2B3M"),
             $value,
             $test);
}
{
    my $test  = 'netscape';
    my $key   = 'apache';
    my $value = 'ok';
    my $cookie = qq{$key=$value};
    ok t_cmp(GET_BODY("$location?test=$test&key=$key", Cookie => $cookie),
             $value,
             $test);
}
{
    my $test  = 'rfc';
    my $key   = 'apache';
    my $value = 'ok';
    my $cookie = qq{\$Version="1"; $key="$value"; \$Path="$location"};
    ok t_cmp(GET_BODY("$location?test=$test&key=$key", Cookie => $cookie),
             qq{"$value"},
             $test);
}
{
    my $test  = 'encoded value with space';
    my $key   = 'apache';
    my $value = 'okie dokie';
    my $cookie = "$key=" . join '',
        map {/ / ? '+' : sprintf '%%%.2X', ord} split //, $value;
    ok t_cmp(GET_BODY("$location?test=$test&key=$key", Cookie => $cookie),
             $value,
             $test);
}
{
    my $test  = 'bake';
    my $key   = 'apache';
    my $value = 'ok';
    my $cookie = "$key=$value";
    my ($header) = GET_HEAD("$location?test=$test&key=$key",
                            Cookie => $cookie) =~ /^#Set-Cookie:\s+(.+)/m;

    ok t_cmp($header, $cookie, $test);
}

{
    my $test = 'cookies';
    my $key = 'first';
    my $cookie1 = qq{\$Version="1"; one="1"};
    my $cookie2 = qq{\$Version="1"; two="2"};
    my $cookie3 = qq{\$Version="1"; three="3"};
    my $value = qq{"1"};

    my $str = GET_BODY("$location?test=$test&key=$key",
                       Cookie  => $cookie1,
                       Cookie  => $cookie2,
                       Cookie  => $cookie3,
                      );

    ok t_cmp($str, $value, $test);
}

{
    my $test = 'cookies';
    my $key = 'two';
    my $cookie1 = qq{\$Version="1"; one="1"};
    my $cookie2 = qq{\$Version="1"; two="2"};
    my $cookie3 = qq{\$Version="1"; three="3"};
    my $value = qq{"2"};

    my $str = GET_BODY("$location?test=$test&key=$key",
                       Cookie  => $cookie1,
                       Cookie  => $cookie2,
                       Cookie  => $cookie3,
                      );

    ok t_cmp($str, $value, $test);
}

{
    my $test = 'cookies';
    my $key = 'name';
    my $cookie1 = qq{\$Version="1"; one="1"};
    my $cookie2 = qq{\$Version="1"; two="2"};
    my $cookie3 = qq{\$Version="1"; three="3"};
    my $value = qq{one three two};

    my $str = GET_BODY("$location?test=$test&key=$key",
                       Cookie  => $cookie1,
                       Cookie  => $cookie2,
                       Cookie  => $cookie3,
                      );

    ok t_cmp($str, $value, $test);
}

{
    my $test = 'overload';
    my $cookie = qq{\$Version="1"; one="1"};
    my $value = qq{one="1"; Version=1};
    my $str = GET_BODY("$location?test=$test", Cookie => $cookie);

    ok t_cmp($str, $value, $test);
}


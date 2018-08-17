use Test::More;

use CGI::BrowserDetect;

my $ua = CGI::BrowserDetect->new(
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36",
	"en-UK, blah, blah, blah"
);

my $detect = $ua->detect(qw/os lang language cnty country device device_type/);

my $expected = {
  'os' => 'macosx',
  'cnty' => 'UK',
  'device_type' => 'computer',
  'lang' => 'en',
  'language' => 'en',
  'country' => 'UK',
};

is_deeply($detect, $expected);

$ua = CGI::BrowserDetect->new(
	HTTP_USER_AGENT => "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
	HTTP_ACCEPT_LANGUAGE => "en-UK, blah, blah, blah"
);

my %detect = $ua->detect(qw/os lang language cnty country device device_type/);
$expected->{os} = 'ios';
$expected->{device} = 'iphone';
$expected->{device_type} = 'mobile';
is_deeply(\%detect, $expected);

$ua = CGI::BrowserDetect->new(
	"Mozilla/5.0 (Linux; Android 4.4.3; KFTHWI Build/KTU84M) en-us; AppleWebKit/537.36 (KHTML, like Gecko) Silk/47.1.79 like Chrome/47.0.2526.80 Safari/537.36");

$detect = $ua->detect(qw/os language country device device_type/);

is_deeply($detect, {
  'os' => 'android',
  'device' => 'android',
  'device_type' => 'tablet',
  'country' => 'US',
  'language' => 'EN'
});


$ua = CGI::BrowserDetect->new(
	"Mozilla/5.0 (Linux; Android 4.4.3; KFTHWI Build/KTU84M) AppleWebKit/537.36 (KHTML, like Gecko) Silk/47.1.79 like Chrome/47.0.2526.80 Safari/537.36");

$detect = $ua->detect(qw/os language country device device_type/);

is_deeply($detect, {
  'os' => 'android',
  'device' => 'android',
  'device_type' => 'tablet',
});

done_testing();

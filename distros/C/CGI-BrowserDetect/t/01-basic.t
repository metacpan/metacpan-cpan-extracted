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

done_testing();

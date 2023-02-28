use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojo::File qw(path);

my $script = path(qw(script proxyforurl))->to_abs;
plan skip_all => 'script/proxyforurl not found' unless -r $script;
my $t = Test::Mojo->new($script);

$t->get_ok('/')->status_is(200)->element_exists('textarea[name=rules]')
  ->element_exists('input[name=url]')->element_exists('input[name=host]')
  ->element_exists('table#pac_log');

$t->get_ok('/pac.js')->status_is(200);
for my $method (qw(
  alert
  dateRange
  dnsDomainIs
  dnsDomainLevels
  dnsResolve
  isInNet
  isPlainHostName
  isResolvable
  localHostOrDomainIs
  myIpAddress
  shExpMatch
  timeRange
  weekdayRange
))
{
  $t->content_like(qr/async\s$method\(/);
}

done_testing;

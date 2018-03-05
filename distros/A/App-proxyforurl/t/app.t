use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'script/proxyforurl not found' unless -e 'script/proxyforurl';
do './script/proxyforurl' or die $@;
my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->element_exists('a[href="//metacpan.org/pod/App::proxyforurl#DESCRIPTION"]')
  ->element_exists('textarea#rules')->element_exists('input#url')->element_exists('input#host')
  ->element_exists('input#rule');

$t->get_ok('/pac.js')->status_is(200);
for my $method (
  qw(
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
  )
  )
{
  $t->content_like(qr{proto\.$method\s+=})->content_like(qr{'$method'});
}

$t->get_ok('/gethostbyname')->status_is(400);

$t->get_ok('/within')->status_is(400);

done_testing;

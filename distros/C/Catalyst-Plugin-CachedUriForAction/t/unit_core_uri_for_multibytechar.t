use utf8;
use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestApp;

my $base = 'http://127.0.0.1';

my $request = Catalyst::Request->new({
    _log => Catalyst::Log->new,
    base => URI->new($base),
    uri  => URI->new("$base/"),
});

my $context = TestApp->new({
    request => $request,
});


my $uri_with_multibyte = URI->new($base);
$uri_with_multibyte->path('/');
$uri_with_multibyte->query_form(
    name => '村瀬大輔',
);

# multibyte with utf8 bytes
is($context->uri_for_action('/chain_root_index', { name => '村瀬大輔' }), $uri_with_multibyte, 'uri_for with utf8 bytes query');

# multibyte with utf8 string
is($context->uri_for_action('/chain_root_index', { name => "\x{6751}\x{702c}\x{5927}\x{8f14}" }), $uri_with_multibyte, 'uri_for with utf8 string query');

# multibyte captures and args
my $action = '/action/chained/roundtrip_urifor_end';

is($context->uri_for_action($action, ['hütte'], 'hütte', {
    test => 'hütte'
}),
'http://127.0.0.1/chained/roundtrip_urifor/h%C3%BCtte/h%C3%BCtte?test=h%C3%BCtte',
'uri_for with utf8 captures and args');

is(
  $context->uri_for_action($action, ['♥'], '♥', { '♥' => '♥'}),
  'http://127.0.0.1/chained/roundtrip_urifor/' . '%E2%99%A5' . '/' . '%E2%99%A5' . '?' . '%E2%99%A5' . '=' . '%E2%99%A5',
    'uri_for with utf8 captures and args');

# ^ the match string is purposefully broken up to aid viewing, please to 'fix' it.

done_testing;

# $Id: 01-verify.t 1846 2005-05-27 20:24:40Z btrott $

use Test::More tests => 21;
use Authen::TypeKey;

my $vars = {
    ts => '1091163746',
    email => 'bentwo@stupidfool.org',
    name => 'Melody',
    nick => 'foobar baz',
    sig => 'GWwAIXbkb2xNrQO2e/r2LDl14ek=:U5+tDsPM0+EXeKzFWsosizG7+VU=',
};
my $q = My::Query->new($vars);

my $tk = Authen::TypeKey->new;
ok($tk, 'Created Authen::TypeKey object');

is($tk->version, 1.1, 'Default protocol version is 1.1');

$tk->token('foo');
is($tk->token, 'foo', 'Token is gettable/settable');

## Test that verify functions with a hash ref.
my $res = $tk->verify($vars);
ok(!$res);
like($tk->errstr, qr/expired/);

## Test that verify works with a query object.
$res = $tk->verify($q);
ok(!$res);
like($tk->errstr, qr/expired/);

$tk->skip_expiry_check(1);
$res = $tk->verify($q);
ok($res);
is($res->{ts}, $q->param('ts'));
is($res->{email}, $q->param('email'));
is($res->{name}, $q->param('name'));
is($res->{nick}, $q->param('nick'));

$tk->skip_expiry_check(0);
$tk->expires(-1);
$res = $tk->verify($q);
ok(!$res);
like($tk->errstr, qr/expired/);

$tk->expires(time);
$res = $tk->verify($q);
ok($res);
is($res->{ts}, $q->param('ts'));
is($res->{email}, $q->param('email'));
is($res->{name}, $q->param('name'));
is($res->{nick}, $q->param('nick'));

$tk->key_url('http://www.example.com/nothing-there');
$res = $tk->verify($q);
ok(!$res);
like($tk->errstr, qr/failed to fetch key/i);

package My::Query;
sub new { my %hash = %{ $_[1] }; bless \%hash, $_[0] }
sub param { $_[0]{$_[1]} }

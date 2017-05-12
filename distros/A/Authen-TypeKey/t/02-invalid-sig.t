# $Id: 02-invalid-sig.t 1915 2006-02-06 06:26:33Z btrott $

use Test::More tests => 2;
use Authen::TypeKey;

# set up some phony values
my $vars = {
    ts => time,
    email => 'foo',
    name => 'foo',
    nick => 'foo',
    sig => 'foo',
};

my $tk = Authen::TypeKey->new;
ok($tk, 'Created Authen::TypeKey object');

my $res = $tk->verify($vars);
ok(!$res, 'Failed Verification');

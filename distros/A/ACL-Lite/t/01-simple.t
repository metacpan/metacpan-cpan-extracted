#! perl -T

use strict;
use warnings;
use Test::More tests => 27;

use ACL::Lite;

my ($perms, $acl, @parr, $pref, $ret);

# permissions in a string
$perms = 'foo,bar';

$acl = ACL::Lite->new(permissions => $perms);

isa_ok($acl, 'ACL::Lite');

ok($acl->check('foo') eq 'foo');
ok($acl->check('bar') eq 'bar');
ok($acl->check(['foo', 'bar']) eq 'foo');
ok(! defined($acl->check('baz')));

test_return_of_permissions($acl);

# permissions in an array reference
$perms = [qw/foo bar/];

$acl = ACL::Lite->new(permissions => $perms);

isa_ok($acl, 'ACL::Lite');

ok($acl->check('foo') eq 'foo');
ok($acl->check('bar') eq 'bar');
ok($acl->check(['foo', 'bar']) eq 'foo');
ok(! defined($acl->check('baz')));

test_return_of_permissions($acl);

# permissions from a provider
$perms = sub {my %p = (anonymous => 1, foo => 1, bar => 1); return \%p};

$acl = ACL::Lite->new(permissions => $perms);

isa_ok($acl, 'ACL::Lite');

ok($acl->check('foo') eq 'foo');
ok($acl->check('bar') eq 'bar');
ok($acl->check(['foo', 'bar']) eq 'foo');
ok(! defined($acl->check('baz')));

test_return_of_permissions($acl);

# anonymous and authenticated permissions
$acl = ACL::Lite->new(permissions => '', uid => undef);

isa_ok($acl, 'ACL::Lite');

$ret = $acl->check('anonymous');
ok(defined $ret && $ret eq 'anonymous', 'Check for anonymous permission of anonymous user.')
    || diag "Return value: $ret:";

$ret = $acl->check('authenticated');
ok(! defined($ret), 'Check for authenticated permission of anonymous user.')
    || diag "Return value: $ret.";

$acl = ACL::Lite->new(permissions => '', uid => 666);

isa_ok($acl, 'ACL::Lite');

$ret = $acl->check('authenticated');
ok(defined $ret && $ret eq 'authenticated', 'Check for authenticated permission of authenticated user.')
    || diag "Return value: $ret:";

$ret = $acl->check('anonymous');
ok(! defined($ret), 'Check for anonymous permission of authenticated user.')
    || diag "Return value: $ret.";

sub test_return_of_permissions {
    my $acl = shift;

    @parr = $acl->permissions;

    is_deeply([sort @parr], ['anonymous', 'bar', 'foo'], "Test return value of permissions method (array).");

    $pref = $acl->permissions;

    is_deeply([sort keys %$pref], ['anonymous', 'bar', 'foo'], "Test return value of permissions method (hash reference).");
}

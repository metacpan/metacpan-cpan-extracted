# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 26; }
    else { plan skip_all => 'Working directory is not in AFS file system ...'; }

    use_ok('AFS::ACL');
}

is(AFS::ACL->ascii2rights('write'), 63, 'ascii2rights');

my $acl = AFS::ACL->new({'foobar' => 'none'}, {'anyuser' => 'write'});
is(ref($acl), 'AFS::ACL', 'AFS::ACL->new()');

$acl->set('rjs' => 'write');
is("$acl->[0]->{rjs}", 'write', 'set');
$acl->nset('opusl' => 'write');
is("$acl->[1]->{opusl}", 'write', 'nset');

$acl->remove('rjs' => 'write');
ok(! defined $acl->[0]->{rjs}, 'remove');

$acl->clear;
ok(! defined $acl->[0]->{foobar}, 'clear');

my $copy = $acl->copy;
is(ref($copy), 'AFS::ACL', 'acl->copy()');

my $rights = AFS::ACL->crights('read');
is($rights, 'rl', 'crights');

my $new_acl = AFS::ACL->retrieve('./');
is(ref($new_acl), 'AFS::ACL', 'AFS::ACL->retrieve()');

is($new_acl->is_clean, 1, 'acl->is_clean()');

can_ok('AFS::ACL', qw(apply));
can_ok('AFS::ACL', qw(copyacl));
can_ok('AFS::ACL', qw(modifyacl));
can_ok('AFS::ACL', qw(cleanacl));
can_ok('AFS::ACL', qw(empty));
can_ok('AFS::ACL', qw(rights2ascii));
can_ok('AFS::ACL', qw(get_rights));
can_ok('AFS::ACL', qw(nget_rights));
can_ok('AFS::ACL', qw(get_users));
can_ok('AFS::ACL', qw(nget_users));
can_ok('AFS::ACL', qw(length));
can_ok('AFS::ACL', qw(nlength));
can_ok('AFS::ACL', qw(exists));
can_ok('AFS::ACL', qw(nexists));
can_ok('AFS::ACL', qw(add));


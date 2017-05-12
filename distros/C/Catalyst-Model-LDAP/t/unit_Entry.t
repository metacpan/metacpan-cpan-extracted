use strict;
use warnings;
use Catalyst::Model::LDAP::Entry;
use Test::More;

plan tests => 6;

my $DN          = 'uflEduUniversityId=FAKE,ou=People,dc=ufl,dc=edu';
my $UID         = 'dwc';
my $LOGIN_SHELL = '/usr/local/bin/glshell';

my $entry = Catalyst::Model::LDAP::Entry->new(
    $DN,
    uid        => $UID,
    loginShell => $LOGIN_SHELL,
);

isa_ok($entry, 'Catalyst::Model::LDAP::Entry');

is($entry->dn, $DN, 'entry DN matches');
is($entry->get_value('uid'), $UID, 'entry uid matches');
is($entry->uid, $UID, 'entry uid via AUTOLOAD matches');
is($entry->get_value('loginShell'), $LOGIN_SHELL, 'entry loginShell matches');
is($entry->loginShell, $LOGIN_SHELL, 'entry loginShell via AUTOLOAD matches');

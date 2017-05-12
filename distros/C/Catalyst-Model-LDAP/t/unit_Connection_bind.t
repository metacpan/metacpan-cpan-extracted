use strict;
use warnings;
use Catalyst::Model::LDAP::Connection;
use Test::More;

plan skip_all => 'set TEST_AUTHOR, LDAP_BINDDN, and LDAP_PASSWORD to enable this test'
    unless $ENV{TEST_AUTHOR} and $ENV{LDAP_BINDDN} and $ENV{LDAP_PASSWORD};
plan tests    => 7;

my $UID = 'dwc';

my $ldap = Catalyst::Model::LDAP::Connection->new(
    host => 'ldap.ufl.edu',
    base => 'ou=People,dc=ufl,dc=edu',
);
isa_ok($ldap, 'Catalyst::Model::LDAP::Connection', 'created connection');

$ldap->bind(
    dn       => $ENV{LDAP_BINDDN},
    password => $ENV{LDAP_PASSWORD},
);

my $mesg = $ldap->search("(uid=$UID)");

isa_ok($mesg, 'Catalyst::Model::LDAP::Search');
ok(! $mesg->is_error, 'server response okay');
is($mesg->count, 1, 'got one entry');

my $entry = $mesg->entry(0);
isa_ok($entry, 'Catalyst::Model::LDAP::Entry');
is($entry->get_value('uid'), $UID, 'entry uid matches');
is($entry->uid, $UID, 'entry uid via AUTOLOAD matches');

use strict;
use warnings;
use Catalyst::Model::LDAP::Connection;
use Test::More;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};
plan tests    => 7;

my $SN = 'TEST';

my $ldap = Catalyst::Model::LDAP::Connection->new(
    host => 'ldap.ufl.edu',
    base => 'ou=People,dc=ufl,dc=edu',
);

isa_ok($ldap, 'Catalyst::Model::LDAP::Connection', 'created connection');

my $mesg = $ldap->search("(sn=$SN)");

isa_ok($mesg, 'Catalyst::Model::LDAP::Search');
ok(! $mesg->is_error, 'server response okay');
ok($mesg->entries, 'got entries');

my $entry = $mesg->entry(0);
isa_ok($entry, 'Catalyst::Model::LDAP::Entry');
is(uc($entry->get_value('sn')), $SN, 'first entry sn matches');
is(uc($entry->sn), $SN, 'first entry sn via AUTOLOAD matches');

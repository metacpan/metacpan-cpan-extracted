use strict;
use warnings;
use Catalyst::Model::LDAP::Connection;
use Net::LDAP::Constant qw/LDAP_SIZELIMIT_EXCEEDED/;
use Test::More;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};
plan tests    => 7;

my $SIZELIMIT = 2;
my $SN        = 'SMITH';

my $ldap = Catalyst::Model::LDAP::Connection->new(
    host    => 'ldap.ufl.edu',
    base    => 'ou=People,dc=ufl,dc=edu',
    options => {
        sizelimit => $SIZELIMIT,
    },
);

isa_ok($ldap, 'Catalyst::Model::LDAP::Connection', 'created connection');

my $mesg = $ldap->search("(sn=$SN)");

isa_ok($mesg, 'Catalyst::Model::LDAP::Search');
is($mesg->code, LDAP_SIZELIMIT_EXCEEDED, 'server response okay');
is($mesg->count, $SIZELIMIT, 'number of entries matches sizelimit');

my $entry = $mesg->entry(0);
isa_ok($entry, 'Catalyst::Model::LDAP::Entry');
is(uc($entry->get_value('sn')), $SN, 'entry sn matches');
is(uc($entry->sn), $SN, 'entry sn via AUTOLOAD matches');

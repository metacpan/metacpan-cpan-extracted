#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 1 + 6*9;

use_ok('Data::Identifier');

foreach my $args (
    [uuid => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31'],
    [oid  => '2.25.185931400843933321174392841337080429617'],
    [uri  => 'urn:uuid:8be115d2-dc2f-4a98-91e1-a6e3075cbc31'],
    [uri  => 'https://uriid.org/uuid/8be115d2-dc2f-4a98-91e1-a6e3075cbc31'],
    [uri  => 'https://uriid.org/8be115d2-dc2f-4a98-91e1-a6e3075cbc31/8be115d2-dc2f-4a98-91e1-a6e3075cbc31'],
    [sid  => 2],
) {
    my $identifier = Data::Identifier->new(@{$args});

    ok(defined($identifier), 'defined');
    is($identifier->type->displayname, 'uuid', 'type name');
    is($identifier->type->uuid, '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'type uuid');
    is($identifier->displayname, 'uuid', 'name');
    is($identifier->uuid, '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'uuid');
    is($identifier->oid, '2.25.185931400843933321174392841337080429617', 'oid');
    is($identifier->uri, 'urn:uuid:8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'uri');
    is($identifier->sid, 2, 'sid');
    is($identifier->ise, '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'ise');
}

exit 0;


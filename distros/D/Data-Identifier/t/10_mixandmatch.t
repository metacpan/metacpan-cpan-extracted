#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 1 + 6*11 + 4*6;

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

    isa_ok($identifier, 'Data::Identifier');
    is($identifier->type->displayname, 'uuid', 'type name');
    is($identifier->type->uuid, '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'type uuid');
    is($identifier->displayname, 'uuid', 'name');
    is($identifier->uuid, '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'uuid');
    is($identifier->oid, '2.25.185931400843933321174392841337080429617', 'oid');
    is($identifier->uri, 'urn:uuid:8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'uri');
    is($identifier->sid, 2, 'sid');
    is($identifier->ise, '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'ise');
    is($identifier->null_to_undef, $identifier, 'not null (null_to_undef)');
    ok(!$identifier->is_null, 'not null (is_null)');
}

foreach my $args (
    [uuid => '00000000-0000-0000-0000-000000000000'],
    [oid => '2.25.0'],
    [sid => 0],
    [sni => 0],
) {
    my $identifier = Data::Identifier->new(@{$args});

    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, '00000000-0000-0000-0000-000000000000', 'uuid');
    is($identifier->oid, '2.25.0', 'oid');
    is($identifier->sid, 0, 'sid');
    ok(!defined($identifier->null_to_undef), 'null (null_to_undef)');
    ok($identifier->is_null, 'null (is_null)');
}

exit 0;

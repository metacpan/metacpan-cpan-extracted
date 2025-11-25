#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 9;

use_ok('Data::Identifier');

my $identifier = Data::Identifier->new(uuid => 'c2cef883-7677-4f0a-9bec-26c6db7afbc1');

ok(defined($identifier), 'defined');
is($identifier->type->uuid, '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'type uuid');
is($identifier->type->sid, 2, 'type sid');
is($identifier->type->displayname, 'uuid', 'type name');
is($identifier->uuid, 'c2cef883-7677-4f0a-9bec-26c6db7afbc1', 'uuid');
is($identifier->uri,  'urn:uuid:c2cef883-7677-4f0a-9bec-26c6db7afbc1', 'uri');
is($identifier->uri(style => 'uriid'),  'https://uriid.org/uuid/c2cef883-7677-4f0a-9bec-26c6db7afbc1', 'uri style uriid');
is($identifier->ise,  'c2cef883-7677-4f0a-9bec-26c6db7afbc1', 'ise');

exit 0;

#!/usr/bin/env perl

use Test::More;
use HTTP::Status    qw(HTTP_OK);

use lib 'lib', 't';
use Couch::DB::Util qw(simplified);
use Test;

#$dump_answers = 1;
#$dump_values  = 1;
#$trace = 1;

my $couch = _framework;
ok defined $couch, 'Created the framework';

my @clients = $couch->clients;
cmp_ok scalar @clients, '==', 1, 'One auto-generated client';

my $client = $clients[0];
isa_ok $client, 'Couch::DB::Client', '...';
is $client->name, '_local', '... found _local in list';

my $client2 = $couch->client('_local');
is $client2->name, '_local', '... found _local by name';
isa_ok $client, 'Couch::DB::Client', '...';

my $server = $client->server;
ok defined $server, 'Server URL';
isa_ok $server, 'Mojo::URL', '...';

##### $client->serverInfo

my $info = _result info => $client->serverInfo(cached => 'NEVER');

ok defined $info, 'Requested server info';
isa_ok $info, 'Couch::DB::Result', '... got results';
ok $info->isReady, '... the results are ready';
cmp_ok $info->code, '==', HTTP_OK, '... the results are ok';

my $data    = $info->answer;
ok defined $data, 'Answer';
isa_ok $data, 'HASH', '...';
is $data->{couchdb}, 'Welcome', '... data as expected';

my $data2  = $data->{version};
ok defined $data2, '... found version';
like $data2, qr/^[0-9.]+$/, '... expected pattern';

my $values  = $info->values;
ok defined $values, 'Take values';
is ref $values, 'HASH', '... returned as HASH';
$trace && warn simplified values => $values;

my $value   = $values->{version};
ok defined $value, "... version value $value";
isa_ok $value, 'version', '... version type';

my $version = $client->version;
ok defined $version, "Asked for the version, got $version";
isa_ok $version, 'version', '...';

##### $client->databaseNames

my $dbs = $client->databaseNames;
$trace && warn simplified values => $dbs->values;

done_testing;

#!/usr/bin/env perl
# Test the Couch::DB::Result paging

use Test::More;

use lib 'lib', 't';
use Test;

#$dump_answers = 1;
#$dump_values  = 1;
#$trace = 1;

my $couch = _framework;
ok defined $couch, 'Created the framework';

#### requestUUDs call

my $u1 = _result uuids1 => $couch->requestUUIDs(100);

my $uuids1 = $u1->values->{uuids};
ok defined $uuids1, '... received uuids';
cmp_ok scalar @$uuids1, '==', 100, '... received enough';

#### freshUUIDs abstraction

my @uuids2 = $couch->freshUUIDs(5);
ok scalar @uuids2, 'freshUUIDs abstraction';
$trace && warn Dumper \@uuids2;
cmp_ok scalar @uuids2, '==', 5, '... received enough';

my @uuids3 = $couch->freshUUIDs(25, bulk => 10);
ok scalar @uuids3, 'freshUUIDs, requires multiple calls';
$trace && warn Dumper \@uuids3;
cmp_ok scalar @uuids3, '==', 25, '... received enough';


done_testing;

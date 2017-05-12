
use strict;
use warnings;
use Test::More;
use Business::RO::CNP;
use utf8;

my $code = 1920229319996;

my $cnp = Business::RO::CNP->new($code);

ok(!$cnp->valid, 'The CNP is not valid');

cmp_ok($cnp->sex, 'ne', 'f', 'The sex is not OK');

cmp_ok($cnp->sex_id, '!=', 2, 'The sex ID is not OK');

cmp_ok($cnp->birthday->ymd, 'ne', '1904-02-29', 'The birthday is not OK');

cmp_ok($cnp->county, 'ne', 'Cluj', 'The county is not OK');

cmp_ok($cnp->county_id, '!=', 12, 'The county ID is not OK');

cmp_ok($cnp->order_number, '!=', 200, 'The order ID is not OK');

cmp_ok($cnp->checksum, '!=', 1, 'The checksum is not OK');

cmp_ok($cnp->validator, '!=', 1, 'The validator is not OK');

cmp_ok($cnp->cnp, '!=', $code + 1, 'The CNP returned is not OK');

done_testing(10);

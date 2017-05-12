
use strict;
use warnings;
use Test::More;
use Business::RO::CNP;
use utf8;

my $code = 1040229319996;

my $cnp = Business::RO::CNP->new($code);

ok($cnp->valid, 'The CNP is valid');

cmp_ok($cnp->sex, 'eq', 'm', 'The sex is OK');

cmp_ok($cnp->sex_id, '==', 1, 'The sex ID is OK');

cmp_ok($cnp->birthday->ymd, 'eq', '1904-02-29', 'The birthday is OK');

cmp_ok($cnp->county, 'eq', 'Sălaj', 'The county is OK');

cmp_ok($cnp->county_id, '==', 31, 'The county ID is OK');

cmp_ok($cnp->order_number, '==', 999, 'The order ID is OK');

cmp_ok($cnp->checksum, '==', 6, 'The checksum is OK');

cmp_ok($cnp->validator, '==', 6, 'The validator is OK');

cmp_ok($cnp->cnp, '==', $code, 'The CNP returned is OK');

done_testing(10);

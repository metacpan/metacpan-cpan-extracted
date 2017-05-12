use Test::More;
use strict; use warnings FATAL => 'all';

use Crypt::Bcrypt::Easy;

my $passwd;
ok $passwd = bcrypt->crypt('cake'), 'default ->crypt() ok';
ok bcrypt->compare( text  => 'cake', crypt => $passwd ),
  'default ->compare() ok';
ok ! bcrypt->compare( text => 'foo', crypt => $passwd ),
  'negative default ->compare() ok';

undef $passwd;

ok $passwd = bcrypt->crypt( text  => 'pie', cost  => 2 ),
  'tuned cost ->crypt() ok';
ok bcrypt->compare( text  => 'pie', crypt => $passwd ),
  'tuned cost ->compare() ok';
ok ! bcrypt->compare( text => 'foo', crypt => $passwd ),
  'negative tuned ->compare() ok';

undef $passwd;

my $bc = new_ok 'Crypt::Bcrypt::Easy';
ok $passwd = $bc->crypt('cake'), 'obj default ->crypt() ok';
ok $bc->compare( text  => 'cake', crypt => $passwd ),
  'obj default ->compare() ok';
ok ! $bc->compare( text => 'foo', crypt => $passwd ),
  'negative obj default ->compare() ok';

undef $passwd;
undef $bc;

$bc = new_ok 'Crypt::Bcrypt::Easy' => [ cost => 2 ];
ok $passwd = $bc->crypt('pie'), 'obj tuned ->crypt() ok';
ok $bc->compare( text  => 'pie', crypt => $passwd ),
  'obj tuned ->compare() ok';
ok ! $bc->compare( text => 'foo', crypt => $passwd ),
  'negative obj tuned ->compare() ok';

undef $passwd;
undef $bc;

ok $passwd = Crypt::Bcrypt::Easy->crypt('pie'),
  '->crypt() as class method ok';
ok !!Crypt::Bcrypt::Easy->compare(text => 'pie', crypt => $passwd),
  '->compare() as class method ok';

undef $passwd;

$passwd = Crypt::Bcrypt::Easy->crypt(text => 'pie', cost => 10);
ok index($passwd, '$2a$10') == 0, '->crypt() as class method with adjusted cost ok'
  or diag explain $passwd;

undef $passwd;

ok $bc = bcrypt( cost => 2 ), 'simple bcrypt constructor ok';
isa_ok $bc, 'Crypt::Bcrypt::Easy';
ok $bc->cost == 2, 'cost() ok';

ok $bc = bcrypt( reset_seed => 1 ), 'bcrypt constructor with reset_seed ok';

done_testing;

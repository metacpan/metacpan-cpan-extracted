#! perl -T
#
# Testing basic functions of iterator.

use strict;
use warnings;
use Test::More tests => 11;

use Data::Transpose::Iterator::Base;

my ($cart, $iter);

$cart = [{isbn => '978-0-2016-1622-4', title => 'The Pragmatic Programmer',
          quantity => 1},
         {isbn => '978-1-4302-1833-3',
          title => 'Pro Git', quantity => 1},
         {isbn => '978-1-4302-1833-3',
          title => 'Pro Git', quantity => 1}
 		];

$iter = new Data::Transpose::Iterator::Base(records => $cart);
isa_ok($iter, 'Data::Transpose::Iterator::Base');

ok($iter->count == 3);

$iter->sort('title');

my $first = $iter->next;
isa_ok($first, 'HASH');
is($first->{title},'Pro Git','iterator has sorted as expected');
is($iter->index,1,'iterator is at expected index');

$iter->reset;
is($iter->index,0,'iterator has reset back to 0');

$iter->sort('title',1);
$first = $iter->next;
is($first->{title},'Pro Git','iterator has sorted as expected');
is($iter->count,2,'iterator has sorted uniquely');

$iter->seed({isbn => '978-0-9779201-5-0', title => 'Modern Perl',
             quantity => 10});

ok($iter->count == 1);
$first = $iter->next;
is($first->{title},'Modern Perl','iterator has sorted as expected');
ok(!$iter->next,'iterator returns nothing when it reaches the end');

# -*- perl -*-

# t/basic.t - basic tests

use Test::More tests => 6389;

BEGIN { use_ok( 'Data::Pager' ) };

my $object = Data::Pager->new({limit => 1000_000_000});

isa_ok ($object, 'Data::Pager');

for(1..1000){
	is($object->set_current($_)->current, $_);
	is($object->current($_), $_);
	is($object->next(), $_ + 1);
}
for(reverse(1..100)){
	is($object->set_current($_)->current, $_);
}
is($object->prev, undef);
is($object->limit, 1000_000_000);
is($object->end, 1000_000_00);
is($object->final, 1000_000_00);
for(0..9){
 	is($object->list->[$_], $_+1);
}
for(10..1100){
	$object->set_current($_);
	is($object->to, $_ * 10);
	is($object->from, $_ * 10 - 10);
	is($object->current, $object->list->[5]);
}

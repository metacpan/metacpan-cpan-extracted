package Jopa;
use Test::More ($] < 5.016) ? (skip_all => 'utf8 support on this perl is broken') : (no_plan);
use parent 'Class::Accessor::Inherited::XS';
use strict;
use utf8;

my $utf8_key = "ц";
my $nonutf_key = "ц";
utf8::encode($nonutf_key);

my $utf8_acc = "тест";
my $nonutf_acc = "тест";
utf8::encode($nonutf_acc);

__PACKAGE__->mk_inherited_accessors([$utf8_acc, $utf8_key], [$nonutf_acc, $nonutf_key]);
my $obj = bless {}, 'Jopa';

is $obj->тест, undef;
$obj->тест(42);
is($obj->тест , 42);
is($obj->{ц}, 42);
is($obj->$utf8_acc, 42);
is($obj->{$utf8_key}, 42);
is($obj->{$nonutf_key}, undef);

is($obj->$nonutf_acc, undef);

is($obj->$nonutf_acc(17), 17);
is($obj->{$nonutf_key}, 17);

is($obj->$utf8_acc, 42);
is($obj->{$utf8_key}, 42);

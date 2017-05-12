package Jopa;
use Test::More ($] >= 5.016) ? (skip_all => 'utf8 support on this perl is not broken') : (no_plan);
use Test::More;
use parent 'Class::Accessor::Inherited::XS';
use utf8;

my $broken_utf8_subs = ($] < 5.016); #see perl5160delta

my $utf8_key = "ц";
my $nonutf_key = "ц";
utf8::encode($nonutf_key);

my $utf8_acc = "тест";
my $nonutf_acc = "тест";
utf8::encode($nonutf_acc);

__PACKAGE__->mk_inherited_accessors([$utf8_acc, $utf8_key], [$nonutf_acc, $nonutf_key]);

is(Jopa->тест, undef);
Jopa->тест(42);
is(Jopa->тест, 42);

is(Jopa->$utf8_acc, 42);
is(Jopa->$nonutf_acc, 42);

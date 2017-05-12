use strict;
use warnings FATAL => 'all';

use Test::More tests => 43;
use File::Slurp;
use File::Temp qw(tempdir);
use Test::TempDatabase;

BEGIN { use_ok('Apache::SWIT::Maker::Conversions');
	use_ok('Apache::SWIT::Maker::Manifest');
	use_ok('Apache::SWIT::Test::Request');
}

# check that ht_make_root_class does inheritance only once
package Foo;
use base 'Apache::SWIT::HTPage';

package main;
my $rc1 = Foo->ht_make_root_class;
isnt($rc1->can('ht_add_widget'), undef);

my $rc2 = Foo->ht_make_root_class('Apache::SWIT::Test::Request');
isnt($rc2->can('ht_add_widget'), undef);

eval { Apache::SWIT::Test::Request->log_error('foobar') };
like($@, qr/foobar/);

is($rc1, $rc2);
is($rc2->can('get_server_port'), undef);

is(Apache::SWIT::Test::Request->get_server_port, 80);
is(Apache::SWIT::Test::Request->get_server_name, 'some.host');

my $r = Apache::SWIT::Test::Request->new({ uri => 'foof/ffo' });
is($r->uri, 'foof/ffo');
is($r->unparsed_uri, 'foof/ffo');

Test::TempDatabase->become_postgres_user;

is(conv_table_to_class('order'), 'Order');
is(conv_table_to_class('customer_order'), 'CustomerOrder');

is(conv_make_full_class('AA', 'B', 'C'), 'AA::B::C');
is(conv_make_full_class('AA', 'B', 'AA::DD'), 'AA::DD');

is(conv_next_dual_test("a/b.pm\nt/323_one.t\nt/dual/110_two.t\n"
			. "t/dual/222_e.t"), "232");
is(conv_next_dual_test("a/b.pm\nt/323_one.t\nt/dual/110_two.t\n"
			. "t/dual/222_e.t\n"), "232");
is(conv_next_dual_test("t/dual/001_load.t"), "011");

is(conv_class_to_app_name("Hello::World"), "hello_world");

my $td = tempdir('/tmp/pltemp_045_XXXXXX', CLEANUP => 1);
write_file("$td/aaa.txt", "ffff\n");
chmod 0444, "$td/aaa.txt";
conv_forced_write_file("$td/aaa.txt", "gggg\n");
is(read_file("$td/aaa.txt"), "gggg\n");
ok(! -w "$td/aaa.txt");

chdir $td;
swmani_write_file("boo/ggg.txt", "hoho");
like(read_file('MANIFEST'), qr/ggg/);
ok(-f "boo/ggg.txt");
swmani_write_file("boo/ccc.txt", "hoho");

eval { swmani_write_file("boo/ccc.txt", "hoho"); };
like($@, qr/Cowardly/);

my $mf = read_file('MANIFEST');
like($mf, qr/ggg/);
like($mf, qr/ccc/);
ok(-f "boo/ccc.txt");

swmani_replace_file("boo/c", "b/c/d/");
ok(! -f "boo/ccc.txt");
ok(-f "b/c/d/cc.txt");
$mf = read_file('MANIFEST');
like($mf, qr#b/c/d/cc\.txt#);
unlike($mf, qr#ccc\.txt#);

is(conv_file_to_class("lib/A/UI/G"), "A::UI::G");
is(conv_file_to_class("lib/A/UI/G.pm"), "A::UI::G");
is(conv_class_to_entry_point("A::UI::G::B"), "g/b");

# and now with root class given
is(conv_class_to_entry_point("A::B::C", "A::B"), "c");

swmani_replace_in_files("hoho", "haha");
my $ccf = read_file("b/c/d/cc.txt"); 
like($ccf, qr/haha/);
unlike($ccf, qr/hoho/);

swmani_replace_in_files("haha\$", "bobo");
$ccf = read_file("b/c/d/cc.txt"); 
like($ccf, qr/bobo/);
unlike($ccf, qr/haha/);

swmani_replace_in_files(sub { s/b(.)/A$1/g; });
$ccf = read_file("b/c/d/cc.txt"); 
like($ccf, qr/AoAo/);
unlike($ccf, qr/bobo/);

chdir '/';

is(conv_next_dual_test(<<ENDS), '021');
t/001_load.t
t/dual/001_load.t
t/dual/011_the_table.t
ENDS

#!/usr/bin/perl

use Test::More tests => 23;
use Test::Exception;
use Test::Deep;
use Data::Dumper;
use lib qw(lib t ../..);

BEGIN {
    use_ok( 'Ambrosia::Meta' ); #test #1
}
require_ok( 'Ambrosia::Meta' ); #test #2

BEGIN {
    use_ok( 'Ambrosia::core::Object' ); #test #3
}
require_ok( 'Ambrosia::core::Object' ); #test #4

use t::Foo;
use t::Bar;

#test create the object
my $my_foo = new_ok t::Foo => [foo_pub1 => 1, foo_pro1 => 2, foo_pri1 => 3]; #test #5

#test access to fields of the object
cmp_ok($my_foo->foo_pub1, '==', 1, 'Public field of Foo.'); #test #6
$my_foo->foo_pub1 = 321;
cmp_ok($my_foo->foo_pub1, '==', 321, 'Public field of Foo.'); #test #7

throws_ok { $my_foo->foo_pro1 } 'Ambrosia::error::Exception::AccessDenied', 'Ambrosia::error::Exception::AccessDenied to protected fields exception thrown'; #test #8
throws_ok { $my_foo->foo_pri1 } 'Ambrosia::error::Exception::AccessDenied', 'Ambrosia::error::Exception::AccessDenied to private fields exception thrown'; #test #9

#test methods of the object
#test static methods
my $H = {foo_pub1 => 1, foo_pub2 => 1, bar_pub1 => 1, bar_pub2 => 1};

my $my_bar = new_ok t::Bar => []; #test #11

cmp_deeply({map {$_ => 1} $my_bar->fields()}, $H, 'fields() is ok'); #test #12

my $string_dump = $my_bar->string_dump();
like($string_dump, '/^\^Storable|||hex|Compress::Zlib\^[a-z0-9]+$/', "string_dump looks good"); #test #13

my $hBar = $my_bar->as_hash(1, qw/
                                  get_list_pri:getListPri
                                  get_list_pro:getListPro
                                  get_list_pri_ex:getListPriEx
                                  get_list_pro_ex:getListProEx
                                  el_pro{0}
                                  el_pro:EL1{1}
                                  /, "twice_pro");

my $asHash = {
    'foo_pub2' => 'foo_pub2',
    'foo_pub1' => 'foo_pub1',
    'bar_pub1' => 'bar_pub1',
    'bar_pub2' => 'bar_pub2',

    'getListPri' => [
            {
                'foo_pub1' => 'Plist1.1',
                'foo_pub2' => 'Plist1.2',
            },
            {
                'foo_pub1' => 'Plist2.1',
                'foo_pub2' => 'Plist2.2',
            }
        ],
    'getListPro' => [
            {
                'foo_pub1' => 'pro list1.1',
                'foo_pub2' => 'pro list1.2',
            },
            {
                'foo_pub1' => 'pro list2.1',
                'foo_pub2' => 'pro list2.2',
            }
        ],

    'getListPriEx' => [
            {
                'foo_pub1' => 'Plist1.1',
                'foo_pub2' => 'Plist1.2',
            },
            {
                'foo_pub1' => 'Plist2.1',
                'foo_pub2' => 'Plist2.2',
            }
        ],
    'getListProEx' => [
            {
                'foo_pub2' => 'pro list1.2',
                'foo_pub1' => 'pro list1.1'
            },
            {
                'foo_pub2' => 'pro list2.2',
                'foo_pub1' => 'pro list2.1'
            }
        ],

    'el_pro' => {
            'foo_pub1' => 'pro list1.1',
            'foo_pub2' => 'pro list1.2',
        },

    'EL1' => {
            'foo_pub1' => 'pro list2.1',
            'foo_pub2' => 'pro list2.2',
        },
    'twice_pro' => 'foo_pro1;foo_pro2',
};

cmp_deeply($hBar, $asHash, 'as_hash() is ok'); #test #14

my $my_bar_copy = new t::Bar();
$my_bar->foo_pub1 = 'modify for copy';
$my_bar->copy_to($my_bar_copy);
cmp_deeply($my_bar_copy->as_hash, $my_bar->as_hash, 'copy_to() is ok'); #test #15

my $my_bar_clone = $my_bar->clone();
my $hBarClone = $my_bar_clone->as_hash(1, qw/
                                  get_list_pri:getListPri
                                  get_list_pro:getListPro
                                  get_list_pri_ex:getListPriEx
                                  get_list_pro_ex:getListProEx
                                  el_pro{0}
                                  el_pro:EL1{1}
                                  /, "twice_pro");
$asHash->{foo_pub1} = 'modify for copy';
cmp_deeply($hBarClone, $asHash, 'clone() is ok'); #test #16

$my_bar_clone = $my_bar->clone(1);
$hBarClone = $my_bar_clone->as_hash(1, qw/
                                  get_list_pri:getListPri
                                  get_list_pro:getListPro
                                  get_list_pri_ex:getListPriEx
                                  get_list_pro_ex:getListProEx
                                  el_pro{0}
                                  el_pro:EL1{1}
                                  /, "twice_pro");
cmp_deeply($hBarClone, $asHash, 'clone(deep) is ok'); #test #17

#$my_bar->equal($my_bar);

ok($my_bar->equal($my_bar) eq '1', 'Self equal self'); #test #18
ok($my_bar->equal($my_bar,0,1) eq '1', 'Self is identical self'); #test #19
ok($my_bar->equal($my_foo,0,0) ne '1', 'Bar not equal Foo'); #test #20

ok($my_bar->equal($my_bar_clone,1) eq '1', 'Bar absolute equal the self clone'); #test #21

$my_bar_clone->foo_pub1 = 1;
cmp_ok($my_bar_clone->foo_pub1, '==', 1, 'Parent field of Foo in Bar.'); #test #22

ok($my_bar->equal($my_bar_clone,0,1) ne '1', 'Modified clone is not identical the self parent'); #test #23

ok($my_bar->equal($my_bar_clone,1) ne '1', 'Bar not absolute equal bar2'); #test #24

{
#TODO parce xml string
my $xmlBar = $my_bar_clone->as_xml(error_ignore => 1, methods => [qw/
                                  get_list_pri:getListPri
                                  get_list_pro:getListPro
                                  get_list_pri_ex:getListPriEx
                                  get_list_pro_ex:getListProEx
                                  el_pro{0}
                                  el_pro:EL1{1}
                                  /, "twice_pro"]);

my $xmlBarToString = $xmlBar->toString(2);
print $xmlBarToString, "\n";
}

{
#TODO parce xml string
my $document = XML::LibXML->createDocument( '1.0', 'utf-8' );
my $node = $document->createElement('test');
my $xmlBar = Ambrosia::core::Object::as_xml_nodes($document, $node, 'repository', {
        Coupon => [
            [{Partner=>'google',Nominal=>1000},{Partner=>'begun',Nominal=>1000}],
            {Partner=>'google',Nominal=>2000}
        ],
    } );

my $xmlBarToString = $xmlBar->toString(2);
print $xmlBarToString, "\n";
}

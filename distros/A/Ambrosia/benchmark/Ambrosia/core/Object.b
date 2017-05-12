#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(lib t);

use Benchmark;
use Data::Dumper;

use Ambrosia::core::ClassFactory;
use Ambrosia::core::Object;
use Bar;

my $bar = new Bar;
$bar->foo_pub1 = 1;

my @fields = $bar->fields;
my @values = ();

my $i = 0;
#timethese(10000, {
#        'new'    => sub {
#            my $my_bar = Bar->new();
#        },
#});
#
#
#timethese(500000, {
#        'fields'    => sub {
#            @fields = $bar->fields();
#        },
#
#        'values'    => sub {
#            @values = $bar->value(@fields);
#        },
#
#        'values_ref'    => sub {
#            my $values = $bar->value(@fields);
#        },
#});
#
#print "2:---------------------------------- \n\n";

my $strDump = $bar->string_dump;
my $obj = Ambrosia::core::Object::string_restore($strDump);

timethese(50000, {
    'string_dump'    => sub { my $strDump = $bar->string_dump(); },
    'string_restore' => sub { my $obj = Ambrosia::core::Object::string_restore($strDump); },

    #'as_hash_simple' => sub { my $h = $bar->as_hash(); },
    #
    #'as_hash_complex'=> sub { my $hBar = $bar->as_hash(1, qw/
    #                              get_list_pri:getListPri
    #                              get_list_pro:getListPro
    #                              get_list_pri_ex:getListPriEx
    #                              get_list_pro_ex:getListProEx
    #                              el1{0}
    #                              el1:EL1{1}
    #                              /, "twice_pro");
    #                    },
    #
    #'as_xml_simple' => sub { my $xmlDoc = $bar->as_xml(); },
    #
    #'as_xml_complex' => sub { my $xmlDoc = $bar->as_xml(error_ignore => 1, methods => [qw/
    #                              get_list_pri:getListPri
    #                              get_list_pro:getListPro
    #                              get_list_pri_ex:getListPriEx
    #                              get_list_pro_ex:getListProEx
    #                              el_pro{0}
    #                              el_pro:EL1{1}
    #                              /, "twice_pro"]);
    #                    },
});

#timethese(5000, {
#    'clone'     => sub { my $h = $bar->clone(); },
#    'cloneDeep' => sub { my $h = $bar->clone(1); },
#});
#
#{
#    print "Compare to equal objects\n";
#    my $my_bar1 = new Bar; #test #9
#    my $my_bar2 = new Bar; #test #9
#
#    timethese(50000, {
#        'identical' => sub { my $eq = $my_bar1->equal($my_bar2,0,1) },
#        'cmp' => sub { my $eq = $my_bar1->equal($my_bar2) },
#        'cmp_deep' => sub { my $eq = $my_bar1->equal($my_bar2,1) },
#    });
#}
#
#{
#    print "Compare to not equal objects\n";
#    my $my_bar1 = new Bar; #test #9
#    my $my_bar2 = new Bar; #test #9
#    $my_bar2->foo_pub1 = 1;
#
#    timethese(50000, {
#        'identical' => sub { my $eq = $my_bar1->equal($my_bar2,0,1) },
#        'cmp' => sub { my $eq = $my_bar1->equal($my_bar2) },
#        'cmp_deep' => sub { my $eq = $my_bar1->equal($my_bar2,1) },
#    });
#}

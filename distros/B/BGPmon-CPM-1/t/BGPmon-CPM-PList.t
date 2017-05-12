#!/usr/bin/perl
#########################
use strict;
#use Test::More skip_all => "";
use Test::More skip_all => "Skipping.  Be sure your database is setup before running the tests mantually." ;
BEGIN {use_ok('BGPmon::CPM::PList')};
BEGIN {use_ok('BGPmon::CPM::PList::Manager')};

#########################
use BGPmon::CPM::PList;
use BGPmon::CPM::PList::Manager;

my $list = BGPmon::CPM::PList::Manager->getListByName("test");
if($list){
  ok($list->delete,"Delete leftover test");
}
$list = BGPmon::CPM::PList->new(name=>'test');
ok($list->save,"First Save Failed");

my $test = BGPmon::CPM::PList->new(name=>'test');
ok($test->load,"Load following save failed");
ok(defined($test->dbid),"The dbid was not defined");
ok(BGPmon::CPM::PList::Manager->get_plists_count > 0,"Count is 0");
my @lists = BGPmon::CPM::PList::Manager->getListNames();
ok((scalar(@lists) > 0),"No lists found");

$list = BGPmon::CPM::PList->new(name=>'test');
ok(!$list->save,"Duplicate save was meant to fail");

ok($test->delete,"Delete record to clean up");



done_testing();
1;

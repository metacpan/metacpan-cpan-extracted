#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BGPmon-CPM-Demo.t'

#########################

use Test::More skip_all => "You must set up your database before running these tests";

BEGIN {use_ok('BGPmon::CPM::Prefix')};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use BGPmon::CPM::Prefix;
use BGPmon::CPM::PList::Manager;
use BGPmon::CPM::PList;
use BGPmon::CPM::Domain;


my $list = BGPmon::CPM::PList->new(name=>'test');
ok($list->save,"List creation failed");

my $domain_obj = BGPmon::CPM::Domain->new(domain=>'localhost');
$list->prefixes({prefix=>'127.0.0.1/32',watch_more_specifics=>1,watch_covering=>1,domains=>[{domain=>'localhost'}]});
ok($list->save,"Second Save Failed");

$list->add_or_edit_prefixes({prefix=>'127.0.0.2',watch_more_specifics=>0,
                         watch_covering=>1,
                         search_paths=>[{path=>"localhost CNAME localhost2"}],
                         authoritative_for=>[{domain=>"localhost"}],
                         domains=>[{domain=>'localhost'}]});
ok($list->save,"Third Save Failed");

$list->add_or_edit_prefixes({prefix=>'127.0.0.2',watch_more_specifics=>0,
                         watch_covering=>1,
                         search_paths=>[{path=>"localhost3 CNAME localhost4"}],
                         authoritative_for=>[{domain=>"localhost5"}],
                         domains=>[{domain=>'localhost6'}]});
ok($list->save,"fourth Save Failed");


my @prefixes = $list->prefixes;
ok(scalar(@prefixes)==2,"prefixes has wrong cardinality " . scalar(@prefixes));

## get the list object for the list we are currently workingon
$list = BGPmon::CPM::PList::Manager->getListByName('test');

$#prefixes = 0;
push @prefixes,'1.2.3/24';
## go through each one and determine if it can be added to the list
foreach my $prefix (@prefixes){
  my @search_paths;
  push @search_paths,{path=>"Whois Expansion",param_prefix=>'1.2.3.4'};

  $list->add_or_edit_prefixes({prefix=>$prefix,watch_more_specifics=>1,
                       watch_covering=>1,
                       search_paths=>\@search_paths});
}
$list->save;

done_testing();
